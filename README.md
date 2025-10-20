<div align="center">
  <a href="https://axonops.com/">
    <img src="https://digitalis-marketplace-assets.s3.us-east-1.amazonaws.com/AxonopsDigitalMaster_AxonopsFullLogoBlue.jpg" alt="AxonOps Logo" width="300">
  </a>

  # AxonOps Cassandra Lab: Complete Infrastructure & Configuration

  [![Apache Cassandra](https://img.shields.io/badge/Apache%20Cassandra-5.0.5-1287B1?style=for-the-badge&logo=apache-cassandra)](https://cassandra.apache.org/)
  [![Terraform](https://img.shields.io/badge/Terraform-1.0+-7B42BC?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
  [![Ansible](https://img.shields.io/badge/Ansible-Automation-EE0000?style=for-the-badge&logo=ansible)](https://www.ansible.com/)
  [![AxonOps](https://img.shields.io/badge/AxonOps-Monitoring-4A90E2?style=for-the-badge)](https://axonops.com/)
</div>

---

## Overview

This project provides a complete, production-ready solution for deploying Apache Cassandra clusters on Hetzner Cloud with comprehensive monitoring via AxonOps. It combines:

- **Infrastructure as Code (Terraform)**: Automated provisioning of cloud infrastructure on Hetzner Cloud
- **Configuration Management (Ansible)**: Automated deployment and configuration of Cassandra and AxonOps
- **Multi-Environment Support**: Separate configurations for dev, staging, and production
- **Advanced Topology**: Multi-datacenter clusters with rack awareness and proper seed node configuration
- **Comprehensive Monitoring**: Production-grade alerting, backups, and service checks via AxonOps

## Table of Contents

- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Terraform: Infrastructure Provisioning](#-terraform-infrastructure-provisioning)
- [Ansible: Configuration Management](#-ansible-configuration-management)
- [Complete Deployment Workflow](#-complete-deployment-workflow)
- [Advanced Operations](#-advanced-operations)
- [Troubleshooting](#-troubleshooting)

## 🏗️ Architecture

This lab creates a production-grade multi-datacenter Cassandra cluster:

```
┌─────────────────────────────────────────────────────────────┐
│                    Hetzner Cloud (sin)                       │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Private Network (10.18.0.0/16)                      │   │
│  │                                                        │   │
│  │  ┌─────────────┐  ┌─────────────┐                    │   │
│  │  │ Datacenter  │  │ Datacenter  │                    │   │
│  │  │     dc1     │  │     dc2     │                    │   │
│  │  │             │  │             │                    │   │
│  │  │ rack1 (2n)  │  │ rack1 (2n)  │                    │   │
│  │  │ rack2 (2n)  │  │ rack2 (2n)  │                    │   │
│  │  │ rack3 (2n)  │  │ rack3 (2n)  │                    │   │
│  │  └─────────────┘  └─────────────┘                    │   │
│  │                                                        │   │
│  │  Total: 12 Cassandra Nodes                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────┐                                            │
│  │   Bastion    │  (Public SSH access + WireGuard VPN)      │
│  └──────────────┘                                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Key Features:**
- **12-node cluster** across 2 datacenters (dc1, dc2)
- **3 racks per datacenter** for fault tolerance
- **Placement groups** ensure nodes spread across physical hosts
- **Private networking** for inter-node communication
- **Bastion host** with WireGuard VPN for secure access
- **Automated firewall rules** for Cassandra ports (7000, 7001, 9042)

## 📋 Prerequisites

### Required Tools
- **Terraform** >= 1.0 ([Install](https://www.terraform.io/downloads))
- **Ansible** >= 2.9 ([Install](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- **Pipenv** for Python dependency management ([Install](https://pipenv.pypa.io/en/latest/install/))
- **Hetzner Cloud Account** ([Sign up](https://www.hetzner.com/cloud))
- **AxonOps Account** ([Sign up](https://axonops.com/))

### Required Credentials
1. **Hetzner Cloud API Token** - Generate from [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. **AxonOps Organization Name** - From [AxonOps Console](https://console.axonops.cloud/)
3. **AxonOps Agent Key** - From [AxonOps Console](https://console.axonops.cloud/)
4. **AxonOps API Token** - From [AxonOps Console](https://console.axonops.cloud/) (for alerts configuration)
5. **Ansible Vault Password** - For encrypting sensitive data

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository_url>
cd ansible-cassandra-lab
```

### 2. Set Up Environment Variables
```bash
# Hetzner Cloud
export HCLOUD_TOKEN="your-hetzner-api-token"

# AxonOps
export AXONOPS_ORG="your-org-name"
export AXONOPS_TOKEN="your-api-token"

# Ansible Vault
echo "your-vault-password" > ~/.ansible_vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass
```

### 3. Provision Infrastructure (Terraform)
```bash
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Create infrastructure
terraform apply

# Inventory is automatically created at ../ansible/inventories/lab/hosts.ini
cd ..
```

### 4. Deploy Cassandra & AxonOps (Ansible)
```bash
cd ansible

# Install Ansible dependencies
make prep

# Apply base system configuration
make common ENVIRONMENT=lab

# Deploy Cassandra and AxonOps agent
make cassandra ENVIRONMENT=lab

# Configure AxonOps alerts and monitoring
make alerts ENVIRONMENT=lab
```

Your cluster is now ready! 🎉

## 🏗️ Terraform: Infrastructure Provisioning

The [terraform/](terraform/) directory contains Infrastructure as Code for Hetzner Cloud.

### What Gets Created

| Resource | Quantity | Purpose |
|----------|----------|---------|
| Cassandra Nodes | 12 | Multi-DC cluster (6 per DC) |
| Bastion Host | 1 | Secure SSH access + WireGuard VPN |
| Private Network | 1 | Inter-node communication (10.18.0.0/16) |
| Placement Groups | 6 | Spread nodes across physical hosts |
| Firewalls | 2 | Security rules for Cassandra and bastion |
| SSH Key | 1 | Auto-generated or use existing |

### Configuration

Create `terraform/terraform.tfvars`:

```hcl
# Environment and location
environment = "lab"
location    = "sin"  # Singapore (or nbg1, fsn1, hel1, ash)

# Instance types
server_type        = "cpx31"  # 4 vCPU, 8GB RAM
bastion_server_type = "cpx11"  # 2 vCPU, 2GB RAM

# Security
allowed_cidrs = ["YOUR_IP/32"]  # Restrict access to your IP

# SSH keys (leave empty to auto-generate)
ssh_keys = []
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

# Show outputs (IPs, SSH commands, etc.)
terraform output

# Destroy infrastructure
terraform destroy
```

### Key Outputs

After `terraform apply`, you'll get:

- **SSH key path** - Location of generated private key
- **Ansible inventory** - Automatically created at `../ansible/inventories/lab/hosts.ini`
- **Bastion IP** - Public IP of bastion host
- **Cassandra node IPs** - All node public IPs with DC/rack assignments
- **Seed nodes** - Comma-separated list for Cassandra configuration

### Network Architecture

```
Firewall Rules:
├── Bastion
│   ├── SSH (22) ← from allowed_cidrs
│   ├── HTTPS (443) ← from allowed_cidrs
│   └── WireGuard (51920) ← from 0.0.0.0/0
│
└── Cassandra Nodes
    ├── SSH (22) ← from bastion + allowed_cidrs
    ├── CQL (9042) ← from allowed_cidrs + private network
    ├── Inter-node (7000, 7001) ← from other Cassandra nodes
    └── Private network ← from 10.18.0.0/16
```

For detailed Terraform documentation, see [terraform/README.md](terraform/README.md).

## ⚙️ Ansible: Configuration Management

The [ansible/](ansible/) directory contains playbooks and roles for configuring Cassandra and AxonOps.

### Project Structure

```
ansible/
├── Makefile                    # Main commands interface
├── requirements.yml            # Ansible collections
├── inventories/
│   └── lab/
│       └── hosts.ini          # Generated by Terraform
├── group_vars/
│   ├── all/                   # Global defaults
│   │   ├── cassandra.yml      # Cassandra config
│   │   └── axonops.yml        # AxonOps config
│   └── lab/                   # Environment overrides
│       ├── cassandra.yml      # Lab-specific settings
│       ├── axonops.yml        # Lab-specific settings
│       ├── vault.yml          # Encrypted secrets
│       └── ssl_vault.yml      # Encrypted SSL passwords
├── alerts-config/             # AxonOps monitoring config
│   └── training/              # Organization name
│       ├── alert_endpoints.yml
│       ├── metric_alert_rules.yml
│       ├── log_alert_rules.yml
│       └── lab/               # Cluster-specific
│           ├── alert_routes.yml
│           ├── backups.yml
│           └── service_checks.yml
└── *.yml                      # Playbooks
```

### Available Playbooks

| Command | Playbook | Description |
|---------|----------|-------------|
| `make common` | [common.yml](ansible/common.yml) | OS hardening, base packages, security |
| `make cassandra` | [cassandra.yml](ansible/cassandra.yml) | Java, Cassandra, AxonOps agent |
| `make alerts` | [alerts.yml](ansible/alerts.yml) | Alerts, backups, service checks |
| `make rolling-restart` | [rolling-restart.yml](ansible/rolling-restart.yml) | Safe cluster restart |
| `make wipe` | [wipe.yml](ansible/wipe.yml) | Remove Cassandra data |

### Environment Configuration

Each environment needs its own configuration in `group_vars/<environment>/`:

**Required files:**
- **cassandra.yml** - Cluster name, seeds, performance tuning
- **axonops.yml** - Organization name, agent key
- **vault.yml** - Encrypted passwords and keys
- **ssl.yml** (optional) - SSL/TLS configuration
- **ssl_vault.yml** (optional) - SSL certificate passwords

**Example:** [group_vars/lab/cassandra.yml](ansible/group_vars/lab/cassandra.yml)
```yaml
cassandra_cluster_name: "lab-cluster"
cassandra_seeds: "10.18.1.1,10.18.1.2,10.18.1.3,10.18.1.4"
cassandra_version: "5.0.5"

# Performance tuning
cassandra_heap_size: "4G"
cassandra_heap_newsize: "800M"
cassandra_compaction_throughput_mb_per_sec: 64
```

### Managing Secrets with Ansible Vault

```bash
# Create encrypted vault file
ansible-vault create group_vars/lab/vault.yml

# Edit existing vault
ansible-vault edit group_vars/lab/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/lab/vault.yml

# View encrypted file
ansible-vault view group_vars/lab/vault.yml
```

**Vault file example:**
```yaml
# group_vars/lab/vault.yml
vault_axon_agent_key: "your-axonops-agent-key"
vault_cassandra_admin_password: "secure-password"
vault_ssl_keystore_password: "keystore-pass"
```

Reference vault variables in regular config files:
```yaml
# group_vars/lab/axonops.yml
axon_agent_key: "{{ vault_axon_agent_key }}"
```

### Configuring AxonOps Monitoring

The [alerts-config/](ansible/alerts-config/) directory provides data-driven monitoring configuration:

**Organization-level** (`alerts-config/<org_name>/`):
- `alert_endpoints.yml` - Slack, PagerDuty, email integrations
- `metric_alert_rules.yml` - CPU, memory, disk, Cassandra metrics
- `log_alert_rules.yml` - Log pattern alerts

**Cluster-level** (`alerts-config/<org_name>/<cluster_name>/`):
- `alert_routes.yml` - Route alerts to specific integrations
- `backups.yml` - Backup schedules and retention
- `service_checks.yml` - Custom health checks
- `commitlog_archive.yml` - Commitlog archiving configuration

**Example:** [alerts-config/training/lab/backups.yml](ansible/alerts-config/training/lab/backups.yml)
```yaml
axonops_backups:
  - name: "daily-full-backup"
    schedule: "0 2 * * *"  # 2 AM daily
    type: "full"
    destination: "s3"
    s3_bucket: "cassandra-backups"
    retention_days: 30
```

Apply monitoring configuration:
```bash
make alerts ENVIRONMENT=lab
```

For complete Ansible documentation, see [ansible/README.md](ansible/README.md).

## 🔄 Complete Deployment Workflow

### Step-by-Step Guide

#### Phase 1: Infrastructure Provisioning

```bash
# 1. Set Hetzner Cloud token
export HCLOUD_TOKEN="your-token"

# 2. Navigate to Terraform directory
cd terraform

# 3. Initialize Terraform
terraform init

# 4. Create terraform.tfvars
cat > terraform.tfvars <<EOF
environment = "lab"
location    = "sin"
server_type = "cpx31"
allowed_cidrs = ["$(curl -s ifconfig.me)/32"]
ssh_keys = []
EOF

# 5. Deploy infrastructure
terraform apply -auto-approve

# 6. Verify inventory was created
cat ../ansible/inventories/lab/hosts.ini
```

#### Phase 2: Base Configuration

```bash
# 1. Navigate to Ansible directory
cd ../ansible

# 2. Create vault password file
echo "my-secure-vault-password" > ~/.ansible_vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass

# 3. Install Ansible dependencies
make prep

# 4. Configure environment variables
export ENVIRONMENT=lab
export ANSIBLE_USER=root

# 5. Update group_vars for your environment
# Edit group_vars/lab/cassandra.yml
# Edit group_vars/lab/axonops.yml

# 6. Create/edit vault with secrets
ansible-vault edit group_vars/lab/vault.yml
# Add: vault_axon_agent_key: "your-key"

# 7. Apply base configuration
make common ENVIRONMENT=lab
```

#### Phase 3: Cassandra Deployment

```bash
# 1. Deploy Cassandra cluster
make cassandra ENVIRONMENT=lab

# 2. Verify cluster status (from bastion)
ssh -i ../terraform/ssh_key root@<bastion-ip>
# Then from bastion:
ssh root@<cassandra-node-ip> "nodetool status"
```

#### Phase 4: Monitoring Setup

```bash
# 1. Set AxonOps credentials
export AXONOPS_ORG="your-org-name"
export AXONOPS_TOKEN="your-api-token"

# 2. Configure alerts directory
# Create: alerts-config/your-org-name/
# Copy examples from alerts-config/training/

# 3. Apply monitoring configuration
make alerts ENVIRONMENT=lab

# 4. Verify in AxonOps Console
# Visit: https://console.axonops.cloud/
```

### Environment-Specific Deployments

```bash
# Development
terraform apply -var='environment=dev'
make cassandra ENVIRONMENT=dev

# Staging
terraform apply -var='environment=stg'
make cassandra ENVIRONMENT=stg

# Production
terraform apply -var='environment=prd'
make cassandra ENVIRONMENT=prd ANSIBLE_USER=ubuntu
```

## 🔧 Advanced Operations

### Configuration-Only Updates

Update Cassandra configuration without reinstalling:

```bash
# 1. Edit configuration
vim group_vars/lab/cassandra.yml

# 2. Apply config changes (doesn't restart)
make cassandra ENVIRONMENT=lab EXTRA="--tags config"

# 3. Perform rolling restart
make rolling-restart ENVIRONMENT=lab
```

### Rolling Restart

Safe, zero-downtime cluster restart:

```bash
make rolling-restart ENVIRONMENT=lab
```

The playbook automatically:
1. Verifies node health (`UN` status)
2. Drains the node (`nodetool drain`)
3. Stops Cassandra service
4. Starts Cassandra service
5. Waits for node to rejoin
6. Proceeds to next node

### Scaling the Cluster

```bash
# 1. Update Terraform node count
cd terraform
vim main.tf  # Modify count in hcloud_server.cassandra

# 2. Apply infrastructure changes
terraform apply

# 3. Deploy Cassandra to new nodes
cd ../ansible
make cassandra ENVIRONMENT=lab --limit new-node-ip
```

### SSL/TLS Configuration

```bash
# 1. Place certificates in files/<env>/ssl/
mkdir -p files/lab/ssl
# Copy your .jks files here

# 2. Configure SSL in group_vars
vim group_vars/lab/ssl.yml

# 3. Create SSL vault with passwords
ansible-vault edit group_vars/lab/ssl_vault.yml

# 4. Apply configuration
make cassandra ENVIRONMENT=lab EXTRA="--tags config,ssl"

# 5. Rolling restart
make rolling-restart ENVIRONMENT=lab
```

### Backup and Restore

Configure backups in `alerts-config/<org>/<cluster>/backups.yml`:

```yaml
axonops_backups:
  - name: "hourly-incremental"
    schedule: "0 * * * *"
    type: "incremental"
    destination: "s3"
    s3_bucket: "cassandra-backups"
    retention_days: 7

  - name: "daily-full"
    schedule: "0 3 * * *"
    type: "full"
    destination: "s3"
    s3_bucket: "cassandra-backups"
    retention_days: 30
```

Apply:
```bash
make alerts ENVIRONMENT=lab
```

### Ad-Hoc Commands

```bash
# Check cluster status
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "nodetool status"

# Check AxonOps agent status
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "systemctl status axon-agent"

# Restart a specific node
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  --limit "cassandra-node-001" \
  -m service -a "name=cassandra state=restarted"

# Collect logs from all nodes
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m fetch -a "src=/var/log/cassandra/system.log dest=/tmp/logs/"
```

### Monitoring and Debugging

```bash
# Check connectivity
make ENVIRONMENT=lab
pipenv run ansible -i inventories/lab/hosts.ini all -m ping

# Gather facts
pipenv run ansible -i inventories/lab/hosts.ini cassandra -m setup

# Check disk space
pipenv run ansible -i inventories/lab/hosts.ini cassandra \
  -m shell -a "df -h /var/lib/cassandra"

# View real-time logs
ssh -i ../terraform/ssh_key root@<bastion-ip>
ssh root@<cassandra-node-ip>
tail -f /var/log/cassandra/system.log
```

## 🔍 Troubleshooting

### Terraform Issues

**Problem:** `Error creating server: placement group is full`
```bash
# Solution: This is normal for spread placement groups
# Terraform will automatically retry
```

**Problem:** `Error: Invalid SSH key`
```bash
# Solution: Check SSH key format
terraform output ssh_key_path
chmod 600 ssh_key
```

**Problem:** Inventory not created
```bash
# Solution: Check output resource
terraform output ansible_inventory
# Manually create if needed:
terraform output -raw ansible_inventory > ../ansible/inventories/lab/hosts.ini
```

### Ansible Issues

**Problem:** `Failed to connect to host`
```bash
# Solution: Verify SSH access
ssh -i ../terraform/ssh_key root@<node-ip>

# Check firewall rules
terraform output
# Ensure your IP is in allowed_cidrs
```

**Problem:** `Vault password not found`
```bash
# Solution: Set vault password file
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass
echo "your-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```

**Problem:** `AxonOps agent not starting`
```bash
# Solution: Check logs and credentials
ssh root@<node-ip> "journalctl -u axon-agent -n 50"

# Verify agent key
ansible-vault view group_vars/lab/vault.yml
```

### Cassandra Issues

**Problem:** Nodes show as `DN` (Down)
```bash
# Check status
nodetool status

# Check logs
tail -100 /var/log/cassandra/system.log

# Common causes:
# 1. Insufficient memory (check heap settings)
# 2. Network connectivity (check firewall)
# 3. Seed node misconfiguration (check cassandra.yaml)
```

**Problem:** Cluster not forming
```bash
# Verify seed nodes
grep seeds /etc/cassandra/cassandra.yaml

# Check network connectivity
nodetool describecluster

# Verify datacenter/rack settings
nodetool status
```

**Problem:** Performance issues
```bash
# Check heap usage
nodetool info | grep Heap

# Check GC stats
nodetool gcstats

# Review metrics in AxonOps Console
```

### Network Issues

**Problem:** Cannot access CQL port (9042)
```bash
# Check firewall rules
terraform output
# Verify allowed_cidrs includes your IP

# Test connectivity
nc -zv <node-ip> 9042
```

**Problem:** Inter-node communication failing
```bash
# Verify private network
ssh root@<node-ip> "ip addr show"
# Should see 10.18.1.x address

# Check inter-node firewall
ssh root@<node-ip> "iptables -L -n"
```

## 📚 Additional Resources

- **AxonOps Documentation**: [docs.axonops.com](https://docs.axonops.com)
- **Cassandra Documentation**: [cassandra.apache.org](https://cassandra.apache.org/doc/latest/)
- **Hetzner Cloud Docs**: [docs.hetzner.com](https://docs.hetzner.com/)
- **Ansible Documentation**: [docs.ansible.com](https://docs.ansible.com/)
- **Terraform Documentation**: [terraform.io/docs](https://www.terraform.io/docs)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is provided as-is for educational and demonstration purposes.

## 🆘 Support

For issues or questions:
- **AxonOps Support**: support@axonops.com
- **GitHub Issues**: [Create an issue](https://github.com/your-repo/issues)

---

<div align="center">
  <p><strong>Built with ❤️ by the AxonOps team</strong></p>
  <p>
    <a href="https://axonops.com">Website</a> •
    <a href="https://docs.axonops.com">Documentation</a> •
    <a href="https://console.axonops.cloud">Console</a>
  </p>
</div>
