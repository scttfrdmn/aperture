# EventBridge Module
# Provides event-driven workflows for the Aperture platform

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "eventbridge"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

#############################################
# Custom Event Bus
#############################################

resource "aws_cloudwatch_event_bus" "aperture" {
  name = "${var.project_name}-${var.environment}-events"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-event-bus"
    }
  )
}

#############################################
# S3 Event Notifications
#############################################

# Enable EventBridge for S3 buckets (configured in S3 module)
# This allows EventBridge to receive S3 events

# Rule: Process uploaded media files
resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name           = "${var.project_name}-${var.environment}-s3-object-created"
  description    = "Trigger media processing when files are uploaded to processing bucket"
  event_bus_name = aws_cloudwatch_event_bus.aperture.name

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.processing_bucket_name]
      }
    }
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-s3-object-created"
      Purpose = "Media processing trigger"
    }
  )
}

# Target: Media processing Lambda (placeholder for when Lambda module exists)
resource "aws_cloudwatch_event_target" "media_processing" {
  count = var.media_processing_lambda_arn != "" ? 1 : 0

  rule           = aws_cloudwatch_event_rule.s3_object_created.name
  event_bus_name = aws_cloudwatch_event_bus.aperture.name
  arn            = var.media_processing_lambda_arn
  target_id      = "MediaProcessingLambda"

  retry_policy {
    maximum_retry_attempts       = 2
    maximum_event_age_in_seconds = 3600
  }

  dead_letter_config {
    arn = var.dlq_arn != "" ? var.dlq_arn : null
  }
}

#############################################
# Scheduled Rules
#############################################

# Rule: Daily lifecycle management
resource "aws_cloudwatch_event_rule" "daily_lifecycle" {
  name                = "${var.project_name}-${var.environment}-daily-lifecycle"
  description         = "Daily task to manage data lifecycle (cleanup, archiving)"
  schedule_expression = var.lifecycle_schedule_expression

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-daily-lifecycle"
      Purpose = "Data lifecycle management"
    }
  )
}

# Target: Lifecycle management Lambda
resource "aws_cloudwatch_event_target" "lifecycle_management" {
  count = var.lifecycle_lambda_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.daily_lifecycle.name
  arn       = var.lifecycle_lambda_arn
  target_id = "LifecycleManagementLambda"

  retry_policy {
    maximum_retry_attempts       = 2
    maximum_event_age_in_seconds = 86400
  }
}

# Rule: Weekly budget report
resource "aws_cloudwatch_event_rule" "weekly_budget_report" {
  name                = "${var.project_name}-${var.environment}-weekly-budget"
  description         = "Weekly budget report generation"
  schedule_expression = var.budget_report_schedule_expression

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-weekly-budget"
      Purpose = "Budget monitoring"
    }
  )
}

# Target: Budget report Lambda
resource "aws_cloudwatch_event_target" "budget_report" {
  count = var.budget_report_lambda_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.weekly_budget_report.name
  arn       = var.budget_report_lambda_arn
  target_id = "BudgetReportLambda"
}

#############################################
# CloudWatch Alarms to EventBridge
#############################################

# Rule: High error rate alert
resource "aws_cloudwatch_event_rule" "high_error_rate" {
  name        = "${var.project_name}-${var.environment}-high-error-rate"
  description = "Alert when Lambda error rate exceeds threshold"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [{
        prefix = "${var.project_name}-${var.environment}"
      }]
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-high-error-rate"
      Purpose = "Error monitoring"
    }
  )
}

# Target: SNS topic for alerts
resource "aws_cloudwatch_event_target" "error_alert_sns" {
  count = var.alert_sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.high_error_rate.name
  arn       = var.alert_sns_topic_arn
  target_id = "ErrorAlertSNS"
}

#############################################
# DynamoDB Streams to EventBridge
#############################################

# Rule: DOI registry changes
resource "aws_cloudwatch_event_rule" "doi_registry_changes" {
  name           = "${var.project_name}-${var.environment}-doi-changes"
  description    = "Monitor DOI registry changes for webhooks/notifications"
  event_bus_name = aws_cloudwatch_event_bus.aperture.name

  event_pattern = jsonencode({
    source      = ["aws.dynamodb"]
    detail-type = ["DynamoDB Stream Record"]
    detail = {
      tableName = [var.doi_registry_table_name]
      eventName = ["INSERT", "MODIFY"]
    }
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-doi-changes"
      Purpose = "DOI change notifications"
    }
  )
}

