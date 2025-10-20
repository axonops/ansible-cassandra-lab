<div align="center">
  <img src="https://digitalis-marketplace-assets.s3.us-east-1.amazonaws.com/AxonopsDigitalMaster_AxonopsFullLogoBlue.jpg" alt="AxonOps Workbench Icon" width="256">

  # AxonOps Workbench

  **Purpose-Built Database Management Desktop App for Apache Cassandra®**

  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
</div>

# Apache Cassandra Lab Environment

Production-grade multi-datacenter Apache Cassandra cluster deployment on Hetzner Cloud with AxonOps monitoring. This project combines Terraform for infrastructure provisioning and Ansible for automated configuration management.

## Overview

This lab environment provides:

- **Multi-datacenter Cassandra cluster** with configurable node count (currently 12 nodes)
- **Infrastructure as Code** using Terraform for Hetzner Cloud
- **Configuration Management** using Ansible with AxonOps collection
- **Production features**: SSL/TLS encryption, authentication, audit logging, monitoring
- **Web-based terminal access** via Wetty for easy cluster management
- **Comprehensive monitoring** with AxonOps SaaS platform

## Architecture

### Current Default Topology (12 Nodes)

```
┌─────────────────────────────────────────────────────────────┐
│              Hetzner Cloud Infrastructure                   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Private Network (10.18.0.0/16)                      │   │
│  │                                                      │   │
│  │  Datacenter dc1          Datacenter dc2              │   │
│  │  ┌──────────┐             ┌──────────┐               │   │
│  │  │ rack1 (2)│             │ rack1 (2)│               │   │
│  │  │ rack2 (2)│             │ rack2 (2)│               │   │
│  │  │ rack3 (2)│             │ rack3 (2)│               │   │
│  │  └──────────┘             └──────────┘               │   │
│  │  6 nodes                  6 nodes                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────┐                                           │
│  │   Bastion    │ (SSH + Web Terminal)                      │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

**Key Features:**
- **2 datacenters** (dc1, dc2) for multi-DC replication
- **3 racks per datacenter** for rack-aware topology
- **Placement groups** ensure physical host diversity
- **GossipingPropertyFileSnitch** for datacenter/rack awareness
- **4 seed nodes** (2 per DC) for reliable cluster formation
- **Private networking** (10.18.0.0/16) for inter-node communication

## Prerequisites

### Required Accounts & Credentials

1. **Hetzner Cloud**
   - You'll need a Hetzner Cloud account with API token
   - The token requires read/write permissions
   - Set via environment variable: `export HCLOUD_TOKEN="your-token"`

2. **AxonOps Free Account**

   AxonOps provides a free tier for monitoring Cassandra clusters. To sign up:

   **Step 1: Create Account**
   - Visit [axonops.com/free-trial](https://axonops.com/free-trial) or [console.axonops.cloud](https://console.axonops.cloud/)
   - Click "Sign Up" or "Start Free Trial"
   - Provide your email, name, and create a password
   - Verify your email address

   **Step 2: Create Organization**
   - After logging in, you'll be prompted to create an organization
   - Choose a unique organization name (e.g., "my-company")
   - Note: This organization name is used in configuration files

   **Step 3: Get Agent Key**
   - Navigate to Settings → Agent Keys
   - Copy your agent key (starts with `axon-`)
   - This key connects your Cassandra nodes to AxonOps

   **Step 4: Get API Token (for alerts)**
   - Navigate to Settings → API Tokens
   - Click "Generate New Token"
   - Copy the token immediately (it's only shown once)
   - This token is used to configure alerts via Ansible

   **What you'll need:**
   - Organization name (e.g., "my-company")
   - Agent key (for connecting Cassandra nodes)
   - API token (for configuring monitoring and alerts)

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
# Username: (configured in group_vars/all/wetty.yml)
# Password: (set in group_vars/<env>/vault.yml as vault_wetty_http_password)

# From bastion, connect to any Cassandra node
ssh root@<node-private-ip>

# Check cluster status
nodetool status
```

