# Immich snap — how we got it deploying via Control Tower

This is the engineering record of the changes made on top of the bundled
Immich snap (`186fab7`) to integrate Control Tower (CT) and get Armada/
Landscape deployments to succeed, plus the size and cleanup work done along
the way. It exists so the next person doesn't have to re-derive the painful
bits (especially the snapd config-key rule).

Baseline: a self-contained snap that bundles PostgreSQL 16, Redis and FFmpeg
and runs Immich as native snapd services (`postgresql`, `redis`, `createdb`,
`server`, `ml`). The web server listens on **:3001**.

---

## TL;DR — the things that actually mattered

1. **snapd rejects config keys that aren't lowercase/hyphen/dot.** Tower was
   pushing `DB_PORT`, `DB_PASSWORD`, … (uppercase + underscore). snapd fails
   the whole `snap set` with `invalid option name`, which fails the
   configure-hook change. This was *the* deploy blocker. → All app config is
   now **hardcoded in the snap**; CT supplies only the automatic `ct-*` keys.
2. **Snap hooks don't inherit the snapcraft PATH**, so the CT engine's
   `#!/usr/bin/env python3` shebang couldn't find the interpreter. → A
   `bin/ct-engine-run` shell launcher locates python explicitly.
3. **`snapctl restart` from inside a configure hook fails the change** if the
   target service is missing/unhealthy — regardless of `|| true`. → The hook
   and the engine no longer restart anything.

---

## What was added

### CT engine sidecar
- `ct-engine/ct_engine.py` — the canonical engine, vendored from
  `all_snap_plugin`. Runs in **sidecar mode**: it does **not** manage Immich's
  services, it just validates/persists config and streams status callbacks to
  `ct-callback-url`.
- `ct-engine/ct-engine-run` — a `#!/bin/sh` launcher that finds the bundled
  python and execs the engine; degrades gracefully (idles / no-ops) if no
  interpreter is found, so it can never fail install/refresh.
- `ct-engine/plugin.yaml` — sidecar manifest. `config: {}` (no Tower-settable
  app config); reports `Immich: http://<ip>:3001` on callbacks every 5 min.
- `snapcraft.yaml`: new `ct-engine` app (`command: bin/ct-engine-run run`,
  `install-mode: enable`) and parts `ct-engine` (engine + launcher + manifest)
  and `ct-runtime` (ca-certificates for HTTPS callbacks). python3 is already
  provided by the `immich` part.

### Deployment contract
- `docs/deployment-guide.md` — inputs/outputs, JSON schema, CT deployment
  payload, parameter reference.
- `reference/POST.json` — ready-to-use deployment payload (now `ct-*` keys
  only).

---

## The deploy failures, in order, and the fixes

Each was found from the Armada activity log / `snap change <id>` /
`journalctl -u snapd`.

| # | Symptom | Root cause | Fix | Commit |
|---|---------|-----------|-----|--------|
| 1 | configure hook errored on the lightweight build | hook delegated to a python script but hooks lack `$SNAP/usr/bin` on PATH | export PATH in the hook | (lightweight branch) |
| 2 | refresh "Start services" **and** configure hook both errored | the `ct-engine` daemon wouldn't start — `env python3` shebang unresolved in this snap | `ct-engine-run` launcher locates python explicitly; hook stops enqueuing a sidecar restart | `2893a35` |
| 3 | configure hook still errored | the **vendored engine** itself ran `snapctl restart all-dev-immich.all-dev-immich` (nonexistent service); a hook's `snapctl restart` is deferred into the change and fails it | removed the restart from `hook-configure` | `93ca4ed` |
| 4 | `Run configure hook … invalid option name: "DB_PASSWORD"` (authoritative, from `snap change 810`) | **snapd config keys must be lowercase/hyphen/dot** — `DB_*`/`REDIS_*` are uppercase+underscore and are rejected outright | renamed keys (interim), then hardcoded them out of the config surface entirely | `9cf0f0e`, `90bb9ad` |

Confirmed on-device:
```
$ snap set all-dev-immich DB_HOSTNAME=localhost
error: ... Run configure hook ... (invalid option name: "DB_HOSTNAME")
```

---

## Final configuration model

All Immich app settings are **baked into the snap**. Control Tower supplies
**only** the automatic `ct-*` keys (`ct-callback-url`, `ct-snap-name`,
`ct-node-id`, `ct-deployment-id`). The persisted `config.yaml` therefore
contains only those four keys.

