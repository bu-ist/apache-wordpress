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

All servers run **PHP 7.4.33** with consistent OPcache settings.

## Key Configuration Decisions

### Why Multiple Files?

The multi-file structure allows for:

1. **Separation of concerns** - Base settings vs. deployment vs. tuning
2. **Selective overrides** - Different environments could theoretically use different tuning files
3. **Historical compatibility** - Maintains existing server configuration structure

### Important Settings Explained

- **opcache.validate_timestamps=1** - OPcache checks file timestamps for changes
- **opcache.revalidate_freq=2** - Check for changes every 2 seconds (good for development)
- **opcache.revalidate_path=0** - Don't validate full path (performance optimization)
- **opcache.max_accelerated_files=100000** - Cache up to 100K PHP files
- **opcache.memory_consumption=512** - Allocate 512MB for OPcache
- **opcache.enable_cli=1** - Enable OPcache for CLI scripts (useful for WP-CLI)

### Production Considerations

For production environments, consider:

- Increasing `opcache.revalidate_freq` to 60+ seconds (less frequent checks)
- Setting `opcache.validate_timestamps=0` for maximum performance (requires manual cache clearing on deployments)
- Monitoring OPcache memory usage and hit rates via `opcache_get_status()`

## Deployment

These files should be deployed to `/etc/php.d/` and require an Apache restart to take effect:

```bash
sudo systemctl restart httpd
```

Or for graceful reload:

```bash
sudo systemctl reload httpd
```