## Project Structure

```
ansible-cassandra-lab/
├── README.md                       # This file
├── .gitignore                      # Git ignore patterns
│
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Main infrastructure (12 nodes + bastion)
│   ├── variables.tf               # Configurable parameters
│   ├── outputs.tf                 # Inventory generation & outputs
│   ├── providers.tf               # Hetzner Cloud & MinIO providers
│   ├── bucket.tf                  # Object storage configuration (optional)
│   ├── terraform.tfvars.example   # Configuration template
│   ├── README.md                  # Terraform-specific documentation
│   └── *.tfvars                   # Environment-specific configs (git-ignored)
│
└── ansible/                       # Configuration Management
    ├── Makefile                   # Main entry point - run all commands from here
    ├── ansible.cfg                # Ansible configuration
    ├── Pipfile                    # Python dependencies
    ├── requirements.yml           # Ansible Galaxy collections & roles
    ├── LICENSE                    # Project license
    │
    ├── Playbooks (root level):
    │   ├── common.yml            # OS hardening, NTP, base packages, Wetty
    │   ├── cassandra.yml         # Java, Cassandra 5.0.5, AxonOps agent
    │   ├── alerts.yml            # AxonOps monitoring configuration
    │   ├── rolling-restart.yml   # Safe sequential cluster restart
    │   ├── wipe.yml              # Stop services & wipe data (destructive)
    │   ├── _keystore.yml         # SSL keystore generation (imported)
    │   └── _wetty.yml            # Web terminal setup (imported)
    │
    ├── inventories/              # Terraform auto-generates these
    │   ├── lab/
    │   │   └── hosts.ini         # Lab environment inventory
    │   ├── stg/
    │   │   └── hosts.ini         # Staging environment inventory
    │   └── prd/
    │       └── hosts.ini         # Production environment inventory
    │
    ├── group_vars/
    │   ├── all/                  # Global defaults for all environments
    │   │   ├── common.yml       # Common variables
    │   │   ├── cassandra.yml    # Cassandra 5.0.5 default settings
    │   │   └── axonops.yml      # AxonOps agent 2.0.9 default config
    │   │
    │   ├── lab/                 # Lab environment overrides
    │   │   ├── cassandra.yml    # Lab-specific performance tuning
    │   │   ├── axonops.yml      # Lab organization settings
    │   │   ├── ssl.yml          # SSL/TLS configuration (optional)
    │   │   ├── vault.yml        # Encrypted credentials (git-ignored)
    │   │   └── ssl_vault.yml    # Encrypted SSL passwords (git-ignored)
    │   │
    │   ├── stg/                 # Staging environment overrides
    │   │   ├── cassandra.yml
    │   │   ├── axonops.yml
    │   │   └── vault.yml        # Encrypted (git-ignored)
    │   │
    │   └── prd/                 # Production environment overrides
    │       ├── cassandra.yml
    │       ├── axonops.yml
    │       ├── ssl.yml
    │       ├── vault.yml        # Encrypted (git-ignored)
    │       └── ssl_vault.yml    # Encrypted (git-ignored)
    │
    ├── alerts-config/            # AxonOps monitoring (YAML-driven)
    │   └── <org-name>/          # Your organization name (e.g., "training")
    │       │
    │       ├── Organization-level configs:
    │       │   ├── alert_endpoints.yml     # Integrations (Slack, PagerDuty, email)
    │       │   ├── metric_alert_rules.yml  # Default metric alerts (all clusters)
    │       │   └── log_alert_rules.yml     # Default log alerts (all clusters)
    │       │
    │       ├── lab/              # Lab cluster monitoring
    │       │   ├── alert_routes.yml         # Route alerts to endpoints
    │       │   ├── backups.yml              # Backup schedules & retention
    │       │   ├── service_checks.yml       # Custom health checks
    │       │   ├── commitlog_archive.yml    # Commitlog archiving config
    │       │   ├── dashboards.yml           # Custom dashboard definitions
    │       │   ├── metric_alert_rules.yml   # Cluster-specific metric alerts
    │       │   └── log_alert_rules.yml      # Cluster-specific log alerts
    │       │
    │       ├── stg/              # Staging cluster monitoring (same structure)
    │       │   └── ...
    │       │
    │       └── prd/              # Production cluster monitoring (same structure)
    │           └── ...
    │
    ├── templates/
    │   └── alerts/               # Jinja2 templates for service check scripts
    │       ├── check-node-down.sh.j2
    │       ├── check-keyspaces-strategy.sh.j2
    │       └── check-schema-disagreements.sh.j2
    │
    ├── files/
    │   └── ssl/                  # SSL certificates per environment
    │       ├── lab/              # Lab environment certs
    │       ├── stg/              # Staging environment certs
    │       └── prd/              # Production environment certs
    │
    └── collections/              # Ansible Galaxy collections (installed)
        └── ansible_collections/
            └── axonops/
                └── axonops/      # AxonOps Ansible collection
```

