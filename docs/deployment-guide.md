# Required inputs & outputs of Immich

## Snap Details

- **Snap name**: `all-dev-immich`
- **Version**: `2.5.6`
- **Description**: Self-hosted photo and video management platform. FFmpeg, Redis, and PostgreSQL are bundled; the web server listens on port `3001`. Control Tower integration is provided by a `ct-engine` reporting sidecar (it does not manage Immich's own services).

---

> ## Config is hardcoded — Tower only sends `ct-*` keys
>
> All Immich app settings are **baked into the snap**, so Control Tower does
> **not** push them via `snap set`:
>
> | Setting | Hardcoded value | Where |
> |---------|-----------------|-------|
> | DB host / port | `127.0.0.1` / `5433` | `snapcraft.yaml` `server.environment` |
> | DB name / user / pass | `immich` / `postgres` / `postgres` | same |
> | Redis host / port | `127.0.0.1` / `6379` | same |
> | Machine learning | **on** | `ml` service install-mode `enable` |
>
> The deployment payload therefore sends **only** the automatic `ct-*` keys.
>
> **Why:** snapd config option names must be lowercase ASCII letters/digits/
> hyphens (dots for nesting). Immich's env-var names (`DB_PORT`, `DB_PASSWORD`,
> …) are uppercase/underscore and snapd rejects them with
> `invalid option name`, which fails the whole `snap set` / configure-hook
> change. Hardcoding avoids this entirely.

---

## Inputs

### From User / Dev / Admin

None. The snap is fully self-contained (bundled PostgreSQL + Redis, ML enabled).

### Auto-assigned from Control Tower

1. `ct-callback-url` — URL for Control Tower callbacks
2. `ct-deployment-id` — Unique deployment identifier
3. `ct-node-id` — Node identifier in the cluster

### Fixed (hardcoded) Data

1. **DB**: `127.0.0.1:5433`, db `immich`, user/pass `postgres`/`postgres`
2. **Redis**: `127.0.0.1:6379`
3. **ML**: enabled

---

## Outputs

| Message Type | Description | Example |
|--------------|-------------|---------|
| `message_initial` | Initial status on installation | "Immich: http://192.168.1.10:3001" |
| `message` | Periodic status updates | "Immich: http://192.168.1.10:3001" |
| `deployment_stop` | Shutdown notification | "all-dev-immich stopped." |

**Output Mode**: `logs`
**Interval**: 5 minutes

---

## Input Configuration Schema

The snap exposes **no user-settable app config** — everything is hardcoded.
Only the automatic Control Tower keys are used:

```json
{
  "type": "object",
  "title": "Immich Configuration",
  "required": [],
  "properties": {
    "ct-callback-url": {
      "type": "string",
      "title": "Control Tower Callback URL",
      "description": "Auto-assigned by Control Tower"
    },
    "ct-node-id": {
      "type": "string",
      "title": "Node ID",
      "description": "Auto-assigned by Control Tower"
    },
    "ct-deployment-id": {
      "type": "string",
      "title": "Deployment ID",
      "description": "Auto-assigned by Control Tower"
    }
  },
  "description": "Immich app settings are hardcoded in the snap; Control Tower only supplies the ct-* integration keys."
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

> ⚠️ Do **not** add `DB_*`/`REDIS_*` (or any uppercase/underscore) keys to
> `settings` — snapd rejects them with `invalid option name` and the deploy
> fails. Those values are hardcoded in the snap.

---

## Configuration Parameters Reference

| Parameter | Type | Required | Visibility | Default | Description |
|-----------|------|----------|------------|---------|-------------|
| `ct-callback-url` | url | No | ct | - | Control Tower callback URL |
| `ct-deployment-id` | string | No | ct | - | Deployment identifier |
| `ct-node-id` | string | No | ct | - | Node identifier |

---

## Notes

- **All Immich app config is hardcoded** in the snap (DB/Redis in
  `snapcraft.yaml` `server.environment`; ML enabled). Tower supplies only the
  `ct-*` keys.
- **Never send uppercase/underscore config keys** — snapd rejects them
  (`invalid option name`), failing the deploy. snap config keys must be
  lowercase / hyphen / dot.
- Immich runs its own snapd services: `postgresql`, `redis`, `server`,
  `createdb`, `ml`. The `ct-engine` sidecar reports status to Control Tower;
  it does not manage those services.
- To run an external DB/cache or disable ML, change the hardcoded values in
  `snapcraft.yaml` / `src/immich-server.sh` and rebuild — it is not
  Tower-configurable by design.
- Logs/status are sent to Control Tower every 5 minutes (`output.interval`).
