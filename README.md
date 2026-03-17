# Access limitation and GDPR-aligned operational model for the Debian server with myVesta hosting panel

## 1. Purpose
This document defines the technical and organizational measures used to ensure strict separation between infrastructure maintenance and access to Swiss personal data hosted on the server. It provides an audit-ready explanation of how infrastructure maintenance can be performed without practical access to customer data, and how any exceptional access is handled under client control.

**The goal is that:**
* We can maintain the operating system and core services (security updates, configuration, availability).
* We do not have practical, routine, or direct read access to WordPress databases, customer content, or user uploads.
* Privileged actions are limited to an explicit allowlist and are auditable.
* The client retains full control over any access that could lead to customer data exposure.

### Important note on the operational baseline
From the start of this cooperation, our standard operational approach is infrastructure-only maintenance. We do not need, request, or use access to website files, WordPress configuration files, uploads, or database contents to perform OS-level maintenance.

This document formalizes and hardens that approach into a GDPR-aligned model suitable for audits, ownership changes, and third-country access risk mitigation.

---

## 2. Scope
This document applies to:
* Debian server running **myVesta** and core infrastructure services.
* Our support and maintenance access used strictly for OS and infrastructure administration.

**This document does not cover:**
* Application administration (WordPress admin, plugins, WooCommerce, CRM, etc.).
* Customer database administration and data handling.
* Hosting panel administration under client credentials (except limited maintenance commands explicitly allowlisted below).

---

## 3. Roles and Responsibilities

### 3.1 Client (Data Owner / Controller)
* Owns the data and determines purposes and means of processing.
* Retains control over hosting panel admin credentials and root-level access.
* Retains control over application credentials and database credentials.
* Approves any action outside routine OS maintenance, especially anything that could affect hosted applications or expose data.

### 3.2 Us (Maintenance Provider)
* Act as OS and infrastructure administrators only, within the restricted-access model described here.
* Perform security maintenance, reliability operations, and incident response on OS and core services.
* Do not administer customer applications.
* Do not access or process customer database contents as part of standard maintenance.

---

## 4. Access Design Principles

### 4.1 Least Privilege
* No shared root access for daily work.
* No general-purpose interactive root shell for our team.
* Only allowlisted commands on allowlisted paths can run with elevated privileges via `sudo`.

### 4.2 Data Minimization
* Commands and tooling are selected for infrastructure operations only.
* File viewing and editing are restricted to explicitly allowlisted operational paths (Section 10), and not to customer data locations.

### 4.3 Segregation of Duties
* We do not have client hosting panel administrator credentials.
* We do not have customer application credentials.
* We do not have database administrator credentials.

### 4.4 Auditability
* Privileged actions are executed via `sudo` with logging.
* Authentication events and `sudo` events are available for review and audit evidence.

---

## 5. Accounts and Authentication

### 5.1 Maintenance Account
We use a dedicated Unix account for infrastructure maintenance:
* **User:** `devops`
* **Purpose:** OS maintenance with restricted `sudo` privileges (allowlist model).
* **Authentication:** SSH keys stored on YubiKey (OpenPGP) per engineer.
* No credential sharing.
* VPN-only access (mandatory).

### 5.2 Root Access Model
Root access is client-controlled.
* Direct root SSH password login is disabled.
* Root access is available only via SSH key authentication (YubiKey) controlled by the client.
* Our engineers do not retain client root keys as part of standard maintenance.

---

## 6. Launch Phase (Activation Procedure)
This section describes the steps to activate the restricted-access model. This procedure can be attached to an audit as proof of implementation.

### 6.1 Prerequisites
* Client provides their own pre-generated YubiKey SSH public keys for root access.
* Client confirms maintenance window for applying the changes.
* Client confirms `devops` is the only routine maintenance account.
* Client confirms that hosting panel admin password and any backup storage credentials are client-controlled.

### 6.2 Step-by-step Activation
1.  **Step 1: Disable password-based root access (already standard)**
    * Ensure SSH daemon configuration enforces key-based root access only.
    * Confirm that password authentication for root is disabled.
