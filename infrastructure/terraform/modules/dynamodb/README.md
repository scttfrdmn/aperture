# DynamoDB Module

This module creates and manages all DynamoDB tables for the Aperture platform.

## Tables Created

### 1. Users Table
Stores user accounts, roles, and permissions.

**Schema:**
- `user_id` (Hash Key): Unique user identifier
- `created_at` (Range Key): Account creation timestamp
- `email`: User email address
- `orcid`: ORCID identifier
- Additional attributes: name, role, permissions, status, etc.

**Indexes:**
- `EmailIndex`: Query users by email
- `OrcidIndex`: Query users by ORCID

### 2. DOI Registry Table
Stores DOI metadata and landing page information.

**Schema:**
- `doi` (Hash Key): DOI identifier (e.g., 10.5555/example.2024.001)
- `version` (Range Key): DOI version number
- `dataset_id`: Associated dataset ID
- `status`: DOI status (draft, registered, published, tombstone)
- `minted_at`: DOI creation timestamp
- Additional attributes: metadata, landing_page_url, etc.

**Indexes:**
- `DatasetIndex`: Query DOIs by dataset ID
- `StatusIndex`: Query DOIs by status

### 3. Access Logs Table
Stores summarized access patterns and analytics.

**Schema:**
- `dataset_id` (Hash Key): Dataset being accessed
- `timestamp` (Range Key): Access timestamp
- `user_id`: User who accessed the dataset
- `date`: Access date (YYYY-MM-DD)
- Additional attributes: action, ip_address, user_agent, etc.

**Indexes:**
- `UserAccessIndex`: Query access patterns by user
- `DateIndex`: Query access patterns by date

**TTL:** Enabled (90 days default via `expiration_time` attribute)

### 4. Budget Tracking Table
Stores cost tracking and budget alerts.

**Schema:**
- `resource_id` (Hash Key): Resource identifier
- `month` (Range Key): Month (YYYY-MM)
- `account_id`: AWS account ID
- `cost_category`: Cost category (storage, compute, transfer, etc.)
- Additional attributes: cost, currency, budget, alert_threshold, etc.

**Indexes:**
- `AccountCostIndex`: Query costs by account
- `CategoryIndex`: Query costs by category

## Features

- **Encryption**: Server-side encryption enabled (with optional KMS)
- **Backup**: Point-in-time recovery enabled by default
- **Auto-scaling**: Configurable for provisioned capacity mode
- **TTL**: Enabled for access logs to auto-delete old data
- **Global Secondary Indexes**: Optimized for common query patterns

## Usage

