# Brief description of the project

This project allows a system administrator to use a `devops` account that allows them to administer the server without having the ability to see the /home folder, user data, and their databases.

There are `/usr/local/bin/devops-*` scripts that allow service managment, viewing and editing files with elevated privileges for specific allowlisted paths.

# Project "rootless-devops" full description

Restricted-access DevOps maintenance model for Debian/Ubuntu servers (GDPR-aligned)

This project implements a practical “rootless” operations approach for infrastructure maintenance on Debian/Ubuntu servers, including servers running hosting panels such as myVesta.

The main idea is simple:

- The server owner wants you to administer his server but at the same time he doesn't want you to be able to see the user data on the server.
- With this scripts you can maintain the operating system and core services,
- You cannot access customer content, application files, or database contents,
- Privileged actions are limited to an explicit allowlist and are auditable.

## Why this exists

Many teams need to provide OS and service maintenance (system updates, service restarts, troubleshooting) while minimizing access to hosted data. This repository provides a structured way to enforce:

- least privilege,
- data minimization,
- segregation of duties,
- auditability,

and to support GDPR-aligned operational expectations around access control and accountability.

## What this is

A set of scripts and wrappers that:

- introduce a dedicated Unix user (`devops` user) for maintenance work (so you don't need root SSH access),
- allow only specific elevated commands via sudo (allowlist),
- restrict file access to configuration and logs only (path-based guardrails),
- provide a controlled `systemctl` wrapper limited to allowlisted services,
- optionally allow a small set of hosting-panel maintenance commands.

## What this is not

- a hosting panel, or a replacement for one
- an application administration toolkit (WordPress admin, CRM admin, etc.)
- a database administration tool
- a sandbox, container, or full MAC policy system (it complements those, but does not replace them)

## Requirements

- Debian or Ubuntu server
- SSH key-based access
- Installed `sudo` command
- Recommended: VPN-only access to the SSH maintenance entry point
- Recommended: Hardware-backed SSH keys (YubiKey or similar)

## Installation

Under the `root` account run:
```
wget -nv https://raw.githubusercontent.com/myvesta/rootless-devops/refs/heads/main/install.sh -O /root/install-rootless-devops.sh
bash /root/install-rootless-devops.sh
```

Installer script will:

1. Create a dedicated `devops` user
2. Install wrapper scripts such as `devops-systemctl`
3. Configure `sudo` allowlist for the `devops` user

After install, you should:
1. Add your SSH keys to `/home/devops/.ssh/authorized_keys`
2. (Optional) Configure allowlisted services and allowed paths in `/usr/local/bin/devops-override-conf` (see array format and variable names at the beginning of the file `/usr/local/bin/devops-func.sh`)
3. Verify if `devops` SSH login works, verify if `devops-*` command works, and confirm forbidden paths are blocked.
4. Remove your SSH keys from `/root/.ssh/authorized_keys`
5. Explain to the server owner how to change the root password, as well as the password for the hosting panel, backup, etc.

## Threat model (practical)

This project is designed to reduce risk from routine maintenance access by making it difficult and impractical to:

- browse `/home/*`,
- open website files and uploads,
- read application configs that often contain DB credentials,
- access database contents or database backups,
- log into a hosting panel as administrator,
- obtain a general-purpose interactive root shell.

If exceptional access is ever required, it should be handled via a separate, explicitly approved procedure with a defined scope and time window (see “Exceptional access procedure”).

## Architecture overview

### 1) Dedicated maintenance user

Typical setup uses a dedicated Unix account:

- user: `devops`
- purpose: OS maintenance with restricted sudo privileges
- authentication: SSH keys (recommended: hardware-backed keys such as YubiKey OpenPGP)
- root SSH login disabled
- no credential sharing, individual keys per engineer
- recommended: VPN-only access

### 2) Restricted privilege escalation (sudo allowlist)

The `devops` user can only execute an explicit allowlist of operational commands with elevated privileges.

Examples of allowed categories:

#### Patch management
Allowed for OS security and stability maintenance:
- `sudo apt update`
- `sudo apt upgrade`
- `sudo apt remove`

Not allowed:
- `sudo apt install` (prevents installing new tooling during routine access)

#### Service control (wrapped as `devops-systemctl`)
Allowed operations (for allowlisted services only):
- `status`
- `restart`
- `reload`
- `start`
- `stop`
- `enable`
- `disable`

Typical allowlisted services for hosting operations:
- nginx, apache2, php-fpm, mariadb, exim, dovecot, fail2ban, cron, ssh

#### System diagnostics (read-only)
Allowed to diagnose performance and incidents without reading customer content:
- `sudo top`
- `sudo iotop`
- `sudo iftop`
- `sudo reboot`

#### Hosting panel maintenance commands (optional)
If you use a hosting panel and want to permit maintenance-only actions (not admin access), you can allow a limited list of panel maintenance commands.

Example (myVesta):
- `sudo /usr/local/bin/devops-run-allowlisted-command /usr/local/vesta/bin/v-update-myvesta`
- `sudo /usr/local/bin/devops-run-allowlisted-command /usr/local/vesta/bin/v-clean-garbage`

A common pattern is to keep these in a root-owned allowlist file, for example:
- `/usr/local/bin/devops-override-conf`

See array format and variable names at the beginning of the file `/usr/local/bin/devops-func.sh`.

Only `root` should be able to extend that list.

### 3) Controlled file access (configuration and logs only)

To support troubleshooting while preventing access to hosted content, wrapper commands enforce path restrictions. Even if a wrapper runs as root, it only allows operations on explicitly approved locations.

Wrappers commonly included:
- `sudo devops-cat`
- `sudo devops-chmod`
- `sudo devops-chown`
- `sudo devops-cp`
- `sudo devops-echo`
- `sudo devops-mv`
- `sudo devops-rm`
- `sudo devops-sed`
- `sudo devops-stat`
- `sudo devops-tail`
- `sudo devops-self-update` (fetches updates from this repo)
- `sudo devops-mcview`
- `devops_mcedit` (partially elevated)

Allowed file locations (typical):
- `/etc/`
- `/var/log/`

Key protections:
- block path traversal (`../`)
- resolve real paths and ensure they remain inside allowed directories (symlink bypass prevention)

This enables access to:
- system configuration (for service operation)
- system logs (for auditing and troubleshooting)

while blocking browsing of:
- `/home/*`
- web roots under user directories
- application content directories
- backups and archives outside `/var/log`

#### Hardening controls for `/etc`
Allowing full edits under `/etc` is too broad because it contains security-sensitive files. To preserve the restricted-access model, deny edits to sensitive paths such as:
- `/etc/sudoers`, `/etc/sudoers.d/*`
- `/etc/ssh/*`
- `/etc/systemd/*`
- `/etc/cron*`
- `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`

This avoids trivial privilege recovery by changing sudo rules, startup units, or SSH access.

## Logging and auditability

All authentication and sudo actions should be logged and reviewable.

Typical audit sources:
- `/var/log/auth.log` (SSH logins, sudo usage)
- sudo logs (depending on configuration)
- service logs under `/var/log/*`

Optional enhancements:
- sudo I/O logging (session recording for allowed commands)
- centralized log shipping to the client SIEM/log platform

## Backup access limitations (recommended)

If you use backups that may contain customer content:

- the maintenance user should not have permission to browse or read backup repositories/data sets
- backup operations (creation, verification, retention, cleanup) should run via automated scripts/cron jobs
- restore actions should be performed via hosting panel or automation, only on explicit client request/approval
- any privileged backup-related actions should be logged the same way as other sudo-controlled operations

## Exceptional access procedure (recommended)

Sometimes a serious incident cannot be resolved with the restricted model alone. If that happens:

- treat it as a separate procedure
- define scope, time window, and explicit approval
- log all actions
- revert to restricted mode immediately after completion

Do not normalize “temporary root” as part of routine maintenance.

## Configuration concepts

### Allowlisted commands
Define exactly what `devops` may run with sudo. Keep it minimal and review changes like code.

### Allowlisted paths
Wrappers must validate the target path:
- must be within allowed roots (`/etc`, `/var/log`)
- must not escape via `../`
- must pass realpath checks to prevent symlink tricks

### Allowlisted services
`sudo devops-systemctl` should only accept known service names. Everything else should be rejected.

## Usage examples (typical)

- Check service status:
  - `sudo devops-systemctl status nginx`
- Restart a service:
  - `sudo devops-systemctl restart php-fpm`
- View logs:
  - `sudo devops-tail -f /var/log/nginx/error.log`
- Copy files:
  - `sudo devops-cp /etc/fstab /etc/fstab.backup`
- View config file (if allowed):
  - `sudo devops-cat /etc/nginx/nginx.conf`
  - `sudo devops-mcview /etc/nginx/nginx.conf`
- Edit config file (if allowed):
  - `devops_mcedit /etc/nginx/nginx.conf` (the only devops command without `sudo`)
- Update system software (allowed subset):
  - `sudo apt update`
  - `sudo apt upgrade`

## Security notes

- This is a “reduce practical access” model, not a cryptographic guarantee.
- You should still apply standard hardening: firewalling, MFA/VPN, timely updates, least privilege everywhere, monitoring, and incident response.
- Review allowlists periodically and treat changes as security-sensitive.
- Prefer immutable logs and centralized audit where possible.

## GDPR alignment (operational summary)

These measures support expectations around:
- access control and least privilege
- data minimization
- confidentiality and integrity
- accountability through logging

Operationally:
- infrastructure maintenance is possible
- access to customer content and database contents is not required, and is restricted by design

## Contributing

Contributions are welcome, especially:
- hardening improvements to path validation
- additional safe wrappers (with strict guardrails)
- documentation and test cases
- service allowlist patterns for common Debian/Ubuntu hosting stacks

Please open an issue or PR with:
- what problem you are solving
- threat/abuse cases considered
- how you tested it

## License

[GPL v3 license](https://github.com/myvesta/rootless-devops/blob/main/LICENSE)

## Disclaimer

This project helps enforce a restricted maintenance model, but no tooling can replace proper governance, approvals, and security reviews. Always validate that the configuration matches your legal, compliance, and operational requirements.
