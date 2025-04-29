# Generate a UUID for the bucket name dynamically
resource "random_uuid" "s3_bucket_uuid" {}

# Create an S3 bucket with auto-generated UUID as the name
resource "aws_s3_bucket" "webapp_bucket" {
  bucket = random_uuid.s3_bucket_uuid.result
  # Allows Terraform to delete the bucket even if it's not empty
  force_destroy = true
}

# Ensure public access is blocked
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default encryption (cheapest option)
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      # sse_algorithm = "AES256"
      # Attach kms key for encryption
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

# Lifecycle policy to move objects to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    id     = "transition_to_IA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
