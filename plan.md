# klack.cloud Consistency Refactor Plan

This plan normalizes the shape of all compose files, config templating, and shell
scripts in this repository. It was produced by a senior review on 2026-07-06 and is
written to be executed by another engineer or AI agent without additional context.

## How to use this plan

- Execute phases **in order**. Each phase is independently shippable and ends with a
  verification step. Do not start a phase until the previous one verifies clean.
- Phases 1–3 are low risk (mechanical). Phases 4–5 change runtime behavior and must be
  verified against a running stack.
- **Never** edit files listed in `.gitignore` (e.g. `.env`, `config/radarr/config.xml`,
  `web/index.html`). Those are generated. Edit their `.template` sources instead.
- Commit at the end of each phase with the message given in that phase.
- The stack targets a Raspberry Pi 5 (arm64) but also runs on amd64. Do not remove any
  arm64-specific logic (`build_images.sh`, `platform.sh`).

## Repository orientation

| Path | Role |
| --- | --- |
| `compose.yml` | Root compose file; `include:`s every file in `compose/` and defines the `klack` and `honey` networks |
| `compose/*.yml` | One file per service (or service group) |
| `config/<service>/` | Bind-mounted configs; `*.template` files are rendered to their non-template names by scripts |
| `scripts/` | Setup helpers, called by `setup.sh` |
| `setup.sh` → `gen_config.sh` → `pre_run.sh` → `start.sh` → `post_run.sh` | Setup order |
| `start.sh` / `stop.sh` | Day-to-day lifecycle |
| `.env.template` | Rendered to `.env` by `scripts/gen_config.sh` |

Docker Compose profiles in use: `apps` (sftpgo, immich, radicale), `video` (plex),
`downloaders` (qbittorrent-wireguard, radarr, sonarr, jackett, flaresolverr, unpackerr).
Services with **no** profile always start. `start.sh` runs
`docker compose --profile apps up -d` plus conditional `plex` / `--profile downloaders`.

---

# Phase 1 — Bug fixes

Six defects found during review. Fix exactly as described.

### 1.1 Unpackerr cannot reach Radarr (IP typo)

File: `compose/unpackerr.yml` line 27.

```yaml
# before
      - UN_RADARR_0_URL=http://12.0.0.1:7878
# after
      - UN_RADARR_0_URL=http://127.0.0.1:7878
```

(`127.0.0.1` is correct because unpackerr shares the network namespace of
`qbittorrent-wireguard` via `network_mode: service:qbittorrent-wireguard`, same as the
Sonarr URL on the line above it.)

### 1.2 Grafana SMTP port is rendered as the hostname

File: `scripts/gen_config.sh` line 123.

```bash
# before
sed -i "s/\${GF_SMTP_PORT}/${DEFAULT_MAIL_HOST}/g" .env
# after
sed -i "s/\${GF_SMTP_PORT}/${DEFAULT_MAIL_PORT}/g" .env
```

Result in `.env` must be `GF_SMTP_HOST=smtp.protonmail.ch:587`, not
`GF_SMTP_HOST=smtp.protonmail.ch:smtp.protonmail.ch`.

### 1.3 Duplicati has a duplicate, hardcoded timezone

File: `compose/duplicati.yml`. The environment list sets `TZ` twice (lines 5 and 8).
Delete the hardcoded second entry:

```yaml
      - TZ=America/Denver   # DELETE this line; the earlier `- TZ=${TZ}` line stays
```

### 1.4 Flaresolverr: hardcoded timezone and unmanaged host path

File: `compose/jackett.yml`, `flaresolverr` service.

a) Replace `- TZ=America/Denver` with `- TZ=${TZ}`.

b) Replace the volume `- /var/lib/flaresolver:/config` with a named volume. No script
creates `/var/lib/flaresolver` and `clean.sh` never removes it. Change to:

```yaml
    volumes:
      - flaresolverr:/config
```

and add `flaresolverr:` to the `volumes:` block at the top of `compose/jackett.yml`
(next to the existing `jackett:` entry).

c) Delete the `container_name: flaresolverr` line — no other service in the project
sets `container_name`.

d) The flaresolverr service references `${LOG_LEVEL}`, `${LOG_FILE}`, `${LOG_HTML}`,
`${CAPTCHA_SOLVER}` which exist nowhere in `.env.template`. They all have inline
defaults (`:-info` etc.), so leave the references, but this is resolved for real in
Phase 4.5 (documenting all variables in `.env.template`).

### 1.5 qBittorrent LAN_NETWORK is malformed and hardcoded

