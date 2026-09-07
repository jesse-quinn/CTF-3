# Tasks

## 1. Offline-reproducible climax (R3)

- [x] 1.1 Change the Stage 5 breakout in `docs/WALKTHROUGH.md` from `alpine` to
  `php:8.4-apache` and note that any locally-present image works so no play-time
  pull is needed.
- [x] 1.2 Add a note to `README.md` that the challenge needs no internet at solve
  time (only at build time).

## 2. Walkthrough honesty about the socket primitive (R5)

- [x] 2.1 Rewrite the `docs/WALKTHROUGH.md` Notes section to state that the
  socket mount is a full outer-root primitive, both outer flags are directly
  readable, and the `netops` SSH stage is a realism flourish, not required.

## 3. Robust service startup (R6)

- [x] 3.1 Bound the dockerd wait loop in `entrypoint.sh` and emit a diagnostic
  and `exit 1` on timeout.

## 4. Reproducible build pins (R7)

- [x] 4.1 Add a maintainer note next to `DOCKER_CLI_VERSION` in
  `docker-web/web.Dockerfile` (refresh guidance + BuildKit dependency) and record
  the live-verified pin in `CHANGELOG.md`.

## 5. Duplicated-credential single source of truth (R-sync)

- [x] 5.1 Add a sync marker naming the partner file next to the `netops`
  credential in `Dockerfile`.
- [x] 5.2 Add a sync marker naming the partner file next to the `diag`
  credential in `docker-web/web.Dockerfile`.
- [x] 5.3 Add a maintainer credential-sync verify step to `docs/WALKTHROUGH.md`
  that greps each password out of its login-side file and asserts it appears in
  its leaked-side partner.

## 6. Outer-image hygiene

- [x] 6.1 Drop the unused `nano` package from the outer `Dockerfile`.

## 7. Docs

- [x] 7.1 Add a `CHANGELOG.md` entry dated 2026-09-06 summarizing the integrity
  fixes.
