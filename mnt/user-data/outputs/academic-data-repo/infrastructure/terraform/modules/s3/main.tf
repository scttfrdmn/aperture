# S3 Buckets Module for Academic Media Repository
# Implements intelligent tiering and lifecycle management

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

# Public Media Bucket (Published datasets with DOIs)
resource "aws_s3_bucket" "public_media" {
  bucket = "${var.project_name}-public-media-${var.environment}"
  
  tags = {
    Name        = "Public Media"
    Access      = "Public"
    ContentType = "Research Data"
  }
}

resource "aws_s3_bucket_versioning" "public_media" {
  bucket = aws_s3_bucket.public_media.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  # Rule 1: Intelligent Tiering for Original Media
  rule {
    id     = "intelligent-tiering-originals"
    status = "Enabled"
    
    filter {
      prefix = "datasets/"
      
      tag {
        key   = "FileType"
        value = "Original"
      }
    }
    
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }
    
    transition {
      days          = 1095  # 3 years
      storage_class = "DEEP_ARCHIVE"
    }
  }
  
  # Rule 2: Aggressive tiering for access/proxy files
  rule {
    id     = "aggressive-tiering-proxies"
    status = "Enabled"
    
    filter {
      prefix = "datasets/"
      
      tag {
        key   = "FileType"
        value = "Proxy"
      }
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }
  }
  
  # Rule 3: Keep previews hot for 30 days
  rule {
    id     = "preview-tiering"
    status = "Enabled"
    
    filter {
      prefix = "datasets/"
      
      tag {
        key   = "FileType"
        value = "Preview"
      }
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  
  # Rule 4: Cleanup incomplete multipart uploads
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  
  # Rule 5: Delete old noncurrent versions
  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER_IR"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront will access via OAI, not public access
resource "aws_s3_bucket_cors_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# Private Media Bucket (Pre-publication, researcher workspaces)
resource "aws_s3_bucket" "private_media" {
  bucket = "${var.project_name}-private-media-${var.environment}"
  
  tags = {
    Name        = "Private Media"
    Access      = "Private"
    ContentType = "Pre-publication Data"
  }
}

resource "aws_s3_bucket_versioning" "private_media" {
  bucket = aws_s3_bucket.private_media.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  # Aggressive tiering for private data
  rule {
    id     = "private-data-tiering"
    status = "Enabled"
    
    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }
  }
  
  # Auto-delete abandoned drafts after 2 years of no access
  rule {
    id     = "cleanup-abandoned-drafts"
    status = "Enabled"
    
    filter {
      tag {
        key   = "LastAccessed"
        value = "Stale"
      }
    }
    
    expiration {
      days = 730  # 2 years
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Restricted Media Bucket (Authenticated users only)
resource "aws_s3_bucket" "restricted_media" {
  bucket = "${var.project_name}-restricted-media-${var.environment}"
  
  tags = {
    Name        = "Restricted Media"
    Access      = "Authenticated"
    ContentType = "Restricted Research Data"
  }
}

resource "aws_s3_bucket_versioning" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  rule {
    id     = "restricted-data-tiering"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Embargoed Media Bucket (Time-locked datasets)
resource "aws_s3_bucket" "embargoed_media" {
  bucket = "${var.project_name}-embargoed-media-${var.environment}"
  
  tags = {
    Name        = "Embargoed Media"
    Access      = "Embargoed"
    ContentType = "Time-locked Research Data"
  }
}

resource "aws_s3_bucket_versioning" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  # Embargoed data goes straight to cheaper storage
  rule {
    id     = "embargoed-data-deep-archive"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "embargoed_media" {
  bucket = aws_s3_bucket.embargoed_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Frontend Bucket (Static website)
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"
  
  tags = {
    Name        = "Frontend"
    Access      = "Public"
    ContentType = "Static Website"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Processing Bucket (Thumbnails, proxies, transcriptions)
resource "aws_s3_bucket" "processing" {
  bucket = "${var.project_name}-processing-${var.environment}"
  
  tags = {
    Name        = "Processing Output"
    Access      = "Private"
    ContentType = "Generated Assets"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processing" {
  bucket = aws_s3_bucket.processing.id

  # Processing outputs are cheap to regenerate
  rule {
    id     = "processing-output-tiering"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    # Delete very old processing outputs (can be regenerated)
    expiration {
      days = 730  # 2 years
    }
  }
}

resource "aws_s3_bucket_public_access_block" "processing" {
  bucket = aws_s3_bucket.processing.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Access Logs Bucket
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.project_name}-access-logs-${var.environment}"
  
  tags = {
    Name        = "Access Logs"
    Access      = "Private"
    ContentType = "Logs"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "log-expiration"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
    
    expiration {
      days = 2555  # 7 years for compliance
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server access logging
resource "aws_s3_bucket_logging" "public_media" {
  bucket = aws_s3_bucket.public_media.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "public-media-logs/"
}

resource "aws_s3_bucket_logging" "private_media" {
  bucket = aws_s3_bucket.private_media.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "private-media-logs/"
}

resource "aws_s3_bucket_logging" "restricted_media" {
  bucket = aws_s3_bucket.restricted_media.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "restricted-media-logs/"
}

# Intelligent-Tiering configuration for cost optimization
resource "aws_s3_bucket_intelligent_tiering_configuration" "public_media" {
  bucket = aws_s3_bucket.public_media.id
  name   = "EntirePublicBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
  
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
}

# Outputs
output "public_media_bucket_id" {
  value = aws_s3_bucket.public_media.id
}

output "public_media_bucket_arn" {
  value = aws_s3_bucket.public_media.arn
}

output "private_media_bucket_id" {
  value = aws_s3_bucket.private_media.id
}

output "private_media_bucket_arn" {
  value = aws_s3_bucket.private_media.arn
}

output "restricted_media_bucket_id" {
  value = aws_s3_bucket.restricted_media.id
}

output "restricted_media_bucket_arn" {
  value = aws_s3_bucket.restricted_media.arn
}

output "embargoed_media_bucket_id" {
  value = aws_s3_bucket.embargoed_media.id
}

output "embargoed_media_bucket_arn" {
  value = aws_s3_bucket.embargoed_media.arn
}

output "frontend_bucket_id" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "processing_bucket_id" {
  value = aws_s3_bucket.processing.id
}

output "processing_bucket_arn" {
  value = aws_s3_bucket.processing.arn
}

output "access_logs_bucket_id" {
  value = aws_s3_bucket.access_logs.id
}

output "access_logs_bucket_arn" {
  value = aws_s3_bucket.access_logs.arn
}
