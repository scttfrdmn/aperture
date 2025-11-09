# S3 Module Variables

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

variable "enable_versioning" {
  description = "Enable versioning for media buckets (public, private, restricted, embargoed, frontend)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable access logging for all buckets (logs stored in logs bucket)"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for server-side encryption (leave empty for SSE-S3)"
  type        = string
  default     = ""
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS configuration"
  type        = list(string)
  default     = ["*"]
}

variable "processing_expiration_days" {
  description = "Number of days before objects in processing bucket expire"
  type        = number
  default     = 7
  validation {
    condition     = var.processing_expiration_days >= 1 && var.processing_expiration_days <= 365
    error_message = "Processing expiration days must be between 1 and 365."
  }
}

variable "logs_retention_days" {
  description = "Number of days to retain logs (compliance: 7 years = 2555 days)"
  type        = number
  default     = 2555
  validation {
    condition     = var.logs_retention_days >= 1
    error_message = "Logs retention days must be at least 1."
  }
}

variable "enable_static_website" {
  description = "Enable static website hosting for frontend bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
