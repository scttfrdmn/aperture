# EventBridge Module Outputs

#############################################
# Event Bus
#############################################

output "event_bus_name" {
  description = "Name of the custom EventBridge event bus"
  value       = aws_cloudwatch_event_bus.aperture.name
}

output "event_bus_arn" {
  description = "ARN of the custom EventBridge event bus"
  value       = aws_cloudwatch_event_bus.aperture.arn
}

#############################################
# Event Rules
#############################################

output "s3_object_created_rule_arn" {
  description = "ARN of the S3 object created event rule"
  value       = aws_cloudwatch_event_rule.s3_object_created.arn
}

output "s3_object_created_rule_name" {
  description = "Name of the S3 object created event rule"
  value       = aws_cloudwatch_event_rule.s3_object_created.name
}

output "daily_lifecycle_rule_arn" {
  description = "ARN of the daily lifecycle management event rule"
  value       = aws_cloudwatch_event_rule.daily_lifecycle.arn
}

output "daily_lifecycle_rule_name" {
  description = "Name of the daily lifecycle management event rule"
  value       = aws_cloudwatch_event_rule.daily_lifecycle.name
}

output "weekly_budget_report_rule_arn" {
  description = "ARN of the weekly budget report event rule"
  value       = aws_cloudwatch_event_rule.weekly_budget_report.arn
}

output "weekly_budget_report_rule_name" {
  description = "Name of the weekly budget report event rule"
  value       = aws_cloudwatch_event_rule.weekly_budget_report.name
}

output "high_error_rate_rule_arn" {
  description = "ARN of the high error rate alert event rule"
  value       = aws_cloudwatch_event_rule.high_error_rate.arn
}

output "high_error_rate_rule_name" {
  description = "Name of the high error rate alert event rule"
  value       = aws_cloudwatch_event_rule.high_error_rate.name
}

output "doi_registry_changes_rule_arn" {
  description = "ARN of the DOI registry changes event rule"
  value       = aws_cloudwatch_event_rule.doi_registry_changes.arn
}

output "doi_registry_changes_rule_name" {
  description = "Name of the DOI registry changes event rule"
  value       = aws_cloudwatch_event_rule.doi_registry_changes.name
}

output "dataset_publication_rule_arn" {
  description = "ARN of the dataset publication workflow event rule"
  value       = aws_cloudwatch_event_rule.dataset_publication.arn
}

output "dataset_publication_rule_name" {
  description = "Name of the dataset publication workflow event rule"
  value       = aws_cloudwatch_event_rule.dataset_publication.name
}

output "failed_jobs_rule_arn" {
  description = "ARN of the failed jobs notification event rule"
  value       = aws_cloudwatch_event_rule.failed_jobs.arn
}

output "failed_jobs_rule_name" {
  description = "Name of the failed jobs notification event rule"
  value       = aws_cloudwatch_event_rule.failed_jobs.name
}

#############################################
# IAM Roles
#############################################

output "eventbridge_step_functions_role_arn" {
  description = "ARN of the IAM role for EventBridge to invoke Step Functions"
  value       = aws_iam_role.eventbridge_step_functions.arn
}

output "eventbridge_step_functions_role_name" {
  description = "Name of the IAM role for EventBridge to invoke Step Functions"
  value       = aws_iam_role.eventbridge_step_functions.name
}

output "eventbridge_sns_role_arn" {
  description = "ARN of the IAM role for EventBridge to publish to SNS"
  value       = var.alert_sns_topic_arn != "" ? aws_iam_role.eventbridge_sns[0].arn : null
}

output "eventbridge_sns_role_name" {
  description = "Name of the IAM role for EventBridge to publish to SNS"
  value       = var.alert_sns_topic_arn != "" ? aws_iam_role.eventbridge_sns[0].name : null
}

#############################################
# Event Archive
#############################################

output "event_archive_arn" {
  description = "ARN of the EventBridge event archive"
  value       = var.enable_event_archive ? aws_cloudwatch_event_archive.aperture_events[0].arn : null
}

output "event_archive_name" {
  description = "Name of the EventBridge event archive"
  value       = var.enable_event_archive ? aws_cloudwatch_event_archive.aperture_events[0].name : null
}

#############################################
# CloudWatch Logs
#############################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EventBridge"
  value       = var.enable_eventbridge_logging ? aws_cloudwatch_log_group.eventbridge[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EventBridge"
  value       = var.enable_eventbridge_logging ? aws_cloudwatch_log_group.eventbridge[0].arn : null
}

#############################################
# Summary
#############################################

output "summary" {
  description = "Summary of EventBridge resources created"
  value = {
    event_bus_name  = aws_cloudwatch_event_bus.aperture.name
    total_rules     = 7
    scheduled_rules = 2
    event_rules     = 5
    archive_enabled = var.enable_event_archive
    logging_enabled = var.enable_eventbridge_logging
    environment     = var.environment
  }
}
