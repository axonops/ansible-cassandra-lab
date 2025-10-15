# Private key location (only if generated)
output "ssh_key_path" {
  description = "Path to the generated SSH private key (only if auto-generated)"
  value       = local.create_ssh_key ? local_file.ssh_private_key[0].filename : "Using existing SSH keys: ${join(", ", var.ssh_keys)}"
}

# Ansible inventory snippet
output "ansible_inventory" {
  description = "Ansible inventory snippet for the cluster"
  value       = <<-EOT
[bastion]
${hcloud_server.bastion.ipv4_address} ansible_host=${hcloud_server.bastion.ipv4_address} ansible_user=root

[${var.environment}]
${join("\n", [for idx, server in hcloud_server.cassandra : "${server.ipv4_address} cassandra_rack=${server.labels.cassandra_rack} cassandra_dc=${server.labels.cassandra_dc} ansible_hostname=cassandra-node-${idx + 1}"])}

[cassandra:children]
${var.environment}

[all:vars]
ansible_user=root
${local.create_ssh_key ? "ansible_ssh_private_key_file=${local_file.ssh_private_key[0].filename}" : "# Using existing SSH keys configured in Hetzner"}
cassandra_seeds=${join(",", slice(tolist(flatten(hcloud_server.cassandra[*].network)[*].ip), 0, 2))}
  EOT
}

resource "local_file" "inventory" {
  content  = <<-EOT
[bastion]
${hcloud_server.bastion.ipv4_address} ansible_host=${hcloud_server.bastion.ipv4_address} ansible_user=root

[${var.environment}]
${join("\n", [for idx, server in hcloud_server.cassandra : "${server.ipv4_address} cassandra_rack=${server.labels.cassandra_rack} cassandra_dc=${server.labels.cassandra_dc} ansible_hostname=cassandra-node-${idx + 1}"])}

[cassandra:children]
${var.environment}

[all:vars]
ansible_user=root
${local.create_ssh_key ? "ansible_ssh_private_key_file=${local_file.ssh_private_key[0].filename}" : "# Using existing SSH keys configured in Hetzner"}
cassandra_seeds=${join(",", slice(tolist(flatten(hcloud_server.cassandra[*].network)[*].ip), 0, 2))}
  EOT
  filename = "../ansible/inventories/lab/hosts.ini"
}