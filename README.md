# Apache Cassandra Lab Environment

Production-grade multi-datacenter Apache Cassandra cluster deployment on Hetzner Cloud with AxonOps monitoring. This project combines Terraform for infrastructure provisioning and Ansible for automated configuration management.

## Overview

This lab environment provides:

- **Multi-datacenter Cassandra cluster** with configurable node count (currently 12 nodes, scalable to 15+)
- **Infrastructure as Code** using Terraform for Hetzner Cloud
- **Configuration Management** using Ansible with AxonOps collection
- **Production features**: SSL/TLS encryption, authentication, audit logging, monitoring
- **Web-based terminal access** via Wetty for easy cluster management
- **Comprehensive monitoring** with AxonOps SaaS platform

## Architecture

### Current Default Topology (12 Nodes)

```
┌─────────────────────────────────────────────────────────────┐
│              Hetzner Cloud Infrastructure                    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Private Network (10.18.0.0/16)                      │   │
│  │                                                        │   │
│  │  Datacenter dc1          Datacenter dc2              │   │
│  │  ┌──────────┐             ┌──────────┐               │   │
│  │  │ rack1 (2)│             │ rack1 (2)│               │   │
│  │  │ rack2 (2)│             │ rack2 (2)│               │   │
│  │  │ rack3 (2)│             │ rack3 (2)│               │   │
│  │  └──────────┘             └──────────┘               │   │
│  │  6 nodes                  6 nodes                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────┐                                            │
│  │   Bastion    │ (SSH + WireGuard VPN + Web Terminal)     │
│  └──────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

**Key Features:**
- **2 datacenters** (dc1, dc2) for multi-DC replication
- **3 racks per datacenter** for rack-aware topology
- **Placement groups** ensure physical host diversity
- **GossipingPropertyFileSnitch** for datacenter/rack awareness
- **4 seed nodes** (2 per DC) for reliable cluster formation
- **Private networking** (10.18.0.0/16) for inter-node communication
- **Bastion host** with WireGuard VPN and web terminal access

## Prerequisites

### Required Accounts & Credentials

1. **Hetzner Cloud**
   - Account: [console.hetzner.cloud](https://console.hetzner.cloud/)
   - API Token with read/write permissions

2. **AxonOps SaaS**
   - Account: [console.axonops.cloud](https://console.axonops.cloud/)
   - Organization name
   - Agent key (from organization settings)
   - API token (for alerts configuration)

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://www.terraform.io/) | >= 1.0 | Infrastructure provisioning |
| [Ansible](https://www.ansible.com/) | >= 2.9 | Configuration management |
| [Pipenv](https://pipenv.pypa.io/) | Latest | Python dependency management |
| SSH | Any | Server access |

### Install Dependencies

```bash
# macOS
brew install terraform ansible pipenv

# Ubuntu/Debian
sudo apt-get install terraform ansible pipenv

# Fedora/RHEL
sudo dnf install terraform ansible pipenv
```

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd ansible-cassandra-lab
```

### 2. Configure Environment Variables

```bash
# Hetzner Cloud API token
export HCLOUD_TOKEN="your-hetzner-cloud-api-token"

# AxonOps credentials (for alerts configuration)
export AXONOPS_ORG="your-organization-name"
export AXONOPS_TOKEN="your-api-token"

# Ansible vault password (create this file)
echo "your-secure-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass
```

### 3. Provision Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create infrastructure (12 nodes + bastion)
terraform apply

# Note: This automatically creates ansible/inventories/lab/hosts.ini
```

### 4. Configure Secrets with Ansible Vault

```bash
cd ../ansible

# Edit the vault file with your AxonOps credentials
ansible-vault edit group_vars/lab/vault.yml
```

Add the following content:
```yaml
---
vault_axon_agent_customer_name: "your-org-name"
vault_axon_agent_key: "your-agent-key"
```

### 5. Deploy Cassandra Cluster

```bash
# Install Ansible dependencies
make prep

# Apply base system configuration (OS hardening, NTP, etc.)
make common ENVIRONMENT=lab

