# rootless-devops

Restricted-access DevOps maintenance model for Debian/Ubuntu servers (GDPR-aligned)

This project implements a practical “rootless” operations approach for infrastructure maintenance on Debian/Ubuntu servers, including servers running hosting panels such as myVesta.

The main idea is simple:

- we can maintain the operating system and core services,
- we cannot practically access customer content, application files, or database contents,
- privileged actions are limited to an explicit allowlist and are auditable.

## Why this exists

Many teams need to provide OS and service maintenance (patching, restarts, troubleshooting) while minimizing access to hosted data. This repository provides a structured way to enforce:

- least privilege,
- data minimization,
- segregation of duties,
- auditability,

and to support GDPR-aligned operational expectations around access control and accountability.

## What this is

A set of scripts and wrappers that:

- introduce a dedicated Unix user (example: `devops`) for maintenance work,
- disable direct root SSH access,
- allow only specific elevated commands via sudo (allowlist),
- restrict file access to configuration and logs only (path-based guardrails),
- provide a controlled `systemctl` wrapper limited to allowlisted services,
- optionally allow a small set of hosting-panel maintenance commands.

## What this is not

- a hosting panel, or a replacement for one
- an application administration toolkit (WordPress admin, CRM admin, etc.)
- a database administration tool
- a sandbox, container, or full MAC policy system (it complements those, but does not replace them)

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
- `apt update`
- `apt upgrade`
- `apt remove`

Not allowed:
- `apt install` (prevents installing new tooling during routine access)

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
- `top` (or `htop`)
- `du` (restricted usage)
- `iotop`
- `iftop`

#### Hosting panel maintenance commands (optional)
If you use a hosting panel and want to permit maintenance-only actions (not admin access), you can allow a limited list of panel maintenance commands.

Example (myVesta):
- `v-update-myvesta`
- `v-clean-garbage`

A common pattern is to keep these in a root-owned allowlist file, for example:
- `/usr/local/bin/devops-override-conf`

Only `root` should be able to extend that list.

### 3) Controlled file access (configuration and logs only)

To support troubleshooting while preventing access to hosted content, wrapper commands enforce path restrictions. Even if a wrapper runs as root, it only allows operations on explicitly approved locations.

Wrappers commonly included:
- `devops-cat`
- `devops-chmod`
- `devops-chown`
- `devops-cp`
- `devops-echo`
- `devops-mv`
- `devops-rm`
- `devops-sed`
- `devops-stat`
- `devops-tail`
- `devops-self-update` (fetches updates from this repo)
- `devops-mcview`
- `devops-mcedit` (partially elevated)

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

## Requirements

- Debian or Ubuntu server
- SSH key-based access
- sudo
- recommended: VPN-only access to the maintenance entry point
- recommended: hardware-backed SSH keys (YubiKey or similar)

## Installation (high level)

Exact steps can differ per environment, but the typical flow is:

1. Create a dedicated user (example: `devops`)
2. Disable direct root SSH login
3. Install wrapper scripts and `devops-systemctl`
4. Configure sudo allowlist for the `devops` user
5. Configure allowlisted services and allowed paths
6. (Optional) Configure hosting panel maintenance allowlist
7. Verify logging, confirm forbidden paths are blocked

## Configuration concepts

### Allowlisted commands
Define exactly what `devops` may run with sudo. Keep it minimal and review changes like code.

### Allowlisted paths
Wrappers must validate the target path:
- must be within allowed roots (`/etc`, `/var/log`)
- must not escape via `../`
- must pass realpath checks to prevent symlink tricks

### Allowlisted services
`devops-systemctl` should only accept known service names. Everything else should be rejected.

## Usage examples (typical)

- check service status:
  - `devops-systemctl status nginx`
- restart a service:
  - `devops-systemctl restart php-fpm`
- view logs:
  - `devops-tail /var/log/nginx/error.log`
- view config file (if allowed):
  - `devops-cat /etc/nginx/nginx.conf`
- run patching (allowed subset):
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
