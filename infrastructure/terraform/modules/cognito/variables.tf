# Cognito Module Variables
# Copyright 2025 Scott Friedman

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# Password Policy
variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 12
}

variable "password_require_lowercase" {
  description = "Require lowercase characters in password"
  type        = bool
  default     = true
}

variable "password_require_uppercase" {
  description = "Require uppercase characters in password"
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Require numbers in password"
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Require symbols in password"
  type        = bool
  default     = true
}

variable "temporary_password_validity_days" {
  description = "Number of days temporary password is valid"
  type        = number
  default     = 7
}

# MFA Configuration
variable "mfa_configuration" {
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "MFA configuration must be OFF, ON, or OPTIONAL."
  }
}

# Security
variable "advanced_security_mode" {
  description = "Advanced security mode (OFF, AUDIT, ENFORCED)"
  type        = string
  default     = "ENFORCED"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "Advanced security mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for user pool"
  type        = bool
  default     = true
}

# Email Configuration
variable "ses_email_identity" {
  description = "SES email identity ARN for sending emails (optional)"
  type        = string
  default     = null
}

variable "from_email_address" {
  description = "From email address for Cognito emails"
  type        = string
  default     = null
}

variable "reply_to_email_address" {
  description = "Reply-to email address"
  type        = string
  default     = null
}

variable "support_email" {
  description = "Support email address for user communications"
  type        = string
  default     = "support@example.com"
}

# Domain Configuration
variable "custom_domain" {
  description = "Custom domain for Cognito hosted UI (optional)"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = null
}

# ORCID Configuration
variable "enable_orcid" {
  description = "Enable ORCID identity provider"
  type        = bool
  default     = true
}

variable "orcid_client_id" {
  description = "ORCID OAuth client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "orcid_client_secret" {
  description = "ORCID OAuth client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "orcid_environment" {
  description = "ORCID environment (production or sandbox)"
  type        = string
  default     = "sandbox"

  validation {
    condition     = contains(["production", "sandbox"], var.orcid_environment)
    error_message = "ORCID environment must be production or sandbox."
  }
}

variable "orcid_scopes" {
  description = "ORCID OAuth scopes"
  type        = string
  default     = "openid email profile"
}

# App Client Configuration
variable "callback_urls" {
  description = "List of callback URLs for OAuth"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "List of logout URLs for OAuth"
  type        = list(string)
  default     = []
}

variable "id_token_validity" {
  description = "ID token validity in hours"
  type        = number
  default     = 1
}

variable "access_token_validity" {
  description = "Access token validity in hours"
  type        = number
  default     = 1
}

variable "refresh_token_validity" {
  description = "Refresh token validity in days"
  type        = number
  default     = 30
}

# API Client Configuration
variable "create_api_client" {
  description = "Create app client for API/CLI access"
  type        = bool
  default     = true
}

variable "api_client_scopes" {
  description = "OAuth scopes for API client"
  type        = list(string)
  default     = []
}

# Logging
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logging for Cognito events"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

# Risk Configuration
variable "enable_risk_configuration" {
  description = "Enable risk-based authentication"
  type        = bool
  default     = true
}

variable "compromised_credentials_action" {
  description = "Action to take on compromised credentials (BLOCK or NO_ACTION)"
  type        = string
  default     = "BLOCK"

  validation {
    condition     = contains(["BLOCK", "NO_ACTION"], var.compromised_credentials_action)
    error_message = "Compromised credentials action must be BLOCK or NO_ACTION."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