File: `compose/qbittorrent-wireguard.yml` line 40. `192.168.1.0/16` is an invalid
prefix (host bits set) and ignores the `NETWORK` variable that `start.sh` already
derives into `.env` (e.g. `NETWORK=192.168.1`).

```yaml
# before
      - "LAN_NETWORK=192.168.1.0/16"
# after
      - "LAN_NETWORK=${NETWORK}.0/24"
```

### 1.6 Personal ACME email is baked into a tracked config file

File: `config/traefik/traefik.yml` line 103 contains `email: admin@suntrustmail.com`.
Move it to `.env`, following the exact runtime-templating pattern Traefik already uses
for `dynamic_conf.yml` (see `config/traefik/entrypoint.sh`).

a) `git mv config/traefik/traefik.yml config/traefik/traefik.yml.template` and inside
it change the email line to:

```yaml
      email: ${ACME_EMAIL}
```

b) Add `config/traefik/traefik.yml` to `.gitignore` (it will now be generated at
container start — actually rendered inside the container, but add the ignore defensively).

c) In `config/traefik/entrypoint.sh`, extend the existing `sed` block that renders
`dynamic_conf.yml` with a second render, placed immediately after it:

```sh
sed "s|\${ACME_EMAIL}|${ACME_EMAIL}|g" \
     /etc/traefik/traefik.yml.template > /etc/traefik/traefik.yml
```

d) In `compose/traefik.yml`:
   - change the volume `../config/traefik/traefik.yml:/etc/traefik/traefik.yml` to
     `../config/traefik/traefik.yml.template:/etc/traefik/traefik.yml.template`
   - add `ACME_EMAIL: ${ACME_EMAIL}` to the `environment:` map.

e) In `.env.template` add under a new `#Traefik` comment section:

```
ACME_EMAIL=
```

f) In `scripts/gen_config.sh`, after the `EXTERNAL_DOMAIN` substitution (line ~69), add:

```bash
sed -i "s|^ACME_EMAIL=.*|ACME_EMAIL=admin@$EXTERNAL_DOMAIN|" .env
```

### Phase 1 verification

```bash
docker compose config > /dev/null            # must exit 0, no warnings about undefined vars other than pre-existing ones
grep -rn "America/Denver" compose/           # must return nothing
grep -rn "12\.0\.0\.1" compose/              # must return nothing
grep -rn "suntrustmail" config/ compose/     # must return nothing (only git history)
```

If a live host is available: `./start.sh`, then confirm Traefik serves
`https://<HOST_IP>` and `docker logs klack-cloud-traefik-1` shows no ACME config error.

Commit: `Fix config bugs: unpackerr URL, SMTP port, hardcoded TZ/email/LAN_NETWORK`

---

# Phase 2 — Normalize compose file shape

Apply the following conventions to **every** file in `compose/` (and `compose.yml`).
These are style-only edits; `docker compose config` output must be semantically
identical before/after except where a rule below explicitly changes behavior
(2.4, 2.5, 2.6, 2.7).

### 2.1 One environment syntax: map form

Convert all list-form environment blocks (`- KEY=value`) to map form (`KEY: value`).
Files currently using list form: `dionaea.yml`, `cowrie.yml`, `duplicati.yml`,
`radarr.yml`, `sonarr.yml`, `jackett.yml`, `unpackerr.yml`,
`qbittorrent-wireguard.yml`, `radicale.yml`.

Rules while converting:
- Values that start with a digit-like string or contain `:` should be quoted
  (`WATCHTOWER_POLL_INTERVAL: "7200"` style is fine either way; be consistent with
  quoting only when YAML requires it).
- Booleans passed to containers must be quoted strings: `UN_QUIET: "false"`.
- Keep any explanatory end-of-line comments.

### 2.2 One networks syntax

Use list form `networks:\n      - klack` everywhere **except** where per-network
options are required (dionaea and cowrie need map form for `ipv4_address` — leave
those as maps). Files to convert from map to list: `traefik.yml`, `watchtower.yml`,
`duplicati.yml`, `sftpgo.yml`, `plex.yml`, `qbittorrent-wireguard.yml`, `nginx.yml`,
`immich.yml` (4 services), `whoami.yml`.

### 2.3 Remove dead config

- Delete every commented-out `# ports:` block (`grafana.yml`, `prometheus.yml`,
  `duplicati.yml`, `radarr.yml`, `sonarr.yml`, `jackett.yml`,
  `qbittorrent-wireguard.yml`, `nginx.yml`, `radicale.yml`). The exposed port is
  already documented by each service's `loadBalancer.server.port` label.
  Exception: keep the commented port in `compose/grafana.yml` for **promtail's syslog
  port 1514** and loki's `3100` ONLY if you keep the matching commented syslog job in
  `config/promtail/promtail-config.yml`; they document an optional feature together.
  Simplest correct action: delete both commented port blocks and leave the promtail
  syslog comment, which is self-contained.
