# Apache WordPress Scripts

This branch contains utility scripts for managing and verifying the Apache WordPress infrastructure at Boston University.

## Available Scripts

This branch provides four scripts for OPcache configuration management. Choose the appropriate script based on your needs:

### Quick Reference

| Script | Purpose | Auth Method | Output Format | Use When |
|--------|---------|-------------|---------------|----------|
| `quick-opcache-scan.sh` | Fast scan of key settings | SSH keys | Terminal | Quick verification |
| `compare-opcache-settings.sh` | Compare across environments | SSH keys | Terminal table | Verify consistency |
| `full-opcache-inventory.sh` | Complete configuration dump | SSH keys | Text file | Deep investigation |
| `collect-opcache-inventory.sh` | Comprehensive report | Password (sshpass) | Markdown file | Formal documentation |

---

### quick-opcache-scan.sh

**Purpose:** Rapidly scan all WordPress app servers and display key OPcache settings.

**Use this when:** You need a quick check of the current configuration across all servers.

**Prerequisites:**
- SSH key-based authentication configured for all servers

**Usage:**
```bash
./quick-opcache-scan.sh
```

**Output:** Displays configuration directly to terminal for all 10 servers.

---

### compare-opcache-settings.sh

**Purpose:** Side-by-side comparison of OPcache settings across DEV, TEST, and PROD environments.

**Use this when:** You need to verify configuration consistency across environments or identify discrepancies.

**Prerequisites:**
- SSH key-based authentication configured for all servers

**Usage:**
```bash
./compare-opcache-settings.sh
```

**Output:** Displays comparison table with environment differences highlighted (⚠️).

**Example Output:**
```
Setting                        | DEV    | TEST   | PROD
-------------------------------|--------|--------|--------
opcache.memory_consumption     | 512    | 512    | 512
opcache.max_accelerated_files  | 200000 | 200000 | 200000
opcache.revalidate_path        | 1      | 1      | 1
```

---

### full-opcache-inventory.sh

**Purpose:** Generate comprehensive OPcache configuration inventory including all file contents and effective settings.

**Use this when:** You need complete configuration details for troubleshooting or audit purposes.

**Prerequisites:**
- SSH key-based authentication configured for all servers

**Usage:**
```bash
./full-opcache-inventory.sh
```

**Output:** Creates timestamped text file: `opcache-inventory-YYYYMMDD-HHMMSS.txt`

**Contents:**
- PHP version for each server
- Complete contents of all `/etc/php.d/*opcache*.ini` files
- Effective settings from `php -i`
- Apache service status

---

### collect-opcache-inventory.sh

**Purpose:** Comprehensive OPcache inventory with password-based authentication and Markdown output.

**Use this when:** You need formal documentation and don't have SSH keys configured, or want a nicely formatted Markdown report.

**Prerequisites:**

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

**Usage:**
```bash
# Basic usage (CLI configuration only)
SSHUSER=your_username ./collect-opcache-inventory.sh

# Include mod_php HTTP probe
SSHUSER=your_username VHOST=www.bu.edu ./collect-opcache-inventory.sh
```

**What It Does:**
1. Prompts for your SSH password once
2. Connects to all 10 WordPress application servers:
   - **DEV**: ist-wp-app-d01, d02
   - **TEST**: ist-wp-app-t01, t02
   - **PROD**: ist-wp-app-pr01, pr02, pr03, pr04, pr05, pr06
3. Collects configured OPcache settings from `/etc/php.d/*.ini` files
4. Collects effective OPcache settings via PHP CLI
5. Optionally probes mod_php configuration via HTTP (if VHOST is set)
6. Generates a timestamped Markdown report: `OPcache-Inventory-YYYY-MM-DD.md`

**Output:** Markdown-formatted report with organized sections for each server.

## Related Branches

For Apache and PHP configuration files, see:

- **devl** - Development environment configuration (dv01-dv02)
- **test** - Test environment configuration (te01-te02)
- **prod** - Production environment configuration (pr01-pr06)

All environments now running optimized OPcache settings as of Nov 19, 2025:
- 512MB memory, 200K files, revalidate_freq=2, revalidate_path=1

## Questions or Issues

If you encounter issues with the inventory collection script or need to verify OPcache configuration, contact the WordPress infrastructure team.
