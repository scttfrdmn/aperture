# DynamoDB Tables Module
# Copyright 2025 Scott Friedman
# Manages all DynamoDB tables for Aperture metadata storage

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Table 1: Users and Permissions
# Stores user accounts, roles, and access permissions
resource "aws_dynamodb_table" "users" {
  name           = "${var.project_name}-users-${var.environment}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.users_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.users_write_capacity : null
  hash_key       = "user_id"
  range_key      = "created_at"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "orcid"
    type = "S"
  }

  # Global Secondary Index for email lookup
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.users_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.users_write_capacity : null
  }

  # Global Secondary Index for ORCID lookup
  global_secondary_index {
    name            = "OrcidIndex"
    hash_key        = "orcid"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.users_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.users_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    enabled        = false
    attribute_name = ""
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-users-${var.environment}"
      Purpose     = "User accounts and permissions"
      Environment = var.environment
    }
  )
}

# Table 2: DOI Registry
# Stores DOI metadata and landing page information
resource "aws_dynamodb_table" "doi_registry" {
  name           = "${var.project_name}-doi-registry-${var.environment}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.doi_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.doi_write_capacity : null
  hash_key       = "doi"
  range_key      = "version"

  attribute {
    name = "doi"
    type = "S"
  }

  attribute {
    name = "version"
    type = "N"
  }

  attribute {
    name = "dataset_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "minted_at"
    type = "S"
  }

  # Global Secondary Index for dataset lookup
  global_secondary_index {
    name            = "DatasetIndex"
    hash_key        = "dataset_id"
    range_key       = "minted_at"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.doi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.doi_write_capacity : null
  }

  # Global Secondary Index for status queries
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "minted_at"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.doi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.doi_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    enabled        = false
    attribute_name = ""
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-doi-registry-${var.environment}"
      Purpose     = "DOI metadata and tracking"
      Environment = var.environment
    }
  )
}

# Table 3: Access Logs Summary
# Stores summarized access patterns and analytics
resource "aws_dynamodb_table" "access_logs" {
  name           = "${var.project_name}-access-logs-${var.environment}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.logs_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.logs_write_capacity : null
  hash_key       = "dataset_id"
  range_key      = "timestamp"

  attribute {
    name = "dataset_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  # Global Secondary Index for user access patterns
  global_secondary_index {
    name            = "UserAccessIndex"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.logs_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.logs_write_capacity : null
  }

  # Global Secondary Index for daily analytics
  global_secondary_index {
    name            = "DateIndex"
    hash_key        = "date"
    range_key       = "dataset_id"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.logs_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.logs_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # Enable TTL for automatic log cleanup (90 days default)
  ttl {
    enabled        = var.enable_logs_ttl
    attribute_name = "expiration_time"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-access-logs-${var.environment}"
      Purpose     = "Access patterns and analytics"
      Environment = var.environment
    }
  )
}

# Table 4: Budget Tracking
# Stores cost tracking and budget alerts
resource "aws_dynamodb_table" "budget_tracking" {
  name           = "${var.project_name}-budget-${var.environment}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.budget_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.budget_write_capacity : null
  hash_key       = "resource_id"
  range_key      = "month"

  attribute {
    name = "resource_id"
    type = "S"
  }

  attribute {
    name = "month"
    type = "S"
  }

  attribute {
    name = "account_id"
    type = "S"
  }

  attribute {
    name = "cost_category"
    type = "S"
  }

  # Global Secondary Index for account-level costs
  global_secondary_index {
    name            = "AccountCostIndex"
    hash_key        = "account_id"
    range_key       = "month"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.budget_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.budget_write_capacity : null
  }

  # Global Secondary Index for cost category analysis
  global_secondary_index {
    name            = "CategoryIndex"
    hash_key        = "cost_category"
    range_key       = "month"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.budget_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.budget_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    enabled        = false
    attribute_name = ""
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-budget-${var.environment}"
      Purpose     = "Cost tracking and budget monitoring"
      Environment = var.environment
    }
  )
}

# Table 5: Knowledge Base Embeddings
# Stores vector embeddings for RAG (Retrieval-Augmented Generation)
resource "aws_dynamodb_table" "knowledge_base_embeddings" {
  name           = "${var.project_name}-knowledge-base-embeddings-${var.environment}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.embeddings_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.embeddings_write_capacity : null
  hash_key       = "embedding_id"
  range_key      = "created_at"

  attribute {
    name = "embedding_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "dataset_id"
    type = "S"
  }

  attribute {
    name = "content_type"
    type = "S"
  }

  # Global Secondary Index for dataset lookup
  global_secondary_index {
    name            = "DatasetIdIndex"
    hash_key        = "dataset_id"
    range_key       = "created_at"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.embeddings_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.embeddings_write_capacity : null
  }

  # Global Secondary Index for content type filtering
  global_secondary_index {
    name            = "ContentTypeIndex"
    hash_key        = "content_type"
    range_key       = "created_at"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.embeddings_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.embeddings_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    enabled        = false
    attribute_name = ""
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-knowledge-base-embeddings-${var.environment}"
      Purpose     = "Vector embeddings for RAG knowledge base"
      Environment = var.environment
    }
  )
}

# Auto-scaling for Users table (if using PROVISIONED billing)
resource "aws_appautoscaling_target" "users_read" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  max_capacity       = var.users_read_max_capacity
  min_capacity       = var.users_read_capacity
  resource_id        = "table/${aws_dynamodb_table.users.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "users_read" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  name               = "${var.project_name}-users-read-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.users_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.users_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_target_value
  }
}

resource "aws_appautoscaling_target" "users_write" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  max_capacity       = var.users_write_max_capacity
  min_capacity       = var.users_write_capacity
  resource_id        = "table/${aws_dynamodb_table.users.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "users_write" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  name               = "${var.project_name}-users-write-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.users_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.users_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_target_value
  }
}
