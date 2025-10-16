locals {
  name_prefix    = "cassandra-${var.location}-${var.environment}"
  create_ssh_key = length(var.ssh_keys) == 0

  # Determine which SSH keys to use
  ssh_key_ids        = local.create_ssh_key ? [hcloud_ssh_key.cassandra[0].id] : [for key in data.hcloud_ssh_key.existing : key.id]
  cassandra_node_ips = [for server in hcloud_server.cassandra : "${server.ipv4_address}/32"]
  cassandra_ports    = ["7000", "7001", "9042"]
}

# Generate SSH key for instances (only if no existing keys provided)
resource "tls_private_key" "ssh" {
  count = local.create_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create SSH key in Hetzner (only if no existing keys provided)
resource "hcloud_ssh_key" "cassandra" {
  count = local.create_ssh_key ? 1 : 0

  name       = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh[0].public_key_openssh
}

# Save private key locally (only if generated)
resource "local_file" "ssh_private_key" {
  count = local.create_ssh_key ? 1 : 0

  content         = tls_private_key.ssh[0].private_key_pem
  filename        = "${path.module}/ssh_key"
  file_permission = "0600"
}

# Data source to get existing SSH keys if provided
data "hcloud_ssh_key" "existing" {
  for_each = toset(var.ssh_keys)
  name     = each.value
}

# Bastion firewall - allows SSH from allowed CIDRs
resource "hcloud_firewall" "bastion" {
  name = "${local.name_prefix}-bastion-firewall"

  # SSH access from allowed CIDRs
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_cidrs
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.allowed_cidrs
  }
}

# Bastion instance
resource "hcloud_server" "bastion" {
  name         = "${local.name_prefix}-bastion"
  server_type  = var.bastion_server_type
  location     = var.location
  image        = var.image
  ssh_keys     = local.ssh_key_ids
  firewall_ids = [hcloud_firewall.bastion.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.sin_lab_net.id
    ip         = "10.18.1.250"
  }

  labels = {
    role        = "bastion"
    environment = var.environment
  }

  lifecycle {
    ignore_changes = [user_data, network, firewall_ids]
  }

  depends_on = [hcloud_network_subnet.sin_lab_subnet]
}

# Initial firewall for Cassandra cluster (without inter-node rules)
resource "hcloud_firewall" "cassandra" {
  name = "${local.name_prefix}-firewall"

  # SSH access - restricted to bastion only
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = concat(["${hcloud_server.bastion.ipv4_address}/32"], var.allowed_cidrs)
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.allowed_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22-9042"
    source_ips = ["10.18.0.0/16"]
  }
}

# Private network for internal communication
resource "hcloud_network" "sin_lab_net" {
  name     = "sin-lab-net"
  ip_range = "10.18.0.0/16"
}

# Subnet for the private network
resource "hcloud_network_subnet" "sin_lab_subnet" {
  network_id   = hcloud_network.sin_lab_net.id
  type         = "cloud"
  network_zone = "ap-southeast"
  ip_range     = "10.18.1.0/24"
}

# Placement groups to spread nodes across physical hosts (one per rack per DC)
resource "hcloud_placement_group" "cassandra_dc1_rack1" {
  name = "${local.name_prefix}-dc1-rack1-placement"
  type = "spread"
}

resource "hcloud_placement_group" "cassandra_dc1_rack2" {
  name = "${local.name_prefix}-dc1-rack2-placement"
  type = "spread"
}

resource "hcloud_placement_group" "cassandra_dc1_rack3" {
  name = "${local.name_prefix}-dc1-rack3-placement"
  type = "spread"
}

resource "hcloud_placement_group" "cassandra_dc2_rack1" {
  name = "${local.name_prefix}-dc2-rack1-placement"
  type = "spread"
}

resource "hcloud_placement_group" "cassandra_dc2_rack2" {
  name = "${local.name_prefix}-dc2-rack2-placement"
  type = "spread"
}

resource "hcloud_placement_group" "cassandra_dc2_rack3" {
  name = "${local.name_prefix}-dc2-rack3-placement"
  type = "spread"
}

# resource "hcloud_volume" "cassandra" {
#   count = 3

#   name     = "${local.name_prefix}-volume-${format("%03d", count.index + 1)}"
#   size     = var.disk_size
#   location = var.location
#   format   = "ext4"
# }

# resource "hcloud_volume_attachment" "cassandra" {
#   count = 3

#   volume_id = hcloud_volume.cassandra[count.index].id
#   server_id = hcloud_server.cassandra[count.index].id
#   automount = true
# }

# Cassandra cluster nodes - 12 nodes across 2 DCs with 3 racks each
resource "hcloud_server" "cassandra" {
  count = 12

  name               = "${local.name_prefix}-${format("%03d", count.index + 1)}"
  server_type        = var.server_type
  location           = var.location
  image              = var.image
  ssh_keys           = local.ssh_key_ids
  firewall_ids       = [hcloud_firewall.cassandra.id]

  # Assign placement group based on DC and rack
  # DC1: nodes 0-5, DC2: nodes 6-11
  # Each rack gets 2 nodes (rack1: 0,1 & 6,7, rack2: 2,3 & 8,9, rack3: 4,5 & 10,11)
  placement_group_id = count.index < 6 ? (
    count.index < 2 ? hcloud_placement_group.cassandra_dc1_rack1.id :
    count.index < 4 ? hcloud_placement_group.cassandra_dc1_rack2.id :
    hcloud_placement_group.cassandra_dc1_rack3.id
  ) : (
    count.index < 8 ? hcloud_placement_group.cassandra_dc2_rack1.id :
    count.index < 10 ? hcloud_placement_group.cassandra_dc2_rack2.id :
    hcloud_placement_group.cassandra_dc2_rack3.id
  )

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.sin_lab_net.id
  }

  labels = {
    role           = "cassandra"
    environment    = var.environment
    node_number    = count.index + 1
    cassandra_dc   = count.index < 6 ? "dc1" : "dc2"
    cassandra_rack = (count.index < 2 || (count.index >= 6 && count.index < 8)) ? "rack1" : ((count.index < 4 || (count.index >= 8 && count.index < 10)) ? "rack2" : "rack3")
  }

  lifecycle {
    ignore_changes = [user_data, network, firewall_ids]
  }

  depends_on = [hcloud_network_subnet.sin_lab_subnet]
}

resource "hcloud_firewall" "cassandra_internode" {
  name = "${local.name_prefix}-internode-firewall"


  dynamic "rule" {
    for_each = local.cassandra_ports
    content {
      direction = "in"
      protocol  = "tcp"
      port      = rule.value
      # Use the local variable containing all Cassandra node IPs
      source_ips = local.cassandra_node_ips
    }
  }
}

# Attach inter-node firewall to servers
resource "hcloud_firewall_attachment" "cassandra_internode" {
  firewall_id = hcloud_firewall.cassandra_internode.id
  server_ids  = [for server in hcloud_server.cassandra : server.id]

  depends_on = [ hcloud_firewall.cassandra ]
}