2.  **Step 2: Rotate root SSH keys so only the client retains root**
    * Remove any non-client SSH keys from `/root/.ssh/authorized_keys`.
    * Add only the client-provided YubiKey SSH public keys for root.
    * *Result:* Only the client can access root via SSH.
3.  **Step 3: Enforce devops-only access for our team**
    * Ensure our engineers’ YubiKey SSH keys are authorized only for the `devops` user.
    * Confirm `devops` has no general root shell capability and is limited to `sudo` allowlist wrappers.
4.  **Step 4: Rotate myVesta panel administrator password (client-controlled)**
    * The myVesta admin password is client-controlled and must be rotated at launch so that only the client knows it.
    * Client logs into the server via SSH using their root access (YubiKey).
    * Client executes: `v-change-user-password ‘admin’ ‘new_password’`
    * Client sets a new strong password that is not shared with us.
    * *Note:* Root password does not need to be rotated for SSH access because root login is key-based (YubiKey).
5.  **Step 5: Rotate backup storage credentials (client-controlled, Hetzner Storage Share)**
    * Client changes the password and access credentials for Hetzner Storage Share used for backups.
    * Updated credentials are stored only in client-controlled configuration locations.
    * Our team does not receive or store those credentials.
6.  **Step 6: Confirm restricted-access controls and audit evidence**
    * Verify `devops` `sudo` allowlist is active.
    * Verify wrapper-based file access restrictions are active (allowlisted read/write paths).
    * Verify mandatory logging, session evidence, and centralized log shipping is active (Section 12).

---

## 7. No Hosting Panel Administration Access
We do not keep or use a hosting panel administrator password.
* We cannot log into myVesta as administrator.
* Any panel-level administrative actions remain under client-controlled credentials.
* Our interaction with myVesta is limited to explicitly allowlisted maintenance commands (Sections 9 and 10).

---

## 8. No Database Content Access
We do not maintain customer database credentials.
* We do not store MySQL/MariaDB root passwords for use by our engineers.
* We do not access application database users or passwords.
* We do not access database backups (SQL dump files).
* Routine maintenance does not require reading database tables or application data.

Additionally, the restricted access model is designed so that the `devops` user cannot access typical locations where database credentials are stored (for example WordPress configuration files under user home directories).

---

## 9. Restricted Privilege Escalation (Sudo Allowlist)
To enforce least privilege, the `devops` user can execute only an explicit allowlist of operational commands with elevated privileges.

