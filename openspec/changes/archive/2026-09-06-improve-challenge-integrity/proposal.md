# Improve challenge integrity for CTF-3 (NetDiag Command-Injection)

## Why

The 2026-09-06 adversarial review of CTF-1..CTF-10 traced the CTF-3 chain end to
end and confirmed it works, but flagged four integrity issues that will bite a
future rebuild or an offline solve, plus two hygiene nits:

- The Stage 5 socket breakout runs `docker run ... alpine`, an image the outer
  engine never pulls during the build. On a network-isolated host (a common CTF
  hosting posture) the climax fails at an image pull and reads as a broken
  challenge.
- Two credentials are each stored in two files with no single source of truth
  (the `diag` password in `web.Dockerfile` and `scheduler.conf`; the `netops`
  password in `Dockerfile` and `deploy-notes.txt`). A maintainer rotating one
  copy but not the other produces a challenge that builds green while the pivot
  silently dead-ends.
- The walkthrough frames the `netops` credential + outer SSH as the intended
  route to the outer user flag, but the socket mount is a full outer-root
  primitive: both outer flags are directly readable, so that stage gates
  nothing.
- The static Docker CLI is hard-pinned to an exact patch (`29.8.0`) with no
  maintainer note about when to refresh it or the BuildKit dependency the inner
  build relies on.
- The outer `entrypoint.sh` waits for dockerd with an unbounded loop, so a run
  without `--privileged` hangs silently with no diagnostic.
- `nano` is installed in the outer image but no documented step uses it.

## What Changes

Documentation and challenge-content hardening only. The ADDED requirements:

- **Offline-reproducible climax**: the Stage 5 breakout reuses an image already
  present in the outer engine from the inner build (`php:8.4-apache`) instead of
  pulling `alpine` at solve time.
- **Walkthrough honesty about the socket primitive**: the walkthrough states
  plainly that the mounted docker.sock yields outer root and both outer flags
  directly, and marks the `netops` SSH stage a realism flourish, not a
  requirement.
- **Robust service startup**: the wait for the inner Docker engine is bounded
  and emits a diagnostic on timeout instead of hanging silently.
- **Reproducible build pins**: the pinned Docker CLI version carries a
  maintainer note about refreshing it and the BuildKit dependency.
- **Duplicated-credential single source of truth**: each duplicated credential
  carries a sync marker naming its partner file, and the maintainer docs carry a
  grep assertion that each password reaches exactly its partner.

## Impact

- Affected: docs (`README.md`, `docs/WALKTHROUGH.md`, `CHANGELOG.md`) and
  challenge content (`Dockerfile`, `entrypoint.sh`, `docker-web/web.Dockerfile`).
- No scoring change: no flag value is altered and no flag file is moved or
  deleted; all five flags remain at their documented paths, owners, and modes.
- No credential rotation: passwords are unchanged; only sync markers and a verify
  step are added.
- No git commit is made; all edits are left uncommitted in the working tree on
  `main`.
