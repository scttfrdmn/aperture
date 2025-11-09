# S3 Buckets Module
# Provides storage infrastructure for the Aperture platform with 7 purpose-specific buckets

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  bucket_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Module      = "s3"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

#############################################
# 1. Public Media Bucket
#############################################

resource "aws_s3_bucket" "public_media" {
  bucket = "${local.bucket_prefix}-public-media"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-public-media"
      Purpose = "Public datasets with DOIs"
    }
  )
}

resource "aws_s3_bucket_versioning" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "public_media" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.public_media.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "public-media/"
}

resource "aws_s3_bucket_cors_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id
  name   = "EntirePublicMediaBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

#############################################
# 2. Private Media Bucket
#############################################

resource "aws_s3_bucket" "private_media" {
  bucket = "${local.bucket_prefix}-private-media"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-private-media"
      Purpose = "Private/restricted access datasets"
    }
  )
}

resource "aws_s3_bucket_versioning" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "private_media" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.private_media.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "private-media/"
}

resource "aws_s3_bucket_cors_configuration" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "private_media" {
  bucket = aws_s3_bucket.private_media.id
  name   = "EntirePrivateMediaBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

#############################################
# 3. Restricted Media Bucket
#############################################

resource "aws_s3_bucket" "restricted_media" {
  bucket = "${local.bucket_prefix}-restricted-media"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-restricted-media"
      Purpose = "Datasets with access control requirements"
    }
  )
}

resource "aws_s3_bucket_versioning" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "restricted_media" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.restricted_media.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "restricted-media/"
}

resource "aws_s3_bucket_cors_configuration" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id
  name   = "EntireRestrictedMediaBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

#############################################
# 4. Embargoed Media Bucket
#############################################

resource "aws_s3_bucket" "embargoed_media" {
  bucket = "${local.bucket_prefix}-embargoed-media"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-embargoed-media"
      Purpose = "Datasets under embargo"
    }
  )
}

resource "aws_s3_bucket_versioning" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "embargoed_media" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.embargoed_media.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "embargoed-media/"
}

resource "aws_s3_bucket_cors_configuration" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id
  name   = "EntireEmbargoedMediaBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

#############################################
# 5. Processing Bucket
#############################################

resource "aws_s3_bucket" "processing" {
  bucket = "${local.bucket_prefix}-processing"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-processing"
      Purpose = "Temporary media processing"
    }
  )
}

# No versioning for processing bucket (temporary files)

resource "aws_s3_bucket_server_side_encryption_configuration" "processing" {
  bucket = aws_s3_bucket.processing.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "processing" {
  bucket = aws_s3_bucket.processing.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "processing" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.processing.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "processing/"
}

resource "aws_s3_bucket_lifecycle_configuration" "processing" {
  bucket = aws_s3_bucket.processing.id

  rule {
    id     = "cleanup-temporary-files"
    status = "Enabled"

    filter {}

    expiration {
      days = var.processing_expiration_days
    }
  }
}

#############################################
# 6. Logs Bucket
#############################################

resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket_prefix}-logs"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-logs"
      Purpose = "S3 access logs and CloudTrail logs"
    }
  )
}

# No versioning for logs bucket

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.logs_retention_days
    }
  }
}

# Allow S3 to write access logs
resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

#############################################
# 7. Frontend Bucket
#############################################

resource "aws_s3_bucket" "frontend" {
  bucket = "${local.bucket_prefix}-frontend"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_prefix}-frontend"
      Purpose = "React application hosting"
    }
  )
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "frontend" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.frontend.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "frontend/"
}

resource "aws_s3_bucket_cors_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Website configuration for frontend bucket (optional)
resource "aws_s3_bucket_website_configuration" "frontend" {
  count = var.enable_static_website ? 1 : 0

  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
