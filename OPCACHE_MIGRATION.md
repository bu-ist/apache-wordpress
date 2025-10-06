# OPcache Configuration Migration Summary

**Date**: January 2025
**Author**: Daniel Crews
**Purpose**: Align repository configuration with actual server deployment

## Overview

This document describes the migration of OPcache configuration from Apache `php_admin_value` directives to PHP `.ini` files, matching the actual deployment on DEV/TEST/PROD servers.

## Problem Statement

The repository previously tracked OPcache configuration in `conf.d/php.conf` using Apache directives:

```apache
php_admin_value opcache.enable 1
php_admin_value opcache.enable_cli 1
php_admin_value opcache.memory_consumption 512
# ... etc
```

However, the actual servers (ist-wp-app-dv01, dv02, te01, te02) use PHP `.ini` files in `/etc/php.d/`:

- `10-opcache.ini`
- `10-opcache-site.deploy.ini`
- `10-opcache-site.tuned.ini`
- `99-opcache-tuned.ini`

This discrepancy meant the repository didn't accurately reflect the as-built configuration.

## Solution

### 1. Created `php.d/` Directory Structure

Added four `.ini` files matching the server deployment:

```
php.d/
├── 10-opcache.ini                    # Base OPcache enablement
├── 10-opcache-site.deploy.ini        # Deployment settings
├── 10-opcache-site.tuned.ini         # Site-specific tuning
├── 99-opcache-tuned.ini              # Global tuning (loaded last)
└── README.md                          # Comprehensive documentation
```

### 2. Configuration File Contents

#### 10-opcache.ini

```ini
opcache.enable=1
opcache.huge_code_pages=0
```

#### 10-opcache-site.deploy.ini

```ini
opcache.revalidate_path=1
```

#### 10-opcache-site.tuned.ini

```ini
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=512
opcache.max_accelerated_files=200000
opcache.validate_timestamps=1
opcache.revalidate_freq=2
opcache.revalidate_path=1
opcache.file_update_protection=2
```