**Key Files to Customize:**

1. **Infrastructure:**
   - `terraform/terraform.tfvars` - Hetzner Cloud configuration
   - `terraform/*.tfvars` - Per-environment configs (lab, stg, prd)

2. **Cassandra Configuration:**
   - `ansible/group_vars/all/cassandra.yml` - Global defaults
   - `ansible/group_vars/<env>/cassandra.yml` - Environment overrides

3. **AxonOps Configuration:**
   - `ansible/group_vars/all/axonops.yml` - Global defaults
   - `ansible/group_vars/<env>/axonops.yml` - Environment settings
   - `ansible/group_vars/<env>/vault.yml` - Encrypted credentials

4. **Monitoring Configuration:**
   - `ansible/alerts-config/<org>/alert_endpoints.yml` - Alert integrations
   - `ansible/alerts-config/<org>/<cluster>/backups.yml` - Backup schedules
   - `ansible/alerts-config/<org>/<cluster>/alert_routes.yml` - Alert routing

**Git-Ignored Files:**

These files contain sensitive data and are excluded from version control:
- `terraform/*.tfvars` (except `.example`)
- `terraform/.terraform/`
- `terraform/terraform.tfstate*`
- `ansible/group_vars/*/vault*.yml`
- `ansible/files/ssl/` (certificates)
- `ansible/collections/` (installed collections)

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

The project includes a comprehensive Makefile for simplified Terraform operations.

**Quick Start:**
```bash
cd terraform

# See all available commands
make help

# Initialize Terraform
make init

# Plan changes for lab environment (default)
make plan

# Apply changes
make apply

# Plan/apply for different environments
make plan ENVIRONMENT=stg
make apply ENVIRONMENT=prd
```

**Common Makefile Commands:**

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make init` | Initialize Terraform (download providers) |
| `make plan` | Show execution plan |
| `make apply` | Apply infrastructure changes |
| `make destroy` | Destroy infrastructure |
| `make output` | Show Terraform outputs |
| `make console` | Open Terraform console |
| `make validate` | Validate configuration |
| `make fmt` | Format Terraform files |

**Environment Management:**
```bash
# Use different environment configurations
make plan ENVIRONMENT=lab    # Uses lab.terraform.tfvars (default)
make plan ENVIRONMENT=stg    # Uses stg.terraform.tfvars
make apply ENVIRONMENT=prd   # Uses prd.terraform.tfvars
```

**Workspace Commands:**
```bash
make workspace-list                    # List all workspaces
make workspace-new WORKSPACE=stg       # Create new workspace
make workspace-select WORKSPACE=prd    # Switch workspace
make workspace-show                    # Show current workspace
```

**Inventory Management:**
```bash
make inventory                # Show Ansible inventory
make inventory-save           # Save to ../ansible/inventories/<env>/hosts.ini
```

**SSH Helpers:**
```bash
make ssh-bastion              # SSH to bastion host
make ssh-node NODE=1          # SSH to Cassandra node 1 via bastion
```

**Setup Helpers:**
```bash
make setup-lab                # Create lab.terraform.tfvars from example
make setup-stg                # Create stg.terraform.tfvars template
make setup-prd                # Create prd.terraform.tfvars template
```

**Quick Deployment:**
```bash
make deploy-lab               # Full workflow: init → plan → apply → save inventory
make deploy-stg               # Deploy staging (with workspace management)
make deploy-prd               # Deploy production (with workspace management)
```

**Direct Terraform Commands:**

You can also use Terraform commands directly:
```bash
cd terraform

