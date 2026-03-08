#!/usr/bin/env bash
set -euo pipefail

# Deploy Astro static site to Mikr.us VPS using scp + atomic release switch.
# Usage:
#   ./deploy.sh
# Optional env overrides:
#   VPS_HOST, VPS_PORT, VPS_USER, REMOTE_WEBROOT, KEEP_BACKUPS, SKIP_NPM_CI

VPS_HOST="${VPS_HOST:-aneta145.mikrus.xyz}"
VPS_PORT="${VPS_PORT:-10145}"
VPS_USER="${VPS_USER:-root}"
REMOTE_WEBROOT="${REMOTE_WEBROOT:-/var/www/html}"
KEEP_BACKUPS="${KEEP_BACKUPS:-5}"
SKIP_NPM_CI="${SKIP_NPM_CI:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ARCHIVE="/tmp/personal_website_$(date +%Y%m%d_%H%M%S).tar.gz"
REMOTE_ARCHIVE="/tmp/personal_website_deploy.tar.gz"

cd "$SCRIPT_DIR"

echo "[config] VPS: ${VPS_USER}@${VPS_HOST}:${VPS_PORT}"
echo "[config] Remote web root: ${REMOTE_WEBROOT}"
echo "[config] Remote upload tmp: ${REMOTE_ARCHIVE}"

echo "[preflight] Verifying remote paths..."
ssh -p "$VPS_PORT" "${VPS_USER}@${VPS_HOST}" /bin/bash <<EOF
set -euo pipefail

REMOTE_WEBROOT="${REMOTE_WEBROOT}"
REMOTE_ARCHIVE="${REMOTE_ARCHIVE}"

echo "[remote] pwd: \$(pwd)"
echo "[remote] home: \$HOME"
echo "[remote] /tmp: \$(ls -ld /tmp)"

if [[ ! -d "\$(dirname "\$REMOTE_WEBROOT")" ]]; then
  echo "[remote][error] Parent directory does not exist: \$(dirname "\$REMOTE_WEBROOT")"
  exit 1
fi

if [[ ! -w "\$(dirname "\$REMOTE_WEBROOT")" ]]; then
  echo "[remote][error] Parent directory is not writable: \$(dirname "\$REMOTE_WEBROOT")"
  exit 1
fi

echo "[remote] Target parent dir OK: \$(dirname "\$REMOTE_WEBROOT")"
echo "[remote] Archive will be uploaded to: \$REMOTE_ARCHIVE"
EOF

echo "[1/5] Building site..."
if [[ "$SKIP_NPM_CI" != "1" ]]; then
  npm ci
fi
npm run build

echo "[2/5] Packaging dist -> $TMP_ARCHIVE"
tar -czf "$TMP_ARCHIVE" -C dist .

echo "[3/5] Uploading archive via scp to ${VPS_USER}@${VPS_HOST}:${REMOTE_ARCHIVE}"
scp -P "$VPS_PORT" "$TMP_ARCHIVE" "${VPS_USER}@${VPS_HOST}:${REMOTE_ARCHIVE}"

echo "[4/5] Activating new release atomically on VPS..."
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

echo "[5/5] Cleaning up local temp archive"
rm -f "$TMP_ARCHIVE"

echo "Deploy complete: https://modrzejewski.it"
