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

- **devl** branch → Development servers: ist-wp-app-dv01, ist-wp-app-dv02
- **test** branch → Test servers: ist-wp-app-te01, ist-wp-app-te02
- **prod** branch → Production servers: ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06
- **olap** branch → OLAP environment
- **scripts** branch → Utility scripts for inventory collection and verification

All environments run PHP 7.4.33 with Apache HTTP Server.

### Current OPcache Configuration Status

As of November 19, 2025:

- **Phase 2 PROD Cleanup Complete**: All 6 PROD servers (pr01-pr06) updated
- **Clean 4-file structure** implemented across all environments
- **Optimized settings**: 512MB memory, 200K files, revalidate_freq=2, revalidate_path=1
- Configuration verified and deployed to all DEV, TEST, and PROD servers
- See `OPCACHE_MIGRATION.md` for deployment procedures