- Delete the commented `# env_file:` block in `compose/immich.yml`.

### 2.4 `stack` label on every service

The `stack` label is consumed by promtail
(`config/promtail/promtail-config.yml`, relabel of
`__meta_docker_container_label_stack`) and Grafana dashboards filter on it. Services
missing it get an empty `stack` label in Loki and fall out of dashboards.

Rule: every service gets exactly one `stack` label. Monitoring-pipeline services
(`loki`, `promtail`, `grafana`, `grafana-db`, `prometheus`) use `stack=loggers`;
everything else uses `stack=klack.cloud`.

Add `- "stack=klack.cloud"` to the `labels:` (create the block if absent) of:
- `compose/jackett.yml` → `jackett` (it has labels but no stack) and `flaresolverr`
- `compose/unpackerr.yml` → `unpackerr`
- `compose/cowrie.yml` → `cowrie`
- `compose/dionaea.yml` → `dionaea`
- `compose/immich.yml` → `immich-machine-learning`, `redis`, `database`

### 2.5 One restart-policy rule

Rule: **services without a profile use `restart: always`; profile-gated services use
`restart: unless-stopped`** (so that a profile-stopped app stays stopped across host
reboots, while core infra always comes back).

Changes required:
- `compose/dionaea.yml`: `unless-stopped` → `always` (no profile)
- `compose/nginx.yml`: add `restart: always` (currently missing)
- `compose/duplicati.yml`: keep `always` (no profile) — no change
- `compose/immich.yml`: `immich-server`, `immich-machine-learning` → `unless-stopped`
  (they carry the `apps` profile). `redis` and `database` are handled by 2.6 and then
  also become `unless-stopped`.
- All others already comply; verify each file against the rule.

### 2.6 Complete the `apps` profile in immich.yml

`redis` and `database` in `compose/immich.yml` have no `profiles:` entry, so they run
even when the `apps` profile is not enabled, while the `immich-server` that needs them
does not. Add to both services:

```yaml
    profiles:
      - apps
```

`immich-server` already declares `depends_on: [redis, database]`, which is valid when
all three share the profile.

### 2.7 Parameterize UID/GID

`1000` is hardcoded in eight compose files and three scripts as the local user's
UID/GID. Make it explicit:

a) `.env.template`, under `LOCAL_USER=`, add:

```
PUID=
PGID=
```

b) `scripts/gen_config.sh`, next to the `LOCAL_USER` substitution (line ~59), add:

```bash
sed -i "s|^PUID=.*|PUID=$(id -u "$LOCAL_USER")|" .env
sed -i "s|^PGID=.*|PGID=$(id -g "$LOCAL_USER")|" .env
```

(Note: gen_config.sh runs under sudo, so use `id -u "$LOCAL_USER"`, not `id -u`.)

c) In compose files, replace every hardcoded UID/GID:
- `user: 1000:1000` → `user: ${PUID}:${PGID}` (`grafana.yml` grafana,
  `immich.yml` immich-server and database, `radicale.yml`)
- `PUID=1000` / `PGID=1000` env entries → `PUID: ${PUID}` / `PGID: ${PGID}`
  (`duplicati.yml`, `radarr.yml`, `sonarr.yml`, `jackett.yml`,
  `qbittorrent-wireguard.yml`)
- `PLEX_UID: 1000` / `PLEX_GID: 1000` → `${PUID}` / `${PGID}` (`plex.yml`)

d) In scripts, replace `chown -R 1000:1000` with `chown -R "$PUID:$PGID"` in
`scripts/pre_run.sh` (2 occurrences) and `scripts/clean.sh` (1 occurrence). Both
scripts already `source ./.env`. Do **not** change `chown -R 999:999 /var/log/cowrie`
— cowrie's container user is genuinely 999.

### 2.8 Watchtower opt-out labels on pinned images

Images pinned to an exact digest or version cannot be meaningfully auto-updated;
mark them explicitly the same way `plex.yml` already does:

Add `- "com.centurylinklabs.watchtower.enable=false"` to the labels of:
- `compose/immich.yml` → `redis`, `database` (digest-pinned)
- `compose/radicale.yml` → `radicale` (version-pinned `3-5-4-alpine`)

### 2.9 TLS certresolver consistency

Rule: routers matched via the **public domain** carry
`tls.certresolver=myresolver`; routers only reachable on the LAN IP do not (ACME
cannot issue for IPs). Currently `radicale` violates the rule: it serves
`https://your-domain.com/planner/` on `web-secure` but has no resolver, so clients get
the default self-signed cert while `/files` on the same port gets the ACME cert.

