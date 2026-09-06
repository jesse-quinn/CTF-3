# Changelog

## Initial release

Original docker-in-docker CTF themed on OS command injection in a network-tools
web application. Built to the same architecture as the reference Docker-in-Docker
CTF: one privileged outer container runs its own Docker engine and deploys the
vulnerable inner stack with Docker Compose.

### Challenge

- Web entry point is a "NetDiag" console that runs ping/nslookup/whois. The host
  field is concatenated into the shell command without sanitization, giving OS
  command injection as `www-data` (first inner flag).
- The app config on disk (`/opt/netdiag/scheduler.conf`) leaks the diagnostics
  operator credential. Reusing it over the inner SSH pivot reaches user `diag`
  (second inner flag).
- `diag` has `sudo NOPASSWD` on `/usr/bin/awk`, which spawns a root shell in the
  container (GTFOBins) for the inner root flag (`SHELL_FLAG{...}`).
- Inner root abuses the mounted outer Docker socket to run a container that
  mounts the outer host filesystem and reads the outer root flag. Root also finds
  the outer deploy account credential (`/root/deploy-notes.txt`), which logs in
  over the outer-host SSH port to read the outer user flag. Both outer flags are
  `MAIN_FLAG{...}`.

### Build hygiene

- Inner stack base image and the static Docker client are pulled at build time
  (no pre-baked image tarballs), so the challenge is multi-arch (amd64 and
  arm64).
- The outer Dockerfile declares `VOLUME /var/lib/docker` so the nested engine
  does not run overlay-on-overlay.
- `.dockerignore` keeps git history, docs, license, and runtime state out of the
  build context; `.gitignore` excludes runtime log state.
