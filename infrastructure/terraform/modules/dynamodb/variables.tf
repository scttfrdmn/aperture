# DynamoDB Module Variables
# Copyright 2025 Scott Friedman

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for tables"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for provisioned tables"
  type        = bool
  default     = true
}

variable "autoscaling_target_value" {
  description = "Target utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "enable_logs_ttl" {
  description = "Enable TTL for access logs table"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (optional)"
  type        = string
  default     = null
}

# Users table capacity settings
variable "users_read_capacity" {
  description = "Read capacity units for users table (PROVISIONED mode only)"
  type        = number
  default     = 5
}

variable "users_write_capacity" {
  description = "Write capacity units for users table (PROVISIONED mode only)"
  type        = number
  default     = 5
}

variable "users_read_max_capacity" {
  description = "Maximum read capacity for auto-scaling (PROVISIONED mode only)"
  type        = number
  default     = 100
}

variable "users_write_max_capacity" {
  description = "Maximum write capacity for auto-scaling (PROVISIONED mode only)"
  type        = number
  default     = 100
}

# DOI registry table capacity settings
variable "doi_read_capacity" {
  description = "Read capacity units for DOI registry table (PROVISIONED mode only)"
  type        = number
  default     = 5
}

variable "doi_write_capacity" {
  description = "Write capacity units for DOI registry table (PROVISIONED mode only)"
  type        = number
  default     = 5
}

# Access logs table capacity settings
variable "logs_read_capacity" {
  description = "Read capacity units for access logs table (PROVISIONED mode only)"
  type        = number
  default     = 5
}

variable "logs_write_capacity" {
  description = "Write capacity units for access logs table (PROVISIONED mode only)"
  type        = number
  default     = 10
}

# Budget tracking table capacity settings
variable "budget_read_capacity" {
  description = "Read capacity units for budget table (PROVISIONED mode only)"
  type        = number
  default     = 2
}

variable "budget_write_capacity" {
  description = "Write capacity units for budget table (PROVISIONED mode only)"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
