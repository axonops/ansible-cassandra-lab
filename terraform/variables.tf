variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "lab"
}

variable "location" {
  description = "Hetzner Cloud location (e.g., nbg1, fsn1, hel1, ash, hil)"
  type        = string
  default     = "sin"
}

variable "server_type" {
  description = "Hetzner Cloud server type (e.g., cx22, cx32, cx42, ccx13, ccx23, ccx33)"
  type        = string
  default     = "cpx31"
}

variable "bastion_server_type" {
  description = "Hetzner Cloud server type (e.g., cx22, cx32, cx42, ccx13, ccx23, ccx33)"
  type        = string
  default     = "cpx11"
}

variable "disk_size" {
  description = "Size of data volume in GB per node"
  type        = number
  default     = 40
}

variable "image" {
  description = "OS image to use"
  type        = string
  default     = "ubuntu-24.04"
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access CQL and JMX ports"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "ssh_keys" {
  description = "List of existing SSH key names in Hetzner Cloud to attach to servers. Leave empty to auto-generate a new SSH key."
  type        = list(string)
  default     = []
}

variable "object_storage_region" {
  description = "Hetzner Object Storage region (fsn1, nbg1, hel1)"
  type        = string
  default     = "fsn1"
}

variable "object_storage_access_key" {
  description = "Hetzner Object Storage access key (can also be set via MINIO_ACCESS_KEY env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "object_storage_secret_key" {
  description = "Hetzner Object Storage secret key (can also be set via MINIO_SECRET_KEY env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_cidrs_cassandra" {
  description = "Additional CIDR blocks allowed to access CQL and JMX ports for Cassandra nodes"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