# Deploy Cassandra and AxonOps agent
make cassandra ENVIRONMENT=lab

# Configure AxonOps monitoring and alerts
make alerts ENVIRONMENT=lab
```

### 6. Access Your Cluster

```bash
# Get bastion IP
cd ../terraform
terraform output | grep bastion

# SSH to bastion
ssh -i ssh_key root@<bastion-ip>

# Access web terminal
https://<bastion-ip>
# Username: wetty
# Password: AxonOpsLab2025!

# From bastion, connect to any Cassandra node
ssh root@<node-private-ip>

# Check cluster status
nodetool status
```

## Project Structure

```
ansible-cassandra-lab/
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Main infrastructure (12 nodes + bastion)
│   ├── variables.tf               # Configurable parameters
│   ├── outputs.tf                 # Inventory generation
│   ├── providers.tf               # Hetzner Cloud provider
│   ├── bucket.tf                  # Object storage (optional)
│   └── terraform.tfvars.example   # Configuration template
│
└── ansible/                       # Configuration Management
    ├── Makefile                   # Main entry point for commands
    ├── requirements.yml           # Ansible Galaxy dependencies
    │
    ├── inventories/
    │   └── lab/
    │       └── hosts.ini         # Auto-generated by Terraform
    │
    ├── group_vars/
    │   ├── all/                  # Global defaults
    │   │   ├── cassandra.yml    # Cassandra 5.0.5 settings
    │   │   └── axonops.yml      # AxonOps agent 2.0.9 config
    │   └── lab/                 # Environment-specific overrides
    │       ├── cassandra.yml    # Performance tuning
    │       ├── axonops.yml      # Organization settings
    │       ├── ssl.yml          # SSL/TLS configuration
    │       ├── vault.yml        # Encrypted credentials
    │       └── ssl_vault.yml    # Encrypted SSL passwords
    │
    ├── alerts-config/            # AxonOps monitoring (YAML-driven)
    │   └── <org-name>/
    │       ├── alert_endpoints.yml     # Integrations (Slack, etc.)
    │       ├── metric_alert_rules.yml  # Org-wide metric alerts
    │       ├── log_alert_rules.yml     # Org-wide log alerts
    │       └── <cluster-name>/
    │           ├── alert_routes.yml         # Route alerts to endpoints
    │           ├── backups.yml              # Backup schedules
    │           ├── service_checks.yml       # Custom health checks
    │           ├── commitlog_archive.yml    # Commitlog archiving
    │           ├── metric_alert_rules.yml   # Cluster-specific alerts
    │           └── log_alert_rules.yml      # Cluster-specific logs
    │
    ├── templates/
    │   └── alerts/               # Service check scripts
    │       ├── check-node-down.sh.j2
    │       ├── check-keyspaces-strategy.sh.j2
    │       └── check-schema-disagreements.sh.j2
    │
    └── playbooks:
        ├── common.yml            # OS hardening, NTP, base packages
        ├── cassandra.yml         # Java, Cassandra, AxonOps agent
        ├── alerts.yml            # AxonOps monitoring configuration
        ├── rolling-restart.yml   # Safe cluster restart
        └── wipe.yml              # Remove Cassandra data
```

## Terraform Configuration

### Infrastructure Components

The Terraform configuration creates:

| Resource | Count | Purpose |
|----------|-------|---------|
| Cassandra Nodes | 12 (configurable) | Multi-DC cluster |
| Bastion Host | 1 | Secure access point |
| Private Network | 1 | Inter-node communication (10.18.0.0/16) |
| Placement Groups | 6 | Physical host diversity (1 per DC per rack) |
| Firewalls | 2 | Security rules (bastion + cassandra) |
| SSH Key | 1 | Auto-generated or existing |

### Customizing Infrastructure

Edit `terraform/terraform.tfvars`:

```hcl
# Environment and location
environment = "lab"               # Used in resource naming
location    = "sin"               # Singapore (nbg1, fsn1, hel1, ash, hil)

