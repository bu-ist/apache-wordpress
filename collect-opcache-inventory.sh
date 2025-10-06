#!/usr/bin/env bash
# collect-opcache-inventory.sh
# One-password, per-environment OPcache inventory for BU WP app hosts.

set -euo pipefail

# ----------------------------
# Hosts by environment
# ----------------------------
DEV=(ist-wp-app-dv01 ist-wp-app-dv02)
TEST=(ist-wp-app-te01 ist-wp-app-te02)
PROD=(ist-wp-app-pr01 ist-wp-app-pr02 ist-wp-app-pr03 ist-wp-app-pr04 ist-wp-app-pr05 ist-wp-app-pr06)

# Optional vhost for an HTTP probe (leave blank to skip)
VHOST="${VHOST:-}"

SSHUSER="${SSHUSER:-$USER}"
SSHOPTS=(-o BatchMode=no -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)

# ----------------------------
# Single password (sshpass)
# ----------------------------
prompt_secret() {
  printf "%s" "$1"
  stty -echo 2>/dev/null || true
  read -r PW
  stty echo 2>/dev/null || true
  printf "\n"
  echo "$PW"
}

if ! command -v sshpass >/dev/null 2>&1; then
  echo "ERROR: sshpass is required for one-password mode."
  echo "Install it (e.g., macOS: brew install hudochenkov/sshpass/sshpass) and re-run."
  exit 1
fi

PW="$(prompt_secret "SSH password for ${SSHUSER}: ")"
SSHCMD=(sshpass -p "$PW" ssh "${SSHOPTS[@]}")

# ----------------------------
# Remote collectors
# ----------------------------
remote_info() {
  cat <<'REMOTE'
set -e
echo "### $(hostname -s)"
echo
echo "#### Configured (opcache.* in /etc/php.d/*.ini)"
for f in /etc/php.d/*.ini; do
  [ -f "$f" ] || continue
  grep -Hn '^opcache\.' "$f" 2>/dev/null || true
done
echo
echo "#### Effective (CLI)"
php -v | head -n1
php -r '
$keys=[
 "opcache.enable","opcache.enable_cli","opcache.validate_timestamps","opcache.revalidate_freq",
 "opcache.revalidate_path","opcache.file_update_protection","opcache.max_accelerated_files",
 "opcache.memory_consumption","realpath_cache_ttl"
];
foreach($keys as $k){ printf("%-30s %s\n",$k.":",ini_get($k)); }' 2>/dev/null
echo
echo "#### Apache modules (mod_php present?)"
( apachectl -M 2>/dev/null || httpd -M 2>/dev/null ) | grep -iE 'php([0-9_]*_)?module' || echo "(php module not listed by Apache)"
echo
REMOTE
}

remote_http_probe() {
  cat <<'REMOTE'
set -e
VHOST="$1"
PROBE="/var/www/cms/current/wp-opcache-probe.php"
MAKE='cat > "$PROBE" <<PHP
<?php
header("Content-Type: text/plain");
\$keys=[
 "opcache.enable","opcache.enable_cli","opcache.validate_timestamps","opcache.revalidate_freq",
 "opcache.revalidate_path","opcache.file_update_protection","opcache.max_accelerated_files",
 "opcache.memory_consumption","realpath_cache_ttl"
];
foreach(\$keys as \$k){ printf("%-30s %s\n", \$k.\":\", ini_get(\$k)); }
PHP'
if sudo sh -c "$MAKE" 2>/dev/null || sh -c "$MAKE" 2>/dev/null; then
  echo "#### Effective (mod_php via https://$VHOST/wp-opcache-probe.php)"
  curl -sk --max-time 8 --resolve "$VHOST:443:127.0.0.1" "https://$VHOST/wp-opcache-probe.php" || true
  sudo rm -f "$PROBE" 2>/dev/null || rm -f "$PROBE" 2>/dev/null || true
else
  echo "#### Effective (mod_php) probe not created (no perms)"
fi
echo
REMOTE
}

# ----------------------------
# Run and write Markdown
# ----------------------------
OUTFILE="OPcache-Inventory-$(date +%Y-%m-%d).md"
{
  echo "# OPcache Inventory — DEV / TEST / PROD"
  echo "_Generated on $(date)_ by $USER"
  echo

  run_env() {
    local envname="$1"; shift
    local hosts=("$@")
    echo "## $envname"
    echo
    for H in "${hosts[@]}"; do
      echo "Collecting from $H..." 1>&2
      # core info
      "${SSHCMD[@]}" "$SSHUSER@$H" bash -s -- <<<"$(remote_info)" || {
        echo "### $H"
        echo
        echo "_(failed to collect via SSH)_"
        echo
        continue
      }
      # optional mod_php HTTP probe
      if [ -n "$VHOST" ]; then
        "${SSHCMD[@]}" "$SSHUSER@$H" bash -s -- "$VHOST" <<<"$(remote_http_probe)" || true
      fi
    done
    echo
  }

  run_env "DEV"  "${DEV[@]}"
  run_env "TEST" "${TEST[@]}"
  run_env "PROD" "${PROD[@]}"

} > "$OUTFILE"

echo "✅ Done. Wrote $OUTFILE"
echo "Tip: git add $OUTFILE in your apache-wordpress repo."