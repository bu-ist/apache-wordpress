#!/bin/bash
# full-opcache-inventory.sh
# Complete OPcache configuration inventory for BU WordPress infrastructure
#
# Purpose: Generate comprehensive OPcache configuration inventory including all file
#          contents, effective settings, and system status for all servers
# Usage: ./full-opcache-inventory.sh
#
# Output: Creates timestamped file: opcache-inventory-YYYYMMDD-HHMMSS.txt
#
# Prerequisites:
#   - SSH key-based authentication configured for all servers
#   - User has read access to /etc/php.d/ on all servers
#   - User has permission to check systemd status
#
# Author: Daniel Crews
# Last Updated: November 19, 2025

set -euo pipefail

# Generate output filename with timestamp
OUTPUT_FILE="opcache-inventory-$(date +%Y%m%d-%H%M%S).txt"

# Server list
SERVERS=(
    ist-wp-app-d01 ist-wp-app-d02      # DEV
    ist-wp-app-t01 ist-wp-app-t02      # TEST
    ist-wp-app-pr01 ist-wp-app-pr02    # PROD
    ist-wp-app-pr03 ist-wp-app-pr04
    ist-wp-app-pr05 ist-wp-app-pr06
)

# Initialize output file with header
cat > "$OUTPUT_FILE" <<EOF
BU WordPress OPcache Configuration Inventory
Generated: $(date)
========================================

This report contains complete OPcache configuration from all WordPress
application servers including file contents and effective settings.

EOF

# Iterate through all servers and collect configuration
for server in "${SERVERS[@]}"; do
    echo "Processing $server..."

    cat >> "$OUTPUT_FILE" <<EOF

========================================
SERVER: $server
========================================
EOF

    # Collect comprehensive configuration from remote server
    ssh "$server" '
    echo "Hostname: $(hostname -f)"
    echo "PHP Version: $(php -v | head -1)"
    echo ""
    echo "Configuration Files:"
    ls -lh /etc/php.d/*opcache*.ini 2>/dev/null || echo "No OPcache .ini files found"
    echo ""
    echo "=== File Contents ==="
    for file in /etc/php.d/*opcache*.ini; do
        if [ -f "$file" ]; then
            echo ""
            echo "--- $file ---"
            cat "$file"
        fi
    done
    echo ""
    echo "=== Effective Settings (from php -i) ==="
    php -i | grep -E "^opcache\." | sort
    echo ""
    echo "=== Apache Status ==="
    systemctl status httpd --no-pager | head -5
    ' >> "$OUTPUT_FILE" 2>&1 || echo "⚠️  Failed to connect to $server" >> "$OUTPUT_FILE"

done

# Add footer
cat >> "$OUTPUT_FILE" <<EOF

========================================
Inventory Complete
========================================
EOF

echo ""
echo "✅ Inventory saved to: $OUTPUT_FILE"
echo ""
echo "Summary:"
wc -l "$OUTPUT_FILE"
echo ""

# Optionally display the file
read -p "Display inventory file? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat "$OUTPUT_FILE"
fi
