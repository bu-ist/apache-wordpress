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

| Setting                           | Value  | Source File                                                            |
| --------------------------------- | ------ | ---------------------------------------------------------------------- |
| `opcache.enable`                  | 1      | 99-opcache-tuned.ini                                                   |
| `opcache.enable_cli`              | 1      | 99-opcache-tuned.ini (overrides 0 from 10-opcache-site.tuned.ini)      |
| `opcache.memory_consumption`      | 512    | 99-opcache-tuned.ini                                                   |
| `opcache.interned_strings_buffer` | 16     | 99-opcache-tuned.ini                                                   |
| `opcache.max_accelerated_files`   | 100000 | 99-opcache-tuned.ini (overrides 200000 from 10-opcache-site.tuned.ini) |
| `opcache.validate_timestamps`     | 1      | 99-opcache-tuned.ini                                                   |
| `opcache.revalidate_freq`         | 2      | 99-opcache-tuned.ini                                                   |
| `opcache.revalidate_path`         | 0      | 99-opcache-tuned.ini (overrides 1 from earlier files)                  |
| `opcache.file_update_protection`  | 2      | 10-opcache-site.tuned.ini                                              |
| `opcache.save_comments`           | 1      | 99-opcache-tuned.ini                                                   |
| `opcache.enable_file_override`    | 1      | 99-opcache-tuned.ini                                                   |
| `opcache.file_cache_only`         | 0      | 99-opcache-tuned.ini                                                   |
| `opcache.huge_code_pages`         | 0      | 10-opcache.ini                                                         |

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

All servers run **PHP 7.4.33** with consistent OPcache settings verified via inventory on October 6, 2025.

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