Add to `compose/radicale.yml` labels:

```yaml
      - "traefik.http.routers.radicale.tls.certresolver=myresolver"
```

`nginx` (homepage) is LAN-IP-only per the README — leave it without a resolver.

### Phase 2 verification

```bash
# Semantic diff — render before starting the phase and after finishing:
git stash && docker compose --profile apps --profile video --profile downloaders config > /tmp/before.yml && git stash pop
docker compose --profile apps --profile video --profile downloaders config > /tmp/after.yml
diff /tmp/before.yml /tmp/after.yml
```

The diff must show ONLY: added `stack`/watchtower/certresolver labels, restart-policy
changes from 2.5, profile additions from 2.6, UID variables resolving to the same
values, and removed comments. Anything else is a mistake.

Then on a live host: `./start.sh`; in Grafana confirm the logs dashboard now shows
containers `jackett`, `unpackerr`, `cowrie`, `dionaea`, `redis`, `database` under the
`stack` label.

Commit: `Normalize compose files: env syntax, stack labels, restart policy, PUID/PGID`

---

# Phase 3 — Consolidate the shell scripts

### 3.1 Create `scripts/lib.sh`

New file, sourced by every script. Contents:

```bash
#!/bin/bash
# Shared helpers for klack.cloud scripts. Source this; do not execute it.

# Resolve the project root (parent of scripts/, or the dir containing setup.sh)
# and cd there so every script can use relative paths safely.
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$LIB_DIR")"
cd "$PROJECT_ROOT" || exit 1

require_root() {
  if [ "$EUID" != 0 ]; then
    echo "Must be run as root" >&2
    exit 1
  fi
}

refuse_root() {
  if [ "$EUID" == 0 ]; then
    echo "Do not run this script as root" >&2
    exit 1
  fi
}

load_env() {
  if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "Run ./setup.sh first" >&2
    exit 1
  fi
  source "$PROJECT_ROOT/.env"
}

detect_platform() {
  case "$(uname -m)" in
    x86_64) PLATFORM="linux/amd64" ;;
    aarch64) PLATFORM="linux/arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

# Host log directories bind-mounted into containers. Referenced by pre_run.sh
# (creation + chown), clean.sh (removal), and mirrored by promtail mounts in
# compose/grafana.yml and rotation rules in config/logrotate.d/.
LOG_DIRS=(
  "/var/log/traefik"
  "/var/log/duplicati"
  "/var/log/dionaea"
  "/var/log/plex"
  "/var/log/plex/PMS Plugin Logs"
  "/var/log/radarr"
  "/var/log/sonarr"
  "/var/log/cowrie"
)
```

Note `lib.sh` lives in `scripts/`, so `PROJECT_ROOT` is its parent. `setup.sh`,
`start.sh`, `stop.sh` at the root must source it as `source ./scripts/lib.sh`; scripts
inside `scripts/` source it as `source "$(dirname "$0")/lib.sh"`.

### 3.2 Apply lib.sh to every script

For each script, at the top after the shebang add `set -euo pipefail` and the
appropriate `source` + helper calls, then delete the code the helper replaces:

| Script | Add | Delete |
| --- | --- | --- |
| `setup.sh` | `source ./scripts/lib.sh; refuse_root` | inline EUID check |
| `start.sh` | `source ./scripts/lib.sh; refuse_root; load_env` | EUID check, `.env` existence check, the broken `basename dirname PWD = scripts` cd block, `source ./.env` |
| `stop.sh` | `source ./scripts/lib.sh` | the `basename dirname PWD` cd block |
| `scripts/pre_run.sh` | `source "$(dirname "$0")/lib.sh"; require_root; load_env` | EUID check, `source ./.env`, its `LOG_DIRS=(...)` array |
| `scripts/post_run.sh` | `source "$(dirname "$0")/lib.sh"; load_env` | `source ./.env` |
| `scripts/clean.sh` | `source "$(dirname "$0")/lib.sh"; require_root; load_env` | EUID check, the `basename PWD != klack.cloud` check, `source ./.env`, its `LOG_DIRS=(...)` array |
| `scripts/gen_config.sh` | `source "$(dirname "$0")/lib.sh"; detect_platform` | its inline `case "$ARCH"` block and `PWD=$(pwd)` reassignment (use `$PROJECT_ROOT`) |
| `scripts/platform.sh` | `source "$(dirname "$0")/lib.sh"; load_env` | `source ./.env`, `PWD=$(pwd)` (use `$PROJECT_ROOT`) |
| `scripts/build_images.sh` | `source "$(dirname "$0")/lib.sh"; detect_platform` | its inline `case "$ARCH"` block |

