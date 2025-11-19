#!/bin/bash
# compare-opcache-settings.sh
# Compare OPcache settings across DEV/TEST/PROD environments
#
# Purpose: Display side-by-side comparison of key OPcache settings across environments
#          to verify configuration consistency
# Usage: ./compare-opcache-settings.sh
#
# Prerequisites:
#   - SSH key-based authentication configured for all servers
#   - User has read access to /etc/php.d/ on all servers
#
# Notes:
#   - Samples one representative server from each environment
#   - Uses the last matching setting from .ini files (respects file load order)
#
# Author: Daniel Crews
# Last Updated: November 19, 2025

set -euo pipefail

# Representative servers for each environment
DEV_SERVER="ist-wp-app-d01"
TEST_SERVER="ist-wp-app-t01"
PROD_SERVER="ist-wp-app-pr01"

# Key OPcache settings to compare
SETTINGS=(
    "memory_consumption"
    "max_accelerated_files"
    "revalidate_freq"
    "revalidate_path"
    "validate_timestamps"
    "enable_cli"
    "interned_strings_buffer"
)

echo "=== OPcache Settings Comparison ==="
echo "Generated: $(date)"
echo ""
echo "Comparing: $DEV_SERVER (DEV) | $TEST_SERVER (TEST) | $PROD_SERVER (PROD)"
echo ""

# Print table header
printf "%-30s | %-6s | %-6s | %-6s\n" "Setting" "DEV" "TEST" "PROD"
echo "-------------------------------|--------|--------|--------"

# Compare each setting across environments
for setting in "${SETTINGS[@]}"; do
    printf "%-30s |" "opcache.$setting"

    # DEV value
    dev_val=$(ssh "$DEV_SERVER" "grep '^opcache.$setting' /etc/php.d/*.ini 2>/dev/null | tail -1 | cut -d= -f2" 2>/dev/null || echo "N/A")
    printf " %-6s |" "${dev_val:-N/A}"

    # TEST value
    test_val=$(ssh "$TEST_SERVER" "grep '^opcache.$setting' /etc/php.d/*.ini 2>/dev/null | tail -1 | cut -d= -f2" 2>/dev/null || echo "N/A")
    printf " %-6s |" "${test_val:-N/A}"

    # PROD value
    prod_val=$(ssh "$PROD_SERVER" "grep '^opcache.$setting' /etc/php.d/*.ini 2>/dev/null | tail -1 | cut -d= -f2" 2>/dev/null || echo "N/A")
    printf " %-6s" "${prod_val:-N/A}"

    # Check for inconsistencies
    if [ "$dev_val" != "$test_val" ] || [ "$test_val" != "$prod_val" ] || [ "$dev_val" != "$prod_val" ]; then
        printf " ⚠️"
    fi

    printf "\n"
done

echo ""
echo "Legend: ⚠️  = Inconsistent across environments"
echo ""

# Display PHP versions for reference
echo "=== PHP Versions ==="
printf "%-10s | %s\n" "Environment" "Version"
echo "-----------|---------------------------"
printf "%-10s | " "DEV"
ssh "$DEV_SERVER" "php -v | head -1" 2>/dev/null || echo "Unable to retrieve"
printf "%-10s | " "TEST"
ssh "$TEST_SERVER" "php -v | head -1" 2>/dev/null || echo "Unable to retrieve"
printf "%-10s | " "PROD"
ssh "$PROD_SERVER" "php -v | head -1" 2>/dev/null || echo "Unable to retrieve"

echo ""
echo "=== Configuration Files (by environment) ==="
echo ""

for env_server in "$DEV_SERVER:DEV" "$TEST_SERVER:TEST" "$PROD_SERVER:PROD"; do
    server="${env_server%:*}"
    env="${env_server#*:}"

    echo "[$env] $server:"
    ssh "$server" "ls -1 /etc/php.d/*opcache*.ini 2>/dev/null" 2>&1 || echo "  Unable to list files"
    echo ""
done
