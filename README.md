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
- **prod** branch → Production servers: ist-wp-app-pr01 through pr06
- **olap** branch → OLAP environment
- **verify** branch → Inventory collection tools

All environments run PHP 7.4.33 with Apache HTTP Server.

### Current OPcache Configuration Status

As of October 6, 2025 inventory:

- **devl** and **test** branches have identical OPcache configuration
- Configuration verified against actual server deployment in /etc/php.d/
- See `OPCACHE_MIGRATION.md` for deployment procedures

## OPcache Inventory Collection

The **verify** branch contains `collect-opcache-inventory.sh`, a script for collecting OPcache configuration from all environments.

### Prerequisites

Install `sshpass` for password-based SSH authentication:

```bash
# macOS
brew install hudochenkov/sshpass/sshpass

# Linux (Debian/Ubuntu)
sudo apt-get install sshpass

# Linux (RHEL/CentOS)
sudo yum install sshpass
```

### Usage

```bash
# Basic usage (CLI configuration only)
SSHUSER=dcrews ./collect-opcache-inventory.sh

# Include mod_php HTTP probe
SSHUSER=dcrews VHOST=www.bu.edu ./collect-opcache-inventory.sh
```

The script will:

1. Prompt for your SSH password once
2. Connect to all DEV, TEST, and PROD servers
3. Collect configured OPcache settings from `/etc/php.d/*.ini`
4. Collect effective OPcache settings via PHP CLI
5. Optionally probe mod_php settings via HTTP (if VHOST is set)
6. Generate a timestamped Markdown report: `OPcache-Inventory-YYYY-MM-DD.md`

### Servers Inventoried

- **DEV**: ist-wp-app-dv01, ist-wp-app-dv02
- **TEST**: ist-wp-app-te01, ist-wp-app-te02
- **PROD**: ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06
