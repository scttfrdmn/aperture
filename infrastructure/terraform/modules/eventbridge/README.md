# EventBridge Module

Event-driven workflow orchestration for the Aperture platform using AWS EventBridge.

## Overview

This module provides a comprehensive EventBridge setup for the Aperture academic media repository, enabling event-driven architectures, scheduled tasks, and automated workflows. EventBridge acts as the central nervous system of the platform, coordinating responses to S3 uploads, DynamoDB changes, CloudWatch alarms, and custom application events.

### Key Features

- **Custom Event Bus**: Dedicated event bus for Aperture events
- **S3 Event Integration**: Automatic media processing on file upload
- **Scheduled Tasks**: Cron-based scheduling for lifecycle and budget management
- **CloudWatch Alarm Routing**: Automatic alert handling
- **DynamoDB Stream Monitoring**: React to DOI registry changes
- **Custom Application Events**: Publication workflows, failure notifications
- **Event Archive**: 90-day event replay capability
- **Dead Letter Queue**: Failed event handling
- **CloudWatch Logging**: Full audit trail of all events

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EventBridge Event Bus                        │
│                     aperture-{env}-events                           │
└─────────────────────────────────────────────────────────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐         ┌────────────────┐        ┌────────────────┐
│  S3 Events    │         │   Scheduled    │        │  DynamoDB      │
│               │         │   Rules        │        │  Streams       │
│ • Object      │         │                │        │                │
│   Created     │         │ • Daily (2 AM) │        │ • DOI Registry │
│               │         │ • Weekly (Mon) │        │   Changes      │
└───────┬───────┘         └────────┬───────┘        └────────┬───────┘
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐         ┌────────────────┐        ┌────────────────┐
│ Media         │         │ Lifecycle      │        │ DOI            │
│ Processing    │         │ Management     │        │ Notification   │
│ Lambda        │         │ Lambda         │        │ Lambda         │
└───────────────┘         └────────────────┘        └────────────────┘
                                   │
                          ┌────────┴────────┐
                          ▼                 ▼
                  ┌──────────────┐  ┌──────────────┐
                  │  Budget       │  │  SNS Topic   │
                  │  Report       │  │  (Alerts)    │
                  │  Lambda       │  │              │
                  └──────────────┘  └──────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        CloudWatch Alarms                            │