### Open-source implementation
We maintain the allowlist and wrapper tooling as an open-source project available for public review:
[https://github.com/myvesta/rootless-devops](https://github.com/myvesta/rootless-devops)

### 9.1 Patch Management
Allowed for OS security and stability maintenance:
* `apt update`
* `apt upgrade`
* `apt remove`

**Not allowed:**
* `apt install` (prevents installing new tooling outside agreed scope)

**Additional restriction for `apt remove` (safety control):**
Removal of critical security and logging components (e.g., `fail2ban`, audit tooling, SSH, logging shippers, firewall tooling) is not permitted. Any attempted removal is treated as a security event.

### 9.2 Service Control (wrapped as `devops-systemctl`)
Allowed service operations (status, restart, reload, start, stop, enable, disable) for:
* `nginx`, `apache2`
* `php-fpm`
* `mariadb` (service control only, no database access)
* `exim`, `dovecot`
* `fail2ban`
* `cron`
* `ssh`

### 9.3 System Diagnostics (read-only)
* `top` (or `htop`)
* `du` (restricted usage)
* `iotop`
* `iftop`

### 9.4 myVesta Maintenance Commands (custom allowlist)
Allowed commands in `devops-override-conf`:
* `/usr/local/vesta/bin/v-list-sys-services`
* `/usr/local/vesta/bin/v-commander`
* `/usr/local/vesta/bin/v-clean-garbage`
* `/usr/local/vesta/bin/v-clear-fail2ban`
* `/usr/local/vesta/bin/v-update-myvesta`
* `/usr/local/vesta/bin/v-update-firewall`

---

## 10. Controlled File Access
To support troubleshooting while preventing access to hosted content, we use wrapper commands:
`devops-cat`, `devops-chmod`, `devops-chown`, `devops-cp`, `devops-echo`, `devops-mv`, `devops-rm`, `devops-sed`, `devops-stat`, `devops-tail`, `devops-self-update`, `devops-mcview`, `devops_mcedit`.

### 10.1 Allowlisted Read and Write Paths
**Read access:**
* `/usr/local/vesta/data/firewall/rules.conf`
* `/usr/local/vesta/log/`
* `/root/vesta` (post-update-myvesta-custom-scripts)
* `/root/myvesta` (myvesta-custom-scripts-for-disk-usage-monitoring)
* `/root/check` (uptime-server-monitoring-system)

**Write access:**
* Identical to read paths above.

### 10.2 How Wrappers Enforce Path Restrictions
* **Real path resolution:** Prevents `../` traversal and symlink bypass.
* **Explicit allowlist matching:** Operations permitted only if target matches allowlist.
* **Argument hardening:** Prevents shell injection.
* **Deny-by-default:** Any unproven path is denied and logged.

### 10.3 General Restrictions
This prevents routine browsing of:
* `/home/*`
* Web roots, application configs, uploads, media libraries.
* Database dumps and customer backups.

### 10.4 Hardening Controls for `/etc` Access
If `/etc` is allowlisted, the following sensitive paths remain **explicitly denied**:
* `/etc/sudoers` and `/etc/sudoers.d/*`
* `/etc/ssh/*`
* `/etc/systemd/*`
* `/etc/cron*`
* `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`

---

## 11. What We Explicitly Cannot Do
* Browse `/home` directories.
* Open website files or application configs in user homes.
* Retrieve database credentials.
* Log into myVesta as admin.
* Access database contents or generate SQL dumps.
* General-purpose root shell.

---

## 12. Logging, Session Evidence, and Audit Trail (Mandatory)

### 12.1 Visibility
* `/var/log/auth.log` (SSH logins, sudo usage).

### 12.2 Mandatory sudo I/O logging
Provides auditable evidence of what was executed and produced.

### 12.3 Mandatory Centralized Log Shipping
Logs are shipped to a client-controlled remote location to prevent local alteration.

### 12.4 Full SSH Session Recording
Available upon client request and provider approval for specific sessions.

---

## 13. Residual Risk Note for Logs Containing Personal Data

### 13.1 Assessment
`/usr/local/vesta/log/` can contain IP addresses or email addresses related to security events.

### 13.2 Control and Minimization
Access is restricted to this narrow path for troubleshooting only, and all access is auditable.

---

## 14. Backups (Access Limitations)

### 14.1 Standard Rule (no routine access)
* `devops` account cannot browse or read backup repositories.
* Backups handled via automated scheduled jobs.

### 14.3 Break-glass Backup Restore
Performed under client supervision (e.g., AnyDesk) without sharing credentials with our team.

---

## 15. Emergency Procedures (Break-glass)
* **Rule:** Requires client approval, clear scope, and time window.
* **Post-incident review:** Mandatory review covering reason, actions, and evidence.
* **Commercial note:** Written reports are billed per working hour: [https://www.mycity-hosting.rs/cenovnik-pojedinacnih-usluga/](https://www.mycity-hosting.rs/cenovnik-pojedinacnih-usluga/)

---

## 16. SSH Session Controls
* **Timeouts:** SSH idle timeouts are supported.
* **Key rotation:** Engineers rotate hardware keys internally; server-side rotation on client request (billed service).

---

## 17. Change Management
* **Routine:** OS security updates performed in maintenance window.
* **Non-routine:** Client notification and approval required.

---

## 18. Periodic Review of Allowlists
Quarterly review of all allowed commands, paths, and services. Any change requires client approval.

---

## 19. Summary for GDPR Alignment
These measures implement:
* Access control and least privilege.
* Data minimization.
* Accountability through logging.
* Segregation of duties.

---

## Appendix A. Authoritative Allowlist Excerpt
*(Refer to Section 9.4 and 10.1 for current allowlisted commands and paths.)*

## Appendix B. Recommended Audit Evidence Set (Minimum)
* `/var/log/auth.log` extracts.
* `sudo` logs and `sudo I/O` records.
* Evidence of centralized log shipping destination.
* Copy of active `devops-override-conf`.
* Reference to `rootless-devops` version used.
