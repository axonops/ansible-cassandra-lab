terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.3"
    }
  }
}

provider "hcloud" {
  # Set HCLOUD_TOKEN environment variable with your Hetzner Cloud API token
}

# MinIO provider configured for Hetzner Object Storage
# Requires Hetzner Object Storage credentials
provider "minio" {
  # Server endpoint format: {location}.your-objectstorage.com
  # Example: fsn1.your-objectstorage.com
  minio_server = "${var.object_storage_region}.your-objectstorage.com"

  # Set via environment variables or variables:
  # MINIO_ACCESS_KEY or var.object_storage_access_key
  # MINIO_SECRET_KEY or var.object_storage_secret_key
  minio_user     = var.object_storage_access_key
  minio_password = var.object_storage_secret_key

  # Region should match Hetzner location (fsn1, nbg1, hel1)
  minio_region = var.object_storage_region

  # SSL enabled for Hetzner Object Storage
  minio_ssl = true
}
