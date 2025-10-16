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
cassandra_seeds=${join(",", concat(
  slice([for s in hcloud_server.cassandra : tolist(s.network)[0].ip if s.labels.cassandra_dc == "dc1"], 0, 2),
  slice([for s in hcloud_server.cassandra : tolist(s.network)[0].ip if s.labels.cassandra_dc == "dc2"], 0, 2)
))}
  EOT
}

resource "local_file" "inventory" {
  filename = "../ansible/inventories/lab/hosts.ini"
  content  = <<-EOT
[bastion]
${hcloud_server.bastion.ipv4_address} ansible_host=${hcloud_server.bastion.ipv4_address} ansible_user=root

[${var.environment}]
${join("\n", [for idx, server in hcloud_server.cassandra : "${server.ipv4_address} cassandra_rack=${server.labels.cassandra_rack} cassandra_dc=${server.labels.cassandra_dc} ansible_hostname=cassandra-node-${idx + 1}"])}

[cassandra-rack1]
${join("\n", [for idx, s in hcloud_server.cassandra : "${s.ipv4_address} cassandra_rack=${s.labels.cassandra_rack} cassandra_dc=${s.labels.cassandra_dc} ansible_hostname=cassandra-node-${idx + 1}" if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack1"])}

[cassandra-rack2]
${join("\n", [for idx, s in hcloud_server.cassandra : "${s.ipv4_address} cassandra_rack=${s.labels.cassandra_rack} cassandra_dc=${s.labels.cassandra_dc} ansible_hostname=cassandra-node-${idx + 1}" if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack2"])}

[cassandra-rack3]
${join("\n", [for idx, s in hcloud_server.cassandra : "${s.ipv4_address} cassandra_rack=${s.labels.cassandra_rack} cassandra_dc=${s.labels.cassandra_dc} ansible_hostname=cassandra-node-${idx + 1}" if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack3"])}

[cassandra:children]
cassandra-rack1
cassandra-rack2
cassandra-rack3

[seeds-dc1-rack1]
${join("\n", slice([for idx, s in hcloud_server.cassandra : s.ipv4_address if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack1"], 0, 1))}

[seeds-dc1-rack2]
${join("\n", slice([for idx, s in hcloud_server.cassandra : s.ipv4_address if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack2"], 0, 1))}

[seeds-dc2-rack1]
${join("\n", slice([for idx, s in hcloud_server.cassandra : s.ipv4_address if s.labels.cassandra_dc == "dc2" && s.labels.cassandra_rack == "rack1"], 0, 1))}

[seeds-dc2-rack2]
${join("\n", slice([for idx, s in hcloud_server.cassandra : s.ipv4_address if s.labels.cassandra_dc == "dc2" && s.labels.cassandra_rack == "rack2"], 0, 1))}

[seeds:children]
seeds-dc2-rack1
seeds-dc2-rack2
seeds-dc1-rack1
seeds-dc1-rack2

[all:vars]
ansible_user=root
${local.create_ssh_key ? "ansible_ssh_private_key_file=${local_file.ssh_private_key[0].filename}" : ""}
cassandra_seeds=${join(",", concat(
  slice([for s in hcloud_server.cassandra : tolist(s.network)[0].ip if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack1"], 0, 1),
  slice([for s in hcloud_server.cassandra : tolist(s.network)[0].ip if s.labels.cassandra_dc == "dc2" && s.labels.cassandra_rack == "rack1"], 0, 1),
  slice([for s in hcloud_server.cassandra : tolist(s.network)[0].ip if s.labels.cassandra_dc == "dc1" && s.labels.cassandra_rack == "rack2"], 0, 1),
  slice([for s in hcloud_server.cassandra : tolist(s.network)[0].ip if s.labels.cassandra_dc == "dc2" && s.labels.cassandra_rack == "rack2"], 0, 1)
))}
  EOT
}