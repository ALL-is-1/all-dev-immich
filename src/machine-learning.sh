#!/bin/sh -eux

gunicorn immich_ml.main:app                           \
  --log-config-json "${SNAP}/etc/log_conf.json"       \
  --worker-class immich_ml.config.CustomUvicornWorker \
  --bind 127.0.0.1:3003 --workers 1                   \
  --keep-alive 2 --timeout 120 --graceful-timeout 10