`set -euo pipefail` caveats — commands that legitimately fail need `|| true`:
- `setup.sh`: `sudo killall node_exporter || true` (may not be running)
- `scripts/clean.sh`: `killall node_exporter || true`, and the
  `docker volume ls ... | xargs` pipeline should tolerate empty results (it already
  uses `xargs -r`; add `|| true` to the `grep`s in the pipeline or restructure as:
  `docker volume ls -q --filter name='^klack-cloud_' | grep -Ev '...' | xargs -r docker volume rm -f || true`)
- `scripts/gen_config.sh` reads user input and calls docker; review each pipeline.
- With `set -u`, `platform.sh` referencing `$PLATFORM` from `.env` is fine after
  `load_env`, but quote the comparison: `if [ "$PLATFORM" == "linux/arm64" ]` (the
  current unquoted `$PLATFORM` is a bug waiting for an empty value).

Also in `setup.sh`: because `set -e` now aborts on any failure, the existing
`if [ $? -ne 0 ]` blocks become dead code — replace them with `|| { echo "..."; exit 1; }`
on the same line as the command, or simply delete them and let `set -e` handle it
(keep the human-readable messages by using the `||` form).

### 3.3 Small script fixes

- `scripts/clean.sh`: remove `./data` from the `rm -rfv` line — that directory no
  longer exists in this project (`./cloud-metadata` replaced it).
- `scripts/clean.sh`: remove `"/var/log/plex/PMS Plugin Logs"` from any local list —
  it's covered by the shared `LOG_DIRS` (which lists parent `/var/log/plex` first).
- `git mv scripts/generate_pkbdf2.py scripts/generate_pbkdf2.py` and update the
  reference in `scripts/gen_config.sh` line ~111
  (`python generate_pkbdf2.py` → `python generate_pbkdf2.py`).
- `scripts/platform.sh` and `scripts/install_node_exp.sh`: drop interior `sudo`
  (they only ever run as root via `pre_run.sh`; after 3.2 they can assert
  `require_root` instead). NOTE: `install_node_exp.sh` is deleted entirely in
  Phase 5 — if executing phases in order, skip touching it here.

### Phase 3 verification

```bash
bash -n setup.sh start.sh stop.sh scripts/*.sh   # syntax check all scripts
shellcheck setup.sh start.sh stop.sh scripts/*.sh || true  # review new warnings only
```

On a live host, run the full cycle: `./stop.sh && ./start.sh` from the project root,
then again from inside `scripts/` (`cd scripts && ../start.sh`) to prove the
`PROJECT_ROOT` cd works from anywhere. If a scratch machine is available, run
`./setup.sh` end-to-end.

Commit: `Consolidate scripts: shared lib.sh, strict mode, dedupe LOG_DIRS/platform`

---

# Phase 4 — One templating mechanism

Today there are three: (a) ad-hoc `sed` on `.template` files scattered across
`gen_config.sh` and `start.sh`, (b) runtime entrypoint `sed` inside the traefik and
prometheus containers, (c) native compose `${VAR}` interpolation. Keep (b) and (c)
as-is — (b) exists because those values must re-render on every container start, and
(c) is native. This phase consolidates all of (a) into one script.

### 4.1 Create `scripts/render_templates.sh`

New file. It renders every host-side template using `envsubst` with an **explicit
variable whitelist per file** (never bare `envsubst` — several templates contain `$`
strings that must survive, e.g. Grafana's `$__interval` and dashboard JSON, and the
PBKDF2 hash contains `$`).

