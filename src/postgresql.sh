#!/bin/sh -eux

_setpriv() {
    setpriv --clear-groups --reuid _daemon_ --regid _daemon_ -- "$@"
}

_data="$(snapctl get postgresql.db)"
_port="$(snapctl get postgresql.port)"
_data="$(snapctl get postgresql.data)"
PGDATA="${_data:-$SNAP_COMMON/postgresql/database}"

export _data _port _data PGDATA

log() {
    printf '%s: %s\n' "$1" "$2"
}

_wait_for_postgres() {
    _tries=0
    while ! pg_isready -h 127.0.0.1 -p "${_port:-5433}" -q; do
        _tries=$((_tries + 1))
        [ "${_tries}" -lt 30 ] || { log "ERROR" "PostgreSQL not ready after 60s"; return 1; }
        sleep 2
    done
}

createdb() {
    _wait_for_postgres

    [ "$(snapctl get postgresql.db)" = "created" ] ||
        _setpriv psql -lqt -U postgres -h 127.0.0.1 -p 5433 | cut -d\| -f1 | grep -qw immich || {
            log "INFO" "Creating postgresql database"
            _setpriv createdb              \
            --no-password                  \
            --host=127.0.0.1               \
            --port="${_port:-5433}"        \
            --username="${user:-postgres}" \
            "${_dbname:-immich}"

        # We need the extension control file but that's not in the normal search path
        # and not modifiable until postgresql 18:
        # https://github.com/postgres/postgres/commit/4f7f7b0375854e2f89876473405a8f21c95012af
        # Thus, pgvecto.rs and vchord must be provided by the postgres snap
        cat > /tmp/enable-vectors.sql << EOF
\c immich
CREATE EXTENSION IF NOT EXISTS vchord CASCADE;
CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;
EOF

        _setpriv psql     \
            --no-password \
            -h 127.0.0.1  \
            -p 5433       \
            -U postgres   \
            -d immich     \
            -f /tmp/enable-vectors.sql

            rm -f /tmp/enable-vectors.sql
        }

    snapctl set postgresql.db=created
}

start() {
    if [ ! -s "${PGDATA}/PG_VERSION" ]; then
        log "INFO" "Initializing postgresql database cluster"
        mkdir -p "${PGDATA}"
        chown _daemon_:_daemon_ "${PGDATA}"
        _setpriv initdb \
            --pgdata="${PGDATA}" \
            --username=postgres \
            --auth=trust \
            --auth-local=trust
    fi

    log "INFO" "Starting postgresql database"
    mkdir -p "${SNAP_COMMON}/postgresql"
    chown _daemon_:_daemon_ "${SNAP_COMMON}/postgresql"
    _setpriv postgres                              \
        -h 127.0.0.1                               \
        -p "${_port:-5433}"                        \
        -k "${SNAP_COMMON}/postgresql"             \
        -c shared_preload_libraries=vchord         \
        -D "${PGDATA}"
}

stop() {
    log "WARN" "Stopping postgresql database"
    pg_pid="$(_setpriv head -1 "${PGDATA}/postmaster.pid")"
    kill -INT "$pg_pid"
}

reload() {
    log "INFO" "Restarting postgresql database"
    stop && start
}

"$@"