#### 99-opcache-tuned.ini

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=512
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=100000
opcache.validate_timestamps=1
opcache.revalidate_freq=2
opcache.save_comments=1
opcache.enable_file_override=1
opcache.revalidate_path=0
opcache.file_cache_only=0
```

### 3. Updated Apache Configuration

Modified `conf.d/php.conf` to remove OPcache directives and add documentation:

```apache
#
# PHP OPcache Configuration (PHP 7.4.33)
# OPcache is configured via PHP .ini files in /etc/php.d/:
#   - 10-opcache.ini (base settings)
#   - 10-opcache-site.deploy.ini (deployment settings)
#   - 10-opcache-site.tuned.ini (site-specific tuning)
#   - 99-opcache-tuned.ini (global tuning, loaded last)
# See php.d/ directory in this repository for configuration files.
#
```

## Effective Configuration

Due to PHP's alphanumeric loading order, `99-opcache-tuned.ini` is loaded last and overrides earlier settings:

| Setting                           | Effective Value | Notes                                           |
| --------------------------------- | --------------- | ----------------------------------------------- |
| `opcache.enable`                  | **1**           | Enabled                                         |
| `opcache.enable_cli`              | **1**           | Overrides 0 from 10-opcache-site.tuned.ini      |
| `opcache.memory_consumption`      | **512**         | 512MB allocated                                 |
| `opcache.interned_strings_buffer` | **16**          | 16MB for interned strings                       |
| `opcache.max_accelerated_files`   | **100000**      | Overrides 200000 from 10-opcache-site.tuned.ini |
| `opcache.validate_timestamps`     | **1**           | Check for file changes                          |
| `opcache.revalidate_freq`         | **2**           | Check every 2 seconds                           |
| `opcache.revalidate_path`         | **0**           | Overrides 1 from earlier files                  |
| `opcache.file_update_protection`  | **2**           | 2-second protection window                      |
| `opcache.save_comments`           | **1**           | Preserve docblocks                              |
| `opcache.enable_file_override`    | **1**           | Performance optimization                        |
| `opcache.file_cache_only`         | **0**           | Use shared memory                               |
| `opcache.huge_code_pages`         | **0**           | Disabled                                        |

## Key Differences from Previous Configuration

### Apache Directives vs. PHP .ini Files

**Previous (Apache directives)**:

- Only applied to mod_php requests (web requests)
- Did not affect CLI scripts
- Configured in `conf.d/php.conf`

**Current (PHP .ini files)**:

- Applied to ALL PHP processes (web + CLI)
- Matches actual server deployment
- Configured in `php.d/*.ini` files

### Configuration Conflicts Resolved

The multi-file structure contains intentional conflicts that are resolved by load order:

1. **opcache.enable_cli**: Set to 0 in `10-opcache-site.tuned.ini`, overridden to 1 in `99-opcache-tuned.ini`
2. **opcache.max_accelerated_files**: Set to 200000 in `10-opcache-site.tuned.ini`, overridden to 100000 in `99-opcache-tuned.ini`
3. **opcache.revalidate_path**: Set to 1 in multiple files, overridden to 0 in `99-opcache-tuned.ini`

These conflicts are **intentional** and match the actual server configuration verified via the October 2025 inventory.

## Verification

### Using the Inventory Collection Script

Use the comprehensive inventory collection script from the **scripts** branch:

```bash
# Switch to scripts branch
git checkout scripts

# Run inventory collection
SSHUSER=your_username ./collect-opcache-inventory.sh

# Or include mod_php HTTP probe
SSHUSER=your_username VHOST=www.bu.edu ./collect-opcache-inventory.sh
```

This will:

1. Prompt for your SSH password once
2. Connect to all 12 WordPress application servers (DEV, TEST, PROD)
3. Collect configured OPcache settings from `/etc/php.d/*.ini` files
4. Collect effective OPcache settings via PHP CLI
5. Optionally probe mod_php configuration via HTTP
6. Generate a timestamped Markdown report: `OPcache-Inventory-YYYY-MM-DD.md`

### Manual Verification

Check effective OPcache settings on a server:

```bash
# View all OPcache settings
php -i | grep opcache

# Check specific values
php -r "echo 'opcache.enable: ' . ini_get('opcache.enable') . PHP_EOL;"
php -r "echo 'opcache.max_accelerated_files: ' . ini_get('opcache.max_accelerated_files') . PHP_EOL;"

# View configuration files
grep -r "opcache\." /etc/php.d/
```

## Deployment Instructions

To deploy these configuration files to a server:

1. **Copy files to server**:

   ```bash
   sudo cp php.d/*.ini /etc/php.d/
   sudo chown root:root /etc/php.d/*opcache*.ini
   sudo chmod 644 /etc/php.d/*opcache*.ini
   ```

2. **Verify configuration**:

   ```bash
   php -i | grep opcache
   ```

3. **Restart Apache** (required for mod_php):

   ```bash
   sudo systemctl restart httpd
   ```

   Or for graceful reload:

   ```bash
   sudo systemctl reload httpd
   ```

4. **Verify OPcache is active**:
   ```bash
   php -r "var_dump(opcache_get_status());"
   ```

## Environment Consistency

These configuration files are deployed identically across all environments:

- ✓ **Development**: ist-wp-app-dv01, ist-wp-app-dv02
- ✓ **Test**: ist-wp-app-te01, ist-wp-app-te02
- ✓ **Production**: (servers TBD)

All servers run **PHP 7.4.33** with consistent OPcache settings verified via inventory on October 6, 2025.

## Performance Implications

### Current Settings (Development/Test)

The current configuration is optimized for **development and testing**:

- `opcache.validate_timestamps=1` - Files are checked for changes
- `opcache.revalidate_freq=2` - Checks happen every 2 seconds
- `opcache.enable_cli=1` - CLI scripts benefit from OPcache (useful for WP-CLI)

### Production Recommendations

For production environments, consider these optimizations:

```ini
; Disable timestamp validation for maximum performance
opcache.validate_timestamps=0

; If keeping validation enabled, increase revalidation frequency
opcache.revalidate_freq=60

; Consider increasing max accelerated files if needed
opcache.max_accelerated_files=200000
```

**Important**: With `validate_timestamps=0`, you must manually clear OPcache after deployments:

```bash
# Via CLI
php -r "opcache_reset();"

# Via Apache restart
sudo systemctl restart httpd
```

## Monitoring

Monitor OPcache performance using:

```php
<?php
$status = opcache_get_status();
echo "Memory Usage: " . $status['memory_usage']['used_memory'] . " / " .
     $status['memory_usage']['free_memory'] . "\n";
echo "Hit Rate: " . ($status['opcache_statistics']['hits'] /
     ($status['opcache_statistics']['hits'] + $status['opcache_statistics']['misses']) * 100) . "%\n";
echo "Cached Scripts: " . $status['opcache_statistics']['num_cached_scripts'] . " / " .
     $status['opcache_statistics']['max_cached_scripts'] . "\n";
```

Ideal metrics:

- **Hit Rate**: > 95%
- **Memory Usage**: < 80% of allocated
- **Cached Scripts**: Well below max_accelerated_files

## References

- **OPcache Inventory**: Generated October 6, 2025 by danielcrews
- **PHP Version**: 7.4.33 (consistent across all environments)
- **Server Documentation**: See `php.d/README.md` for detailed configuration documentation

## Questions or Issues

If you encounter discrepancies between the repository and server configuration:

1. Run the inventory collection script from the **scripts** branch (see Verification section above)
2. Check the generated OPcache inventory report
3. Verify file load order: `php --ini`
4. Check effective values: `php -i | grep opcache`

For configuration changes, update the appropriate `.ini` file based on the setting's purpose:

- **Base settings** → `10-opcache.ini`
- **Deployment settings** → `10-opcache-site.deploy.ini`
- **Site tuning** → `10-opcache-site.tuned.ini`
- **Global overrides** → `99-opcache-tuned.ini`
