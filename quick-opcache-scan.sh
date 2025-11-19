#!/bin/bash
# quick-opcache-scan.sh
# Quick OPcache configuration scanner for BU WordPress infrastructure
#
# Purpose: Rapidly scan all WordPress app servers and display key OPcache settings
# Usage: ./quick-opcache-scan.sh
#
# Prerequisites:
#   - SSH key-based authentication configured for all servers
#   - User has read access to /etc/php.d/ on all servers
#
# Author: Daniel Crews
# Last Updated: November 19, 2025

set -euo pipefail

# Server list
SERVERS=(
    ist-wp-app-d01 ist-wp-app-d02      # DEV
    ist-wp-app-t01 ist-wp-app-t02      # TEST
    ist-wp-app-pr01 ist-wp-app-pr02    # PROD
    ist-wp-app-pr03 ist-wp-app-pr04
    ist-wp-app-pr05 ist-wp-app-pr06
)

echo "=== BU WordPress OPcache Configuration Report ==="
echo "Generated: $(date)"
echo ""

for server in "${SERVERS[@]}"; do
    echo "=========================================="
    echo "SERVER: $server"
    echo "=========================================="

    # Execute remote commands to gather OPcache configuration
    ssh "$server" 'hostname -s && \
    echo "" && \
    echo "Configuration Files:" && \
    ls -1 /etc/php.d/*opcache*.ini 2>/dev/null && \
    echo "" && \
    echo "Key Settings:" && \
    grep -h -E "^opcache\.(enable|enable_cli|memory_consumption|max_accelerated_files|revalidate_freq|revalidate_path|validate_timestamps)" /etc/php.d/*.ini 2>/dev/null | sort -u && \
    echo "" && \
    echo "Apache Status: $(systemctl is-active httpd)" && \
    echo ""' 2>&1 || echo "⚠️  Failed to connect to $server"

    echo ""
done

echo "=========================================="
echo "Scan Complete"
echo "=========================================="
