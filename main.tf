# Academic Media Repository - Main Terraform Configuration
# Provider: AWS
# Purpose: Complete serverless multimedia repository with FAIR principles

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Configure your backend
    # bucket = "your-terraform-state-bucket"
    # key    = "academic-repo/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Academic Media Repository"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "academic-media-repo"
}

variable "domain_name" {
  description = "Custom domain name for the repository"
  type        = string
  default     = "repo.university.edu"
}

variable "datacite_prefix" {
  description = "DataCite DOI prefix (e.g., 10.5555)"
  type        = string
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

variable "budget_alert_email" {
  description = "Email for budget alerts"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 500
}

# S3 Buckets
module "s3_buckets" {
  source = "./infrastructure/terraform/modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# DynamoDB Tables
module "dynamodb" {
  source = "./infrastructure/terraform/modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  billing_mode                  = "PAY_PER_REQUEST"
  enable_point_in_time_recovery = true
  enable_logs_ttl               = true
}

# CloudFront Distribution (TODO: Issue #3)
# module "cloudfront" {
#   source = "./infrastructure/terraform/modules/cloudfront"
#
#   project_name         = var.project_name
#   domain_name          = var.domain_name
#   frontend_bucket      = module.s3_buckets.frontend_bucket_id
#   public_media_bucket  = module.s3_buckets.public_media_bucket_id
# }

# Cognito User Pool with ORCID Federation (TODO: Issue #2)
# module "cognito" {
#   source = "./infrastructure/terraform/modules/cognito"
#
#   project_name = var.project_name
#   environment  = var.environment
#   domain_name  = var.domain_name
# }

# Lambda Functions (TODO: Issue #5-7)
# module "lambda_functions" {
#   source = "./infrastructure/terraform/modules/lambda"
#
#   project_name           = var.project_name
#   environment            = var.environment
#   cognito_user_pool_id   = module.cognito.user_pool_id
#   doi_registry_table     = module.dynamodb.doi_registry_table_name
#   users_table            = module.dynamodb.users_table_name
#   access_logs_table      = module.dynamodb.access_logs_table_name
#   budget_tracking_table  = module.dynamodb.budget_tracking_table_name
#   datacite_prefix        = var.datacite_prefix
#   datacite_username      = var.datacite_username
#   datacite_password      = var.datacite_password
#
#   # S3 bucket names
#   public_media_bucket    = module.s3_buckets.public_media_bucket_id
#   private_media_bucket   = module.s3_buckets.private_media_bucket_id
#   restricted_media_bucket = module.s3_buckets.restricted_media_bucket_id
#   embargoed_media_bucket = module.s3_buckets.embargoed_media_bucket_id
#   processing_bucket      = module.s3_buckets.processing_bucket_id
# }

# API Gateway (TODO: Future)
# module "api_gateway" {
#   source = "./infrastructure/terraform/modules/api-gateway"
#
#   project_name            = var.project_name
#   environment             = var.environment
#   cognito_user_pool_arn   = module.cognito.user_pool_arn
#
#   # Lambda function ARNs
#   auth_lambda_arn         = module.lambda_functions.auth_lambda_arn
#   doi_minting_lambda_arn  = module.lambda_functions.doi_minting_lambda_arn
#   presigned_url_lambda_arn = module.lambda_functions.presigned_url_lambda_arn
#   access_control_lambda_arn = module.lambda_functions.access_control_lambda_arn
#   bulk_upload_lambda_arn  = module.lambda_functions.bulk_upload_lambda_arn
#   oai_pmh_lambda_arn      = module.lambda_functions.oai_pmh_lambda_arn
#   extraction_lambda_arn   = module.lambda_functions.extraction_lambda_arn
#   metadata_query_lambda_arn = module.lambda_functions.metadata_query_lambda_arn
# }

# EventBridge Rules (TODO: Issue #4)
# module "eventbridge" {
#   source = "./infrastructure/terraform/modules/eventbridge"
#
#   project_name                    = var.project_name
#   environment                     = var.environment
#   media_processing_lambda_arn     = module.lambda_functions.media_processing_lambda_arn
#   lifecycle_management_lambda_arn = module.lambda_functions.lifecycle_management_lambda_arn
#   budget_alert_lambda_arn         = module.lambda_functions.budget_alert_lambda_arn
#
#   # S3 bucket ARNs for event notifications
#   public_media_bucket_arn    = module.s3_buckets.public_media_bucket_arn
#   private_media_bucket_arn   = module.s3_buckets.private_media_bucket_arn
# }

# Budget Alerts (TODO: Future)
# module "budgets" {
#   source = "./infrastructure/terraform/modules/budgets"
#
#   project_name          = var.project_name
#   monthly_budget_limit  = var.monthly_budget_limit
#   alert_email           = var.budget_alert_email
# }

# Athena for Log Analysis (TODO: Future)
# module "athena" {
#   source = "./infrastructure/terraform/modules/athena"
#
#   project_name     = var.project_name
#   access_logs_bucket = module.s3_buckets.access_logs_bucket_id
# }

# Outputs
output "dynamodb_users_table" {
  description = "DynamoDB users table name"
  value       = module.dynamodb.users_table_name
}

output "dynamodb_doi_registry_table" {
  description = "DynamoDB DOI registry table name"
  value       = module.dynamodb.doi_registry_table_name
}

output "dynamodb_access_logs_table" {
  description = "DynamoDB access logs table name"
  value       = module.dynamodb.access_logs_table_name
}

output "dynamodb_budget_tracking_table" {
  description = "DynamoDB budget tracking table name"
  value       = module.dynamodb.budget_tracking_table_name
}

# output "api_endpoint" {
#   description = "API Gateway endpoint URL"
#   value       = module.api_gateway.api_endpoint
# }
#
# output "cloudfront_domain" {
#   description = "CloudFront distribution domain"
#   value       = module.cloudfront.cloudfront_domain
# }
#
# output "cognito_user_pool_id" {
#   description = "Cognito User Pool ID"
#   value       = module.cognito.user_pool_id
# }
#
# output "cognito_client_id" {
#   description = "Cognito App Client ID"
#   value       = module.cognito.app_client_id
# }
