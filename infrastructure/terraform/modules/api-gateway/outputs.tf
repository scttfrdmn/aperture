# API Gateway Module Outputs

#############################################
# HTTP API
#############################################

output "api_id" {
  description = "ID of the HTTP API"
  value       = aws_apigatewayv2_api.main.id
}

output "api_arn" {
  description = "ARN of the HTTP API"
  value       = aws_apigatewayv2_api.main.arn
}

output "api_endpoint" {
  description = "Endpoint URL of the HTTP API"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_execution_arn" {
  description = "Execution ARN of the HTTP API"
  value       = aws_apigatewayv2_api.main.execution_arn
}

#############################################
# Stage
#############################################

output "stage_id" {
  description = "ID of the API stage"
  value       = aws_apigatewayv2_stage.main.id
}

output "stage_arn" {
  description = "ARN of the API stage"
  value       = aws_apigatewayv2_stage.main.arn
}

output "stage_invoke_url" {
  description = "Invoke URL for the API stage"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

#############################################
# Authorizer
#############################################

output "authorizer_id" {
  description = "ID of the Cognito JWT authorizer"
  value       = aws_apigatewayv2_authorizer.cognito.id
}

#############################################
# CloudWatch Logs
#############################################

output "log_group_name" {
  description = "Name of the CloudWatch log group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.arn
}

#############################################
# Custom Domain (Optional)
#############################################

output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.custom_domain_name != "" ? aws_apigatewayv2_domain_name.main[0].domain_name : ""
}

output "custom_domain_target" {
  description = "Target domain name for custom domain DNS configuration"
  value       = var.custom_domain_name != "" ? aws_apigatewayv2_domain_name.main[0].domain_name_configuration[0].target_domain_name : ""
}

output "custom_domain_hosted_zone_id" {
  description = "Hosted zone ID for custom domain DNS configuration"
  value       = var.custom_domain_name != "" ? aws_apigatewayv2_domain_name.main[0].domain_name_configuration[0].hosted_zone_id : ""
}

#############################################
# Routes Summary
#############################################

output "routes" {
  description = "List of configured API routes"
  value = {
    # Auth routes (public)
    auth_login   = "POST /auth/login"
    auth_refresh = "POST /auth/refresh"

    # Auth routes (protected)
    auth_logout = "POST /auth/logout"
    auth_verify = "GET /auth/verify"

    # Presigned URLs routes (protected)
    urls_generate = "POST /urls/generate"
    urls_batch    = "POST /urls/batch"

    # DOI management routes (protected)
    doi_mint   = "POST /doi/mint"
    doi_update = "PUT /doi/{id}"
    doi_delete = "DELETE /doi/{id}"

    # AI analysis routes (protected)
    ai_analyze_image        = "POST /ai/analyze-image"
    ai_extract_metadata     = "POST /ai/extract-metadata"
    ai_classify_artifact    = "POST /ai/classify-artifact"
    ai_generate_description = "POST /ai/generate-description"
    ai_generate_embeddings  = "POST /ai/generate-embeddings"
    ai_extract_text         = "POST /ai/extract-text"
    ai_analyze_batch        = "POST /ai/analyze-batch"

    # RAG knowledge base routes (protected)
    rag_index_dataset = "POST /rag/index"
    rag_query         = "POST /rag/query"
    rag_search        = "POST /rag/search"
    rag_delete        = "DELETE /rag/{dataset_id}"
  }
}

#############################################
# Summary
#############################################

output "summary" {
  description = "Summary of API Gateway resources created"
  value = {
    api_name         = aws_apigatewayv2_api.main.name
    api_endpoint     = aws_apigatewayv2_api.main.api_endpoint
    stage_invoke_url = aws_apigatewayv2_stage.main.invoke_url
    stage_name       = aws_apigatewayv2_stage.main.name
    total_routes     = 20
    public_routes    = 2
    protected_routes = 18
    environment      = var.environment
    cors_enabled     = length(var.cors_allowed_origins) > 0
    custom_domain    = var.custom_domain_name != "" ? var.custom_domain_name : "none"
  }
}
