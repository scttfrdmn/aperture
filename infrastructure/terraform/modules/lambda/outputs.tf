# Lambda Module Outputs

#############################################
# Auth Lambda
#############################################

output "auth_lambda_arn" {
  description = "ARN of the auth Lambda function"
  value       = aws_lambda_function.auth.arn
}

output "auth_lambda_name" {
  description = "Name of the auth Lambda function"
  value       = aws_lambda_function.auth.function_name
}

output "auth_lambda_invoke_arn" {
  description = "Invoke ARN of the auth Lambda function"
  value       = aws_lambda_function.auth.invoke_arn
}

output "auth_lambda_qualified_arn" {
  description = "Qualified ARN of the auth Lambda function"
  value       = aws_lambda_function.auth.qualified_arn
}

#############################################
# Presigned URLs Lambda
#############################################

output "presigned_urls_lambda_arn" {
  description = "ARN of the presigned URLs Lambda function"
  value       = aws_lambda_function.presigned_urls.arn
}

output "presigned_urls_lambda_name" {
  description = "Name of the presigned URLs Lambda function"
  value       = aws_lambda_function.presigned_urls.function_name
}

output "presigned_urls_lambda_invoke_arn" {
  description = "Invoke ARN of the presigned URLs Lambda function"
  value       = aws_lambda_function.presigned_urls.invoke_arn
}

output "presigned_urls_lambda_qualified_arn" {
  description = "Qualified ARN of the presigned URLs Lambda function"
  value       = aws_lambda_function.presigned_urls.qualified_arn
}

#############################################
# DOI Minting Lambda
#############################################

output "doi_minting_lambda_arn" {
  description = "ARN of the DOI minting Lambda function"
  value       = aws_lambda_function.doi_minting.arn
}

output "doi_minting_lambda_name" {
  description = "Name of the DOI minting Lambda function"
  value       = aws_lambda_function.doi_minting.function_name
}

output "doi_minting_lambda_invoke_arn" {
  description = "Invoke ARN of the DOI minting Lambda function"
  value       = aws_lambda_function.doi_minting.invoke_arn
}

output "doi_minting_lambda_qualified_arn" {
  description = "Qualified ARN of the DOI minting Lambda function"
  value       = aws_lambda_function.doi_minting.qualified_arn
}

#############################################
# Bedrock Analysis Lambda
#############################################

output "bedrock_analysis_lambda_arn" {
  description = "ARN of the Bedrock analysis Lambda function"
  value       = aws_lambda_function.bedrock_analysis.arn
}

output "bedrock_analysis_lambda_name" {
  description = "Name of the Bedrock analysis Lambda function"
  value       = aws_lambda_function.bedrock_analysis.function_name
}

output "bedrock_analysis_lambda_invoke_arn" {
  description = "Invoke ARN of the Bedrock analysis Lambda function"
  value       = aws_lambda_function.bedrock_analysis.invoke_arn
}

output "bedrock_analysis_lambda_qualified_arn" {
  description = "Qualified ARN of the Bedrock analysis Lambda function"
  value       = aws_lambda_function.bedrock_analysis.qualified_arn
}

#############################################
# RAG Knowledge Base Lambda
#############################################

output "rag_knowledge_base_lambda_arn" {
  description = "ARN of the RAG knowledge base Lambda function"
  value       = aws_lambda_function.rag_knowledge_base.arn
}

output "rag_knowledge_base_lambda_name" {
  description = "Name of the RAG knowledge base Lambda function"
  value       = aws_lambda_function.rag_knowledge_base.function_name
}

output "rag_knowledge_base_lambda_invoke_arn" {
  description = "Invoke ARN of the RAG knowledge base Lambda function"
  value       = aws_lambda_function.rag_knowledge_base.invoke_arn
}

output "rag_knowledge_base_lambda_qualified_arn" {
  description = "Qualified ARN of the RAG knowledge base Lambda function"
  value       = aws_lambda_function.rag_knowledge_base.qualified_arn
}

#############################################
# IAM Roles
#############################################

output "auth_lambda_role_arn" {
  description = "ARN of the auth Lambda IAM role"
  value       = aws_iam_role.auth_lambda.arn
}

output "presigned_urls_lambda_role_arn" {
  description = "ARN of the presigned URLs Lambda IAM role"
  value       = aws_iam_role.presigned_urls_lambda.arn
}

output "doi_minting_lambda_role_arn" {
  description = "ARN of the DOI minting Lambda IAM role"
  value       = aws_iam_role.doi_minting_lambda.arn
}

output "bedrock_analysis_lambda_role_arn" {
  description = "ARN of the Bedrock analysis Lambda IAM role"
  value       = aws_iam_role.bedrock_analysis_lambda.arn
}

output "rag_knowledge_base_lambda_role_arn" {
  description = "ARN of the RAG knowledge base Lambda IAM role"
  value       = aws_iam_role.rag_knowledge_base_lambda.arn
}

#############################################
# CloudWatch Log Groups
#############################################

output "auth_lambda_log_group_name" {
  description = "Name of the auth Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.auth_lambda.name
}

output "presigned_urls_lambda_log_group_name" {
  description = "Name of the presigned URLs Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.presigned_urls_lambda.name
}

output "doi_minting_lambda_log_group_name" {
  description = "Name of the DOI minting Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.doi_minting_lambda.name
}

output "bedrock_analysis_lambda_log_group_name" {
  description = "Name of the Bedrock analysis Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.bedrock_analysis_lambda.name
}

output "rag_knowledge_base_lambda_log_group_name" {
  description = "Name of the RAG knowledge base Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.rag_knowledge_base_lambda.name
}

#############################################
# Summary
#############################################

output "summary" {
  description = "Summary of Lambda resources created"
  value = {
    auth_lambda_name              = aws_lambda_function.auth.function_name
    presigned_urls_lambda_name    = aws_lambda_function.presigned_urls.function_name
    doi_minting_lambda_name       = aws_lambda_function.doi_minting.function_name
    bedrock_analysis_lambda_name  = aws_lambda_function.bedrock_analysis.function_name
    rag_knowledge_base_lambda_name = aws_lambda_function.rag_knowledge_base.function_name
    total_functions               = 5
    runtime                       = aws_lambda_function.auth.runtime
    environment                   = var.environment
  }
}
