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
* Denied access attempts are explicitly logged via devops wrapper logging (Section 12.5).

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
    * Client executes: `v-change-user-password 'admin' 'new_password'`
    * Client sets a new strong password that is not shared with us.
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

### Open-source implementation
We maintain the allowlist and wrapper tooling as an open-source project available for public review:
https://github.com/myvesta/rootless-devops

### 9.1 Patch Management
Allowed for OS security and stability maintenance:
* `apt update`
* `apt upgrade`

**Not allowed:**
* `apt install`
* `apt remove`

---

### 9.2 Service Control (wrapped as `devops-systemctl`)
Allowed service operations for:
* `nginx`, `apache2`
* `php-fpm`
* `mariadb`
* `exim`, `dovecot`
* `fail2ban`
* `cron`
* `ssh`

---

### 9.3 System Diagnostics (read-only)
* `top`
* `du`
* `iotop`
* `iftop`

---

### 9.4 myVesta Maintenance Commands (custom allowlist)

#### v-commander
Used strictly for infrastructure and service maintenance.

Capabilities include:
* Service status checks
* Restart/reload of services
* Updating service configurations (web server, fail2ban filters, WAF rules)
* Updating SpamAssassin rules
* Validating server configuration (e.g., Apache MPM mode)

**Restrictions:**
* Does not list users, websites, or email accounts
* Does not expose customer-related data
* Does not read or access files under `/home`
* Does not interact with application-level data

---

#### v-clean-garbage
Used for disk space maintenance and cleanup.

Capabilities include:
* Removal or truncation of unnecessary `*.log` files
* Cleanup of cache directories (e.g., `/wp-content/cache/`)
* Disk space reclamation

**Restrictions:**
* Does not read file contents
* Does not list or expose file names
* Produces only aggregated output (e.g., freed disk space)
* No ability to extract or inspect customer data

**Note:**  
This command may operate on paths under `/home`, but only in a non-inspecting, non-reading manner for cleanup purposes.

---

#### devops-self-update
Used to update wrapper scripts enforcing access restrictions.

**Control model:**
* Can be disabled entirely if required by the client
* Can be restricted to manual execution under client-controlled root session
* Can be configured to pull from a client-controlled fork instead of the upstream repository

**Transparency:**
* All changes are publicly visible via version control history
* No hidden or automatic background updates are performed

---

## 10. Controlled File Access

To support troubleshooting while preventing access to hosted content, we use wrapper commands:
`devops-cat`, `devops-chmod`, `devops-chown`, `devops-cp`, `devops-echo`, `devops-mv`, `devops-rm`, `devops-sed`, `devops-stat`, `devops-tail`, `devops-self-update`, `devops-mcview`, `devops_mcedit`.

---

### 10.3 devops_mcedit (partially elevated editing)

This command enables controlled editing of system configuration files.

**How it works:**
1. File is validated against allowlisted paths
2. File is copied to a temporary location (`/tmp`)
3. Editing is performed as a non-privileged `devops` user
4. Modified file is copied back with elevated privileges

**Security properties:**
* The editor itself runs without privileges
* No access to arbitrary files via editor menus
* No ability to escape into restricted paths
* Only allowlisted files can be modified

---

## 12. Logging, Session Evidence, and Audit Trail (Mandatory)

### 12.1 Visibility
* `/var/log/auth.log`

### 12.2 Mandatory sudo I/O logging

### 12.3 Mandatory Centralized Log Shipping

### 12.4 Full SSH Session Recording

### 12.5 Denied access logging (devops allowlist enforcement)

All denied access attempts triggered by devops wrapper commands are logged to a dedicated log file:

/var/log/devops-denied-access.log

This includes:
* Attempts to access non-allowlisted file paths
* Attempts to execute non-allowlisted commands
* Any rejected operation enforced by wrapper scripts

Purpose:
* Provides audit evidence of enforced access restrictions
* Demonstrates that data access controls are actively preventing unauthorized actions
* Supports incident investigation and compliance audits

Access control:
* Log file is readable only by root
* Entries are append-only and cannot be modified by the devops user

Note:
This log complements standard system logs (e.g. /var/log/auth.log and sudo logs) by providing visibility into blocked actions, not only successful ones.

---

## 13. Log Access and Retention Policy

### 13.1 Purpose
Access to `/usr/local/vesta/log/` is a necessary security control used for:
* Detection of brute-force attacks
* Detection of unauthorized access attempts
* Incident response and forensic analysis

This access is not considered application-level data processing, but a required infrastructure security function.

### 13.2 Data Characteristics
Logs may contain:
* IP addresses
* Email addresses (from authentication events)

These are inherent to security monitoring.

### 13.3 Retention Policy
* Logs are automatically rotated and retained for a limited period (e.g., 7 days)
* Older logs are automatically removed
* Retention period can be adjusted based on client requirements

### 13.4 Access Control
* Access is restricted to allowlisted paths only
* All access is logged and auditable

---

## 14. Backups (Access Limitations)

### 14.1 Standard Rule (no routine access)
* `devops` account cannot browse or read backup repositories
* Backups handled via automated scheduled jobs

### 14.3 Break-glass Backup Restore
Performed under client supervision without sharing credentials

---

## 15. Emergency Procedures (Break-glass)

* Requires client approval and defined scope
* All actions are logged and reviewed post-incident

---

## 16. SSH Session Controls
* SSH idle timeouts supported
* Key rotation supported

---

## 17. Change Management
* Routine updates in maintenance window
* Non-routine requires approval

---

## 18. Periodic Review of Allowlists
Quarterly review with client approval

---

## 19. Commercial and engagement model

All activities described in this document represent controlled, security-oriented maintenance work outside standard unmanaged hosting.

**Standard engagement:**
* Working hours: Monday to Friday, 09:00 to 17:00
* Rate: 50 EUR per working hour

**Extended engagement (upon request and approval):**
* Outside working hours and weekends
* Subject to availability and explicit approval
* Rate: 150 EUR per working hour

---

## 20. Summary for GDPR Alignment
These measures implement:
* Access control and least privilege
* Data minimization
* Accountability through logging
* Segregation of duties

---
