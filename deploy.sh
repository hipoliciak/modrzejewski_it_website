#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${SCRIPT_DIR}/.deploy.env}"

if [[ ! -f "$DEPLOY_ENV_FILE" ]]; then
  echo "[error] Missing deploy env file: $DEPLOY_ENV_FILE"
  echo "Create it (example below):"
  echo "  VPS_HOST=..."
  echo "  VPS_PORT=..."
  echo "  VPS_USER=..."
  echo "  REMOTE_WEBROOT=..."
  echo "  KEEP_BACKUPS=5"
  echo "  SKIP_NPM_CI=0"
  exit 1
fi

set -a
source "$DEPLOY_ENV_FILE"
set +a

: "${VPS_HOST:?VPS_HOST is required in deploy env file}"
: "${VPS_PORT:?VPS_PORT is required in deploy env file}"
: "${VPS_USER:?VPS_USER is required in deploy env file}"
: "${REMOTE_WEBROOT:?REMOTE_WEBROOT is required in deploy env file}"
KEEP_BACKUPS="${KEEP_BACKUPS:-5}"
SKIP_NPM_CI="${SKIP_NPM_CI:-0}"

TMP_ARCHIVE="/tmp/personal_website_$(date +%Y%m%d_%H%M%S).tar.gz"
REMOTE_ARCHIVE="/tmp/personal_website_deploy.tar.gz"

cd "$SCRIPT_DIR"

echo "[config] VPS: ${VPS_USER}@${VPS_HOST}:${VPS_PORT}"
echo "[config] Remote web root: ${REMOTE_WEBROOT}"
echo "[config] Remote upload tmp: ${REMOTE_ARCHIVE}"

echo "[1/4] Building site..."
if [[ "$SKIP_NPM_CI" != "1" ]]; then
  npm ci
fi
npm run build

echo "[2/4] Packaging dist -> $TMP_ARCHIVE"
tar -czf "$TMP_ARCHIVE" -C dist .

echo "[3/4] Uploading archive via scp to ${VPS_USER}@${VPS_HOST}:${REMOTE_ARCHIVE}"
scp -P "$VPS_PORT" "$TMP_ARCHIVE" "${VPS_USER}@${VPS_HOST}:${REMOTE_ARCHIVE}"

echo "[4/4] Activating new release atomically on VPS..."
ssh -p "$VPS_PORT" "${VPS_USER}@${VPS_HOST}" /bin/bash <<EOF
set -euo pipefail

REMOTE_WEBROOT="${REMOTE_WEBROOT}"
KEEP_BACKUPS="${KEEP_BACKUPS}"
REMOTE_ARCHIVE="${REMOTE_ARCHIVE}"

timestamp=\"\$(date +%Y%m%d_%H%M%S)\"
release_dir=\"\${REMOTE_WEBROOT}_new_\${timestamp}\"
backup_dir=\"\${REMOTE_WEBROOT}_backup_\${timestamp}\"

mkdir -p "\$release_dir"
tar -xzf "\$REMOTE_ARCHIVE" -C "\$release_dir"

if [[ -d "\$REMOTE_WEBROOT" ]]; then
  mv "\$REMOTE_WEBROOT" "\$backup_dir"
fi

mv "\$release_dir" "\$REMOTE_WEBROOT"
rm -f "\$REMOTE_ARCHIVE"

if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files --type=service | grep -q '^nginx\.service'; then
    systemctl reload nginx
  else
    echo "[remote] nginx.service not found, skipping reload (likely container-managed or different web server)."
  fi
fi

# Keep only the newest N backups, remove older ones.
if [[ "\$KEEP_BACKUPS" =~ ^[0-9]+$ ]] && (( KEEP_BACKUPS >= 0 )); then
  mapfile -t backups < <(ls -1dt "\${REMOTE_WEBROOT}_backup_"* 2>/dev/null || true)
  if (( \${#backups[@]} > KEEP_BACKUPS )); then
    for old in "\${backups[@]:KEEP_BACKUPS}"; do
      rm -rf "\$old"
    done
  fi
fi
EOF

echo "[cleanup] Cleaning up local temp archive"
rm -f "$TMP_ARCHIVE"

echo "Deploy complete: https://modrzejewski.it"
