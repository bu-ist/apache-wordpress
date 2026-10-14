# PHP OPcache Configuration Files

This directory contains PHP OPcache configuration files that should be deployed to `/etc/php.d/` on the WordPress application servers.

## File Loading Order

PHP loads `.ini` files in name order, and a value from a later file overrides an earlier one. `-` sorts before `.`, so the order is:

1. **10-opcache-site.deploy.ini** - Deployment-specific settings
2. **10-opcache-site.tuned.ini** - Site-specific tuning
3. **10-opcache.ini** - Base OPcache enablement
4. **99-opcache-tuned.ini** - Global tuning (loaded last, takes precedence)

## Effective Configuration

Values set by `/etc/php.d` on every host in this environment (pr01, pr02, pr03, pr04, pr05, pr06), collected October 14, 2026. Where several files set a value, the last one loaded wins.

| Setting | Value |
| --- | --- |
| `opcache.blacklist_filename` | `/etc/php.d/opcache*.blacklist` |
| `opcache.enable` | 1 |
| `opcache.enable_cli` | 0 |
| `opcache.enable_file_override` | 1 |
| `opcache.file_update_protection` | 2 |
| `opcache.huge_code_pages` | 0 |
| `opcache.interned_strings_buffer` | 64 |
| `opcache.max_accelerated_files` | 200000 |
| `opcache.max_wasted_percentage` | 5 |
| `opcache.memory_consumption` | 1024 |
| `opcache.revalidate_freq` | 2 |
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

## Deployment

To deploy these files to a server:

```bash
# Copy files
sudo cp php.d/*.ini /etc/php.d/
sudo chown root:root /etc/php.d/*opcache*.ini
sudo chmod 644 /etc/php.d/*opcache*.ini

# Verify
php -i | grep opcache

# Restart Apache (required for mod_php)
sudo systemctl restart httpd
```

See `OPCACHE_MIGRATION.md` for detailed deployment procedures and migration history.
