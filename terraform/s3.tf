resource "aws_s3_bucket" "bucket_orlando_photos" {
  bucket = "bucket-orlando-photos"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "photos" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id
  key    = "/photos/IMG-2285.jpg"
  source = "/home/orlando/aws_devops_project/Photos_appart/IMG-2285.jpg"
  etag   = filemd5("/home/orlando/aws_devops_project/Photos_appart/IMG-2285.jpg")
}

resource "aws_s3_bucket_policy" "https_only" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id
  policy = data.aws_iam_policy_document.https_only.json
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "https_only" {
  statement {
    sid    = "EnforceHTTPSOnly"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]

    }
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.bucket_orlando_photos.arn,
      "${aws_s3_bucket.bucket_orlando_photos.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.bucket_orlando_photos.id

  depends_on = [aws_s3_bucket_versioning.versioning]

  rule {
    id = "photos"

    filter {
      prefix = "lifecycle/"
    }

    expiration {
      days = 365
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

}