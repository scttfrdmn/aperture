# DynamoDB Module Outputs
# Copyright 2025 Scott Friedman

# Users table outputs
output "users_table_name" {
  description = "Name of the users DynamoDB table"
  value       = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  description = "ARN of the users DynamoDB table"
  value       = aws_dynamodb_table.users.arn
}

output "users_table_id" {
  description = "ID of the users DynamoDB table"
  value       = aws_dynamodb_table.users.id
}

output "users_table_stream_arn" {
  description = "Stream ARN of the users DynamoDB table"
  value       = try(aws_dynamodb_table.users.stream_arn, "")
}

# DOI registry table outputs
output "doi_registry_table_name" {
  description = "Name of the DOI registry DynamoDB table"
  value       = aws_dynamodb_table.doi_registry.name
}

output "doi_registry_table_arn" {
  description = "ARN of the DOI registry DynamoDB table"
  value       = aws_dynamodb_table.doi_registry.arn
}

output "doi_registry_table_id" {
  description = "ID of the DOI registry DynamoDB table"
  value       = aws_dynamodb_table.doi_registry.id
}

output "doi_registry_table_stream_arn" {
  description = "Stream ARN of the DOI registry DynamoDB table"
  value       = try(aws_dynamodb_table.doi_registry.stream_arn, "")
}

# Access logs table outputs
output "access_logs_table_name" {
  description = "Name of the access logs DynamoDB table"
  value       = aws_dynamodb_table.access_logs.name
}

output "access_logs_table_arn" {
  description = "ARN of the access logs DynamoDB table"
  value       = aws_dynamodb_table.access_logs.arn
}

output "access_logs_table_id" {
  description = "ID of the access logs DynamoDB table"
  value       = aws_dynamodb_table.access_logs.id
}

output "access_logs_table_stream_arn" {
  description = "Stream ARN of the access logs DynamoDB table"
  value       = try(aws_dynamodb_table.access_logs.stream_arn, "")
}

# Budget tracking table outputs
output "budget_tracking_table_name" {
  description = "Name of the budget tracking DynamoDB table"
  value       = aws_dynamodb_table.budget_tracking.name
}

output "budget_tracking_table_arn" {
  description = "ARN of the budget tracking DynamoDB table"
  value       = aws_dynamodb_table.budget_tracking.arn
}

output "budget_tracking_table_id" {
  description = "ID of the budget tracking DynamoDB table"
  value       = aws_dynamodb_table.budget_tracking.id
}

output "budget_tracking_table_stream_arn" {
  description = "Stream ARN of the budget tracking DynamoDB table"
  value       = try(aws_dynamodb_table.budget_tracking.stream_arn, "")
}

# Consolidated outputs
output "all_table_names" {
  description = "List of all DynamoDB table names"
  value = [
    aws_dynamodb_table.users.name,
    aws_dynamodb_table.doi_registry.name,
    aws_dynamodb_table.access_logs.name,
    aws_dynamodb_table.budget_tracking.name,
  ]
}

output "all_table_arns" {
  description = "List of all DynamoDB table ARNs"
  value = [
    aws_dynamodb_table.users.arn,
    aws_dynamodb_table.doi_registry.arn,
    aws_dynamodb_table.access_logs.arn,
    aws_dynamodb_table.budget_tracking.arn,
  ]
}