# Instance types
server_type        = "cpx31"      # 4 vCPU, 8GB RAM per Cassandra node
bastion_server_type = "cpx11"     # 2 vCPU, 2GB RAM for bastion

# Security
allowed_cidrs = ["YOUR_IP/32"]    # Restrict access to your IP

# SSH keys
ssh_keys = []                     # Empty = auto-generate, or ["key-name"]

# Object Storage (optional - for backups)
object_storage_region = "fsn1"
# object_storage_access_key = "set via env var"
# object_storage_secret_key = "set via env var"
```

### Terraform Commands

```bash
cd terraform

# Initialize and download providers
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Show all outputs (IPs, inventory, etc.)
terraform output

# Destroy infrastructure
terraform destroy
```

### Network Configuration

**Firewall Rules:**

**Bastion:**
- Port 22 (SSH) ← from `allowed_cidrs`
- Port 443 (HTTPS/Wetty) ← from `allowed_cidrs`
- Port 51920 (WireGuard) ← from `0.0.0.0/0`

**Cassandra Nodes:**
- Port 22 (SSH) ← from bastion + `allowed_cidrs`
- Port 443 (HTTPS) ← from `allowed_cidrs`
- Port 9042 (CQL) ← from `allowed_cidrs` + private network
- Ports 22-9042 ← from private network (10.18.0.0/16)
- Ports 7000, 7001, 9042 ← from other Cassandra node IPs

## Ansible Configuration

### Available Make Commands

Run from the `ansible/` directory:

| Command | Playbook | Description |
|---------|----------|-------------|
| `make prep` | - | Install Ansible Galaxy collections |
| `make common` | common.yml | OS hardening, base packages, NTP, web terminal |
| `make cassandra` | cassandra.yml | Install Java, Cassandra 5.0.5, AxonOps agent |
| `make alerts` | alerts.yml | Configure monitoring, alerts, backups |
| `make rolling-restart` | rolling-restart.yml | Safe sequential cluster restart |
| `make wipe` | wipe.yml | Stop services and wipe data directories |

**Environment variable:**
```bash
make cassandra ENVIRONMENT=lab    # Default
make cassandra ENVIRONMENT=prod   # For production
```

### What Gets Installed

**common.yml:**
- OS security hardening (devsec.hardening.os_hardening)
- System packages: curl, jq, unzip, nginx, chrony
- Chrony NTP for time synchronization
- Wetty web terminal with HTTPS
- CQLAI on bastion host only
- Hosts file configuration for all nodes

**cassandra.yml:**
- Java (from axonops.axonops.java role)
- Apache Cassandra 5.0.5 (tarball installation)
- AxonOps agent 2.0.9
- AxonOps Java agent 1.0.10 for Cassandra 5.0
- SSL/TLS keystores (if enabled)
- Cassandra configuration:
  - PasswordAuthenticator + CassandraAuthorizer
  - Audit logging (DDL, DCL, AUTH, ERROR - excludes SELECT/INSERT/UPDATE/DELETE)
  - GossipingPropertyFileSnitch
  - Multi-DC seed configuration
  - Data directory: /data/cassandra
- cqlshrc configuration with SSL support
- Service check scripts deployment
- Wetty web terminal with nginx reverse proxy

**alerts.yml:**
- AxonOps alert endpoints (Slack, PagerDuty, email)
- Metric alert rules (CPU, disk, Cassandra metrics)
- Log alert rules
- Alert routing configuration
- Backup schedules
- Service checks (node down, schema disagreements, keyspace strategy)
- Commitlog archiving

### Cassandra Configuration

**Global settings** (group_vars/all/cassandra.yml):

```yaml
cassandra_version: 5.0.5
cassandra_install_format: tar
cassandra_install_dir: /opt/cassandra
cassandra_endpoint_snitch: GossipingPropertyFileSnitch

# Data directories
cassandra_data_root: /data/cassandra
cassandra_data_directory: /data/cassandra/data
cassandra_commitlog_directory: /data/cassandra/commitlog
cassandra_log_dir: /var/log/cassandra

