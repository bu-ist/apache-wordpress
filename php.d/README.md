# PHP OPcache Configuration Files

This directory contains PHP OPcache configuration files that should be deployed to `/etc/php.d/` on the WordPress application servers.

## File Loading Order

PHP loads `.ini` files in **alphanumeric order**. The configuration values from later files override earlier ones:

1. **10-opcache.ini** - Base OPcache enablement
2. **10-opcache-site.deploy.ini** - Deployment-specific settings
3. **10-opcache-site.tuned.ini** - Site-specific tuning
4. **99-opcache-tuned.ini** - Global tuning (loaded last, takes precedence)

## Effective Configuration

Due to the loading order, the **effective** OPcache settings are:

| Setting                           | Value  | Source File                                    |
| --------------------------------- | ------ | ---------------------------------------------- |
| `opcache.enable`                  | 1      | 99-opcache-tuned.ini                           |
| `opcache.enable_cli`              | 1      | 99-opcache-tuned.ini                           |
| `opcache.memory_consumption`      | 512    | 99-opcache-tuned.ini                           |
| `opcache.interned_strings_buffer` | 16     | 99-opcache-tuned.ini                           |
| `opcache.max_accelerated_files`   | 200000 | 99-opcache-tuned.ini                           |
| `opcache.validate_timestamps`     | 1      | 99-opcache-tuned.ini                           |
| `opcache.revalidate_freq`         | 2      | 99-opcache-tuned.ini                           |
| `opcache.revalidate_path`         | 1      | 99-opcache-tuned.ini                           |
| `opcache.file_update_protection`  | 2      | 10-opcache-site.tuned.ini                      |
| `opcache.save_comments`           | 1      | 99-opcache-tuned.ini                           |
| `opcache.enable_file_override`    | 1      | 99-opcache-tuned.ini                           |
| `opcache.file_cache_only`         | 0      | 99-opcache-tuned.ini                           |
| `opcache.huge_code_pages`         | 0      | 10-opcache.ini                                 |

## Verification

### Automated Inventory Collection

Use the `collect-opcache-inventory.sh` script from the **scripts** branch to collect comprehensive OPcache configuration from all environments:

```bash
# Switch to scripts branch
git checkout scripts

# Run inventory collection
SSHUSER=your_username ./collect-opcache-inventory.sh

# Or include mod_php HTTP probe
SSHUSER=your_username VHOST=www.bu.edu ./collect-opcache-inventory.sh
```

This generates a timestamped Markdown report with configured and effective settings from all DEV, TEST, and PROD servers.

### Manual Verification

To verify the effective OPcache configuration on a single server:

```bash
# Check CLI configuration
php -i | grep opcache

# Check specific values
php -r "echo 'opcache.enable: ' . ini_get('opcache.enable') . PHP_EOL;"
php -r "echo 'opcache.enable_cli: ' . ini_get('opcache.enable_cli') . PHP_EOL;"
php -r "echo 'opcache.max_accelerated_files: ' . ini_get('opcache.max_accelerated_files') . PHP_EOL;"

# View configuration files
grep -r "opcache\." /etc/php.d/
```

## Environment Consistency

These configuration files are deployed identically across all environments:

- **Development**: ist-wp-app-dv01, ist-wp-app-dv02
- **Test**: ist-wp-app-te01, ist-wp-app-te02
- **Production**: ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06

All servers run **PHP 7.4.33** with optimized OPcache settings deployed Nov 19, 2025.

## Key Configuration Decisions

### Why Multiple Files?

The 4-file structure allows for:

1. **Separation of concerns** - Base settings vs. deployment vs. tuning
2. **Selective overrides** - Different environments can use different tuning files if needed
3. **Clear precedence** - 99-opcache-tuned.ini loads last and sets final values

### Important Settings Explained

- **opcache.validate_timestamps=1** - OPcache checks file timestamps for changes
- **opcache.revalidate_freq=2** - Check for changes every 2 seconds (responsive to updates)
- **opcache.revalidate_path=1** - Validate full paths (ensures correct file resolution)
- **opcache.max_accelerated_files=200000** - Cache up to 200K PHP files (sufficient for multisite)
- **opcache.memory_consumption=512** - Allocate 512MB for OPcache
- **opcache.enable_cli=1** - Enable OPcache for CLI scripts (useful for WP-CLI)

### Optimization Notes

Current settings are optimized for WordPress multisite with:

- Large file capacity (200K files) to handle extensive plugin/theme ecosystem
- Path validation enabled for correct symlink handling
- Moderate revalidation frequency balancing performance and responsiveness

## Deployment

These files should be deployed to `/etc/php.d/` and require an Apache restart to take effect:

```bash
sudo systemctl restart httpd
```

Or for graceful reload:

```bash
sudo systemctl reload httpd
```