│                                                                      │
│  High Error Rate → EventBridge → SNS → Email/Slack/PagerDuty       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        Custom Events                                 │
│                                                                      │
│  aperture.datasets.publication → Step Functions Workflow            │
│  aperture.processing.failed → SNS Alert                             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        Event Archive                                 │
│                                                                      │
│  All events archived for 90 days → Replay capability                │
└─────────────────────────────────────────────────────────────────────┘
```

## Event Rules

### 1. S3 Object Created Rule

**Purpose**: Triggers media processing when files are uploaded to the processing bucket

**Event Pattern**:
```json
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["aperture-dev-processing"]
    }
  }
}
```

**Target**: Media Processing Lambda
**Retry Policy**: 2 attempts, 1-hour max age
**DLQ**: Enabled

### 2. Daily Lifecycle Management

**Purpose**: Runs daily cleanup, archiving, and lifecycle tasks

**Schedule**: `cron(0 2 * * ? *)` (Daily at 2 AM UTC)
**Target**: Lifecycle Management Lambda
**Retry Policy**: 2 attempts, 24-hour max age

### 3. Weekly Budget Report

**Purpose**: Generates and emails weekly budget reports

**Schedule**: `cron(0 9 ? * MON *)` (Weekly Monday at 9 AM UTC)
**Target**: Budget Report Lambda

### 4. High Error Rate Alerts

**Purpose**: Monitors CloudWatch alarms for Lambda errors

**Event Pattern**:
```json
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"],
  "detail": {
    "alarmName": [{
      "prefix": "aperture-dev"
    }],
    "state": {
      "value": ["ALARM"]
    }
  }
}
```

**Target**: SNS Topic for administrator alerts

### 5. DOI Registry Changes

**Purpose**: Monitors DynamoDB DOI registry for new DOIs or updates

**Event Pattern**:
```json
{
  "source": ["aws.dynamodb"],
  "detail-type": ["DynamoDB Stream Record"],
  "detail": {
    "tableName": ["aperture-dev-doi-registry"],
    "eventName": ["INSERT", "MODIFY"]
  }
}
```

**Target**: DOI Notification Lambda
**Use Case**: Send notifications, update external indexes, trigger webhooks

### 6. Dataset Publication Workflow

**Purpose**: Orchestrates multi-step publication process

**Event Pattern**:
```json
{
  "source": ["aperture.datasets"],
  "detail-type": ["Dataset Publication Requested"]
}
```

**Target**: Step Functions State Machine
**Workflow**: Validation → DOI minting → Landing page → Notification

### 7. Failed Jobs Notification

**Purpose**: Alerts administrators when processing jobs fail

**Event Pattern**:
```json
{
  "source": ["aperture.processing"],
  "detail-type": ["Processing Job Failed"]
}
```

**Target**: SNS Topic
**Use Case**: Immediate notification for failed transcoding, thumbnail generation, etc.

## Usage

### Basic Usage

```hcl
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name    = "aperture"
  environment     = "dev"

  # S3 Configuration
  processing_bucket_name = module.s3_buckets.processing_bucket_name

  # DynamoDB Configuration
  doi_registry_table_name = module.dynamodb.doi_registry_table_name

  # Lambda Function ARNs (optional - can be added after Lambda module is created)
  media_processing_lambda_arn = module.lambda.media_processing_arn
  lifecycle_lambda_arn        = module.lambda.lifecycle_arn
  budget_report_lambda_arn    = module.lambda.budget_report_arn

  tags = {
    Project     = "Aperture"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### With Custom Schedule Expressions

```hcl
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name = "aperture"
  environment  = "prod"

  processing_bucket_name      = module.s3_buckets.processing_bucket_name
  doi_registry_table_name     = module.dynamodb.doi_registry_table_name

  # Custom schedules
  lifecycle_schedule_expression      = "cron(0 3 * * ? *)"  # 3 AM UTC
  budget_report_schedule_expression  = "cron(0 8 ? * FRI *)" # Friday 8 AM UTC

  # Event archive with extended retention
  enable_event_archive  = true
  archive_retention_days = 365  # 1 year

  # Extended log retention
  log_retention_days = 180

  tags = {
    Project     = "Aperture"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

### Minimal Configuration (Testing)

```hcl
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name    = "aperture"
  environment     = "dev"

  processing_bucket_name      = "aperture-dev-processing"
  doi_registry_table_name     = "aperture-dev-doi-registry"

  # Disable archive and logging for cost savings in dev
  enable_event_archive      = false
  enable_eventbridge_logging = false
}
```

## Schedule Expression Syntax

EventBridge supports two types of schedule expressions:

### Cron Expressions

Format: `cron(Minutes Hours Day-of-month Month Day-of-week Year)`

**Examples**:
- `cron(0 2 * * ? *)` - Daily at 2:00 AM UTC
- `cron(0 9 ? * MON *)` - Every Monday at 9:00 AM UTC
- `cron(0 */6 * * ? *)` - Every 6 hours
- `cron(0 0 1 * ? *)` - First day of every month at midnight
- `cron(0 12 * * ? *)` - Every day at noon

**Notes**:
- Use `?` for either Day-of-month or Day-of-week (not both)
- Month and Day-of-week support names (JAN, MON, etc.)
- All times are UTC

### Rate Expressions

Format: `rate(value unit)`

**Examples**:
- `rate(5 minutes)` - Every 5 minutes
- `rate(1 hour)` - Every hour
- `rate(7 days)` - Every 7 days

**Notes**:
- Value must be positive integer
- Unit must be minute, minutes, hour, hours, day, or days
- For value > 1, use plural unit

## Event Patterns

### S3 Events

Enable EventBridge notifications on your S3 bucket:

```hcl
resource "aws_s3_bucket_notification" "processing" {
  bucket      = aws_s3_bucket.processing.id
  eventbridge = true
}
```

### Publishing Custom Events

From Lambda functions:

```python
import boto3
import json

events = boto3.client('events')

response = events.put_events(
    Entries=[
        {
            'Source': 'aperture.datasets',
            'DetailType': 'Dataset Publication Requested',
            'Detail': json.dumps({
                'dataset_id': 'ecology-2024-001',
                'user_id': 'researcher-123',
                'publication_type': 'doi'
            }),
            'EventBusName': 'aperture-dev-events'
        }
    ]
)
```

From AWS CLI:

```bash
aws events put-events \
  --entries file://event.json \
  --event-bus-name aperture-dev-events