# Initialize and download providers
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan -var-file=lab.terraform.tfvars

# Apply changes
terraform apply -var-file=lab.terraform.tfvars

# Show all outputs (IPs, inventory, etc.)
terraform output

# Destroy infrastructure
terraform destroy -var-file=lab.terraform.tfvars
```

### Network Configuration

**Firewall Rules:**

**Bastion:**
- Port 22 (SSH) ← from `allowed_cidrs`
- Port 443 (HTTPS/Wetty) ← from `allowed_cidrs`

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
<cassandra-server-ip> cassandra_rack=rack1 cassandra_dc=dc1 ansible_hostname=cassandra-node-1
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
Username: wetty (configurable)
Password: (must be set in vault)
```

**Features:**
- Browser-based terminal
- No SSH client required
- Self-signed SSL certificate
- Nginx reverse proxy on port 443
- HTTP basic authentication

**Configuration:**

Wetty is configured in two places:

1. **Global defaults** (`ansible/group_vars/all/wetty.yml`):
```yaml
wetty_use_nginx: true
wetty_nginx_port: 443
wetty_server_name: "{{ ansible_fqdn }}"

# SSL settings
wetty_use_ssl: true
wetty_generate_self_signed_cert: true
wetty_ssl_cert_path: "/etc/ssl/certs/wetty.pem"
wetty_ssl_key_path: "/etc/ssl/private/wetty.key"

# HTTP basic auth
wetty_http_username: wetty
wetty_http_password: "{{ vault_wetty_http_password }}"
```

2. **Environment-specific password** (stored in vault):
```bash
# Edit vault file for your environment
ansible-vault edit group_vars/lab/vault.yml

# Add the Wetty password:
vault_wetty_http_password: "your-secure-password-here"
```

**To customize:**
- Change username: Edit `wetty_http_username` in `group_vars/all/wetty.yml`
- Change password: Edit `vault_wetty_http_password` in `group_vars/<env>/vault.yml`
- Disable SSL: Set `wetty_use_ssl: false` in environment-specific config
- Change port: Set `wetty_nginx_port` to different port

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

This project supports multiple isolated environments (lab, staging, production) running simultaneously or separately. Each environment has its own:

- Terraform state and infrastructure
- Ansible inventory and configuration
- AxonOps cluster monitoring
- Network isolation

### Environment Naming Convention

We recommend using short environment codes:
- `lab` - Development/testing environment (default)
- `stg` - Staging environment for pre-production testing
- `prd` - Production environment

### Creating a Staging Environment

```bash
# 1. Create staging infrastructure with Terraform
cd terraform

# Create a new Terraform workspace for isolation
terraform workspace new stg

# Create staging configuration
cat > stg.tfvars <<EOF
environment = "stg"
location    = "fsn1"              # Falkenstein (or your preferred location)
server_type = "cpx31"             # 4 vCPU, 8GB RAM
bastion_server_type = "cpx11"
allowed_cidrs = ["YOUR_IP/32"]
ssh_keys = []
EOF

# Deploy staging infrastructure
terraform apply -var-file=stg.tfvars

# Verify inventory was created
cat ../ansible/inventories/stg/hosts.ini

# 2. Create staging Ansible configuration
cd ../ansible

# Create staging group_vars
mkdir -p group_vars/stg
cp -r group_vars/lab/* group_vars/stg/

# Update staging-specific settings
vim group_vars/stg/cassandra.yml
# Adjust: cassandra_cluster_name: "stg"
#         heap sizes, performance tuning, etc.

vim group_vars/stg/axonops.yml
# Keep: axon_agent_customer_name and axon_agent_key reference vault

# Create staging vault with credentials
ansible-vault create group_vars/stg/vault.yml
# Add:
#   vault_axon_agent_customer_name: "your-org"
#   vault_axon_agent_key: "your-agent-key"

# 3. Create staging monitoring configuration
mkdir -p alerts-config/<your-org>/stg
cp -r alerts-config/<your-org>/lab/* alerts-config/<your-org>/stg/

# Customize staging alerts
vim alerts-config/<your-org>/stg/alert_routes.yml
vim alerts-config/<your-org>/stg/backups.yml

# 4. Deploy staging cluster
make common ENVIRONMENT=stg
make cassandra ENVIRONMENT=stg
make alerts ENVIRONMENT=stg

# 5. Verify staging cluster
ssh -i ../terraform/ssh_key root@<stg-bastion-ip>
ssh root@<stg-node-private-ip>
nodetool status
```