```bash
#!/bin/bash
# Renders all *.template files that are consumed on the host side.
# Values come from .env plus per-file overrides passed via environment.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

# render <template> <output> <var-whitelist...>
render() {
  local template="$1" output="$2"; shift 2
  local vars=""
  for v in "$@"; do vars+="\${$v} "; done
  envsubst "$vars" < "$template" > "$output"
  echo "rendered $output"
}

# --- Rendered once at setup (values never change after gen_config) ---
if [ "${RENDER_SETUP:-0}" = "1" ]; then
  API_KEY=$RADARR_API_KEY \
    render config/radarr/config.xml.template config/radarr/config.xml API_KEY
  API_KEY=$SONARR_API_KEY \
    render config/sonarr/config.xml.template config/sonarr/config.xml API_KEY
  API_KEY=$JACKETT_API_KEY INSTANCE_ID=$JACKETT_INSTANCE_ID \
    render config/jackett/ServerConfig.json.template config/jackett/ServerConfig.json API_KEY INSTANCE_ID
  USERNAME=$CLOUD_USER PASSWORD_PBKDF2=$QBT_PASSWORD_PBKDF2 \
    render config/qbittorrent/qBittorrent.conf.template config/qbittorrent/qBittorrent.conf USERNAME PASSWORD_PBKDF2
fi

# --- Re-rendered on every start (depend on HOST_IP, which can change) ---
render config/grafana/dashboards/overview-dashboard.json.template \
       config/grafana/dashboards/overview-dashboard.json NETWORK_INTERFACE HOST_IP
render config/grafana/provisioning/alerting/contact-points.yaml.template \
       config/grafana/provisioning/alerting/contact-points.yaml GF_SMTP_FROM_ADDRESS
render config/grafana/provisioning/alerting/1m-warning.yaml.template \
       config/grafana/provisioning/alerting/1m-warning.yaml HOST_IP
render web/index.html.template web/index.html INTERNAL_DOMAIN EXTERNAL_DOMAIN HOST_IP
```

Prerequisites and notes:
- `envsubst` ships in `gettext-base` on Debian/Raspberry Pi OS. Add a check at the
  top: `command -v envsubst >/dev/null || { echo "Install gettext-base"; exit 1; }`.
- `JACKETT_INSTANCE_ID` is currently generated in `gen_config.sh` but **not** saved to
  `.env` — add it to `.env.template` and have `gen_config.sh` write it, same pattern as
  `JACKETT_API_KEY`.
- `QBT_PASSWORD_PBKDF2`: `gen_config.sh` currently pipes the PBKDF2 hash straight into
  sed. Change `gen_config.sh` to write it to `.env` as `QBT_PASSWORD_PBKDF2="..."`
  instead (the value contains `$` and `"`— write it with single-quote-safe escaping, or
  keep this ONE substitution as sed inside gen_config.sh if escaping proves fragile,
  and note that exception in a comment in render_templates.sh).
- **Compare rendered outputs before/after switching**: for each template, render with
  the old sed pipeline and with render_templates.sh and `diff` the outputs. They must
  be byte-identical. Do this before deleting any sed lines.

### 4.2 Wire it in and delete the sed farms

- `scripts/gen_config.sh`: delete the blocks that `cp` + `sed` render
  radarr/sonarr/jackett/qbittorrent configs (keep the blocks that *generate secrets
  into .env*). At the end of gen_config.sh add:
  `RENDER_SETUP=1 ./scripts/render_templates.sh`.
- `start.sh`: delete lines 32–43 (grafana dashboard + contact-points + 1m-warning
  rendering) and lines 49 & 65–67 (index.html cp + sed), replacing them with a single
  `./scripts/render_templates.sh` call placed where the grafana rendering was.
  **Keep** the two `sed -i` calls that hide homepage panels
  (`#video`, `#download_managers`) — they are conditional edits of the rendered
  output, not template rendering; they must run *after* render_templates.sh.

### 4.3 Fix `.env.template` self-references

`.env.template` currently mixes empty assignments with `${...}` placeholders that only
work because gen_config seds them (lines 7–8, 32). Make every line a plain assignment:

```
# before
EXTERNAL_DOMAIN=${EXTERNAL_DOMAIN}
INTERNAL_DOMAIN=${EXTERNAL_DOMAIN}.local
GF_SMTP_HOST=${GF_SMTP_HOST}:${GF_SMTP_PORT}
# after
EXTERNAL_DOMAIN=
INTERNAL_DOMAIN=
GF_SMTP_HOST=
```

and in `scripts/gen_config.sh` replace the corresponding placeholder-substituting seds
with anchor-style seds like every other variable:

```bash
sed -i "s|^EXTERNAL_DOMAIN=.*|EXTERNAL_DOMAIN=$EXTERNAL_DOMAIN|" .env
sed -i "s|^INTERNAL_DOMAIN=.*|INTERNAL_DOMAIN=$EXTERNAL_DOMAIN.local|" .env
sed -i "s|^GF_SMTP_HOST=.*|GF_SMTP_HOST=$DEFAULT_MAIL_HOST:$DEFAULT_MAIL_PORT|" .env
```

(This also supersedes bug fix 1.2 — verify the port lands correctly.)

Standardize quoting while here: `gen_config.sh` writes some values quoted and some
not. Rule: quote every value it writes (`VAR="value"`). Docker Compose and bash
`source` both strip the quotes.

### 4.4 Namespace the Immich DB variables

