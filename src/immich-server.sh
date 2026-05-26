#!/bin/sh -eux

# postgresql settings
# _pgurl="$(snapctl get postgresql.url)"
# _pgport="$(snapctl get postgresql.port)"
# _pgdbname="$(snapctl get postgresql.dbname)"
# _pgusername="$(snapctl get postgresql.username)"
# _pgpassword="$(snapctl get postgresql.password)"
# _pgloc="$(snapctl get postgresql.dblocation)"
# _pgdata="$(snapctl get postgresql.pgdata)"

# redis settings
# _redisport="$(snapctl get redis.port)"
# _redishostname="$(snapctl get redis.hostname)"

# immich settings
_host="$(snapctl get host)"
_port="$(snapctl get port)"
_medialoc="$(snapctl get location.media)"
_uploadloc="$(snapctl get location.upload)"

# machine learning settings
_mlon="$(snapctl get ml.enabled)"
_mlcache="$(snapctl get ml.cache)"

# Variables consumed by immich
# export DB_PORT="${_pgport:-5433}"
# export DB_URL="${_pgurl:-127.0.0.1}"
# export DB_HOSTNAME="$DB_URL"
# export DB_DATABASE_NAME="${_pgdbname:-immich}"
# export DB_USERNAME="${_pgusername:-postgres}"
# export DB_PASSWORD="${_pgpassword:-postgres}"
# export PGDATA="${_pgdata:-$SNAP_COMMON/postgresql/database}"
# export DB_DATA_LOCATION="${PGDATA}"

# export REDIS_PORT="${_redisport:-6379}"
# export REDIS_HOSTNAME="${_redishostname:-127.0.0.1}"

export IMMICH_HOST="${_host:-0.0.0.0}"
export IMMICH_PORT="${_port:-3001}"
export UPLOAD_LOCATION="${_uploadloc:-$SNAP_COMMON/upload}"
export IMMICH_MEDIA_LOCATION="${_medialoc:-$SNAP_COMMON/media}"
export IMMICH_API_METRICS_PORT="${_apimetricsport:-3004}"
export IMMICH_MICROSERVICES_METRICS_PORT="${_micrometricsport:-3005}"

export NVIDIA_DRIVER_CAPABILITIES=all
export NVIDIA_VISIBLE_DEVICES=all

export IMMICH_MACHINE_LEARNING_ENABLED="${_mlon:-true}"
export MACHINE_LEARNING_CACHE_FOLDER="${_mlcache:-/tmp/cache}"
export IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:3003

# Node is dumb and requires package.json in $PWD for `node <foo>` to work
cd "${SNAP}/usr/lib/immich/app/server"

node dist/main