```

**event.json**:
```json
[
  {
    "Source": "aperture.processing",
    "DetailType": "Processing Job Failed",
    "Detail": "{\"job_id\":\"job-123\",\"error\":\"FFmpeg timeout\"}",
    "EventBusName": "aperture-dev-events"
  }
]
```

## Event Archive and Replay

### Why Use Event Archive?

- **Debugging**: Replay events to test fixes
- **Disaster Recovery**: Replay events after Lambda failures
- **Testing**: Replay production events in dev/staging
- **Compliance**: Audit trail of all events

### Replaying Events

```bash
# Start a replay
aws events start-replay \
  --replay-name test-replay-20241109 \
  --event-source-arn arn:aws:events:us-east-1:123456789012:event-bus/aperture-dev-events \
  --event-start-time 2024-11-09T00:00:00Z \
  --event-end-time 2024-11-09T23:59:59Z \
  --destination '{
    "Arn": "arn:aws:events:us-east-1:123456789012:rule/aperture-dev-s3-object-created"
  }'

# Check replay status
aws events describe-replay --replay-name test-replay-20241109

# Cancel replay if needed
aws events cancel-replay --replay-name test-replay-20241109
```

## Integration with Lambda

### Lambda Permission

EventBridge automatically creates permissions for Lambda targets, but you can also add them explicitly:

```hcl
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.media_processing.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}
```

### Lambda Event Structure

```python
def lambda_handler(event, context):
    # EventBridge event structure
    print(event['source'])       # e.g., "aws.s3"
    print(event['detail-type'])  # e.g., "Object Created"
    print(event['detail'])       # Event-specific data
    print(event['time'])         # Event timestamp
    print(event['region'])       # AWS region
    print(event['resources'])    # Resource ARNs

    # For S3 events
    bucket = event['detail']['bucket']['name']
    key = event['detail']['object']['key']
    size = event['detail']['object']['size']

    return {
        'statusCode': 200,
        'body': 'Event processed successfully'
    }
```

## Cost Considerations

### EventBridge Pricing (as of 2024)

**Event Publishing**:
- First 1M custom events/month: FREE
- Additional custom events: $1.00 per million
- AWS service events (S3, DynamoDB): Always free

**Event Replay**:
- $0.01 per GB replayed

**Schema Registry**: Not used by this module (free tier available)

### Cost Optimization

1. **Event Filtering**: Use detailed event patterns to reduce unnecessary Lambda invocations

**Poor** (matches all S3 events):
```json
{
  "source": ["aws.s3"]
}
```

**Better** (matches only specific bucket):
```json
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["aperture-prod-processing"]
    }
  }
}
```

**Best** (matches specific bucket and file types):
```json
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["aperture-prod-processing"]
    },
    "object": {
      "key": [{
        "suffix": ".mp4"
      }]
    }
  }
}
```

2. **Batch Events**: If possible, batch multiple operations and publish single events
3. **Archive Retention**: Use shorter retention periods in dev/staging (90 days in prod, 7 days in dev)
4. **Dead Letter Queue**: Prevent infinite retry loops that generate events

### Example Monthly Costs

**Small Repository** (100 files/day):
- S3 events: 3,000/month = FREE
- Custom events: 0 = FREE
- **Total: $0/month**

**Medium Repository** (1,000 files/day):
- S3 events: 30,000/month = FREE
- Custom events: 10,000/month = FREE
- **Total: $0/month**

**Large Repository** (10,000 files/day):
- S3 events: 300,000/month = FREE
- Custom events: 50,000/month = FREE
- Event replay: 1 GB/month = $0.01
- **Total: $0.01/month**

**EventBridge is essentially free for typical repository workloads.**

## Monitoring and Logging

### CloudWatch Metrics

EventBridge automatically publishes metrics:

- `Invocations` - Number of times targets were invoked
- `FailedInvocations` - Number of failed target invocations
- `ThrottledRules` - Number of throttled rule evaluations
- `MatchedEvents` - Number of events matched by rules

**View in Console**: CloudWatch → Metrics → Events

### CloudWatch Logs

When `enable_eventbridge_logging = true`, all events are logged to:
```
/aws/events/aperture-{environment}
```

**Log Format**:
```json
{
  "version": "0",
  "id": "abc-123",
  "detail-type": "Object Created",
  "source": "aws.s3",
  "time": "2024-11-09T10:30:00Z",
  "region": "us-east-1",
  "detail": {
    "bucket": {
      "name": "aperture-dev-processing"
    },
    "object": {
      "key": "datasets/ecology-001/video.mp4"
    }
  }
}
```

### Alarms

Create CloudWatch alarms for failed invocations:

```hcl
resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
  alarm_name          = "eventbridge-failed-invocations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when EventBridge has 5+ failed invocations in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

