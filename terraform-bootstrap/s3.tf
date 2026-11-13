resource "aws_s3_bucket" "state_storage" {
  bucket = "terraform-state-storage-2026"

  tags = {
    Name        = "Terraform State Storage"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.state_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.state_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}