# Target: DOI notification Lambda
resource "aws_cloudwatch_event_target" "doi_notification" {
  count = var.doi_notification_lambda_arn != "" ? 1 : 0

  rule           = aws_cloudwatch_event_rule.doi_registry_changes.name
  event_bus_name = aws_cloudwatch_event_bus.aperture.name
  arn            = var.doi_notification_lambda_arn
  target_id      = "DOINotificationLambda"
}

#############################################
# Custom Application Events
#############################################

# Rule: Dataset publication workflow
resource "aws_cloudwatch_event_rule" "dataset_publication" {
  name           = "${var.project_name}-${var.environment}-dataset-publication"
  description    = "Trigger workflow when dataset is ready for publication"
  event_bus_name = aws_cloudwatch_event_bus.aperture.name

  event_pattern = jsonencode({
    source      = ["aperture.datasets"]
    detail-type = ["Dataset Publication Requested"]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-dataset-publication"
      Purpose = "Publication workflow"
    }
  )
}

# Target: Publication workflow Step Functions (placeholder)
resource "aws_cloudwatch_event_target" "publication_workflow" {
  count = var.publication_workflow_arn != "" ? 1 : 0

  rule           = aws_cloudwatch_event_rule.dataset_publication.name
  event_bus_name = aws_cloudwatch_event_bus.aperture.name
  arn            = var.publication_workflow_arn
  target_id      = "PublicationWorkflow"
  role_arn       = aws_iam_role.eventbridge_step_functions.arn
}

# Rule: Failed job notifications
resource "aws_cloudwatch_event_rule" "failed_jobs" {
  name           = "${var.project_name}-${var.environment}-failed-jobs"
  description    = "Notify administrators of failed processing jobs"
  event_bus_name = aws_cloudwatch_event_bus.aperture.name

  event_pattern = jsonencode({
    source      = ["aperture.processing"]
    detail-type = ["Processing Job Failed"]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-${var.environment}-failed-jobs"
      Purpose = "Failure notifications"
    }
  )
}

# Target: Admin notification SNS
resource "aws_cloudwatch_event_target" "failed_job_notification" {
  count = var.alert_sns_topic_arn != "" ? 1 : 0

  rule           = aws_cloudwatch_event_rule.failed_jobs.name
  event_bus_name = aws_cloudwatch_event_bus.aperture.name
  arn            = var.alert_sns_topic_arn
  target_id      = "FailedJobNotificationSNS"
}

#############################################
# EventBridge Archive (Event Replay)
#############################################

resource "aws_cloudwatch_event_archive" "aperture_events" {
  count = var.enable_event_archive ? 1 : 0

  name             = "${var.project_name}-${var.environment}-event-archive"
  event_source_arn = aws_cloudwatch_event_bus.aperture.arn
  retention_days   = var.archive_retention_days

  description = "Archive of all Aperture events for replay and debugging"
}

#############################################
# IAM Roles and Policies
#############################################

# Role for EventBridge to invoke Step Functions
resource "aws_iam_role" "eventbridge_step_functions" {
  name = "${var.project_name}-${var.environment}-eventbridge-sfn"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eventbridge-sfn-role"
    }
  )
}

resource "aws_iam_role_policy" "eventbridge_step_functions" {
  name = "${var.project_name}-${var.environment}-eventbridge-sfn-policy"
  role = aws_iam_role.eventbridge_step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = var.publication_workflow_arn != "" ? [var.publication_workflow_arn] : ["*"]
      }
    ]
  })
}

# Role for EventBridge to publish to SNS
resource "aws_iam_role" "eventbridge_sns" {
  count = var.alert_sns_topic_arn != "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-eventbridge-sns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eventbridge-sns-role"
    }
  )
}

resource "aws_iam_role_policy" "eventbridge_sns" {
  count = var.alert_sns_topic_arn != "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-eventbridge-sns-policy"
  role = aws_iam_role.eventbridge_sns[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.alert_sns_topic_arn
      }
    ]
  })
}

#############################################
# CloudWatch Log Group for EventBridge
#############################################

resource "aws_cloudwatch_log_group" "eventbridge" {
  count = var.enable_eventbridge_logging ? 1 : 0

  name              = "/aws/events/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eventbridge-logs"
    }
  )
}

# Log group resource policy to allow EventBridge to write logs
resource "aws_cloudwatch_log_resource_policy" "eventbridge" {
  count = var.enable_eventbridge_logging ? 1 : 0

  policy_name = "${var.project_name}-${var.environment}-eventbridge-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.eventbridge[0].arn}:*"
      }
    ]
  })
}
