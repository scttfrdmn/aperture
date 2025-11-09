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

# ORCID OAuth Configuration
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
}

variable "cognito_callback_urls" {
  description = "Cognito OAuth callback URLs"
  type        = list(string)
  default     = []
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS configuration"
  type        = list(string)
  default     = ["*"]
}

# S3 Buckets
module "s3_buckets" {
  source = "./infrastructure/terraform/modules/s3"

  project_name = var.project_name
  environment  = var.environment

  enable_versioning = true
  enable_logging    = true

  cors_allowed_origins = var.cors_allowed_origins

  tags = {
    ManagedBy = "Terraform"
  }
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

# CloudFront Distribution
module "cloudfront" {
  source = "./infrastructure/terraform/modules/cloudfront"

  project_name = var.project_name
  environment  = var.environment

  # S3 bucket configuration
  public_media_bucket_id                   = module.s3_buckets.public_media_bucket_id
  public_media_bucket_arn                  = module.s3_buckets.public_media_bucket_arn
  public_media_bucket_regional_domain_name = module.s3_buckets.public_media_bucket_regional_domain_name

  frontend_bucket_id                   = module.s3_buckets.frontend_bucket_id
  frontend_bucket_arn                  = module.s3_buckets.frontend_bucket_arn
  frontend_bucket_regional_domain_name = module.s3_buckets.frontend_bucket_regional_domain_name

  logs_bucket_domain_name = module.s3_buckets.logs_bucket_domain_name

  # Cost optimization
  price_class = "PriceClass_100" # North America and Europe only

  tags = {
    ManagedBy = "Terraform"
  }
}

# Cognito User Pool with ORCID Federation
module "cognito" {
  source = "./infrastructure/terraform/modules/cognito"

  project_name = var.project_name
  environment  = var.environment

  # ORCID Configuration
  enable_orcid        = var.orcid_client_id != ""
  orcid_client_id     = var.orcid_client_id
  orcid_client_secret = var.orcid_client_secret
  orcid_environment   = var.orcid_environment

  # OAuth Configuration
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_callback_urls

  # Email Configuration
  from_email_address = var.budget_alert_email
  support_email      = var.budget_alert_email

  # Security (relaxed for sandbox, enforce in production)
  advanced_security_mode = var.environment == "prod" ? "ENFORCED" : "AUDIT"
  mfa_configuration      = "OPTIONAL"
  deletion_protection    = var.environment == "prod" ? true : false
}

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

# EventBridge Rules
module "eventbridge" {
  source = "./infrastructure/terraform/modules/eventbridge"

  project_name = var.project_name
  environment  = var.environment

  # S3 Configuration
  processing_bucket_name = module.s3_buckets.processing_bucket_name

  # DynamoDB Configuration
  doi_registry_table_name = module.dynamodb.doi_registry_table_name

  # Lambda Functions (will be added when Lambda module is created)
  # media_processing_lambda_arn = module.lambda_functions.media_processing_lambda_arn
  # lifecycle_lambda_arn        = module.lambda_functions.lifecycle_lambda_arn
  # budget_report_lambda_arn    = module.lambda_functions.budget_report_lambda_arn

  # Optional integrations (will be added in future modules)
  # alert_sns_topic_arn         = module.sns.alerts_topic_arn
  # dlq_arn                     = module.sqs.dlq_arn
  # publication_workflow_arn    = module.step_functions.publication_workflow_arn

  tags = {
    Component = "Event-Driven Workflows"
  }
}

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

# S3 Buckets
output "s3_public_media_bucket_id" {
  description = "Public media bucket ID"
  value       = module.s3_buckets.public_media_bucket_id
}

output "s3_private_media_bucket_id" {
  description = "Private media bucket ID"
  value       = module.s3_buckets.private_media_bucket_id
}

output "s3_restricted_media_bucket_id" {
  description = "Restricted media bucket ID"
  value       = module.s3_buckets.restricted_media_bucket_id
}

output "s3_embargoed_media_bucket_id" {
  description = "Embargoed media bucket ID"
  value       = module.s3_buckets.embargoed_media_bucket_id
}

output "s3_processing_bucket_id" {
  description = "Processing bucket ID"
  value       = module.s3_buckets.processing_bucket_id
}

output "s3_logs_bucket_id" {
  description = "Logs bucket ID"
  value       = module.s3_buckets.logs_bucket_id
}

output "s3_frontend_bucket_id" {
  description = "Frontend bucket ID"
  value       = module.s3_buckets.frontend_bucket_id
}

# DynamoDB Tables
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

# S3 Buckets
output "s3_public_media_bucket" {
  description = "S3 public media bucket name"
  value       = module.s3_buckets.public_media_bucket_name
}

output "s3_processing_bucket" {
  description = "S3 processing bucket name"
  value       = module.s3_buckets.processing_bucket_name
}

output "s3_frontend_bucket" {
  description = "S3 frontend bucket name"
  value       = module.s3_buckets.frontend_bucket_name
}

output "s3_logs_bucket" {
  description = "S3 logs bucket name"
  value       = module.s3_buckets.logs_bucket_name
}

# CloudFront Distributions
output "cloudfront_public_media_url" {
  description = "URL for accessing public media via CloudFront"
  value       = module.cloudfront.public_media_url
}

output "cloudfront_frontend_url" {
  description = "URL for accessing frontend application via CloudFront"
  value       = module.cloudfront.frontend_url
}

output "cloudfront_public_media_distribution_id" {
  description = "CloudFront distribution ID for public media"
  value       = module.cloudfront.public_media_distribution_id
}

output "cloudfront_frontend_distribution_id" {
  description = "CloudFront distribution ID for frontend"
  value       = module.cloudfront.frontend_distribution_id
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = module.cognito.user_pool_arn
}

output "cognito_web_app_client_id" {
  description = "Cognito Web App Client ID"
  value       = module.cognito.web_app_client_id
}

output "cognito_user_pool_domain" {
  description = "Cognito hosted UI domain"
  value       = module.cognito.user_pool_domain
}

output "cognito_oauth_authorize_url" {
  description = "OAuth authorization endpoint"
  value       = module.cognito.oauth_authorize_url
}

# EventBridge
output "eventbridge_event_bus_name" {
  description = "EventBridge custom event bus name"
  value       = module.eventbridge.event_bus_name
}

output "eventbridge_event_bus_arn" {
  description = "EventBridge custom event bus ARN"
  value       = module.eventbridge.event_bus_arn
}

output "eventbridge_summary" {
  description = "Summary of EventBridge resources"
  value       = module.eventbridge.summary
}

# output "api_endpoint" {
#   description = "API Gateway endpoint URL"
#   value       = module.api_gateway.api_endpoint
# }
#
# output "cognito_client_id" {
#   description = "Cognito App Client ID"
#   value       = module.cognito.app_client_id
# }