`DB_PASSWORD` / `DB_USERNAME` / `DB_DATABASE_NAME` in `.env` are Immich-specific but
globally named (Grafana's equivalent is already `GRAFANA_DB_PASSWORD`).

- `.env.template`: rename to `IMMICH_DB_PASSWORD`, `IMMICH_DB_USERNAME`,
  `IMMICH_DB_DATABASE_NAME` (keep values: username `postgres`, db `immich`).
- `scripts/gen_config.sh`: update the `DB_PASSWORD` sed (line ~85) to
  `IMMICH_DB_PASSWORD`.
- `compose/immich.yml`: the **container-side** names must not change (Immich reads
  `DB_PASSWORD` etc.). Map old names to new variables in all four services that use
  them:

```yaml
      DB_PASSWORD: ${IMMICH_DB_PASSWORD}
      DB_USERNAME: ${IMMICH_DB_USERNAME}
      DB_DATABASE_NAME: ${IMMICH_DB_DATABASE_NAME}
      # and in the `database` service:
      POSTGRES_PASSWORD: ${IMMICH_DB_PASSWORD}
      POSTGRES_USER: ${IMMICH_DB_USERNAME}
      POSTGRES_DB: ${IMMICH_DB_DATABASE_NAME}
```

  Also update the two healthcheck strings in the `database` service that interpolate
  `${DB_DATABASE_NAME}` / `${DB_USERNAME}`.
- **Migration note for existing installs**: `.env` is generated, so existing hosts
  keep the old names until re-setup. Either instruct the operator to run
  `sed -i 's/^DB_/IMMICH_DB_/' .env`, or add that line to `start.sh` temporarily. Do
  NOT regenerate `.env` (it holds live passwords matching the existing database).

### 4.5 Document every variable in `.env.template`

Add (with empty or default values) the variables referenced by compose files but
absent from the template: `LOG_LEVEL`, `LOG_FILE`, `LOG_HTML`, `CAPTCHA_SOLVER`
(flaresolverr — give them their current inline defaults as comments), plus anything
Phase 1/2 introduced (`ACME_EMAIL`, `PUID`, `PGID`, `JACKETT_INSTANCE_ID`,
`QBT_PASSWORD_PBKDF2`). Group under the existing comment-header sections.

### Phase 4 verification

1. Byte-diff every rendered file (old pipeline vs new) as described in 4.1.
2. On a scratch machine or with `.env` backed up: run `./setup.sh` end-to-end; verify
   `.env` contains no literal `${` strings: `grep -c '\${' .env` must be 0.
3. `./start.sh`; verify Grafana dashboards load, homepage renders with correct
   domain/IP, qBittorrent accepts the login, Radarr/Sonarr/Jackett API keys match
   between `.env` and each app's settings screen, Immich loads and can see its DB.

Commit: `Consolidate templating into render_templates.sh; clean up .env variables`

---

# Phase 5 — Containerize node_exporter

node_exporter is currently the only non-Docker component: installed by
`scripts/install_node_exp.sh` (wget binary → `/usr/local/bin`), started via `nohup` in
`pre_run.sh` and an `@reboot` line in `/etc/crontab`, killed via `killall` in
`setup.sh`/`clean.sh`. Replace all of it with a compose service.

Key fact: the current binary listens on host port **9100** (default); Traefik's
`metrics` entrypoint (:9101) proxies to `http://${HOST_IP}:9100` (see
`config/traefik/dynamic/dynamic_conf.yml.template`), and Prometheus scrapes
`${HOST_IP}:9101` through Traefik. A host-network container on 9100 is a drop-in
replacement — **do not change any port numbers**.

### 5.1 New file `compose/node-exporter.yml`

```yaml
services:
  node-exporter:
    image: quay.io/prometheus/node-exporter:v1.8.2
    command:
      - "--path.rootfs=/host"
    network_mode: host
    pid: host
    volumes:
      - /:/host:ro,rslave
    environment:
      TZ: ${TZ}
    labels:
      - "stack=loggers"
    restart: always
```

Add `- ./compose/node-exporter.yml` to the `include:` list in `compose.yml` (next to
`prometheus.yml`).

### 5.2 Remove the old lifecycle

- Delete `scripts/install_node_exp.sh`.
- `scripts/pre_run.sh`: delete the "Install node_exporter" block (the
  `./scripts/install_node_exp.sh` call and the `nohup ... &` line).
- `setup.sh`: delete `sudo killall node_exporter` — but see 5.3: on hosts with the old
  install, setup must clean it up once, so instead change it to the migration snippet
  in 5.3.
- `scripts/clean.sh`: keep the removal logic for one release (it cleans up old
  installs): `killall node_exporter || true`, `rm -fv /usr/local/bin/node_exporter`,
  and the crontab sed lines stay. Add a comment
  `# Legacy cleanup: node_exporter ran on the host before it was containerized`.

### 5.3 Migration for existing hosts

In `setup.sh`, replace `sudo killall node_exporter` with:

```bash
# Migrate from host-installed node_exporter (pre-containerization)
sudo killall node_exporter 2>/dev/null || true
sudo rm -f /usr/local/bin/node_exporter
sudo sed -i '/node_exporter/d' /etc/crontab
```

### Phase 5 verification

```bash
./start.sh
curl -s http://localhost:9100/metrics | head -5          # node metrics served
curl -sk -u "$CLOUD_USER:$CLOUD_PASS" https://localhost:9101/metrics | head -5  # via traefik
```

Then in Grafana: System dashboard panels (CPU, RAM, disk, temperature) must show live
data. Check the CPU-temperature alert still resolves (Pi-specific collector —
`node-exporter` in a container reads `/sys` via the rootfs mount; if the `hwmon`
collector shows no temp, add `- "--path.sysfs=/host/sys"` to `command:` and re-verify).
Confirm `grep node_exporter /etc/crontab` returns nothing after running setup on a
migrated host.

Commit: `Run node_exporter as a compose service instead of a host binary`

---

# Phase 6 — Documentation and final polish

- `README.md` service table: fix the `Traefk` typo (Prometheus row, "Auth Provider"
  column → `Traefik`); add a `Node Exporter` note that it now runs as a container;
  verify every port in the table still matches `config/traefik/traefik.yml.template`
  entrypoints and `compose/traefik.yml` published ports.
- Add a `# Conventions` comment header to `compose.yml` stating the rules enforced in
  Phase 2, so future services copy the right shape:

```yaml
# Conventions for files in compose/:
#   - environment: map syntax (KEY: value); networks: list syntax unless per-network opts needed
#   - every service has a `stack` label: "loggers" for the monitoring pipeline, else "klack.cloud"
#   - restart: always for unprofiled (core) services; unless-stopped for profiled apps
#   - UID/GID come from ${PUID}/${PGID}; never hardcode 1000
#   - routers reachable via the public domain set tls.certresolver=myresolver; LAN-IP routers don't
#   - profiles: apps (cloud apps), video (plex), downloaders (arr stack); core infra has no profile
#   - templates: <name>.template rendered by scripts/render_templates.sh; rendered files are gitignored
```

- `stop.sh`: add a comment above the `docker compose ... down` line:
  `# NOTE: list every profile here; a service in an unlisted profile will not be stopped.`
- Confirm `.gitignore` covers everything generated in this refactor
  (`config/traefik/traefik.yml` from Phase 1.6 — the rest were already covered).

Commit: `Document compose conventions and fix README typos`

---

# Out of scope (do not do)

- Do **not** unify the named-volume vs `DIR_DATA_ROOT` bind-mount persistence split
  (moving radarr/sonarr/jackett/sftpgo state into `cloud-metadata/`). It changes the
  backup and uninstall story and requires a data-migration script; needs a separate
  decision from the owner.
- Do **not** pin currently-unpinned image tags. Watchtower auto-update of `:latest` is
  the project's chosen update model.
- Do **not** collapse the per-service Traefik entrypoints/ports onto host-based
  routing on 443. Several apps (Plex, Immich) genuinely need their own public ports,
  and the LAN services are IP-addressed by design.
- Do **not** touch anything under `config/plex/git/`, `config/dionaea/`,
  `config/fail2ban/`, `config/radicale/template/`, or the Grafana dashboard JSONs
  (except the documented template substitutions).
- Do **not** modify `compose.override.yml` (machine-local, gitignored) or `vpn.conf`.

# Global acceptance checklist (after all phases)

- [ ] `docker compose --profile apps --profile video --profile downloaders config` exits 0
- [ ] `grep -rn "1000" compose/` returns no UID/GID hardcodes (image-internal values like ports are fine)
- [ ] `grep -rn "America/Denver\|suntrustmail\|12\.0\.0\.1" compose/ config/ scripts/` returns nothing
- [ ] Every service in `compose/*.yml` has: a `stack` label, a `restart` policy matching the rule, map-form environment
- [ ] `bash -n` passes on all scripts; every script sources `lib.sh` and uses `set -euo pipefail`
- [ ] No `sed`-based template rendering outside `render_templates.sh`, `gen_config.sh` (.env writes + the two homepage-panel toggles in start.sh), and the two container entrypoints
- [ ] Fresh `./setup.sh` on a scratch host completes and all README "Alerts" and dashboard features work
- [ ] `./setup.sh --clean` removes everything it should and nothing it shouldn't
