#!/bin/bash

set -e

# Start the outer Docker daemon and the outer SSH daemon.
dockerd > /dev/null 2>&1 &
/usr/sbin/sshd -D > /dev/null 2>&1 &

# Wait for the outer Docker engine before deploying the inner stack. Bound the
# wait so a run without --privileged fails loud instead of hanging silently:
# dockerd is backgrounded, so set -e never trips on its failure.
tries=0
until docker info >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 60 ]; then
        echo "dockerd did not become ready after 60s; did you pass --privileged?" >&2
        exit 1
    fi
    sleep 1
done

# Run CMD (docker compose builds the inner stack and pulls base images).
exec "$@"
