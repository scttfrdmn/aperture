# API Gateway Module Variables

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
# Cognito Configuration
#############################################

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for JWT authorizer"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}

variable "cognito_app_client_id" {
  description = "Cognito App Client ID for JWT audience"
  type        = string
}

#############################################
# Lambda Configuration
#############################################

variable "auth_lambda_name" {
  description = "Name of the auth Lambda function"
  type        = string
}

variable "auth_lambda_arn" {
  description = "ARN of the auth Lambda function"
  type        = string
}

variable "auth_lambda_invoke_arn" {
  description = "Invoke ARN of the auth Lambda function"
  type        = string
}

variable "presigned_urls_lambda_name" {
  description = "Name of the presigned URLs Lambda function"
  type        = string
}

variable "presigned_urls_lambda_arn" {
  description = "ARN of the presigned URLs Lambda function"
  type        = string
}

variable "presigned_urls_lambda_invoke_arn" {
  description = "Invoke ARN of the presigned URLs Lambda function"
  type        = string
}

variable "doi_minting_lambda_name" {
  description = "Name of the DOI minting Lambda function"
  type        = string
}

variable "doi_minting_lambda_arn" {
  description = "ARN of the DOI minting Lambda function"
  type        = string
}

variable "doi_minting_lambda_invoke_arn" {
  description = "Invoke ARN of the DOI minting Lambda function"
  type        = string
}

#############################################
# CORS Configuration
#############################################

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS configuration"
  type        = list(string)
  default     = ["*"]
}

#############################################
# Throttling Configuration
#############################################

variable "throttling_burst_limit" {
  description = "API Gateway throttling burst limit (requests)"
  type        = number
  default     = 500
  validation {
    condition     = var.throttling_burst_limit >= 0 && var.throttling_burst_limit <= 5000
    error_message = "Throttling burst limit must be between 0 and 5000."
  }
}

variable "throttling_rate_limit" {
  description = "API Gateway throttling rate limit (requests per second)"
  type        = number
  default     = 1000
  validation {
    condition     = var.throttling_rate_limit >= 0 && var.throttling_rate_limit <= 10000
    error_message = "Throttling rate limit must be between 0 and 10000."
  }
}

#############################################
# Logging Configuration
#############################################

variable "log_retention_days" {
  description = "Number of days to retain API Gateway logs in CloudWatch"
  type        = number
  default     = 90
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

#############################################
# Custom Domain Configuration (Optional)
#############################################

variable "custom_domain_name" {
  description = "Custom domain name for API Gateway (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain (required if custom_domain_name is set)"
  type        = string
  default     = ""
}

#############################################
# Tags
#############################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
