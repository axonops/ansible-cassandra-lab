# S3 buckets using MinIO provider for Hetzner Object Storage
resource "minio_s3_bucket" "backups" {
  bucket        = "${local.name_prefix}-backups"
  force_destroy = true
  acl           = "private"
}

// access the bucket using
// ${minio_s3_bucket.backups.name}.hel1.your-objectstorage.com