## Troubleshooting

### Events Not Triggering Lambda

**Check**:
1. Lambda has correct permissions
```bash
aws lambda get-policy --function-name aperture-dev-media-processing
```

2. Event rule is enabled
```bash
aws events describe-rule --name aperture-dev-s3-object-created
```

3. Event pattern matches
```bash
aws events test-event-pattern \
  --event-pattern file://pattern.json \
  --event file://test-event.json
```

### DLQ Has Messages

**Investigate**:
```bash
# View DLQ messages
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123/aperture-dev-dlq \
  --max-number-of-messages 10

# Common causes:
# - Lambda timeout (increase timeout)
# - Lambda error (check CloudWatch Logs)
# - Permissions issue (check IAM roles)
# - Resource limit (check concurrency limits)
```

### S3 Events Not Appearing

**Enable S3 EventBridge notifications**:
```bash
aws s3api put-bucket-notification-configuration \
  --bucket aperture-dev-processing \
  --notification-configuration '{
    "EventBridgeConfiguration": {}
  }'
```

**Verify**:
```bash
aws s3api get-bucket-notification-configuration \
  --bucket aperture-dev-processing
```

### Scheduled Rule Not Running

**Check**:
1. Rule is enabled
2. Schedule expression is valid (validate at crontab.guru for cron expressions)
3. Target Lambda has correct permissions
4. Lambda is not timing out
5. Check CloudWatch Logs for the rule

**View recent invocations**:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name Invocations \
  --dimensions Name=RuleName,Value=aperture-dev-daily-lifecycle \
  --start-time 2024-11-08T00:00:00Z \
  --end-time 2024-11-09T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

## Security Best Practices

### 1. Least Privilege IAM Roles

This module creates separate IAM roles for different targets (Step Functions, SNS) with minimal permissions.

### 2. Resource-Based Policies

EventBridge uses resource-based policies instead of storing credentials.

### 3. Encryption

- Events in transit: TLS 1.2+
- Events at rest in archive: Server-side encryption

### 4. VPC Endpoints

For private EventBridge access:

```hcl
resource "aws_vpc_endpoint" "eventbridge" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.events"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.eventbridge.id]
  subnet_ids         = var.private_subnet_ids
}
```

### 5. Event Filtering

Filter events at the rule level to prevent unauthorized Lambda invocations.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | string | - | yes |
| environment | Environment (dev, staging, prod) | string | - | yes |
| processing_bucket_name | S3 processing bucket name | string | - | yes |
| doi_registry_table_name | DOI registry DynamoDB table | string | - | yes |
| media_processing_lambda_arn | Media processing Lambda ARN | string | "" | no |
| lifecycle_lambda_arn | Lifecycle Lambda ARN | string | "" | no |
| budget_report_lambda_arn | Budget report Lambda ARN | string | "" | no |
| doi_notification_lambda_arn | DOI notification Lambda ARN | string | "" | no |
| publication_workflow_arn | Publication workflow Step Functions ARN | string | "" | no |
| alert_sns_topic_arn | Alert SNS topic ARN | string | "" | no |
| dlq_arn | Dead Letter Queue ARN | string | "" | no |
| lifecycle_schedule_expression | Lifecycle cron/rate expression | string | cron(0 2 * * ? *) | no |
| budget_report_schedule_expression | Budget report cron/rate expression | string | cron(0 9 ? * MON *) | no |
| enable_event_archive | Enable event archive | bool | true | no |
| archive_retention_days | Archive retention days | number | 90 | no |
| enable_eventbridge_logging | Enable CloudWatch logging | bool | true | no |
| log_retention_days | Log retention days | number | 90 | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| event_bus_name | Custom event bus name |
| event_bus_arn | Custom event bus ARN |
| s3_object_created_rule_arn | S3 object created rule ARN |
| daily_lifecycle_rule_arn | Daily lifecycle rule ARN |
| weekly_budget_report_rule_arn | Weekly budget report rule ARN |
| eventbridge_step_functions_role_arn | IAM role for Step Functions |
| event_archive_arn | Event archive ARN |
| cloudwatch_log_group_name | Log group name |
| summary | Summary of all resources |

## References

- [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [EventBridge Event Patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
- [Schedule Expressions](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html)
- [EventBridge Pricing](https://aws.amazon.com/eventbridge/pricing/)
- [S3 EventBridge Integration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventBridge.html)
- [Cron Expression Reference](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-cron-expressions.html)

## License

Part of the Aperture Academic Media Repository Platform.
