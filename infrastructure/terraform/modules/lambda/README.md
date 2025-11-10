# Lambda Module

AWS Lambda functions for the Aperture academic media repository platform.

## Overview

This module deploys serverless Lambda functions that provide core backend functionality:

- **Auth**: User authentication with Cognito (login, refresh, logout, verify)
- **Presigned URLs**: Temporary S3 access URL generation with permission checks
- **DOI Minting**: DataCite DOI registration and management

## Lambda Functions

### Auth Lambda
Handles user authentication operations with AWS Cognito.

**Operations**:
- `login`: Username/password authentication
- `refresh`: Token refresh
- `logout`: Global sign-out
- `verify`: JWT token validation

**Runtime**: Python 3.11 | **Timeout**: 30s | **Memory**: 256 MB

### Presigned URLs Lambda
Generates temporary signed URLs for S3 object access with RBAC.

**Operations**:
- `generate`: Single URL generation
- `batch`: Multiple URL generation (max 100)

**Access Control**:
- Public bucket: Anyone
- Private bucket: Researchers+
- Restricted/Embargoed: Dataset-specific permissions

**Runtime**: Python 3.11 | **Timeout**: 30s | **Memory**: 256 MB

### DOI Minting Lambda
Integrates with DataCite API for DOI lifecycle management.

**Operations**:
- `mint`: Register new DOI
- `update`: Update DOI metadata
- `delete`: Tombstone DOI

**Runtime**: Python 3.11 | **Timeout**: 60s | **Memory**: 512 MB

## Usage

```hcl
module "lambda_functions" {
  source = "./infrastructure/terraform/modules/lambda"

  project_name = "aperture"
  environment  = "prod"

  # Cognito
  cognito_user_pool_id   = module.cognito.user_pool_id
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_app_client_id  = module.cognito.web_app_client_id

  # S3 Buckets
  public_media_bucket_name     = module.s3_buckets.public_media_bucket_name
  public_media_bucket_arn      = module.s3_buckets.public_media_bucket_arn
  private_media_bucket_name    = module.s3_buckets.private_media_bucket_name
  private_media_bucket_arn     = module.s3_buckets.private_media_bucket_arn
  restricted_media_bucket_name = module.s3_buckets.restricted_media_bucket_name
  restricted_media_bucket_arn  = module.s3_buckets.restricted_media_bucket_arn
  embargoed_media_bucket_name  = module.s3_buckets.embargoed_media_bucket_name
  embargoed_media_bucket_arn   = module.s3_buckets.embargoed_media_bucket_arn

  # DynamoDB Tables
  doi_registry_table_name  = module.dynamodb.doi_registry_table_name
  doi_registry_table_arn   = module.dynamodb.doi_registry_table_arn
  users_table_name         = module.dynamodb.users_table_name
  users_table_arn          = module.dynamodb.users_table_arn
  access_logs_table_name   = module.dynamodb.access_logs_table_name
  access_logs_table_arn    = module.dynamodb.access_logs_table_arn
  budget_tracking_table_name = module.dynamodb.budget_tracking_table_name
  budget_tracking_table_arn  = module.dynamodb.budget_tracking_table_arn

  # DataCite
  datacite_username = var.datacite_username
  datacite_password = var.datacite_password
  doi_prefix        = var.doi_prefix
  repo_base_url     = "https://repo.university.edu"

  # Optional: API Gateway integration
  api_gateway_execution_arn = module.api_gateway.execution_arn

  tags = {
    Component = "Backend"
  }
}
```

## IAM Permissions

### Auth Lambda
- `cognito-idp:InitiateAuth`
- `cognito-idp:GetUser`
- `cognito-idp:GlobalSignOut`

### Presigned URLs Lambda
- `s3:GetObject` on all media buckets
- `dynamodb:PutItem` on access logs table
- `dynamodb:Query` on DOI registry table

### DOI Minting Lambda
- `dynamodb:PutItem`, `dynamodb:UpdateItem`, `dynamodb:Query` on DOI registry
- `s3:GetObject`, `s3:PutObject` on public media bucket

## Cost Estimate

**Monthly cost** (1M requests):
- Compute: ~$16.50
- Logs (90-day retention): ~$5.00
- **Total**: ~$21.50/month

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_name | Project name | string | yes |
| environment | Environment (dev/staging/prod) | string | yes |
| cognito_user_pool_id | Cognito User Pool ID | string | yes |
| cognito_app_client_id | Cognito App Client ID | string | yes |
| public_media_bucket_name | Public media bucket name | string | yes |
| doi_registry_table_name | DOI registry table name | string | yes |
| datacite_username | DataCite API username | string | yes |
| datacite_password | DataCite API password | string | yes |
| doi_prefix | DOI prefix (e.g., 10.5555) | string | yes |
| repo_base_url | Repository base URL | string | yes |
| log_retention_days | Log retention days | number | no (default: 90) |

## Outputs

| Name | Description |
|------|-------------|
| auth_lambda_arn | Auth Lambda ARN |
| auth_lambda_invoke_arn | Auth Lambda invoke ARN |
| presigned_urls_lambda_arn | Presigned URLs Lambda ARN |
| doi_minting_lambda_arn | DOI minting Lambda ARN |
| summary | Summary of all Lambda resources |

## Development

### Adding New Lambda Functions

1. Create function directory: `lambda/new-function/`
2. Add `handler.py` and `requirements.txt`
3. Add IAM role and policy in `main.tf`
4. Add archive data source
5. Add Lambda function resource
6. Add outputs

### Local Testing

```bash
# Install dependencies
cd lambda/auth
pip install -r requirements.txt

# Test locally with sample event
python -c "
import handler
import json
event = {'body': json.dumps({'operation': 'verify'})}
print(handler.lambda_handler(event, {}))
"
```

## Troubleshooting

### Lambda Function Not Found
Ensure Terraform packaged the Lambda:
```bash
ls infrastructure/terraform/modules/lambda/packages/
```

### Permission Denied Errors
Check IAM role policies in AWS Console → IAM → Roles

### Timeout Errors
Increase `timeout` in Lambda function resource or optimize code

## Security

- All functions use least-privilege IAM roles
- Secrets stored in environment variables (consider AWS Secrets Manager for production)
- CloudWatch logging enabled for audit trails
- CORS headers restrict cross-origin access

## License

Part of the Aperture Academic Media Repository Platform.