# Security
cassandra_authenticator: PasswordAuthenticator
cassandra_authorizer: CassandraAuthorizer
cassandra_auth_write_consistency_level: EACH_QUORUM

# Audit logging
cassandra_audit_log_enabled: true
# Logs: DDL, DCL, AUTH, ERROR (excludes SELECT, INSERT, UPDATE, DELETE)

# Performance
cassandra_concurrent_reads: 32
cassandra_concurrent_writes: 32
cassandra_concurrent_counter_writes: 32

# JMX authentication
cassandra_jmx_user: "jmxuser"
cassandra_jmx_password: "jmxpassword"

# Network
cassandra_listen_address: "{{ ansible_enp7s0.ipv4.address }}"
cassandra_broadcast_rpc_address: "{{ ansible_eth0.ipv4.address }}"
cassandra_rpc_address: 0.0.0.0
```

**Environment overrides** (group_vars/lab/cassandra.yml):

```yaml
# Auto-sizing heap (50% of RAM, max 40GB)
cassandra_max_heap_size: "{% if (ansible_memtotal_mb * 0.5 / 1024) | round | int > 40 %}40{% else %}{{ (ansible_memtotal_mb * 0.5 / 1024) | round | int }}{% endif %}G"

cassandra_concurrent_compactors: "4"
cassandra_compaction_throughput: "64MiB/s"
cassandra_counter_cache_save_period: "7200s"
cassandra_counter_write_request_timeout: "5000s"
```

**Inventory variables** (from Terraform):
```ini
[lab]
5.223.73.105 cassandra_rack=rack1 cassandra_dc=dc1 ansible_hostname=cassandra-node-1
...

[all:vars]
cassandra_seeds=10.18.1.x,10.18.1.y,10.18.1.z,10.18.1.w  # 4 seeds (2 per DC)
```

### AxonOps Configuration

**Global settings** (group_vars/all/axonops.yml):

```yaml
axon_agent_version: "2.0.9"
axon_java_agent_version: "1.0.10"
axon_java_agent: "axon-cassandra5.0-agent-jdk17"

axon_agent_hosts: "agents.axonops.cloud"
axon_agent_port: 443

axon_agent_disable_command_exec: true  # Disable remote command execution

cqlai_host: "localhost"
cqlai_port: 9042
```

**Environment secrets** (group_vars/lab/vault.yml):

```yaml
---
vault_axon_agent_customer_name: "your-org-name"
vault_axon_agent_key: "your-agent-key-from-console"
```

**Environment config** (group_vars/lab/axonops.yml):

```yaml
axon_agent_customer_name: "{{ vault_axon_agent_customer_name }}"
axon_agent_key: "{{ vault_axon_agent_key }}"
axon_agent_ntp_server: "time.cloudflare.com"
```

### Managing Secrets with Ansible Vault

All sensitive data is encrypted using Ansible Vault:

```bash
# Create vault password file
echo "my-secure-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass

# Edit vault file
ansible-vault edit group_vars/lab/vault.yml

# View vault contents
ansible-vault view group_vars/lab/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/lab/vault.yml

# Decrypt file
ansible-vault decrypt group_vars/lab/vault.yml

# Change vault password
ansible-vault rekey group_vars/lab/vault.yml
```

### AxonOps Monitoring Configuration

Monitoring is configured via YAML files in `alerts-config/<org-name>/`:

**Organization Level:**
- `alert_endpoints.yml` - Slack, PagerDuty, email integrations
- `metric_alert_rules.yml` - Default metric alerts for all clusters
- `log_alert_rules.yml` - Default log alerts for all clusters

**Cluster Level** (`alerts-config/<org-name>/<cluster-name>/`):
- `alert_routes.yml` - Route specific alerts to endpoints
- `backups.yml` - Backup schedules and retention
- `service_checks.yml` - Custom health check scripts
- `commitlog_archive.yml` - Commitlog archiving configuration
- `dashboards.yml` - Custom dashboard definitions
- `metric_alert_rules.yml` - Cluster-specific metric overrides
- `log_alert_rules.yml` - Cluster-specific log overrides

**Example structure:**
```
alerts-config/
└── training/                          # Your organization name
    ├── alert_endpoints.yml
    ├── metric_alert_rules.yml
    ├── log_alert_rules.yml
    └── lab/                           # Cluster name
        ├── alert_routes.yml
        ├── backups.yml
        ├── service_checks.yml
        ├── commitlog_archive.yml
        ├── dashboards.yml
        ├── metric_alert_rules.yml
        └── log_alert_rules.yml
