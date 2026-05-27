#!/bin/sh -e

mkdir -p "${SNAP_COMMON}/redis"

exec redis-server \
  --port 6379 \
  --bind 127.0.0.1 \
  --save "" \
  --loglevel warning \
  --dir "${SNAP_COMMON}/redis"
