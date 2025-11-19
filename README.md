# Apache WordPress Scripts

This branch contains utility scripts for managing and verifying the Apache WordPress infrastructure at Boston University.

## Available Scripts

### collect-opcache-inventory.sh

Comprehensive OPcache inventory collection script that gathers configuration data from all WordPress application servers across DEV, TEST, and PROD environments.

#### Prerequisites

Install `sshpass` for password-based SSH authentication:

**macOS (Homebrew):**

```bash
brew install hudochenkov/sshpass/sshpass
```

**Debian/Ubuntu:**

```bash
sudo apt-get install sshpass
```

**RHEL/CentOS:**

```bash
sudo yum install sshpass
```

#### Usage

```bash
# Basic usage (CLI configuration only)
SSHUSER=your_username ./collect-opcache-inventory.sh

# Include mod_php HTTP probe
SSHUSER=your_username VHOST=www.bu.edu ./collect-opcache-inventory.sh
```

#### What It Does

1. Prompts for your SSH password once
2. Connects to all 12 WordPress application servers:
   - **DEV**: ist-wp-app-dv01, dv02
   - **TEST**: ist-wp-app-te01, te02
   - **PROD**: ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06
3. Collects configured OPcache settings from `/etc/php.d/*.ini` files
4. Collects effective OPcache settings via PHP CLI
5. Optionally probes mod_php configuration via HTTP (if VHOST is set)
6. Generates a timestamped Markdown report: `OPcache-Inventory-YYYY-MM-DD.md`

#### Output

The script generates a comprehensive Markdown report containing:

- PHP version information for each server
- Configured OPcache settings from all .ini files
- Effective OPcache settings for key parameters
- Apache module information (mod_php presence)
- Optional mod_php effective settings (when using HTTP probe)

## Related Branches

For Apache and PHP configuration files, see:

- **devl** - Development environment configuration (dv01-dv02)
- **test** - Test environment configuration (te01-te02)
- **prod** - Production environment configuration (pr01-pr06)

All environments now running optimized OPcache settings as of Nov 19, 2025:
- 512MB memory, 200K files, revalidate_freq=2, revalidate_path=1

## Questions or Issues

If you encounter issues with the inventory collection script or need to verify OPcache configuration, contact the WordPress infrastructure team.