```

Apply monitoring configuration:
```bash
cd ansible
make alerts ENVIRONMENT=lab
```

## Complete Deployment Workflow

### Phase 1: Infrastructure Setup

```bash
# 1. Export Hetzner Cloud token
export HCLOUD_TOKEN="your-hetzner-token"

# 2. Navigate to Terraform directory
cd terraform

# 3. Create configuration file
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit with your preferences

# 4. Initialize Terraform
terraform init

# 5. Deploy infrastructure
terraform apply

# 6. Verify inventory creation
cat ../ansible/inventories/lab/hosts.ini

# 7. Note the bastion IP for later
terraform output | grep bastion
```

### Phase 2: Prepare Ansible Configuration

```bash
cd ../ansible

# 1. Set up vault password
echo "your-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass

# 2. Install Ansible dependencies
make prep

# 3. Configure AxonOps credentials
ansible-vault edit group_vars/lab/vault.yml
# Add:
#   vault_axon_agent_customer_name: "your-org"
#   vault_axon_agent_key: "your-key"

# 4. (Optional) Customize Cassandra settings
vim group_vars/lab/cassandra.yml

# 5. Set environment for all commands
export ENVIRONMENT=lab
```

### Phase 3: Base System Configuration

```bash
# Deploy OS hardening, NTP, base packages, web terminal
make common ENVIRONMENT=lab

# This installs:
# - OS security hardening
# - chrony (NTP)
# - nginx, curl, jq, unzip
# - Wetty web terminal at https://<bastion-ip>
# - CQLAI on bastion
# - Hosts file configuration
```

### Phase 4: Cassandra Deployment

```bash
# Deploy Cassandra cluster and AxonOps agent
make cassandra ENVIRONMENT=lab

# This installs:
# - Java
# - Apache Cassandra 5.0.5
# - AxonOps agent 2.0.9
# - Configures SSL, authentication, audit logging
# - Sets up cqlshrc and service checks
```

### Phase 5: Monitoring Setup

```bash
# 1. Set AxonOps API credentials
export AXONOPS_ORG="your-org-name"
export AXONOPS_TOKEN="your-api-token"

# 2. Create monitoring configuration (if not using existing)
mkdir -p alerts-config/your-org-name/lab
# Copy examples from alerts-config/training/

# 3. Apply monitoring
make alerts ENVIRONMENT=lab
```

### Phase 6: Verification

```bash
# 1. Access bastion
ssh -i ../terraform/ssh_key root@<bastion-ip>

# 2. Check cluster status from bastion
ssh root@10.18.1.x  # Any Cassandra node private IP
nodetool status

# Expected output:
# Datacenter: dc1
# Status=Up/Down
# |/ State=Normal/Leaving/Joining/Moving
# --  Address      Load       Tokens  Owns    Host ID   Rack
# UN  10.18.1.x    ...        256     ...     ...       rack1
# UN  10.18.1.y    ...        256     ...     ...       rack1
# (6 nodes in dc1, 6 in dc2)

# 3. Test CQL access
cqlsh --ssl
# Connected to lab at 10.18.1.x:9042

# 4. Check AxonOps agent
systemctl status axon-agent

# 5. View in AxonOps Console
# Visit: https://console.axonops.cloud/
```

## Advanced Operations

### Configuration Updates

Update Cassandra configuration without reinstalling:

```bash
# 1. Edit configuration
vim group_vars/lab/cassandra.yml

# 2. Apply only config changes (no restart)
cd ansible
make cassandra ENVIRONMENT=lab EXTRA="--tags config"

