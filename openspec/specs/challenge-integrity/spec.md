# challenge-integrity Specification

## Purpose
Keep the CTF-3 Docker-socket-breakout challenge coherent, offline-reproducible, and honest: its build, startup, credential duplication, and walkthrough must stay in sync so the intended solve path works without changing any flag value or credential.

## Requirements

### Requirement: Offline-reproducible climax

The socket-breakout step and any other solve-time action SHALL reuse a container
image already present in the outer Docker engine from the inner build, rather
than pulling a new image (such as `alpine`) that requires network access at solve
time.

#### Scenario: Breakout on a network-isolated host

- **WHEN** a player reaches inner root and runs the documented Stage 5 breakout
  on a host that has no internet access after the initial build
- **THEN** the `docker run --rm -v /:/host ... cat /host/root/root.txt` command
  uses an image the outer engine already holds (`php:8.4-apache`, the web image
  base) and succeeds without any registry pull

### Requirement: Walkthrough honesty about the socket primitive

Where the mounted `docker.sock` yields outer root directly, the WALKTHROUGH SHALL
state that plainly and SHALL NOT claim a downstream credential or SSH stage is
required when it is a realism flourish.

#### Scenario: Outer flags reachable without the netops credential

- **WHEN** a maintainer reads the Stage 5 Notes to learn what gates the outer
  user flag
- **THEN** the walkthrough states that the socket mount is a full outer-root
  primitive, that both outer flags (`user.txt` and `root.txt`) are directly
  readable through it, and that recovering the `netops` credential and logging in
  over outer SSH is an optional realism flourish rather than a requirement

### Requirement: Robust service startup

Service startup SHALL be resilient: any wait for the inner Docker engine SHALL be
bounded and emit a diagnostic on failure rather than hanging silently.

#### Scenario: Container started without required privilege

- **WHEN** the outer container is started without `--privileged` so the nested
  dockerd never becomes ready
- **THEN** `entrypoint.sh` stops waiting after a bounded number of iterations,
  prints a diagnostic naming the likely cause (missing `--privileged`), and exits
  non-zero instead of spinning in the wait loop forever

### Requirement: Reproducible build pins

Base images, language packages, and any fetched static binary the documented
exploit depends on SHALL be pinned, and the pinned static Docker CLI SHALL carry
a maintainer note recording the refresh trigger and its build-time dependencies
so the challenge builds reproducibly.

#### Scenario: Maintainer refreshes an aged pin

- **WHEN** a maintainer opens `docker-web/web.Dockerfile` to update the static
  Docker CLI after its tarball is eventually pruned upstream
- **THEN** a note next to `DOCKER_CLI_VERSION` tells them to bump to the current
  `29.x` and records that the inner build relies on BuildKit for the
  `COPY --chmod` instructions, so the refresh does not silently break the build

### Requirement: Duplicated credential single source of truth

Any challenge credential stored in more than one file SHALL carry, at each
build-side site, a marker naming its partner file, and the maintainer
documentation SHALL provide an assertion that each such password reaches exactly
its intended partner, so a rotation cannot silently desynchronize the login side
from the leaked side.

#### Scenario: Maintainer rotates one copy of a duplicated credential

- **WHEN** a maintainer changes the `diag` or `netops` password in its build-side
  file and runs the documented credential-sync check
- **THEN** the sync marker next to the changed credential names the partner file
  to update, and the grep assertion in the walkthrough fails unless the same
  password also appears in that partner file
