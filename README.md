# NetDiag Command-Injection CTF

NetDiag Command-Injection CTF is a Capture The Flag challenge that runs as a
single privileged Docker container. Inside it, an outer host runs its own Docker
engine and deploys a small "network diagnostics" web application with Docker
Compose. The application shells out to system tools without sanitizing its
input, so the way in is OS command injection. From there you pivot through the
inner container, escalate to inner root, and finally break back out to the outer
host.

There are five flags:

| Flag file | Location | Prefix |
|---|---|---|
| user_flag.txt | web container, user `www-data` | `FLAG{...}` |
| diag.txt | web container, user `diag` | `FLAG{...}` |
| root.txt | web container, `root` | `SHELL_FLAG{...}` |
| user.txt | outer host, user `netops` | `MAIN_FLAG{...}` |
| root.txt | outer host, `root` | `MAIN_FLAG{...}` |

## Requirements

- Docker Engine that can run a privileged container (Docker Desktop works).
- Internet access on the first run: the inner stack pulls its base image and a
  static Docker client at build time.
- Works on both amd64 and arm64 hosts.

## Running the challenge

```bash
git clone https://github.com/jesse-quinn/CTF-3.git
cd CTF-3
docker image build -t netdiag-ctf:latest .
docker container run -it --rm --privileged \
  --hostname netdiag-ctf --name netdiag-ctf \
  -p 8080:8080 -p 22:22 -p 23:23 \
  netdiag-ctf:latest
```

Run the build and run from inside the cloned `CTF-3` directory. On Docker
Desktop (macOS, Windows) do not use `sudo`; on a Linux host, prefix both
commands with `sudo` or add your user to the `docker` group.

Then wait for the inner Docker Compose stack to finish deploying. The web
application is served on port 8080.

Note: if you use `-d`, you will not see the inner Compose deployment progress.

If some of those host ports are already in use on your machine, remap the left
side of each `-p` flag (for example `-p 18080:8080 -p 2222:22 -p 2323:23`); the
challenge itself is unaffected. The ports are: 8080 web, 22 outer-host SSH, 23
web-container SSH.

## Rules

- Do not read the flag files or the solution notes during setup. The challenge
  is finding them through gameplay.
- The intended solution path is documented, for maintainers, in
  `docs/WALKTHROUGH.md`. It is a spoiler; do not open it if you want to play.

## Credits

This is an original challenge, inspired by the docker-in-docker format of the
Himanshukr000/CTF-DOCKERS collection and themed on OS command injection in a
network-tools web application.
