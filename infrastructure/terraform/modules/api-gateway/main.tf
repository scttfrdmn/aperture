# API Gateway Module - HTTP API (v2)
# Exposes Lambda functions as REST API endpoints

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#############################################
# HTTP API (API Gateway v2)
#############################################

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"
  description   = "Aperture Academic Media Repository API"

  cors_configuration {
    allow_origins     = var.cors_allowed_origins
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["content-type", "authorization", "x-api-key"]
    expose_headers    = ["content-length", "content-type"]
    max_age           = 300
    allow_credentials = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api"
      Environment = var.environment
    }
  )
}

#############################################
# JWT Authorizer (Cognito)
#############################################

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-${var.environment}-cognito-authorizer"

  jwt_configuration {
    audience = [var.cognito_app_client_id]
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

#############################################
# Lambda Integrations
#############################################

# Auth Lambda Integration
resource "aws_apigatewayv2_integration" "auth" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.auth_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Presigned URLs Lambda Integration
resource "aws_apigatewayv2_integration" "presigned_urls" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.presigned_urls_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# DOI Minting Lambda Integration
resource "aws_apigatewayv2_integration" "doi_minting" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.doi_minting_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Bedrock Analysis Lambda Integration
resource "aws_apigatewayv2_integration" "bedrock_analysis" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.bedrock_analysis_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

#############################################
# Routes - Authentication (Public)
#############################################

resource "aws_apigatewayv2_route" "auth_login" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_apigatewayv2_route" "auth_refresh" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /auth/refresh"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

#############################################
# Routes - Authentication (Protected)
#############################################

resource "aws_apigatewayv2_route" "auth_logout" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/logout"
  target             = "integrations/${aws_apigatewayv2_integration.auth.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "auth_verify" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /auth/verify"
  target             = "integrations/${aws_apigatewayv2_integration.auth.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

#############################################
# Routes - Presigned URLs (Protected)
#############################################

resource "aws_apigatewayv2_route" "urls_generate" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /urls/generate"
  target             = "integrations/${aws_apigatewayv2_integration.presigned_urls.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "urls_batch" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /urls/batch"
  target             = "integrations/${aws_apigatewayv2_integration.presigned_urls.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

#############################################
# Routes - DOI Management (Protected)
#############################################

resource "aws_apigatewayv2_route" "doi_mint" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /doi/mint"
  target             = "integrations/${aws_apigatewayv2_integration.doi_minting.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "doi_update" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /doi/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.doi_minting.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "doi_delete" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /doi/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.doi_minting.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

#############################################
# Routes - AI Analysis (Protected)
#############################################

resource "aws_apigatewayv2_route" "ai_analyze_image" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/analyze-image"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ai_extract_metadata" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/extract-metadata"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ai_classify_artifact" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/classify-artifact"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ai_generate_description" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/generate-description"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ai_generate_embeddings" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/generate-embeddings"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ai_extract_text" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/extract-text"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ai_analyze_batch" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /ai/analyze-batch"
  target             = "integrations/${aws_apigatewayv2_integration.bedrock_analysis.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

#############################################
# Stage
#############################################

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true
  description = "API stage for ${var.environment} environment"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      errorMessage     = "$context.error.message"
      authorizerError  = "$context.authorizer.error"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-stage"
      Environment = var.environment
    }
  )
}

#############################################
# CloudWatch Logs
#############################################

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-logs"
      Environment = var.environment
    }
  )
}

#############################################
# Lambda Permissions
#############################################

# Auth Lambda Permission
resource "aws_lambda_permission" "api_gateway_auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Presigned URLs Lambda Permission
resource "aws_lambda_permission" "api_gateway_presigned_urls" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.presigned_urls_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# DOI Minting Lambda Permission
resource "aws_lambda_permission" "api_gateway_doi_minting" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.doi_minting_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Bedrock Analysis Lambda Permission
resource "aws_lambda_permission" "api_gateway_bedrock_analysis" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.bedrock_analysis_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

#############################################
# Custom Domain (Optional)
#############################################

resource "aws_apigatewayv2_domain_name" "main" {
  count       = var.custom_domain_name != "" ? 1 : 0
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-domain"
      Environment = var.environment
    }
  )
}

resource "aws_apigatewayv2_api_mapping" "main" {
  count       = var.custom_domain_name != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.main[0].id
  stage       = aws_apigatewayv2_stage.main.id
}

#############################################
# Data Sources
#############################################

data "aws_region" "current" {}