### Basic Usage (Pay-per-request)

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = "aperture"
  environment  = "prod"
  billing_mode = "PAY_PER_REQUEST"

  enable_point_in_time_recovery = true
  enable_logs_ttl               = true

  tags = {
    Project     = "Aperture"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
```

### Provisioned Capacity with Auto-scaling

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = "aperture"
  environment  = "prod"
  billing_mode = "PROVISIONED"

  # Users table capacity
  users_read_capacity      = 10
  users_write_capacity     = 10
  users_read_max_capacity  = 100
  users_write_max_capacity = 100

  # DOI registry capacity
  doi_read_capacity  = 5
  doi_write_capacity = 5

  # Access logs capacity (higher write throughput)
  logs_read_capacity  = 5
  logs_write_capacity = 20

  # Budget tracking capacity (low throughput)
  budget_read_capacity  = 2
  budget_write_capacity = 2

  enable_autoscaling       = true
  autoscaling_target_value = 70

  enable_point_in_time_recovery = true
  enable_logs_ttl               = true

  tags = {
    Project = "Aperture"
  }
}
```

### With Custom KMS Encryption

```hcl
resource "aws_kms_key" "dynamodb" {
  description = "KMS key for DynamoDB encryption"
}

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = "aperture"
  environment  = "prod"
  billing_mode = "PAY_PER_REQUEST"

  kms_key_arn                   = aws_kms_key.dynamodb.arn
  enable_point_in_time_recovery = true

  tags = {
    Project = "Aperture"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | - | yes |
| environment | Environment (dev, staging, prod) | string | - | yes |
| billing_mode | Billing mode (PAY_PER_REQUEST or PROVISIONED) | string | "PAY_PER_REQUEST" | no |
| enable_point_in_time_recovery | Enable PITR for tables | bool | true | no |
| enable_autoscaling | Enable auto-scaling (PROVISIONED only) | bool | true | no |
| autoscaling_target_value | Target utilization % for auto-scaling | number | 70 | no |
| enable_logs_ttl | Enable TTL for access logs | bool | true | no |
| kms_key_arn | KMS key ARN for encryption | string | null | no |
| users_read_capacity | Users table read capacity (PROVISIONED only) | number | 5 | no |
| users_write_capacity | Users table write capacity (PROVISIONED only) | number | 5 | no |
| users_read_max_capacity | Max read capacity for scaling | number | 100 | no |
| users_write_max_capacity | Max write capacity for scaling | number | 100 | no |
| doi_read_capacity | DOI table read capacity (PROVISIONED only) | number | 5 | no |
| doi_write_capacity | DOI table write capacity (PROVISIONED only) | number | 5 | no |
| logs_read_capacity | Logs table read capacity (PROVISIONED only) | number | 5 | no |
| logs_write_capacity | Logs table write capacity (PROVISIONED only) | number | 10 | no |
| budget_read_capacity | Budget table read capacity (PROVISIONED only) | number | 2 | no |
| budget_write_capacity | Budget table write capacity (PROVISIONED only) | number | 2 | no |
| tags | Additional tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| users_table_name | Users table name |
| users_table_arn | Users table ARN |
| doi_registry_table_name | DOI registry table name |
| doi_registry_table_arn | DOI registry table ARN |
| access_logs_table_name | Access logs table name |
| access_logs_table_arn | Access logs table ARN |
| budget_tracking_table_name | Budget tracking table name |
| budget_tracking_table_arn | Budget tracking table ARN |
| all_table_names | List of all table names |
| all_table_arns | List of all table ARNs |

## Cost Optimization

### Pay-per-request (Recommended for Development and Variable Workloads)
- **No capacity planning needed**
- **Cost**: $1.25 per million write requests, $0.25 per million read requests
- **Best for**: Development, staging, unpredictable workloads
- **Example cost**: 1M writes + 5M reads = $2.50

### Provisioned Capacity (Recommended for Predictable Workloads)
- **Requires capacity planning**
- **Cost**: $0.00065/hour per WCU, $0.00013/hour per RCU
- **Auto-scaling available**
- **Best for**: Production with consistent traffic
- **Example cost**: 10 WCU + 10 RCU = ~$56/month

### Storage Costs
- **Standard**: $0.25/GB/month
- **With PITR**: Additional $0.20/GB/month
- **Example**: 100GB with PITR = $45/month

## Security

- ✅ Encryption at rest enabled by default
- ✅ Optional KMS encryption
- ✅ Point-in-time recovery available
- ✅ IAM-based access control
- ✅ VPC endpoints supported (configure separately)

## Monitoring

Monitor these CloudWatch metrics:
- `ConsumedReadCapacityUnits`
- `ConsumedWriteCapacityUnits`
- `UserErrors`
- `SystemErrors`
- `ConditionalCheckFailedRequests`

## Backup Strategy

1. **Point-in-time recovery**: Enabled by default, 35-day retention
2. **On-demand backups**: Create via AWS Console or CLI when needed
3. **Cross-region replication**: Configure separately if required

## Migration

To migrate existing data:
1. Export from source using AWS Data Pipeline or custom script
2. Transform to match schema
3. Import using DynamoDB batch write operations
4. Verify data integrity
5. Update application configuration

## License

Copyright 2025 Scott Friedman

Licensed under the Apache License, Version 2.0.