### Creating a Production Environment

```bash
# 1. Create production infrastructure with Terraform
cd terraform

# Create production workspace
terraform workspace new prd

# Create production configuration with larger instances
cat > prd.tfvars <<EOF
environment = "prd"
location    = "hel1"              # Helsinki (or your preferred location)
server_type = "cpx51"             # 16 vCPU, 32GB RAM for production
bastion_server_type = "cpx21"     # Larger bastion for production
allowed_cidrs = ["VPN_IP/32", "OFFICE_IP/32"]  # Restrict to known IPs only
ssh_keys = ["prod-ssh-key"]       # Use existing SSH key for security
EOF

# Deploy production infrastructure
terraform apply -var-file=prd.tfvars

# Verify inventory
cat ../ansible/inventories/prd/hosts.ini

# 2. Create production Ansible configuration
cd ../ansible

# Create production group_vars
mkdir -p group_vars/prd

# Copy base configuration
cp -r group_vars/lab/* group_vars/prd/

# Configure production Cassandra settings
cat > group_vars/prd/cassandra.yml <<EOF
---
# Production-specific overrides

# Larger heap for production (adjust based on your instance size)
cassandra_max_heap_size: "16G"
cassandra_heap_newsize: "4G"

# Higher concurrency for production workload
cassandra_concurrent_compactors: "8"
cassandra_compaction_throughput: "128MiB/s"
cassandra_concurrent_reads: 64
cassandra_concurrent_writes: 64

# Production cache sizes
cassandra_counter_cache_save_period: "7200s"
cassandra_counter_write_request_timeout: "10000s"

# Cluster name
cassandra_cluster_name: "prd"
EOF

# Configure production AxonOps settings
vim group_vars/prd/axonops.yml

# Create production vault (IMPORTANT: Use production credentials!)
ansible-vault create group_vars/prd/vault.yml
# Add:
#   vault_axon_agent_customer_name: "your-org"
#   vault_axon_agent_key: "your-production-agent-key"

# (Optional) Configure SSL for production
vim group_vars/prd/ssl.yml
ansible-vault create group_vars/prd/ssl_vault.yml

# 3. Create production monitoring configuration
mkdir -p alerts-config/<your-org>/prd
cp -r alerts-config/<your-org>/lab/* alerts-config/<your-org>/prd/

# Configure production-specific monitoring
vim alerts-config/<your-org>/prd/alert_routes.yml
# Route critical alerts to PagerDuty for production

vim alerts-config/<your-org>/prd/backups.yml
# More frequent backups and longer retention for production:
# Hourly incrementals, daily fulls, weekly snapshots

vim alerts-config/<your-org>/prd/service_checks.yml
# Stricter thresholds for production

# 4. Deploy production cluster
make common ENVIRONMENT=prd
make cassandra ENVIRONMENT=prd
make alerts ENVIRONMENT=prd

# 5. Verify production cluster
ssh -i ../terraform/ssh_key root@<prd-bastion-ip>
ssh root@<prd-node-private-ip>
nodetool status

# 6. Check AxonOps Console
# Visit: https://console.axonops.cloud/
# Verify you see separate clusters: "lab", "stg", "prd"
```

