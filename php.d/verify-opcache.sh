#!/bin/bash
# OPcache Configuration Verification Script
# Compares repository configuration with actual server settings
# Usage: ./verify-opcache.sh [hostname]

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${1:-$(hostname -s)}"

echo "=================================================================================="
echo "OPcache Configuration Verification"
echo "Host: $HOST"
echo "Date: $(date)"
echo "=================================================================================="
echo ""

# Expected effective values based on repository configuration
declare -A EXPECTED=(
    ["opcache.enable"]="1"
    ["opcache.enable_cli"]="1"
    ["opcache.memory_consumption"]="512"
    ["opcache.interned_strings_buffer"]="16"
    ["opcache.max_accelerated_files"]="100000"
    ["opcache.validate_timestamps"]="1"
    ["opcache.revalidate_freq"]="2"
    ["opcache.revalidate_path"]="0"
    ["opcache.file_update_protection"]="2"
    ["opcache.save_comments"]="1"
    ["opcache.enable_file_override"]="1"
    ["opcache.file_cache_only"]="0"
    ["opcache.huge_code_pages"]="0"
)

echo "[Repository Configuration Files]"
echo "--------------------------------"
for file in "$REPO_DIR"/*.ini; do
    if [ -f "$file" ]; then
        echo "$(basename "$file"):"
        grep -E "^opcache\." "$file" | sed 's/^/  /'
        echo ""
    fi
done

echo ""
echo "[Effective PHP Configuration]"
echo "-----------------------------"

# Check if we can run PHP commands
if ! command -v php &> /dev/null; then
    echo "ERROR: PHP command not found"
    exit 1
fi

echo "PHP Version: $(php -v | head -n 1)"
echo ""

# Check each expected value
MISMATCHES=0
for key in "${!EXPECTED[@]}"; do
    ACTUAL=$(php -r "echo ini_get('$key');")
    EXPECTED_VAL="${EXPECTED[$key]}"

    if [ "$ACTUAL" == "$EXPECTED_VAL" ]; then
        echo "✓ $key: $ACTUAL"
    else
        echo "✗ $key: $ACTUAL (expected: $EXPECTED_VAL)"
        ((MISMATCHES++))
    fi
done

echo ""
echo "[Configuration Files on Server]"
echo "-------------------------------"
if [ -d "/etc/php.d" ]; then
    ls -la /etc/php.d/*opcache*.ini 2>/dev/null || echo "No OPcache .ini files found in /etc/php.d/"
else
    echo "/etc/php.d directory not found"
fi

echo ""
echo "=================================================================================="
if [ $MISMATCHES -eq 0 ]; then
    echo "✓ All OPcache settings match expected values"
    exit 0
else
    echo "✗ Found $MISMATCHES mismatched setting(s)"
    exit 1
fi