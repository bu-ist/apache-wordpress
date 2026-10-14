# PHP OPcache Configuration Files

This directory contains PHP OPcache configuration files that should be deployed to `/etc/php.d/` on the WordPress application servers.

## File Loading Order

PHP loads `.ini` files in name order, and a value from a later file overrides an earlier one. `-` sorts before `.`, so the order is:

1. **10-opcache-site.deploy.ini** - Deployment-specific settings
2. **10-opcache-site.tuned.ini** - Site-specific tuning
3. **10-opcache.ini** - Base OPcache enablement
4. **99-opcache-tuned.ini** - Global tuning (loaded last, takes precedence)

## Effective Configuration

Values set by `/etc/php.d` on every host in this environment (dv01, dv02, dv03), collected October 14, 2026. Where several files set a value, the last one loaded wins.

| Setting | Value |
| --- | --- |
| `opcache.enable` | 1 |
| `opcache.enable_cli` | 0 |
| `opcache.enable_file_override` | 1 |
| `opcache.file_cache_only` | 0 |
| `opcache.file_update_protection` | 2 |
| `opcache.huge_code_pages` | 0 |
| `opcache.interned_strings_buffer` | 64 |
| `opcache.max_accelerated_files` | 200000 |
| `opcache.memory_consumption` | 1024 |
| `opcache.revalidate_freq` | 1 (dv03: 2) |
| `opcache.revalidate_path` | 1 |
| `opcache.save_comments` | 1 |
| `opcache.validate_timestamps` | 1 |
| `realpath_cache_size` | 4096K |
| `realpath_cache_ttl` | 300 |

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

Each environment branch records its own hosts:

- **Development** (`devl`): ist-wp-app-dv01, dv02, dv03
- **Test** (`test`): ist-wp-app-te01, te02
- **Production** (`prod`): ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06

The environments' OPcache settings differ; the top-level `README.md` compares them. All hosts run **PHP 7.4.33**.

## Key Configuration Decisions

### Why Multiple Files?

The 4-file structure allows for:

1. **Separation of concerns** - Base settings vs. deployment vs. tuning
2. **Selective overrides** - Different environments can use different tuning files if needed
3. **Clear precedence** - 99-opcache-tuned.ini loads last and sets final values

### Important Settings Explained

- **opcache.validate_timestamps=1** - OPcache checks file timestamps for changes
- **opcache.revalidate_freq=1 (dv03: 2)** - Seconds between checks for changed files
- **opcache.revalidate_path=1** - Validate full paths (ensures correct file resolution)
- **opcache.max_accelerated_files=200000** - Cache up to 200K PHP files (sufficient for multisite)
- **opcache.memory_consumption=1024** - Shared memory for OPcache, in MB
- **opcache.enable_cli=0** - OPcache is off for CLI scripts such as WP-CLI

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
