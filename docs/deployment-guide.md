# Required inputs & outputs of Immich

## Snap Details

- **Snap name**: `all-dev-immich`
- **Version**: `2.5.6`
- **Description**: Self-hosted photo and video management platform. FFmpeg, Redis, and PostgreSQL are bundled; the web server listens on port `3001`. Control Tower integration is provided by a `ct-engine` reporting sidecar (it does not manage Immich's own services).

---

## Inputs

### From User

No required inputs — the snap ships with working defaults for the bundled PostgreSQL and Redis.

### From Dev

1. **ml.enabled** (optional, default `true`) — enable/disable the machine-learning service.
2. **DB_* / REDIS_*** (optional) — only relevant when pointing Immich at an external database/cache instead of the bundled ones.

### From Admin

1. **ml.enabled** (optional)
2. **DB_HOSTNAME / DB_PORT / DB_USERNAME / DB_PASSWORD / DB_DATABASE_NAME** (optional)
3. **REDIS_HOSTNAME / REDIS_PORT** (optional)

### Auto-assigned from Control Tower

1. `ct-callback-url` — URL for Control Tower callbacks
2. `ct-deployment-id` — Unique deployment identifier
3. `ct-node-id` — Node identifier in the cluster

### Fixed Data for Users

1. **DB (bundled)**: `127.0.0.1:5433`, db `immich`, user/pass `postgres`/`postgres`
2. **Redis (bundled)**: `127.0.0.1:6379`
3. **ML**: enabled by default

---

## Outputs

| Message Type | Description | Example |
|--------------|-------------|---------|
| `message_initial` | Initial status on installation | "Immich: http://192.168.1.108:3001" |
| `message` | Periodic status updates | "Immich: http://192.168.1.108:3001" |
| `deployment_stop` | Shutdown notification | "all-dev-immich stopped." |

**Output Mode**: `logs`
**Interval**: 5 minutes

---

## Input Configuration Schema

```json
{
  "type": "object",
  "title": "Immich Configuration",
  "required": [],
  "properties": {
    "DB_HOSTNAME": {
      "type": "string",
      "title": "Database Hostname",
      "default": "127.0.0.1",
      "description": "Hostname or IP of the PostgreSQL server (bundled: 127.0.0.1)"
    },
    "DB_PORT": {
      "type": "number",
      "title": "Database Port",
      "default": 5433,
      "description": "PostgreSQL server port (bundled Postgres listens on 5433)"
    },
    "DB_USERNAME": {
      "type": "string",
      "title": "Database Username",
      "default": "postgres",
      "description": "PostgreSQL username"
    },
    "DB_PASSWORD": {
      "type": "string",
      "title": "Database Password",
      "default": "postgres",
      "description": "PostgreSQL password"
    },
    "DB_DATABASE_NAME": {
      "type": "string",
      "title": "Database Name",
      "default": "immich",
      "description": "PostgreSQL database name"
    },
    "REDIS_HOSTNAME": {
      "type": "string",
      "title": "Redis Hostname",
      "default": "127.0.0.1",
      "description": "Hostname or IP of the Redis server"
    },
    "REDIS_PORT": {
      "type": "number",
      "title": "Redis Port",
      "default": 6379,
      "description": "Redis server port"
    },
    "ml.enabled": {
      "type": "boolean",
      "title": "Machine Learning Enabled",
      "default": true,
      "description": "Enable the machine-learning service. When false the configure hook disables the ml daemon."
    }
  },
  "description": "Configure the Immich machine-learning toggle and (optionally) external database/cache endpoints."
}
```

---

## Configuration Template (CT Deployment Payload)

```json
{
  "snaps": [
    {
      "name": "all-dev-immich",
      "refresh": true
    }
  ],
  "snap_config": [
    {
      "snap": "all-dev-immich",
      "settings": {
        "DB_HOSTNAME": "127.0.0.1",
        "DB_PORT": "5433",
        "DB_USERNAME": "postgres",
        "DB_PASSWORD": "postgres",
        "DB_DATABASE_NAME": "immich",
        "REDIS_HOSTNAME": "127.0.0.1",
        "REDIS_PORT": "6379",
        "ml.enabled": "true",
        "ct-node-id": "<ALL_APP_NODE_ID>",
        "ct-callback-url": "<ALL_APP_CALLBACK_URL>",
        "ct-deployment-id": "<ALL_APP_DEPLOYMENT_ID>"
      }
    }
  ],
  "ignore_failures": false,
  "pre_service_actions": [],
  "post_service_actions": [
    {
      "names": [
        "all-dev-immich.server"
      ],
      "action": "restart"
    }
  ],
  "interface_connections": [
    {
      "plug": "all-dev-immich:network",
      "slot": ":network",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:network-bind",
      "slot": ":network-bind",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:opengl",
      "slot": ":opengl",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:mount-observe",
      "slot": ":mount-observe",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:removable-media",
      "slot": ":removable-media",
      "action": "connect"
    }
  ]
}
```

> The configure hook fires automatically on every `snap set` (the `snap_config`
> step). It applies the `ml.enabled` toggle, validates/persists config via
> `ct-engine hook-configure`, and restarts the `ct-engine` sidecar. The
> `post_service_actions` restart of `all-dev-immich.server` ensures the web
> server picks up any changed config.

---

## Usage Examples

### User Deployment (Minimal — bundled DB/Redis, ML on)

```json
{
  "snaps": [{"name": "all-dev-immich", "refresh": true}],
  "snap_config": [{
    "snap": "all-dev-immich",
    "settings": {
      "ct-node-id": "<ALL_APP_NODE_ID>",
      "ct-callback-url": "<ALL_APP_CALLBACK_URL>",
      "ct-deployment-id": "<ALL_APP_DEPLOYMENT_ID>"
    }
  }]
}
```

### Developer Deployment (ML disabled)

```json
{
  "snaps": [{"name": "all-dev-immich", "refresh": true}],
  "snap_config": [{
    "snap": "all-dev-immich",
    "settings": {
      "ml.enabled": "false",
      "ct-node-id": "<ALL_APP_NODE_ID>",
      "ct-callback-url": "<ALL_APP_CALLBACK_URL>",
      "ct-deployment-id": "<ALL_APP_DEPLOYMENT_ID>"
    }
  }]
}
```

### Admin Deployment (External Postgres/Redis)

```json
{
  "snaps": [{"name": "all-dev-immich", "refresh": true}],
  "snap_config": [{
    "snap": "all-dev-immich",
    "settings": {
      "DB_HOSTNAME": "10.0.0.5",
      "DB_PORT": "5432",
      "DB_USERNAME": "immich",
      "DB_PASSWORD": "s3cret",
      "DB_DATABASE_NAME": "immich",
      "REDIS_HOSTNAME": "10.0.0.6",
      "REDIS_PORT": "6379",
      "ml.enabled": "true",
      "ct-node-id": "<ALL_APP_NODE_ID>",
      "ct-callback-url": "<ALL_APP_CALLBACK_URL>",
      "ct-deployment-id": "<ALL_APP_DEPLOYMENT_ID>"
    }
  }]
}
```

---

## Configuration Parameters Reference

| Parameter | Type | Required | Visibility | Default | Description |
|-----------|------|----------|------------|---------|-------------|
| `DB_HOSTNAME` | string | No | user | `127.0.0.1` | PostgreSQL host |
| `DB_PORT` | int | No | user | `5433` | PostgreSQL port (bundled) |
| `DB_USERNAME` | string | No | user | `postgres` | PostgreSQL username |
| `DB_PASSWORD` | string | No | user | `postgres` | PostgreSQL password |
| `DB_DATABASE_NAME` | string | No | user | `immich` | PostgreSQL database name |
| `REDIS_HOSTNAME` | string | No | user | `127.0.0.1` | Redis host |
| `REDIS_PORT` | int | No | user | `6379` | Redis port |
| `ml.enabled` | bool | No | user | `true` | Enable the ML service |
| `ct-callback-url` | url | No | ct | - | Control Tower callback URL |
| `ct-deployment-id` | string | No | ct | - | Deployment identifier |
| `ct-node-id` | string | No | ct | - | Node identifier |

---

## Notes

- Immich runs its own snapd services: `postgresql`, `redis`, `server`,
  `createdb`, `ml`. The `ct-engine` sidecar reports status to Control Tower
  and persists config; it does not launch or supervise those services.
- `DB_*`/`REDIS_*` are bundled by default. They are validated and persisted by
  the engine, but the bundled `server` consumes its hardcoded values from
  `snapcraft.yaml` — wire `immich-server.sh` to read these keys if you need CT
  to drive an external DB/cache.
- `ml.enabled=false` disables the ML daemon via the configure hook.
- Settings are sent as strings via snapd's config API (`snap set`); `int`/`bool`
  values are quoted accordingly (e.g. `"5433"`, `"true"`).
- Logs/status are sent to Control Tower every 5 minutes (`output.interval`).
