This repo exists to TRACK changes to the Apache and PHP configuration files in our WordPress environment.

Changes may be made to the in-production file through other means so
this file cannot necessarily be deployed as-is.

## Repository Structure

- **conf/** - Main Apache configuration (httpd.conf)
- **conf.d/** - Modular Apache configuration files
  - `wordpress.conf` - Main WordPress virtual host configuration
  - `php.conf` - PHP module configuration for Apache
  - `shib.conf` - Shibboleth authentication configuration
- **conf.modules.d/** - Apache module loading configuration
- **php.d/** - PHP OPcache configuration files (deployed to /etc/php.d/)
  - `10-opcache.ini` - Base OPcache settings
  - `10-opcache-site.deploy.ini` - Deployment-specific settings
  - `10-opcache-site.tuned.ini` - Site-specific tuning
  - `99-opcache-tuned.ini` - Global tuning (loaded last, takes precedence)

## PHP OPcache Configuration

OPcache settings are managed through PHP .ini files in the `php.d/` directory, which should be deployed to `/etc/php.d/` on the application servers. See `php.d/README.md` for detailed documentation on the configuration structure and effective settings.

## Branches and Environments

This repository uses branches to track configuration for each environment:

- **devl** branch → Development servers: ist-wp-app-dv01, ist-wp-app-dv02, ist-wp-app-dv03
- **test** branch → Test servers: ist-wp-app-te01, ist-wp-app-te02
- **prod** branch → Production servers: ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06
- **olap** branch → The 2023 s3proxy setup for S3 Object Lambda access points (README, image build and key rotation notes). Not an environment; its `docker.sh` no longer matches any host.
- **scripts** branch → Utility scripts for inventory collection and verification

All environments run PHP 7.4.33 with Apache HTTP Server.

### Interim php2shell settings

Since 2026-10-21 every host carries three temporary changes for CVE-2026-109618/-109619, to be removed once a patched PHP is installed:

- `conf.d/wordpress.conf`: `php_admin_value memory_limit -1` instead of `256M`, and no `php_admin_flag allow_call_time_pass_reference` line.
- `php.d/99-php2shell-mitigation.ini`: `session.upload_progress.enabled = 0`.
- `conf.d/zz-php2shell-check.conf`: a loopback-only `/__php2shell-check.php` that reports the PHP version, `memory_limit` and `session.upload_progress.enabled` the web SAPI uses. Its script, `/usr/local/share/bu-php2shell/check.php`, is outside the paths this repo tracks.

Each host keeps its previous `wordpress.conf` in `/root/conf-backups-<host>/`.

### Current OPcache Configuration Status

Values set by `/etc/php.d` on every host, collected October 14, 2026:

| Setting | DEVL | TEST | PROD |
| --- | --- | --- | --- |
| `opcache.memory_consumption` | 1024 | 512 | 1024 |
| `opcache.interned_strings_buffer` | 64 | 64 | 64 |
| `opcache.max_accelerated_files` | 200000 | 200000 | 200000 |
| `opcache.revalidate_freq` | 1 (dv03: 2) | 1 | 2 |
| `opcache.enable_cli` | 0 | 0 | 0 |

`php.d/README.md` lists every OPcache setting for this branch's hosts. See `OPCACHE_MIGRATION.md` for deployment procedures.

## Host-specific files

Files identical on every host in this environment are at their usual paths. A file that differs between hosts, or exists on only some of them, is under `hosts/<host>/` at the same relative path instead.

`hosts/<host>/MANIFEST.txt` lists every file collected from that host (size, date, path, SHA-256 prefix) and its httpd, mod_ssl, php and shibboleth package versions. Backup copies are listed but not recorded. Credentials, memory dumps and the s3proxy scripts other than `docker.sh` are not listed.