# 3. Perform rolling restart
make rolling-restart ENVIRONMENT=lab
```

### Rolling Restart

Safe, sequential restart with health checks:

```bash
cd ansible
make rolling-restart ENVIRONMENT=lab
```

The playbook:
1. Restarts nodes one at a time (`serial: 1`)
2. Restarts both Cassandra and axon-agent services
3. Waits for Cassandra to bind to port 9042
4. Proceeds to next node only after current is healthy

### Scaling the Cluster

To add more nodes (e.g., from 12 to 15):

```bash
# 1. Update Terraform node count
cd terraform
vim main.tf
# Change: resource "hcloud_server" "cassandra" { count = 15 }

# 2. Update placement group assignments and labels
# Adjust the placement_group_id and labels logic for new nodes
# You may need additional placement groups for dc3 or more racks

# 3. Apply infrastructure changes
terraform apply

# 4. Verify new nodes in inventory
cat ../ansible/inventories/lab/hosts.ini

# 5. Deploy Cassandra to all nodes (including new ones)
cd ../ansible
make cassandra ENVIRONMENT=lab

# 6. Verify cluster
# SSH to any node and run: nodetool status
```

### SSL/TLS Configuration

**Option 1: Auto-generated certificates** (lab environments):

```bash
# In group_vars/lab/cassandra.yml
cassandra_ssl_create: true

# Deploy
make cassandra ENVIRONMENT=lab EXTRA="--tags ssl,keystore"
make rolling-restart ENVIRONMENT=lab
```

**Option 2: Custom certificates** (production):

```bash
# 1. Place certificates in files/ssl/lab/
mkdir -p files/ssl/lab
# Copy: keystore.jks, truststore.jks, etc.

# 2. Configure in group_vars/lab/ssl.yml
vim group_vars/lab/ssl.yml

# 3. Store passwords in vault
ansible-vault edit group_vars/lab/ssl_vault.yml
# Add: vault_ssl_keystore_password, vault_ssl_truststore_password

# 4. Deploy SSL configuration
make cassandra ENVIRONMENT=lab EXTRA="--tags ssl,config"
make rolling-restart ENVIRONMENT=lab
```

### Backup Configuration

Edit `alerts-config/<org>/<cluster>/backups.yml`:

```yaml
axonops_backups:
  - name: "hourly-incremental"
    schedule: "0 * * * *"           # Every hour
    type: "incremental"
    destination: "s3"
    s3_bucket: "cassandra-backups"
    s3_prefix: "lab/incremental"
    retention_days: 7

  - name: "daily-full"
    schedule: "0 3 * * *"           # 3 AM daily
    type: "full"
    destination: "s3"
    s3_bucket: "cassandra-backups"
    s3_prefix: "lab/full"
    retention_days: 30

  - name: "weekly-snapshot"
    schedule: "0 4 * * 0"           # Sunday 4 AM
    type: "snapshot"
    destination: "s3"
    s3_bucket: "cassandra-backups"
    s3_prefix: "lab/snapshots"
    retention_days: 90
```

Apply:
```bash
make alerts ENVIRONMENT=lab
```

### Ad-Hoc Commands

```bash
cd ansible

# Check cluster status on all nodes
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "nodetool status"

# Check AxonOps agent status
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "systemctl status axon-agent"

# Restart a specific node
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  --limit "5.223.73.105" \
  -m service -a "name=cassandra state=restarted"

# Collect logs from all nodes
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m fetch -a "src=/var/log/cassandra/system.log dest=/tmp/logs/"

# Check disk space
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "df -h /data/cassandra"

# Check heap usage
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "nodetool info | grep Heap"

# Ping all hosts
pipenv run ansible -i inventories/lab/hosts.ini all -m ping

# Stop/Start nginx and wetty on all nodes
make stop-nginx ENVIRONMENT=lab
make start-nginx ENVIRONMENT=lab
```

### Wipe Data (⚠️ Destructive)

Completely remove all Cassandra data:

```bash
cd ansible
make wipe ENVIRONMENT=lab