### Environment Comparison

| Aspect | Lab | Staging | Production |
|--------|-----|---------|------------|
| Purpose | Development/Testing | Pre-production validation | Live production |
| Instance Size | cpx31 (4vCPU, 8GB) | cpx31 (4vCPU, 8GB) | cpx51 (16vCPU, 32GB) |
| Node Count | 12 | 12 | 12-15 |
| Heap Size | Auto (4-8GB) | Auto (4-8GB) | 16GB+ |
| SSL/TLS | Optional | Recommended | Required |
| Access Control | Open (for testing) | Restricted | Highly restricted |
| Backup Retention | 7 days | 14 days | 30-90 days |
| Alert Routing | Email | Slack | PagerDuty + Slack |
| Cost (monthly) | ~€155 | ~€155 | ~€310 |

### Managing Multiple Environments

**Switch between Terraform workspaces:**
```bash
cd terraform

# List workspaces
terraform workspace list

# Switch to staging
terraform workspace select stg

# Check current workspace
terraform workspace show

# Work with specific environment
terraform apply -var-file=stg.tfvars
```

**Deploy to specific environment with Ansible:**
```bash
cd ansible

# Deploy to staging
make cassandra ENVIRONMENT=stg

# Deploy to production
make cassandra ENVIRONMENT=prd

# Rolling restart staging
make rolling-restart ENVIRONMENT=stg
```

**View environment in AxonOps Console:**

Each environment appears as a separate cluster in the AxonOps Console:
- Cluster name: `lab`, `stg`, or `prd`
- Organization: Same organization for all environments
- Monitoring: Isolated metrics and alerts per cluster

### Best Practices for Multiple Environments

1. **Terraform State Isolation**
   - Use separate workspaces or remote backends per environment
   - Never share state between environments

2. **Credentials Management**
   - Use separate vault files per environment
   - Use different SSH keys for production
   - Rotate production credentials regularly

3. **Network Isolation**
   - Deploy environments in different regions if possible
   - Use separate private networks per environment
   - Restrict production access to VPN/office IPs only

4. **Progressive Deployment**
   - Test changes in `lab` first
   - Promote to `stg` for validation
   - Deploy to `prd` only after staging validation

5. **Monitoring Separation**
   - Configure different alert routes per environment
   - Use PagerDuty for production, Slack for staging/lab
   - Set stricter thresholds for production alerts

6. **Backup Strategy**
   - Lab: Minimal backups (7 days)
   - Staging: Regular backups (14 days)
   - Production: Comprehensive backups (30-90 days)

### Destroying an Environment

```bash
# Destroy lab environment
cd terraform
terraform workspace select lab
terraform destroy

cd ../ansible
rm -rf group_vars/lab
rm -rf inventories/lab
rm -rf alerts-config/<org>/lab

# Destroy staging environment
cd terraform
terraform workspace select stg
terraform destroy

cd ../ansible
rm -rf group_vars/stg
rm -rf inventories/stg
rm -rf alerts-config/<org>/stg
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

## Additional Resources

- **AxonOps Documentation**: [docs.axonops.com](https://docs.axonops.com)
- **AxonOps Console**: [console.axonops.cloud](https://console.axonops.cloud)
- **Ansible AxonOps Collection**: [galaxy.ansible.com/axonops/axonops](https://galaxy.ansible.com/axonops/axonops)

## License

See LICENSE file.

***

## 📄 Legal Notices

*This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.*

- **AxonOps** is a registered trademark of AxonOps Limited.
- **Apache**, **Apache Cassandra**, **Cassandra**, **Apache Spark**, **Spark**, **Apache TinkerPop**, **TinkerPop**, **Apache Kafka** and **Kafka** are either registered trademarks or trademarks of the Apache Software Foundation or its subsidiaries in Canada, the United States and/or other countries.
- **DataStax** is a registered trademark of DataStax, Inc. and its subsidiaries in the United States and/or other countries.