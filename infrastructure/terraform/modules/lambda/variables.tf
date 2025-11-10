# Lambda Module Variables

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
  description = "Cognito User Pool ID"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}

variable "cognito_app_client_id" {
  description = "Cognito App Client ID"
  type        = string
}

#############################################
# S3 Bucket Configuration
#############################################

variable "public_media_bucket_name" {
  description = "Name of the public media S3 bucket"
  type        = string
}

variable "public_media_bucket_arn" {
  description = "ARN of the public media S3 bucket"
  type        = string
}

variable "private_media_bucket_name" {
  description = "Name of the private media S3 bucket"
  type        = string
}

variable "private_media_bucket_arn" {
  description = "ARN of the private media S3 bucket"
  type        = string
}

variable "restricted_media_bucket_name" {
  description = "Name of the restricted media S3 bucket"
  type        = string
}

variable "restricted_media_bucket_arn" {
  description = "ARN of the restricted media S3 bucket"
  type        = string
}

variable "embargoed_media_bucket_name" {
  description = "Name of the embargoed media S3 bucket"
  type        = string
}

variable "embargoed_media_bucket_arn" {
  description = "ARN of the embargoed media S3 bucket"
  type        = string
}

#############################################
# DynamoDB Table Configuration
#############################################

variable "doi_registry_table_name" {
  description = "Name of the DOI registry DynamoDB table"
  type        = string
}

variable "doi_registry_table_arn" {
  description = "ARN of the DOI registry DynamoDB table"
  type        = string
}

variable "users_table_name" {
  description = "Name of the users DynamoDB table"
  type        = string
}

variable "users_table_arn" {
  description = "ARN of the users DynamoDB table"
  type        = string
}

variable "access_logs_table_name" {
  description = "Name of the access logs DynamoDB table"
  type        = string
}

variable "access_logs_table_arn" {
  description = "ARN of the access logs DynamoDB table"
  type        = string
}

variable "budget_tracking_table_name" {
  description = "Name of the budget tracking DynamoDB table"
  type        = string
}

variable "budget_tracking_table_arn" {
  description = "ARN of the budget tracking DynamoDB table"
  type        = string
}

#############################################
# DataCite Configuration
#############################################

variable "datacite_api_url" {
  description = "DataCite API URL"
  type        = string
  default     = "https://api.datacite.org/dois"
}

variable "datacite_username" {
  description = "DataCite API username"
  type        = string
  sensitive   = true
}

variable "datacite_password" {
  description = "DataCite API password"
  type        = string
  sensitive   = true
}

variable "doi_prefix" {
  description = "DOI prefix (e.g., 10.5555)"
  type        = string
}

variable "repo_base_url" {
  description = "Base URL for the repository (e.g., https://repo.university.edu)"
  type        = string
}

#############################################
# API Gateway Configuration
#############################################

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permissions"
  type        = string
  default     = ""
}

#############################################
# Lambda Configuration
#############################################

variable "log_retention_days" {
  description = "Number of days to retain Lambda logs in CloudWatch"
  type        = number
  default     = 90
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

#############################################
# Tags
#############################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