# This will:
# 1. Stop axon-agent
# 2. Stop cassandra
# 3. Delete /data/cassandra/*
```

After wiping, redeploy:
```bash
make cassandra ENVIRONMENT=lab
```

## Web Terminal Access

Each node runs Wetty for browser-based SSH access:

**Access:**
```
URL: https://<node-public-ip>
Username: wetty
Password: AxonOpsLab2025!
```

**Features:**
- Browser-based terminal
- No SSH client required
- Self-signed SSL certificate
- Nginx reverse proxy on port 443
- HTTP basic authentication

**To customize credentials:**

Edit in cassandra.yml:
```yaml
wetty_http_username: wetty
wetty_http_password: "AxonOpsLab2025!"
```

## Troubleshooting

### Terraform Issues

**Problem:** Can't SSH to instances
```bash
# Check SSH key permissions
ls -la terraform/ssh_key
chmod 600 terraform/ssh_key

# Verify your IP is in allowed_cidrs
terraform output

# Test connection
ssh -i terraform/ssh_key -v root@<bastion-ip>
```

**Problem:** Placement group errors
```bash
# Normal for spread placement groups - Terraform will retry
# If persistent, reduce node count or change placement strategy
```

**Problem:** Inventory not generated
```bash
# Manually trigger
cd terraform
terraform output -raw ansible_inventory > ../ansible/inventories/lab/hosts.ini
```

### Ansible Issues

**Problem:** Vault password not found
```bash
# Ensure vault password file exists and is set
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass
cat ~/.ansible_vault_pass  # Should contain your password

# Test vault access
ansible-vault view group_vars/lab/vault.yml
```

**Problem:** "Failed to connect to host"
```bash
# Check SSH connectivity
ssh -i ../terraform/ssh_key root@<node-ip>

# Verify inventory
cat inventories/lab/hosts.ini

# Check firewall rules (ensure your IP is in allowed_cidrs)
cd ../terraform
terraform output
```

**Problem:** AxonOps agent not connecting
```bash
# SSH to node and check logs
ssh root@<node-ip>
journalctl -u axon-agent -n 100 -f

# Common causes:
# 1. Wrong agent key (check vault.yml)
# 2. Wrong organization name
# 3. Firewall blocking agents.axonops.cloud:443

# Verify configuration
cat /etc/axonops/axon-agent.yml

# Test connectivity
curl -v https://agents.axonops.cloud:443
```

### Cassandra Issues

**Problem:** Nodes showing as DN (Down)
```bash
# Check Cassandra logs
tail -100 /var/log/cassandra/system.log

# Check service status
systemctl status cassandra

# Common causes:
# 1. Insufficient heap (check cassandra_max_heap_size)
# 2. Network connectivity issues (check gossip ports)
# 3. Seed node misconfiguration (verify cassandra_seeds)
# 4. Time sync issues (check chrony status)

# Check heap settings
grep -i heap /opt/cassandra/conf/jvm*.options

# Verify seed nodes
grep seeds /opt/cassandra/conf/cassandra.yaml
```

**Problem:** Cluster not forming
```bash
# Verify datacenter/rack in cassandra-rackdc.properties
cat /opt/cassandra/conf/cassandra-rackdc.properties

# Should show:
# dc=dc1  (or dc2)
# rack=rack1  (or rack2, rack3)

# Check gossip info
nodetool gossipinfo

# Verify network connectivity between nodes
nodetool describecluster
```

**Problem:** Authentication errors
```bash
# Default credentials:
# Username: cassandra
# Password: cassandra

# Connect with cqlsh
cqlsh --ssl -u cassandra -p cassandra

# Change default password:
ALTER ROLE cassandra WITH PASSWORD = 'new-secure-password';
```

**Problem:** Performance issues
```bash
# Check heap usage
nodetool info | grep Heap

# Check GC stats
nodetool gcstats

# Check compaction stats
nodetool compactionstats

# Check table statistics
nodetool tablestats <keyspace>.<table>

# Review AxonOps Console for detailed metrics
```

### Network Issues

**Problem:** Can't connect to CQL port 9042
```bash
# Verify firewall allows your IP
cd terraform
terraform output

