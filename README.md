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

## Environments

Configuration is consistent across:

- **Development**: ist-wp-app-dv01, ist-wp-app-dv02
- **Test**: ist-wp-app-te01, ist-wp-app-te02
- **Production**: (servers TBD)

All environments run PHP 7.4.33 with Apache HTTP Server.
