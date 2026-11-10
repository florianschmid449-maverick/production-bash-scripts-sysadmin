# Production-Grade Bash Scripts for System Administrators & DevOps

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Language-Bash%204.4+-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://kernel.org)
[![Quality](https://img.shields.io/badge/Standards-POSIX%20%7C%20ShellCheck-brightgreen.svg)](#coding-standards)

Curated and maintained by **Florian Schmid** ([FlorianSchmid449@gmail.com](mailto:FlorianSchmid449@gmail.com))

---

## Overview

Welcome to the **Production Bash Automation Suite**. This repository contains **100 battle-tested, modular Bash scripts** engineered to simplify system administration, cloud infrastructure maintenance, security compliance, troubleshooting, and daily DevOps workflows.

Each script adheres to professional software engineering standards:
* **Strict error handling:** Configured with `set -euo pipefail` and custom error traps.
* **Predictable CLI arguments:** Complete `-h` / `--help` flags, argument parsing, and input validation.
* **Color-coded output:** Clean ANSI indicators (`[INFO]`, `[SUCCESS]`, `[WARN]`, `[ERROR]`) with automatic detection for non-interactive pipes.
* **Security conscious:** Least-privilege requirements, safe temporary file handling (`trap 'rm -rf "$TMP_DIR"' EXIT`), and non-destructive dry-run modes (`--dry-run`).
* **Cross-distribution compatibility:** Tested across Debian/Ubuntu, RHEL/Rocky/AlmaLinux, Fedora, Arch, and Alpine.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Complete Master Catalog (100 Scripts)](#complete-master-catalog-100-scripts)
  - [01. System Health & Performance Monitoring](#01-system-health--performance-monitoring)
  - [02. Security Hardening & Audit](#02-security-hardening--audit)
  - [03. Network Diagnostics & Troubleshooting](#03-network-diagnostics--troubleshooting)
  - [04. Storage, Backup & Disaster Recovery](#04-storage-backup--disaster-recovery)
  - [05. Log Analysis & Observability](#05-log-analysis--observability)
  - [06. Process & Systemd Service Management](#06-process--systemd-service-management)
  - [07. Docker, Containers & Microservices](#07-docker-containers--microservices)
  - [08. Package & Patch Management](#08-package--patch-management)
  - [09. Cloud, Virtualization & Remote Systems](#09-cloud-virtualization--remote-systems)
  - [10. Admin Productivity & Workflow Automation](#10-admin-productivity--workflow-automation)
- [Coding Standards & Script Header](#coding-standards--script-header)
- [Installation & Quick Start](#installation--quick-start)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [Contributing](#contributing)
- [Author & License](#author--license)

---

## Repository Structure

```
BashScripts2/
├── .gitignore
├── LICENSE
├── README.md
├── PLAN.md
├── 01-system-monitoring/             # Scripts 01-10: CPU, RAM, Disk, Inodes, Sensors
├── 02-security-auditing/             # Scripts 11-20: SSH logins, Sudoers, SUID, Permissions
├── 03-network-diagnostics/           # Scripts 21-30: Ping sweeps, SSL expiry, Latency, Ports
├── 04-backup-storage/                # Scripts 31-40: Rsync, MySQL/Postgres dumps, Archiving
├── 05-log-management/                # Scripts 41-50: Nginx/Apache logs, Journalctl, Size triage
├── 06-process-service-management/    # Scripts 51-60: Auto-healing, Leaks, Systemd health
├── 07-docker-containers/             # Scripts 61-70: Pruning, Healthchecks, Volume backup
├── 08-package-patch-management/      # Scripts 71-80: Security patches, Auto-updates, SBOM
├── 09-cloud-virtualization/          # Scripts 81-90: AWS EC2/S3, Cloudflare DDNS, KVM/PVE
├── 10-admin-productivity/            # Scripts 91-100: Benchmarks, Subnet math, Sanitizers
└── tests/                            # Scripts validation test runner
```

---

## Complete Master Catalog (100 Scripts)

### 01. System Health & Performance Monitoring

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `01` | **cpu_load_monitor.sh** | `01-system-monitoring/cpu_load_monitor.sh` | Reads 1, 5, and 15-minute load averages from `/proc/loadavg`, normalizes against CPU core count, alerts if load exceeds threshold, and logs top 5 CPU consumers. |
| `02` | **ram_usage_alert.sh** | `01-system-monitoring/ram_usage_alert.sh` | Accurately calculates real available physical memory and swap percentage from `/proc/meminfo`, alerting on high memory pressure to prevent OOM kills. |
| `03` | **disk_space_cleaner.sh** | `01-system-monitoring/disk_space_cleaner.sh` | Audits mounted ext4/xfs partitions, identifies safe cleanup candidates (stale `/tmp`, package caches, unlinked open files), and supports safe `--dry-run`. |
| `04` | **inode_usage_checker.sh** | `01-system-monitoring/inode_usage_checker.sh` | Queries `df -i` to detect inode exhaustion across filesystems and traverses directories with astronomical micro-file counts. |
| `05` | **temperature_fan_monitor.sh** | `01-system-monitoring/temperature_fan_monitor.sh` | Interfaces with `/sys/class/thermal` and `lm-sensors` to report CPU temperatures and fan RPM, alerting before hardware thermal throttling occurs. |
| `06` | **swap_monitor.sh** | `01-system-monitoring/swap_monitor.sh` | Parses `/proc/[0-9]*/smaps` to calculate exact VmSwap usage per running process and ranks every active process by swap footprint in MB. |
| `07` | **uptime_sla_reporter.sh** | `01-system-monitoring/uptime_sla_reporter.sh` | Inspects `uptime` and `last reboot` history to compute continuous uptime, reboot frequency, and monthly SLA availability percentages. |
| `08` | **top_process_logger.sh** | `01-system-monitoring/top_process_logger.sh` | Captures high-resolution timestamped CSV snapshots of top CPU and memory-consuming processes at scheduled intervals for trend analysis. |
| `09` | **zombie_process_reaper.sh** | `01-system-monitoring/zombie_process_reaper.sh` | Detects defunct zombie processes (`state Z`), traces parent PIDs (PPID), sends `SIGCHLD` signals to clear tables, and flags stuck parents. |
| `10` | **dmesg_error_watch.sh** | `01-system-monitoring/dmesg_error_watch.sh` | Filters the kernel ring buffer (`dmesg`) for critical hardware warnings, storage I/O timeouts, OOM events, and machine check exceptions (MCE). |

### 02. Security Hardening & Audit

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `11` | **failed_ssh_logins.sh** | `02-security-auditing/failed_ssh_logins.sh` | Parses `/var/log/auth.log` or `/var/log/secure` for failed SSH login attempts, tallies unique attacker IPs, and generates optional firewall drop rules. |
| `12` | **sudo_access_auditor.sh** | `02-security-auditing/sudo_access_auditor.sh` | Audits `/etc/sudoers` and `/etc/sudoers.d/`, flags risky directives (`NOPASSWD: ALL`, shell escapes), and enumerates members of privileged groups. |
| `13` | **user_account_expiry_checker.sh** | `02-security-auditing/user_account_expiry_checker.sh` | Audits `/etc/shadow` and `chage -l` to report accounts with expiring passwords or dormant locked statuses within a configurable warning window. |
| `14` | **find_suid_sgid_binaries.sh** | `02-security-auditing/find_suid_sgid_binaries.sh` | Traverses local filesystems for binaries with SUID (`4000`) or SGID (`2000`) bits set and compares them against a verified system baseline. |
| `15` | **open_ports_auditor.sh** | `02-security-auditing/open_ports_auditor.sh` | Uses `ss` to inspect active TCP/UDP listening sockets, resolves owning process PIDs, and flags unexpected services bound to public interfaces. |
| `16` | **weak_password_finder.sh** | `02-security-auditing/weak_password_finder.sh` | Audits `/etc/shadow` securely to detect accounts with empty passwords, legacy MD5/DES hashes, or disabled password aging policies. |
| `17` | **user_bulk_create.sh** | `02-security-auditing/user_bulk_create.sh` | Provisions multiple Linux user accounts securely from a CSV file, setting home directory permissions (`0700`), groups, and SSH authorized keys. |
| `18` | **inactive_user_lock.sh** | `02-security-auditing/inactive_user_lock.sh` | Queries `lastlog` for user accounts with no recorded login activity for over 90 days, locking dormant accounts to reduce attack surfaces. |
| `19` | **ssh_key_distributor.sh** | `02-security-auditing/ssh_key_distributor.sh` | Distributes administrator SSH public keys across remote server inventories, validating network reachability and enforcing strict permissions (`0700`/`0600`). |
| `20` | **file_permission_hardening.sh** | `02-security-auditing/file_permission_hardening.sh` | Enforces CIS Benchmark permissions on critical OS files (`/etc/passwd`, `/etc/shadow`, `/etc/ssh/sshd_config`, `/etc/crontab`). |
| `20a` | **ssh_hardening_auditor.sh** | `02-security-auditing/ssh_hardening_auditor.sh` | Audits `/etc/ssh/sshd_config` against CIS Benchmark baselines (root login, empty passwords, X11 forwarding, max auth attempts). |
| `20b` | **file_integrity_monitor.sh** | `02-security-auditing/file_integrity_monitor.sh` | Defensive File Integrity Monitoring (FIM) tool building SHA-256 baseline manifests and auditing for modified, added, or deleted files. |
| `20c` | **fail2ban_jail_reporter.sh** | `02-security-auditing/fail2ban_jail_reporter.sh` | Queries Fail2ban intrusion defense daemon across all jails, reporting banned IP volumes and active attacker lists. |

### 03. Network Diagnostics & Troubleshooting

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `21` | **ping_sweep_subnet.sh** | `03-network-diagnostics/ping_sweep_subnet.sh` | Rapidly sweeps an IPv4 subnet range using parallel background subshells, outputting active IP addresses, reverse hostnames, and latency. |
| `22` | **port_connectivity_checker.sh** | `03-network-diagnostics/port_connectivity_checker.sh` | Tests TCP connectivity to a list of `host:port` targets using `/dev/tcp` or `nc` with millisecond timeout controls, returning OPEN/CLOSED/FILTERED states. |
| `23` | **dns_latency_benchmark.sh** | `03-network-diagnostics/dns_latency_benchmark.sh` | Benchmarks DNS query resolution speed across major public resolvers (Cloudflare, Google, Quad9) and local gateways to identify the fastest resolver. |
| `24` | **ssl_cert_expiry_checker.sh** | `03-network-diagnostics/ssl_cert_expiry_checker.sh` | Connects via OpenSSL to HTTPS or TLS endpoints, reads certificate metadata, and warns if certificate expiration is within 30 days. |
| `25` | **public_ip_tracker.sh** | `03-network-diagnostics/public_ip_tracker.sh` | Queries external IP reflection APIs with automated failover, detects WAN IP changes, logs timestamped updates, and triggers alert webhooks. |
| `26` | **bandwidth_speedtest_logger.sh** | `03-network-diagnostics/bandwidth_speedtest_logger.sh` | Automates periodic download/upload speed and latency benchmarks, logging timestamped metrics to CSV for ISP SLA tracking. |
| `27` | **route_trace_diagnostics.sh** | `03-network-diagnostics/route_trace_diagnostics.sh` | Executes multi-iteration traceroute/MTR diagnostic passes to a target destination, pinpointing packet loss percentages and hop-by-hop latency spikes. |
| `28` | **interface_traffic_stats.sh** | `03-network-diagnostics/interface_traffic_stats.sh` | Monitors real-time network interface throughput (KB/s, MB/s) and packet drops from `/proc/net/dev`, alerting on interface saturation. |
| `29` | **arp_spoof_detector.sh** | `03-network-diagnostics/arp_spoof_detector.sh` | Analyzes local ARP cache tables to detect duplicate MAC addresses mapped to multiple IPs or unexpected gateway MAC address changes. |
| `30` | **iptables_firewall_backup_restore.sh** | `03-network-diagnostics/iptables_firewall_backup_restore.sh` | Exports atomic backups of firewall rulesets and offers a safe apply mode that rolls back after 60 seconds if the administrator does not confirm connectivity. |

### 04. Storage, Backup & Disaster Recovery

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `31` | **incremental_rsync_backup.sh** | `04-backup-storage/incremental_rsync_backup.sh` | Performs space-saving incremental filesystem backups using `rsync` hardlinks (`--link-dest`), providing daily snapshots with minimal storage consumption. |
| `32` | **database_mysql_dump.sh** | `04-backup-storage/database_mysql_dump.sh` | Dumps MySQL/MariaDB databases with `--single-transaction`, applies gzip compression, calculates SHA-256 checksums, and enforces retention policies. |
| `33` | **postgres_backup_rotator.sh** | `04-backup-storage/postgres_backup_rotator.sh` | Generates custom-format PostgreSQL backups via `pg_dump`/`pg_dumpall` and rotates archives across daily, weekly, and monthly Grandfather-Father-Son tiers. |
| `34` | **tar_gz_archiver_with_checksum.sh** | `04-backup-storage/tar_gz_archiver_with_checksum.sh` | Archives directory trees into `.tar.gz` with POSIX ACL preservation, creates SHA-256 manifests, and conducts dry-run test extractions to verify data. |
| `35` | **duplicate_file_finder.sh** | `04-backup-storage/duplicate_file_finder.sh` | Identifies duplicate files using a two-stage filter (byte size grouping followed by cryptographic hashing), with options to replace duplicates with hardlinks. |
| `36` | **large_file_finder.sh** | `04-backup-storage/large_file_finder.sh` | Traverses directories to identify files exceeding a defined threshold (e.g. 500MB), outputting a human-readable table sorted by file size. |
| `37` | **zfs_btrfs_snapshot_manager.sh** | `04-backup-storage/zfs_btrfs_snapshot_manager.sh` | Auto-detects ZFS or Btrfs datasets, creates timestamped read-only snapshots, and automatically purges snapshots older than configured retention limits. |
| `38` | **backup_integrity_verifier.sh** | `04-backup-storage/backup_integrity_verifier.sh` | Validates backup repositories by testing archive headers, verifying checksum files, and executing test extractions to prevent corrupted backups. |
| `39` | **stale_backup_cleaner.sh** | `04-backup-storage/stale_backup_cleaner.sh` | Deletes backup files exceeding a retention window while enforcing the safety rule: never deletes the single newest remaining backup copy. |
| `40` | **remote_sftp_sync.sh** | `04-backup-storage/remote_sftp_sync.sh` | Synchronizes local backup directories to an offsite SFTP server with bandwidth rate limits, automatic transfer resumes, and connection retries. |

### 05. Log Analysis & Observability

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `41` | **nginx_traffic_analyzer.sh** | `05-log-management/nginx_traffic_analyzer.sh` | Parses Nginx access logs to report top requesting IPs, top requested URLs, HTTP status code breakdown (2xx/3xx/4xx/5xx), and malicious bot scans. |
| `42` | **apache_404_error_extractor.sh** | `05-log-management/apache_404_error_extractor.sh` | Filters web server access logs for HTTP 404 responses, ranking missing resource paths and identifying referring URLs to detect broken links and scrapers. |
| `43` | **journalctl_critical_exporter.sh** | `05-log-management/journalctl_critical_exporter.sh` | Queries `journalctl` for priority levels 0-3 (`emerg`, `alert`, `crit`, `err`) within a given timeframe, exporting a formatted incident triage digest. |
| `44` | **log_rotation_compressor.sh** | `05-log-management/log_rotation_compressor.sh` | Scans application log directories for uncompressed `.log` files older than N days, compresses them into `.gz`, and purges archives past max age. |
| `45` | **mail_queue_monitor.sh** | `05-log-management/mail_queue_monitor.sh` | Inspects Postfix/Exim mail queues, counts deferred and held messages, and identifies compromised local user accounts generating spam floods. |
| `46` | **real_time_ip_request_counter.sh** | `05-log-management/real_time_ip_request_counter.sh` | Tails active web access logs in real-time, tabulating requests per IP in sliding windows to immediately spot Layer 7 DDoS or aggressive scrapers. |
| `47` | **slow_query_log_parser.sh** | `05-log-management/slow_query_log_parser.sh` | Analyzes MySQL/MariaDB slow query logs, normalizes query literals, and ranks queries by cumulative execution time and lock duration. |
| `48` | **auth_log_geo_tagger.sh** | `05-log-management/auth_log_geo_tagger.sh` | Extracts external IP addresses from authentication logs and resolves their country of origin and ISP to produce a geographic threat distribution report. |
| `49` | **syslog_size_auditor.sh** | `05-log-management/syslog_size_auditor.sh` | Samples `/var/log` file growth rates over time, alerting when any log expands rapidly (>50MB/min) and printing recent lines from the culprit file. |
| `50` | **daily_system_summary_email.sh** | `05-log-management/daily_system_summary_email.sh` | Compiles an executive morning briefing covering disk space, memory, reboot status, failed systemd units, and auth failures, dispatching via email. |

### 06. Process & Systemd Service Management

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `51` | **service_auto_healer.sh** | `06-process-service-management/service_auto_healer.sh` | Monitors vital systemd services (nginx, mysql, docker); if failed or inactive, restarts the service, verifies health, and sends an alert. |
| `52` | **hung_process_killer.sh** | `06-process-service-management/hung_process_killer.sh` | Identifies processes exceeding maximum runtime or CPU limits, attempts graceful shutdown via `SIGTERM`, and escalates to `SIGKILL` if unresponsive. |
| `53` | **process_memory_leak_detector.sh** | `06-process-service-management/process_memory_leak_detector.sh` | Samples Resident Set Size (RSS) memory consumption of a daemon over time, using trend slope calculation to detect creeping memory leaks. |
| `54` | **systemd_failed_services_alert.sh** | `06-process-service-management/systemd_failed_services_alert.sh` | Inspects `systemctl --failed` for degraded units, extracts error exit codes and recent log lines from journalctl, and outputs alert notifications. |
| `55` | **cron_job_auditor.sh** | `06-process-service-management/cron_job_auditor.sh` | Enumerates cron schedules across `/etc/cron*` and `/var/spool/cron`, flagging commands executing from suspicious directories (`/tmp`, `/dev/shm`). |
| `56` | **parallel_task_runner.sh** | `06-process-service-management/parallel_task_runner.sh` | Pure-Bash parallel task manager with concurrency control (e.g. max 8 workers) that processes task lists with exit monitoring and logging. |
| `57` | **pid_resource_tracker.sh** | `06-process-service-management/pid_resource_tracker.sh` | Tracks CPU, RSS memory, thread count, open file descriptors, and I/O rates for a specific PID over time, writing metrics to CSV. |
| `58` | **gracefully_reload_daemons.sh** | `06-process-service-management/gracefully_reload_daemons.sh` | Runs configuration syntax validation (`nginx -t`, `apache2ctl configtest`, etc.) before issuing a zero-downtime service reload to prevent outages. |
| `59` | **service_boot_performance.sh** | `06-process-service-management/service_boot_performance.sh` | Leverages `systemd-analyze` and `systemd-analyze blame` to profile boot initialization time and highlight slow-starting system services. |
| `60` | **health_check_http_endpoint.sh** | `06-process-service-management/health_check_http_endpoint.sh` | Performs synthetic HTTP health checks, validating expected status codes and response payload strings with millisecond latency logging. |

### 07. Docker, Containers & Microservices

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `61` | **docker_prune_unused.sh** | `07-docker-containers/docker_prune_unused.sh` | Cleans up dangling images, stopped containers older than 48 hours, unused networks, and build caches, reporting total disk space reclaimed. |
| `62` | **container_resource_usage.sh** | `07-docker-containers/container_resource_usage.sh` | Streams live Docker container CPU, RAM, and network I/O statistics, alerting when any container exceeds assigned quota thresholds. |
| `63` | **docker_container_healthcheck.sh** | `07-docker-containers/docker_container_healthcheck.sh` | Queries Docker API for containers in an `unhealthy` state or trapped in restart loops, extracting error logs and dispatching alerts. |
| `64` | **registry_image_tag_cleaner.sh** | `07-docker-containers/registry_image_tag_cleaner.sh` | Sorts local Docker image tags by creation timestamp, pruning old build revisions while preserving the latest N images and `:latest`. |
| `65` | **backup_docker_volumes.sh** | `07-docker-containers/backup_docker_volumes.sh` | Mounts Docker named volumes into an ephemeral helper container, creates timestamped `.tar.gz` backups, and verifies archive readability. |
| `66` | **compose_stack_restarter.sh** | `07-docker-containers/compose_stack_restarter.sh` | Checks Docker Compose project directories for updated registry images (`docker compose pull`) and performs rolling updates on changed services. |
| `67` | **inspect_container_env_safe.sh** | `07-docker-containers/inspect_container_env_safe.sh` | Dumps container configurations while automatically redacting sensitive environment variables matching password, secret, or token patterns. |
| `68` | **export_all_containers.sh** | `07-docker-containers/export_all_containers.sh` | Backs up container definitions, network attachments, and volume mount configurations to structured JSON for disaster recovery documentation. |
| `69` | **docker_log_truncator.sh** | `07-docker-containers/docker_log_truncator.sh` | Traverses `/var/lib/docker/containers/*/*-json.log` and truncates log files exceeding a size threshold in-place without restarting containers. |
| `70` | **kubernetes_pod_restart_detector.sh** | `07-docker-containers/kubernetes_pod_restart_detector.sh` | Queries `kubectl` across all namespaces to identify pods with high restart counts or `CrashLoopBackOff` status, printing last termination reasons. |

### 08. Package & Patch Management

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `71` | **check_security_patches.sh** | `08-package-patch-management/check_security_patches.sh` | Queries `apt`, `dnf`, `zypper`, or `apk` specifically for pending security advisories and CVE patches without applying updates. |
| `72` | **automated_apt_dnf_updater.sh** | `08-package-patch-management/automated_apt_dnf_updater.sh` | Refreshes repository metadata, applies non-interactive security updates, logs changes to `/var/log/system_updates.log`, and alerts on reboot flags. |
| `73` | **orphaned_packages_purger.sh** | `08-package-patch-management/orphaned_packages_purger.sh` | Identifies and removes unneeded dependency packages, purges residual configuration files, and cleans package download caches. |
| `74` | **kernel_version_checker_reboot.sh** | `08-package-patch-management/kernel_version_checker_reboot.sh` | Compares running kernel version (`uname -r`) with the newest installed kernel package, checking `/var/run/reboot-required` flags. |
| `75` | **repo_mirror_speed_tester.sh** | `08-package-patch-management/repo_mirror_speed_tester.sh` | Benchmarks connection latency and transfer speeds across official distribution mirrors to identify the fastest mirror for updates. |
| `76` | **installed_packages_inventory.sh** | `08-package-patch-management/installed_packages_inventory.sh` | Generates a Software Bill of Materials (SBOM) covering OS packages, Python pip libraries, and Node.js npm packages in CSV or JSON. |
| `77` | **rollback_pkg_history.sh** | `08-package-patch-management/rollback_pkg_history.sh` | Parses package manager transaction histories (`dnf history` or `/var/log/dpkg.log`) to facilitate rapid rollbacks of faulty package updates. |
| `78` | **pypi_npm_audit.sh** | `08-package-patch-management/pypi_npm_audit.sh` | Scans Python and Node.js project directories for known vulnerabilities and outdated dependencies using `npm audit` and `pip-audit`. |
| `79` | **flatpak_snap_updater.sh** | `08-package-patch-management/flatpak_snap_updater.sh` | Detects Snap and Flatpak application runtimes, checks for available updates, applies them non-interactively, and prunes old revisions. |
| `80` | **check_distro_eol.sh** | `08-package-patch-management/check_distro_eol.sh` | Reads `/etc/os-release` and compares the active distribution release against official lifecycle End-Of-Life (EOL) dates. |

### 09. Cloud, Virtualization & Remote Systems

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `81` | **aws_ec2_instance_auditor.sh** | `09-cloud-virtualization/aws_ec2_instance_auditor.sh` | Uses AWS CLI to enumerate EC2 instances across regions, summarizing states, IP addresses, and flagging stopped instances incurring EBS costs. |
| `82` | **s3_bucket_leak_scanner.sh** | `09-cloud-virtualization/s3_bucket_leak_scanner.sh` | Audits AWS S3 buckets for public read/write permissions, missing bucket policies, and lack of default server-side encryption. |
| `83` | **cloudflare_dns_updater.sh** | `09-cloud-virtualization/cloudflare_dns_updater.sh` | Dynamic DNS (DDNS) client that checks current public WAN IP and updates Cloudflare DNS A/AAAA records via API v4 upon changes. |
| `84` | **libvirt_kvm_snapshotter.sh** | `09-cloud-virtualization/libvirt_kvm_snapshotter.sh` | Manages external KVM/QEMU disk snapshots via `virsh`, creating pre-maintenance recovery points and pruning expired snapshots. |
| `85` | **vagrant_bulk_cleaner.sh** | `09-cloud-virtualization/vagrant_bulk_cleaner.sh` | Queries `vagrant global-status --prune` across the host to identify abandoned development environments and cleanly destroys stale VMs. |
| `86` | **terraform_state_backup.sh** | `09-cloud-virtualization/terraform_state_backup.sh` | Safely downloads and timestamps remote or local `terraform.tfstate` files with MD5 verification before deployments. |
| `87` | **cloud_cost_budget_check.sh** | `09-cloud-virtualization/cloud_cost_budget_check.sh` | Queries AWS/GCP Cost APIs for Month-To-Date expenditures and forecasted burn rates, alerting if projected spend exceeds budget. |
| `88` | **ssh_tunnel_bastion_keeper.sh** | `09-cloud-virtualization/ssh_tunnel_bastion_keeper.sh` | Maintains persistent SSH port forwarding tunnels through bastion jump hosts, automatically reconnecting upon network disconnects. |
| `89` | **vmid_proxmox_lxc_backup.sh** | `09-cloud-virtualization/vmid_proxmox_lxc_backup.sh` | Triggers Proxmox VE `vzdump` backups for LXC containers or VMs, verifying target storage free space before snapshotting. |
| `90` | **ssl_auto_certbot_renewer.sh** | `09-cloud-virtualization/ssl_auto_certbot_renewer.sh` | Automates Let's Encrypt Certbot renewals with pre-flight dry runs, certificate validity validation, and automated web server reloads. |

### 10. Admin Productivity & Workflow Automation

| # | Script Name | Relative Path | Purpose & Functional Description |
|:---|:---|:---|:---|
| `91` | **benchmark_cpu_io_speed.sh** | `10-admin-productivity/benchmark_cpu_io_speed.sh` | Standardized server hardware benchmark measuring single-core CPU prime speed, RAM throughput, and disk direct sequential/random I/O. |
| `92` | **clipboard_history_cleaner.sh** | `10-admin-productivity/clipboard_history_cleaner.sh` | Monitors X11/Wayland clipboard buffers, automatically wiping passwords and sensitive credentials after a configurable timeout. |
| `93` | **dotfiles_sync_git.sh** | `10-admin-productivity/dotfiles_sync_git.sh` | Synchronizes administrative configuration dotfiles (`.bashrc`, `.vimrc`, `.tmux.conf`) with a remote Git repository, auto-committing updates. |
| `94` | **bulk_filename_normalizer.sh** | `10-admin-productivity/bulk_filename_normalizer.sh` | Traverses directories to sanitize filenames: converts to lowercase, replaces spaces with underscores, and strips illegal characters. |
| `95` | **secret_env_file_sanitizer.sh** | `10-admin-productivity/secret_env_file_sanitizer.sh` | Scans directories for exposed credentials, unignored `.env` files, and private keys, generating sanitized `.env.example` templates. |
| `96` | **terminal_session_recorder.sh** | `10-admin-productivity/terminal_session_recorder.sh` | Wraps administrative terminal sessions with `script`, capturing timestamped, tamper-evident audit recordings with timing metadata. |
| `97` | **quick_http_file_server.sh** | `10-admin-productivity/quick_http_file_server.sh` | Instantly spawns a lightweight temporary HTTP file server in the current directory with port binding and access logging. |
| `98` | **ip_calc_subnet_helper.sh** | `10-admin-productivity/ip_calc_subnet_helper.sh` | Pure-Bash IPv4 CIDR calculator computing network address, broadcast, netmask, wildcard, and usable host ranges using bitwise arithmetic. |
| `99` | **markdown_doc_indexer.sh** | `10-admin-productivity/markdown_doc_indexer.sh` | Recursively parses Markdown files, extracts heading anchors, and automatically generates an updated, hyperlinked Table of Contents. |
| `100` | **admin_emergency_panic_lock.sh** | `10-admin-productivity/admin_emergency_panic_lock.sh` | High-priority incident containment tool that terminates non-root SSH sessions, creates `/etc/nologin`, and restricts external network access. |

---

## Coding Standards & Script Header

Every script in this repository includes the standard enterprise author header:

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script Name : <script_name>.sh
# Description : <concise description of functionality>
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'
```

### Key Engineering Principles
1. **Strict Shell Mode:** `set -euo pipefail` ensures that failures in pipes are detected immediately and unset variables cause a fatal exit.
2. **Safe Signal Trapping:** Scripts generating temporary directories use `trap 'rm -rf "$TMP_DIR"' EXIT INT TERM` to ensure zero residue.
3. **Explicit Dependency Checks:** Every script checks its required binary utilities using `command -v <tool>` before proceeding.
4. **Non-Destructive Defaults:** Destructive operations default to dry-run mode or require confirmation unless `--force` is supplied.

---

## Installation & Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/FlorianSchmid/BashScripts.git
cd BashScripts
```

### 2. Grant Execution Permissions
```bash
chmod +x **/*.sh
```

### 3. Run Any Script with `--help`
```bash
# Example: Check CPU load
./01-system-monitoring/cpu_load_monitor.sh --help

# Example: Audit open ports
./02-security-auditing/open_ports_auditor.sh --help

# Example: Run subnet ping sweep
./03-network-diagnostics/ping_sweep_subnet.sh -s 192.168.1
```

---

## Testing & Quality Assurance

This repository includes an automated validation test runner located in `tests/validate_scripts.sh`.

To run the full syntax and compliance suite across all 100 scripts:

```bash
./tests/validate_scripts.sh
```

The test runner validates:
1. Shell syntax validity (`bash -n`)
2. Presence of author attribution (`Florian Schmid`)
3. Shebang correctness (`#!/usr/bin/env bash`)
4. Shell execution safety (`set -euo pipefail`)
5. Proper execution permissions (`chmod +x`)

---

## Contributing

Contributions, bug reports, and enhancements are welcome! Please follow these steps:

1. Fork the project repository.
2. Create your feature branch (`git checkout -b feature/NewAdminScript`).
3. Ensure your script passes `bash -n` and follows the standard header template.
4. Commit your changes (`git commit -m 'Add new admin script'`).
5. Push to the branch (`git push origin feature/NewAdminScript`).
6. Open a Pull Request.

---

## Author & License

**Author:** Florian Schmid  
**Email:** [FlorianSchmid449@gmail.com](mailto:FlorianSchmid449@gmail.com)  
**License:** Distributed under the MIT License. See [LICENSE](LICENSE) for full details.
