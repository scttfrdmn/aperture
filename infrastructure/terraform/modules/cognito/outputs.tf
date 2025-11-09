# Cognito Module Outputs
# Copyright 2025 Scott Friedman

# User Pool
output "user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito user pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito user pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Domain prefix of the Cognito hosted UI"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_domain_cloudfront" {
  description = "CloudFront distribution for Cognito hosted UI"
  value       = aws_cognito_user_pool_domain.main.cloudfront_distribution
}

output "custom_domain" {
  description = "Custom domain for Cognito hosted UI (if configured)"
  value       = try(aws_cognito_user_pool_domain.custom[0].domain, null)
}

# Web App Client
output "web_app_client_id" {
  description = "ID of the web application client"
  value       = aws_cognito_user_pool_client.web_app.id
}

output "web_app_client_name" {
  description = "Name of the web application client"
  value       = aws_cognito_user_pool_client.web_app.name
}

# API Client
output "api_client_id" {
  description = "ID of the API client (if created)"
  value       = try(aws_cognito_user_pool_client.api_client[0].id, null)
}

output "api_client_secret" {
  description = "Secret of the API client (if created)"
  value       = try(aws_cognito_user_pool_client.api_client[0].client_secret, null)
  sensitive   = true
}

# Identity Provider
output "orcid_provider_name" {
  description = "Name of the ORCID identity provider (if enabled)"
  value       = try(aws_cognito_identity_provider.orcid[0].provider_name, null)
}

# User Groups
output "admin_group_name" {
  description = "Name of the admins group"
  value       = aws_cognito_user_group.admins.name
}

output "researcher_group_name" {
  description = "Name of the researchers group"
  value       = aws_cognito_user_group.researchers.name
}

output "reviewer_group_name" {
  description = "Name of the reviewers group"
  value       = aws_cognito_user_group.reviewers.name
}

output "user_group_name" {
  description = "Name of the users group"
  value       = aws_cognito_user_group.users.name
}

# CloudWatch
output "cloudwatch_log_group" {
  description = "CloudWatch log group name for Cognito events (if enabled)"
  value       = try(aws_cloudwatch_log_group.cognito_logs[0].name, null)
}

# OAuth Configuration
output "oauth_authorize_url" {
  description = "OAuth 2.0 authorization endpoint"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/authorize"
}

output "oauth_token_url" {
  description = "OAuth 2.0 token endpoint"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/token"
}

output "oauth_userinfo_url" {
  description = "OAuth 2.0 userinfo endpoint"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/userInfo"
}

output "oauth_jwks_url" {
  description = "JSON Web Key Set (JWKS) endpoint"
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.main.id}/.well-known/jwks.json"
}

# Data source for current AWS region
data "aws_region" "current" {}
