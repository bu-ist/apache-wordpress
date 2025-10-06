---
description: Repository Information Overview
alwaysApply: true
---

# Apache WordPress Configuration Information

## Summary

This repository tracks changes to Apache configuration files for a WordPress environment at Boston University. It contains the complete Apache HTTP server configuration for serving WordPress sites, including virtual hosts, PHP settings, and security configurations.

## Structure

- **conf/**: Main Apache configuration directory containing httpd.conf
- **conf.d/**: Directory for modular configuration files
- **conf.modules.d/**: Directory for Apache module configurations

## Server Configuration

### Web Server

**Server**: Apache HTTP Server
**User/Group**: wpcms
**Document Root**: /var/www/cms/current
**Secondary Document Root**: /var/www/blogs/current (for blogs)

### PHP Configuration

**Version**: PHP 7.4.33
**Module**: libphp7.so (prefork) or libphp7-zts.so (non-prefork)
**Memory Limit**: 256M
**Upload Max Size**: 100M
**Session Storage**: /var/lib/php/session

### PHP OPcache Configuration

**Status**: Enabled (opcache.enable=1)
**CLI Status**: Enabled (opcache.enable_cli=1)
**Memory Consumption**: 512MB
**Max Accelerated Files**: 100,000-200,000 (varies by config file)
**Timestamp Validation**: Enabled (opcache.validate_timestamps=1)
**Revalidation Frequency**: 2 seconds
**Configuration Files**:

- /etc/php.d/10-opcache.ini (base settings)
- /etc/php.d/10-opcache-site.deploy.ini (deployment settings)
- /etc/php.d/10-opcache-site.tuned.ini (site-specific tuning)
- /etc/php.d/99-opcache-tuned.ini (global tuning)

## Virtual Hosts

### HTTP (Port 80)

- Redirects all traffic to HTTPS using 303 redirect
- Serves all hostnames (ServerAlias \*)

### HTTPS (Port 443)

- SSL Configuration:
  - Protocol: All except SSLv2
  - Certificate: /etc/pki/tls/certs/localhost.crt
  - Key: /etc/pki/tls/private/localhost.key
- Supports multiple WordPress environments:
  - Main CMS: /var/www/cms/current
  - Blogs: /var/www/blogs/current
  - Sandboxes: /var/www/sandboxes/[username]/current

## Security Features

- RemoteIP module for handling X-Forwarded-For headers
- Trusted proxy networks configured
- AllowEncodedSlashes NoDecode to prevent content injection
- Shibboleth integration for authentication
- Restricted directory access with specific AllowOverride settings

## File Handling

- Custom file serving for WordPress uploads:
  - Files served from /fs/prod/wp-static/hosts/
- Directory permissions carefully configured for each environment
- PHP file extensions (.php, .phar) handled by PHP interpreter

## Environment Configuration

- Development servers (ist-wp-app-dv01, ist-wp-app-dv02)
- Testing servers (ist-wp-app-te01, ist-wp-app-te02)
- Production servers (not detailed in provided information)
- All environments use consistent PHP OPcache settings
- Development sandbox support (\*.cms-devl.bu.edu)
- Blog-specific configurations (blogs.bu.edu)
