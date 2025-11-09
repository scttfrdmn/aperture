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
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
}

# CloudFront Distribution
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name         = var.project_name
  domain_name          = var.domain_name
  frontend_bucket      = module.s3_buckets.frontend_bucket_id
  public_media_bucket  = module.s3_buckets.public_media_bucket_id
}

# Cognito User Pool with ORCID Federation
module "cognito" {
  source = "./modules/cognito"
  
  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
}

# DynamoDB Tables
module "dynamodb" {
  source = "./modules/dynamodb"
  
  project_name = var.project_name
  environment  = var.environment
}

# Lambda Functions
module "lambda_functions" {
  source = "./modules/lambda"
  
  project_name           = var.project_name
  environment            = var.environment
  cognito_user_pool_id   = module.cognito.user_pool_id
  doi_registry_table     = module.dynamodb.doi_registry_table_name
  users_table            = module.dynamodb.users_table_name
  access_logs_table      = module.dynamodb.access_logs_table_name
  budget_tracking_table  = module.dynamodb.budget_tracking_table_name
  datacite_prefix        = var.datacite_prefix
  datacite_username      = var.datacite_username
  datacite_password      = var.datacite_password
  
  # S3 bucket names
  public_media_bucket    = module.s3_buckets.public_media_bucket_id
  private_media_bucket   = module.s3_buckets.private_media_bucket_id
  restricted_media_bucket = module.s3_buckets.restricted_media_bucket_id
  embargoed_media_bucket = module.s3_buckets.embargoed_media_bucket_id
  processing_bucket      = module.s3_buckets.processing_bucket_id
}

# API Gateway
module "api_gateway" {
  source = "./modules/api-gateway"
  
  project_name            = var.project_name
  environment             = var.environment
  cognito_user_pool_arn   = module.cognito.user_pool_arn
  
  # Lambda function ARNs
  auth_lambda_arn         = module.lambda_functions.auth_lambda_arn
  doi_minting_lambda_arn  = module.lambda_functions.doi_minting_lambda_arn
  presigned_url_lambda_arn = module.lambda_functions.presigned_url_lambda_arn
  access_control_lambda_arn = module.lambda_functions.access_control_lambda_arn
  bulk_upload_lambda_arn  = module.lambda_functions.bulk_upload_lambda_arn
  oai_pmh_lambda_arn      = module.lambda_functions.oai_pmh_lambda_arn
  extraction_lambda_arn   = module.lambda_functions.extraction_lambda_arn
  metadata_query_lambda_arn = module.lambda_functions.metadata_query_lambda_arn
}

# EventBridge Rules
module "eventbridge" {
  source = "./modules/eventbridge"
  
  project_name                    = var.project_name
  environment                     = var.environment
  media_processing_lambda_arn     = module.lambda_functions.media_processing_lambda_arn
  lifecycle_management_lambda_arn = module.lambda_functions.lifecycle_management_lambda_arn
  budget_alert_lambda_arn         = module.lambda_functions.budget_alert_lambda_arn
  
  # S3 bucket ARNs for event notifications
  public_media_bucket_arn    = module.s3_buckets.public_media_bucket_arn
  private_media_bucket_arn   = module.s3_buckets.private_media_bucket_arn
}

# Budget Alerts
module "budgets" {
  source = "./modules/budgets"
  
  project_name          = var.project_name
  monthly_budget_limit  = var.monthly_budget_limit
  alert_email           = var.budget_alert_email
}

# Athena for Log Analysis
module "athena" {
  source = "./modules/athena"
  
  project_name     = var.project_name
  access_logs_bucket = module.s3_buckets.access_logs_bucket_id
}

# Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cloudfront.cloudfront_domain
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.app_client_id
}
