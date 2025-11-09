# EventBridge Module Variables

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

#############################################
# S3 Configuration
#############################################

variable "processing_bucket_name" {
  description = "Name of the S3 processing bucket for event notifications"
  type        = string
}

#############################################
# DynamoDB Configuration
#############################################

variable "doi_registry_table_name" {
  description = "Name of the DOI registry DynamoDB table"
  type        = string
}

#############################################
# Lambda Function ARNs
#############################################

variable "media_processing_lambda_arn" {
  description = "ARN of the media processing Lambda function"
  type        = string
  default     = ""
}

variable "lifecycle_lambda_arn" {
  description = "ARN of the lifecycle management Lambda function"
  type        = string
  default     = ""
}

variable "budget_report_lambda_arn" {
  description = "ARN of the budget report Lambda function"
  type        = string
  default     = ""
}

variable "doi_notification_lambda_arn" {
  description = "ARN of the DOI notification Lambda function"
  type        = string
  default     = ""
}

#############################################
# Step Functions ARNs
#############################################

variable "publication_workflow_arn" {
  description = "ARN of the publication workflow Step Functions state machine"
  type        = string
  default     = ""
}

#############################################
# SNS Configuration
#############################################

variable "alert_sns_topic_arn" {
  description = "ARN of SNS topic for alerts and notifications"
  type        = string
  default     = ""
}

#############################################
# Dead Letter Queue
#############################################

variable "dlq_arn" {
  description = "ARN of SQS Dead Letter Queue for failed events"
  type        = string
  default     = ""
}

#############################################
# Schedule Expressions
#############################################

variable "lifecycle_schedule_expression" {
  description = "Cron/rate expression for lifecycle management schedule"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM UTC
  validation {
    condition     = can(regex("^(rate|cron)\\(.*\\)$", var.lifecycle_schedule_expression))
    error_message = "Schedule expression must be a valid cron() or rate() expression."
  }
}

variable "budget_report_schedule_expression" {
  description = "Cron/rate expression for budget report schedule"
  type        = string
  default     = "cron(0 9 ? * MON *)" # Weekly on Monday at 9 AM UTC
  validation {
    condition     = can(regex("^(rate|cron)\\(.*\\)$", var.budget_report_schedule_expression))
    error_message = "Schedule expression must be a valid cron() or rate() expression."
  }
}

#############################################
# Event Archive
#############################################

variable "enable_event_archive" {
  description = "Enable EventBridge event archive for replay capability"
  type        = bool
  default     = true
}

variable "archive_retention_days" {
  description = "Number of days to retain events in archive"
  type        = number
  default     = 90
  validation {
    condition     = var.archive_retention_days >= 0 && var.archive_retention_days <= 365
    error_message = "Archive retention days must be between 0 and 365."
  }
}

#############################################
# Logging
#############################################

variable "enable_eventbridge_logging" {
  description = "Enable CloudWatch logging for EventBridge"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain EventBridge logs in CloudWatch"
  type        = number
  default     = 90
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

#############################################
# Tags
#############################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
