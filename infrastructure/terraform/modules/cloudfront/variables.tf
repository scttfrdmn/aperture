# CloudFront Module Variables

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

#############################################
# S3 Bucket Configuration
#############################################

variable "public_media_bucket_id" {
  description = "ID of the public media S3 bucket"
  type        = string
}

variable "public_media_bucket_arn" {
  description = "ARN of the public media S3 bucket"
  type        = string
}

variable "public_media_bucket_regional_domain_name" {
  description = "Regional domain name of the public media S3 bucket"
  type        = string
}

variable "frontend_bucket_id" {
  description = "ID of the frontend S3 bucket"
  type        = string
}

variable "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  type        = string
}

variable "frontend_bucket_regional_domain_name" {
  description = "Regional domain name of the frontend S3 bucket"
  type        = string
}

variable "logs_bucket_domain_name" {
  description = "Domain name of the logs S3 bucket for CloudFront logging"
  type        = string
}

#############################################
# CloudFront Configuration
#############################################

variable "enable_ipv6" {
  description = "Enable IPv6 for CloudFront distributions"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "enable_origin_shield" {
  description = "Enable Origin Shield for additional caching layer"
  type        = bool
  default     = false
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version for viewers"
  type        = string
  default     = "TLSv1.2_2021"
  validation {
    condition     = contains(["TLSv1", "TLSv1.1_2016", "TLSv1.2_2018", "TLSv1.2_2019", "TLSv1.2_2021"], var.minimum_protocol_version)
    error_message = "Minimum protocol version must be a valid TLS version."
  }
}

#############################################
# Custom Domain Configuration
#############################################

variable "media_domain_name" {
  description = "Custom domain name for media distribution (e.g., media.example.com)"
  type        = string
  default     = ""
}

variable "frontend_domain_name" {
  description = "Custom domain name for frontend distribution (e.g., app.example.com)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate in us-east-1 for custom domains"
  type        = string
  default     = ""
}

#############################################
# Cache TTL Configuration
#############################################

variable "media_min_ttl" {
  description = "Minimum TTL for media files (seconds)"
  type        = number
  default     = 0
  validation {
    condition     = var.media_min_ttl >= 0
    error_message = "Media minimum TTL must be non-negative."
  }
}

variable "media_default_ttl" {
  description = "Default TTL for media files (seconds)"
  type        = number
  default     = 86400 # 1 day
  validation {
    condition     = var.media_default_ttl >= 0
    error_message = "Media default TTL must be non-negative."
  }
}

variable "media_max_ttl" {
  description = "Maximum TTL for media files (seconds)"
  type        = number
  default     = 31536000 # 1 year
  validation {
    condition     = var.media_max_ttl >= 0
    error_message = "Media maximum TTL must be non-negative."
  }
}

#############################################
# Geographic Restrictions
#############################################

variable "geo_restriction_type" {
  description = "Type of geographic restriction (none, whitelist, blacklist)"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "List of country codes for geographic restrictions (ISO 3166-1-alpha-2)"
  type        = list(string)
  default     = []
}

#############################################
# Tags
#############################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