| Setting | Value | Where it's hardcoded |
|---------|-------|----------------------|
| DB host / port | `127.0.0.1` / `5433` | `snapcraft.yaml` → `apps.server.environment` |
| DB name / user / pass | `immich` / `postgres` / `postgres` | same |
| Redis host / port | `127.0.0.1` / `6379` | same |
| Machine learning | **on** | `ml` app `install-mode: enable`; `immich-server.sh` defaults `IMMICH_MACHINE_LEARNING_ENABLED=true` |

> **Rule to remember:** snap config option names must match lowercase ASCII
> letters/digits/hyphens, with dots for nesting (e.g. `ct-node-id`,
> `ml.enabled`). **Never** send `DB_PORT`-style keys via `snap set`.

To change DB/cache endpoints or toggle ML, edit `snapcraft.yaml` /
`src/immich-server.sh` and rebuild — by design these are not Tower-settable.

---

## The configure hook today

`snap/hooks/configure` is intentionally minimal and best-effort (no `set -e`,
never aborts the deploy):

```sh
#!/bin/sh
export PATH="$SNAP/usr/sbin:$SNAP/usr/bin:$SNAP/sbin:$SNAP/bin:$PATH"
if [ -x "$SNAP/bin/ct-engine-run" ]; then
    "$SNAP/bin/ct-engine-run" hook-configure || true
fi
exit 0
```

It no longer toggles ML (ML is hardcoded) and no longer restarts services
(snapd handles the service lifecycle; the deployment plan's
`post_service_actions` restarts `all-dev-immich.server`).

---

## Size reduction (`fb08fa4`)

The v2.5.6 build was **866 MB** (2.2 GB uncompressed). Applied the
verified-safe wins:

- `compression: lzo → xz` (~2× better ratio).
- `scripts` part `override-prime` strips, from the assembled tree:
  - `include/` dev headers (~60 MB)
  - `__pycache__` + `*.pyc` (~170 MB)
  - top-level `test`/`tests` dirs under the ML site-packages (~15 MB)

Measured result: **866 MB → ~518 MB** download.

**Not done (needs on-device validation):** dropping the duplicate
`opencv-python` vs `-headless` (~150 MB; the shared `cv2/` loader is RPATH-
coupled to one `.libs`, so blind deletion can break ML), and the libLLVM/Mesa
software-GL stack (~260 MB). **Do not remove `libflite*`** — it is a hard
`DT_NEEDED` dependency of ffmpeg's `libavfilter` and removing it breaks all
video/thumbnail processing.

---

## Cleanup (`6835127`)

Removed dead code that implied behavior the snap doesn't have:

- `snap/hooks/connect-plug-postgresql` — never fired (no `postgresql` plug);
  its initdb/pgpass/`shared_preload_libraries`/createdb work is done by
  `src/postgresql.sh` as the `postgresql`/`createdb` service commands.
- `snap/hooks/connect-plug-gpu-2404`, `connect-plug-graphics-core22` — never
  fired (no such plugs); only started an already-enabled server.
- `src/gpu-2404-wrapper`, `src/graphics-core22-wrapper` — unused, were excluded
  from staging anyway.

The snap declares only these plugs: `network`, `network-bind`, `opengl`,
`mount-observe`, `removable-media`. ML is CPU-only (`uv-extras: [cpu]`).

---

## Deploying / debugging

Deploy payload: see `reference/POST.json` (settings = `ct-*` keys only).

Useful checks on a node:
```sh
snap services all-dev-immich          # server/postgresql/redis/ml/ct-engine
snap logs all-dev-immich.server -n 50
snap logs all-dev-immich.ct-engine    # sidecar callbacks
snap changes all-dev-immich           # find a failing change id
snap change <id>                      # the authoritative task error
sudo journalctl -u snapd --since -10min
snap get all-dev-immich               # persisted config (expect only ct-*)
```

> If a deploy still fails with `invalid option name`, the Control Tower
> deployment is still sending non-`ct-*` (or uppercase/underscore) keys in
> `snap_config.settings`. Fix the Tower-side payload — no snap change can make
> snapd accept those names.

---

## Open follow-ups

- **Tower payload**: confirm Tower sends only `ct-*` keys for this snap (it was
  observed still pushing `DB_*`). If Tower derives the key set from
  `plugin.yaml`, republishing this revision is enough; otherwise the
  deployment's `settings` must be edited in the Tower console.
- **OpenCV / libLLVM pruning** for a smaller image, gated on confirming the ML
  import path on-device.
- **GPU ML** (if ever wanted): re-introduce `gpu-2404`/`graphics-core22` plugs
  + provider content, a CUDA/ROCm ML extra, and the connect hooks.
