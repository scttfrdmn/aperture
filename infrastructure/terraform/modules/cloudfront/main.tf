# CloudFront CDN Module
# Provides content delivery network for Aperture platform with optimized caching

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
  common_tags = merge(
    var.tags,
    {
      Module      = "cloudfront"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

#############################################
# Origin Access Control for S3
#############################################

# OAC for Public Media Bucket
resource "aws_cloudfront_origin_access_control" "public_media" {
  name                              = "${var.project_name}-${var.environment}-public-media-oac"
  description                       = "Origin Access Control for public media bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# OAC for Frontend Bucket
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-${var.environment}-frontend-oac"
  description                       = "Origin Access Control for frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#############################################
# CloudFront Distribution for Public Media
#############################################

resource "aws_cloudfront_distribution" "public_media" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = "CDN for ${var.project_name} public media (${var.environment})"
  default_root_object = ""
  price_class         = var.price_class
  aliases             = var.media_domain_name != "" ? [var.media_domain_name] : []

  origin {
    domain_name              = var.public_media_bucket_regional_domain_name
    origin_id                = "S3-${var.public_media_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.public_media.id

    origin_shield {
      enabled              = var.enable_origin_shield
      origin_shield_region = var.enable_origin_shield ? data.aws_region.current.name : null
    }
  }

  # Default cache behavior for media files
  default_cache_behavior {
    target_origin_id       = "S3-${var.public_media_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.media_min_ttl
    default_ttl = var.media_default_ttl
    max_ttl     = var.media_max_ttl
  }

  # Cache behavior for large media files (videos, high-res images)
  ordered_cache_behavior {
    path_pattern           = "*.mp4"
    target_origin_id       = "S3-${var.public_media_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false # Don't compress video files

    forwarded_values {
      query_string = false
      headers      = ["Range"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400    # 1 day
    default_ttl = 604800   # 7 days
    max_ttl     = 31536000 # 1 year
  }

  ordered_cache_behavior {
    path_pattern           = "*.mov"
    target_origin_id       = "S3-${var.public_media_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    forwarded_values {
      query_string = false
      headers      = ["Range"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  ordered_cache_behavior {
    path_pattern           = "*.avi"
    target_origin_id       = "S3-${var.public_media_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    forwarded_values {
      query_string = false
      headers      = ["Range"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  # Cache behavior for thumbnails and processed media
  ordered_cache_behavior {
    path_pattern           = "*/thumbnails/*"
    target_origin_id       = "S3-${var.public_media_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400    # 1 day
    default_ttl = 2592000  # 30 days
    max_ttl     = 31536000 # 1 year
  }

  # Cache behavior for metadata JSON files
  ordered_cache_behavior {
    path_pattern           = "*.json"
    target_origin_id       = "S3-${var.public_media_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600  # 1 hour
    max_ttl     = 86400 # 1 day
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.media_domain_name == "" ? true : false
    acm_certificate_arn            = var.media_domain_name != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.media_domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  logging_config {
    bucket          = var.logs_bucket_domain_name
    prefix          = "cloudfront/media/"
    include_cookies = false
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-public-media-cdn"
      Purpose = "Public media content delivery"
    }
  )
}

#############################################
# CloudFront Distribution for Frontend
#############################################

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = "CDN for ${var.project_name} frontend (${var.environment})"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.frontend_domain_name != "" ? [var.frontend_domain_name] : []

  origin {
    domain_name              = var.frontend_bucket_regional_domain_name
    origin_id                = "S3-${var.frontend_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id

    origin_shield {
      enabled              = var.enable_origin_shield
      origin_shield_region = var.enable_origin_shield ? data.aws_region.current.name : null
    }
  }

  # Default cache behavior for SPA
  default_cache_behavior {
    target_origin_id       = "S3-${var.frontend_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600  # 1 hour
    max_ttl     = 86400 # 1 day
  }

  # Cache behavior for static assets (JS, CSS, fonts)
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "S3-${var.frontend_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400    # 1 day
    default_ttl = 604800   # 7 days
    max_ttl     = 31536000 # 1 year
  }

  # Cache behavior for assets with hash in filename
  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    target_origin_id       = "S3-${var.frontend_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400    # 1 day
    default_ttl = 2592000  # 30 days
    max_ttl     = 31536000 # 1 year
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.frontend_domain_name == "" ? true : false
    acm_certificate_arn            = var.frontend_domain_name != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.frontend_domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  logging_config {
    bucket          = var.logs_bucket_domain_name
    prefix          = "cloudfront/frontend/"
    include_cookies = false
  }

  # SPA routing support - return index.html for 404s
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-frontend-cdn"
      Purpose = "Frontend application delivery"
    }
  )
}

#############################################
# S3 Bucket Policies for CloudFront OAC
#############################################

# Allow CloudFront to access public media bucket
resource "aws_s3_bucket_policy" "public_media_cloudfront" {
  bucket = var.public_media_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.public_media_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.public_media.arn
          }
        }
      }
    ]
  })
}

# Allow CloudFront to access frontend bucket
resource "aws_s3_bucket_policy" "frontend_cloudfront" {
  bucket = var.frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.frontend_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}
