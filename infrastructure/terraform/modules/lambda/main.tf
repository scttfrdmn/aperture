# Lambda Module
# Provides Lambda functions for the Aperture platform

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "lambda"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
    }
  )

  lambda_runtime = "python3.11"
  lambda_timeout = 30
  lambda_memory  = 256
}

#############################################
# Lambda Execution Roles
#############################################

# Auth Lambda Role
resource "aws_iam_role" "auth_lambda" {
  name = "${var.project_name}-${var.environment}-auth-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-auth-lambda-role"
      Function = "authentication"
    }
  )
}

# Auth Lambda Policy
resource "aws_iam_role_policy" "auth_lambda" {
  name = "${var.project_name}-${var.environment}-auth-lambda-policy"
  role = aws_iam_role.auth_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:InitiateAuth",
          "cognito-idp:GetUser",
          "cognito-idp:GlobalSignOut"
        ]
        Resource = var.cognito_user_pool_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-auth:*"
      }
    ]
  })
}

# Presigned URLs Lambda Role
resource "aws_iam_role" "presigned_urls_lambda" {
  name = "${var.project_name}-${var.environment}-presigned-urls-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-presigned-urls-lambda-role"
      Function = "presigned-urls"
    }
  )
}

# Presigned URLs Lambda Policy
resource "aws_iam_role_policy" "presigned_urls_lambda" {
  name = "${var.project_name}-${var.environment}-presigned-urls-lambda-policy"
  role = aws_iam_role.presigned_urls_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${var.public_media_bucket_arn}/*",
          "${var.private_media_bucket_arn}/*",
          "${var.restricted_media_bucket_arn}/*",
          "${var.embargoed_media_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.access_logs_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          var.doi_registry_table_arn,
          "${var.doi_registry_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-presigned-urls:*"
      }
    ]
  })
}

# DOI Minting Lambda Role
resource "aws_iam_role" "doi_minting_lambda" {
  name = "${var.project_name}-${var.environment}-doi-minting-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-doi-minting-lambda-role"
      Function = "doi-minting"
    }
  )
}

# DOI Minting Lambda Policy
resource "aws_iam_role_policy" "doi_minting_lambda" {
  name = "${var.project_name}-${var.environment}-doi-minting-lambda-policy"
  role = aws_iam_role.doi_minting_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          var.doi_registry_table_arn,
          "${var.doi_registry_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${var.public_media_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-doi-minting:*"
      }
    ]
  })
}

#############################################
# Package Lambda Functions
#############################################

# Auth Lambda Package
data "archive_file" "auth_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/auth"
  output_path = "${path.module}/packages/auth.zip"
}

# Presigned URLs Lambda Package
data "archive_file" "presigned_urls_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/presigned-urls"
  output_path = "${path.module}/packages/presigned-urls.zip"
}

# DOI Minting Lambda Package
data "archive_file" "doi_minting_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/doi-minting"
  output_path = "${path.module}/packages/doi-minting.zip"
}

#############################################
# CloudWatch Log Groups
#############################################

resource "aws_cloudwatch_log_group" "auth_lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-auth"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-auth-logs"
      Function = "authentication"
    }
  )
}

resource "aws_cloudwatch_log_group" "presigned_urls_lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-presigned-urls"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-presigned-urls-logs"
      Function = "presigned-urls"
    }
  )
}

resource "aws_cloudwatch_log_group" "doi_minting_lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-doi-minting"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-doi-minting-logs"
      Function = "doi-minting"
    }
  )
}

#############################################
# Lambda Functions
#############################################

# Auth Lambda
resource "aws_lambda_function" "auth" {
  filename         = data.archive_file.auth_lambda.output_path
  function_name    = "${var.project_name}-${var.environment}-auth"
  role             = aws_iam_role.auth_lambda.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.auth_lambda.output_base64sha256
  runtime          = local.lambda_runtime
  timeout          = local.lambda_timeout
  memory_size      = local.lambda_memory

  environment {
    variables = {
      USER_POOL_ID  = var.cognito_user_pool_id
      APP_CLIENT_ID = var.cognito_app_client_id
      ENVIRONMENT   = var.environment
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-auth"
      Function = "authentication"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.auth_lambda
  ]
}

# Presigned URLs Lambda
resource "aws_lambda_function" "presigned_urls" {
  filename         = data.archive_file.presigned_urls_lambda.output_path
  function_name    = "${var.project_name}-${var.environment}-presigned-urls"
  role             = aws_iam_role.presigned_urls_lambda.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.presigned_urls_lambda.output_base64sha256
  runtime          = local.lambda_runtime
  timeout          = local.lambda_timeout
  memory_size      = local.lambda_memory

  environment {
    variables = {
      PUBLIC_MEDIA_BUCKET     = var.public_media_bucket_name
      PRIVATE_MEDIA_BUCKET    = var.private_media_bucket_name
      RESTRICTED_MEDIA_BUCKET = var.restricted_media_bucket_name
      EMBARGOED_MEDIA_BUCKET  = var.embargoed_media_bucket_name
      ACCESS_LOGS_TABLE       = var.access_logs_table_name
      DOI_REGISTRY_TABLE      = var.doi_registry_table_name
      ENVIRONMENT             = var.environment
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-presigned-urls"
      Function = "presigned-urls"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.presigned_urls_lambda
  ]
}

# DOI Minting Lambda
resource "aws_lambda_function" "doi_minting" {
  filename         = data.archive_file.doi_minting_lambda.output_path
  function_name    = "${var.project_name}-${var.environment}-doi-minting"
  role             = aws_iam_role.doi_minting_lambda.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.doi_minting_lambda.output_base64sha256
  runtime          = local.lambda_runtime
  timeout          = 60 # DOI minting may take longer
  memory_size      = 512

  environment {
    variables = {
      DATACITE_API_URL    = var.datacite_api_url
      DATACITE_USERNAME   = var.datacite_username
      DATACITE_PASSWORD   = var.datacite_password
      DOI_PREFIX          = var.doi_prefix
      DOI_REGISTRY_TABLE  = var.doi_registry_table_name
      PUBLIC_MEDIA_BUCKET = var.public_media_bucket_name
      REPO_BASE_URL       = var.repo_base_url
      ENVIRONMENT         = var.environment
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-doi-minting"
      Function = "doi-minting"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.doi_minting_lambda
  ]
}

#############################################
# Lambda Permissions for API Gateway
#############################################

resource "aws_lambda_permission" "auth_api_gateway" {
  count = var.api_gateway_execution_arn != "" ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*"
}

resource "aws_lambda_permission" "presigned_urls_api_gateway" {
  count = var.api_gateway_execution_arn != "" ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_urls.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*"
}

resource "aws_lambda_permission" "doi_minting_api_gateway" {
  count = var.api_gateway_execution_arn != "" ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.doi_minting.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*"
}