# Test connectivity
nc -zv <node-ip> 9042

# Check Cassandra is listening
ssh root@<node-ip> "netstat -tuln | grep 9042"
```

**Problem:** Inter-node communication failing
```bash
# Check private network assignment
ssh root@<node-ip> "ip addr show enp7s0"
# Should have 10.18.1.x address

# Test gossip connectivity
ssh root@<node-ip> "nodetool status"

# Check firewall rules allow inter-node traffic
# Ports 7000, 7001, 9042 should be open between Cassandra nodes
```

## Multi-Environment Setup

### Creating Production Environment

```bash
# 1. Create production Terraform workspace
cd terraform
terraform workspace new prod

# 2. Create prod tfvars
cp terraform.tfvars prod.tfvars
vim prod.tfvars
# Set: environment = "prod"
#      server_type = "cpx51"  # Larger for production
#      allowed_cidrs = ["restricted-ip-ranges"]

# 3. Deploy prod infrastructure
terraform apply -var-file=prod.tfvars

# 4. Create prod Ansible configuration
cd ../ansible
mkdir -p group_vars/prod
cp -r group_vars/lab/* group_vars/prod/

# 5. Update prod settings
vim group_vars/prod/cassandra.yml
vim group_vars/prod/axonops.yml
ansible-vault edit group_vars/prod/vault.yml

# 6. Create prod monitoring config
mkdir -p alerts-config/<org>/prod
cp -r alerts-config/<org>/lab/* alerts-config/<org>/prod/

# 7. Deploy production cluster
make common ENVIRONMENT=prod
make cassandra ENVIRONMENT=prod
make alerts ENVIRONMENT=prod
```

## Performance Tuning

### For SSD-backed nodes:

Edit `group_vars/<env>/cassandra.yml`:
```yaml
cassandra_concurrent_compactors: "4"
cassandra_compaction_throughput: "64MiB/s"
cassandra_concurrent_reads: 32
cassandra_concurrent_writes: 32
```

### For high-memory nodes:

```yaml
# Auto-calculated: 50% of RAM, max 40GB
cassandra_max_heap_size: "{% if (ansible_memtotal_mb * 0.5 / 1024) | round | int > 40 %}40{% else %}{{ (ansible_memtotal_mb * 0.5 / 1024) | round | int }}{% endif %}G"

# Or set manually:
cassandra_max_heap_size: "16G"
cassandra_heap_newsize: "3200M"  # Usually 1/4 of heap
```

### For write-heavy workloads:

```yaml
cassandra_concurrent_writes: 64
cassandra_commitlog_total_space_in_mb: 8192
cassandra_memtable_flush_writers: 4
```

## Cost Estimation

**Default lab setup (12 nodes + bastion):**

| Resource | Type | Quantity | Price/month | Total |
|----------|------|----------|-------------|-------|
| Cassandra nodes | cpx31 (4 vCPU, 8GB) | 12 | €12.50 | €150.00 |
| Bastion | cpx11 (2 vCPU, 2GB) | 1 | €4.50 | €4.50 |
| Private network | 10.18.0.0/16 | 1 | €0.00 | €0.00 |
| **Total** | | | | **€154.50/month** |

**15-node setup:**
- 15× cpx31 + bastion: ~€192/month

*Prices as of 2024, check [Hetzner Pricing](https://www.hetzner.com/cloud#pricing)*

## Additional Resources

- **AxonOps Documentation**: [docs.axonops.com](https://docs.axonops.com)
- **AxonOps Console**: [console.axonops.cloud](https://console.axonops.cloud)
- **Apache Cassandra Docs**: [cassandra.apache.org/doc/5.0](https://cassandra.apache.org/doc/5.0/)
- **Hetzner Cloud Docs**: [docs.hetzner.com](https://docs.hetzner.com/)
- **Ansible AxonOps Collection**: [galaxy.ansible.com/axonops/axonops](https://galaxy.ansible.com/axonops/axonops)

## License

See LICENSE file.

---

**Built for production-grade Cassandra deployments with AxonOps monitoring**
