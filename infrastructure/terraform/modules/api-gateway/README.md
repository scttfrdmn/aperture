# API Gateway Module

AWS HTTP API (API Gateway v2) for the Aperture academic media repository platform.

## Overview

This module deploys a high-performance HTTP API that exposes Lambda functions as REST API endpoints. It uses API Gateway v2 for better performance, lower cost, and simpler configuration compared to REST API (v1).

## Features

- **HTTP API (v2)**: Modern API Gateway with better performance and 70% cost savings
- **Cognito JWT Authorizer**: Automatic authentication for protected endpoints
- **CORS Support**: Configurable cross-origin resource sharing for web clients
- **Lambda Integrations**: Seamless integration with backend Lambda functions
- **CloudWatch Logging**: Comprehensive access logs with JSON formatting
- **Throttling**: Configurable rate limits and burst protection
- **Custom Domain**: Optional custom domain with ACM certificate
- **Auto-Deploy**: Automatic deployment on configuration changes

## API Endpoints

### Authentication (Public)
- `POST /auth/login` - User login with username/password
- `POST /auth/refresh` - Refresh access token

### Authentication (Protected)
- `POST /auth/logout` - User logout (requires JWT)
- `GET /auth/verify` - Verify JWT token (requires JWT)

### Presigned URLs (Protected)
- `POST /urls/generate` - Generate single presigned URL (requires JWT)
- `POST /urls/batch` - Generate batch presigned URLs (requires JWT, max 100)

### DOI Management (Protected)
- `POST /doi/mint` - Mint new DOI (requires JWT, researchers+)
- `PUT /doi/{id}` - Update DOI metadata (requires JWT, researchers+)
- `DELETE /doi/{id}` - Tombstone DOI (requires JWT, admins only)

## Usage

```hcl
module "api_gateway" {
  source = "./infrastructure/terraform/modules/api-gateway"

  project_name = "aperture"
  environment  = "prod"

  # Cognito Configuration
  cognito_user_pool_id   = module.cognito.user_pool_id
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_app_client_id  = module.cognito.web_app_client_id

  # Lambda Functions
  auth_lambda_name              = module.lambda_functions.auth_lambda_name
  auth_lambda_arn               = module.lambda_functions.auth_lambda_arn
  auth_lambda_invoke_arn        = module.lambda_functions.auth_lambda_invoke_arn

  presigned_urls_lambda_name         = module.lambda_functions.presigned_urls_lambda_name
  presigned_urls_lambda_arn          = module.lambda_functions.presigned_urls_lambda_arn
  presigned_urls_lambda_invoke_arn   = module.lambda_functions.presigned_urls_lambda_invoke_arn

  doi_minting_lambda_name       = module.lambda_functions.doi_minting_lambda_name
  doi_minting_lambda_arn        = module.lambda_functions.doi_minting_lambda_arn
  doi_minting_lambda_invoke_arn = module.lambda_functions.doi_minting_lambda_invoke_arn

  # CORS Configuration
  cors_allowed_origins = ["https://repo.university.edu", "http://localhost:3000"]

  # Throttling
  throttling_burst_limit = 500
  throttling_rate_limit  = 1000

  # Optional: Custom Domain
  custom_domain_name = "api.repo.university.edu"
  certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/..."

  tags = {
    Component = "API"
  }
}
```

## Authentication Flow

### Public Endpoints
```bash
# No authentication required
curl -X POST https://api-endpoint/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "user@example.com", "password": "password"}'
```

### Protected Endpoints
```bash
# Include JWT token in Authorization header
curl -X POST https://api-endpoint/urls/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{"bucket": "public", "key": "dataset/video.mp4"}'
```

## CORS Configuration

The API supports configurable CORS with:
- **Methods**: GET, POST, PUT, DELETE, OPTIONS
- **Headers**: content-type, authorization, x-api-key
- **Credentials**: Enabled for authenticated requests
- **Max Age**: 300 seconds (5 minutes)

Configure allowed origins:
```hcl
cors_allowed_origins = [
  "https://repo.university.edu",    # Production frontend
  "https://staging.repo.edu",       # Staging frontend
  "http://localhost:3000"           # Local development
]
```

## Throttling

Protect your API from excessive requests:

- **Burst Limit**: Maximum requests in a burst (default: 500)
- **Rate Limit**: Sustained requests per second (default: 1000)

```hcl
throttling_burst_limit = 500   # requests
throttling_rate_limit  = 1000  # requests/second
```

## Logging

API Gateway logs all requests to CloudWatch with JSON formatting:

```json
{
  "requestId": "abc123",
  "ip": "192.168.1.1",
  "requestTime": "2025-11-09T12:00:00Z",
  "httpMethod": "POST",
  "routeKey": "POST /auth/login",
  "status": 200,
  "protocol": "HTTP/1.1",
  "responseLength": 1234,
  "errorMessage": null,
  "authorizerError": null,
  "integrationError": null
}
```

**Log Retention**: Default 90 days (configurable)

## Custom Domain

Optional custom domain configuration with ACM certificate:

```hcl
custom_domain_name = "api.repo.university.edu"
certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/..."
```

### DNS Configuration

After applying, configure Route53 or your DNS provider:

```hcl
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.repo.university.edu"
  type    = "A"

  alias {
    name                   = module.api_gateway.custom_domain_target
    zone_id                = module.api_gateway.custom_domain_hosted_zone_id
    evaluate_target_health = false
  }
}
```

## Cost Estimate

**HTTP API Pricing** (as of 2025):
- First 300M requests: $1.00 per million
- Next 700M requests: $0.90 per million
- Over 1B requests: $0.80 per million

**Example Monthly Costs**:
- 1M requests: ~$1.00
- 10M requests: ~$10.00
- 100M requests: ~$97.00

**Additional Costs**:
- CloudWatch Logs: ~$0.50 per GB ingested + $0.03 per GB stored
- Data Transfer: $0.09 per GB out to internet

**Total Estimate** (1M requests/month): ~$1.50

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_name | Project name | string | yes |
| environment | Environment (dev/staging/prod) | string | yes |
| cognito_user_pool_id | Cognito User Pool ID | string | yes |
| cognito_app_client_id | Cognito App Client ID | string | yes |
| auth_lambda_name | Auth Lambda function name | string | yes |
| auth_lambda_invoke_arn | Auth Lambda invoke ARN | string | yes |
| presigned_urls_lambda_name | Presigned URLs Lambda name | string | yes |
| presigned_urls_lambda_invoke_arn | Presigned URLs Lambda invoke ARN | string | yes |
| doi_minting_lambda_name | DOI minting Lambda name | string | yes |
| doi_minting_lambda_invoke_arn | DOI minting Lambda invoke ARN | string | yes |
| cors_allowed_origins | Allowed CORS origins | list(string) | no (default: ["*"]) |
| throttling_burst_limit | Throttling burst limit | number | no (default: 500) |
| throttling_rate_limit | Throttling rate limit (req/sec) | number | no (default: 1000) |
| log_retention_days | Log retention days | number | no (default: 90) |
| custom_domain_name | Custom domain name | string | no (default: "") |
| certificate_arn | ACM certificate ARN | string | no (default: "") |

## Outputs

| Name | Description |
|------|-------------|
| api_id | HTTP API ID |
| api_endpoint | API endpoint URL |
| stage_invoke_url | Stage invoke URL (use this for API calls) |
| api_execution_arn | API execution ARN |
| authorizer_id | Cognito authorizer ID |
| log_group_name | CloudWatch log group name |
| routes | Map of all configured routes |
| summary | Summary of API resources |

## Example API Requests

### Login
```bash
curl -X POST https://<api-endpoint>/prod/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "researcher@university.edu",
    "password": "SecurePassword123!"
  }'

# Response
{
  "accessToken": "eyJra...",
  "idToken": "eyJra...",
  "refreshToken": "eyJra...",
  "expiresIn": 3600
}
```

### Generate Presigned URL
```bash
curl -X POST https://<api-endpoint>/prod/urls/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -d '{
    "bucket": "public",
    "key": "datasets/2024/video.mp4",
    "expiration": 3600
  }'

# Response
{
  "url": "https://s3.amazonaws.com/bucket/...",
  "expiresIn": 3600
}
```

### Mint DOI
```bash
curl -X POST https://<api-endpoint>/prod/doi/mint \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -d '{
    "title": "Research Dataset 2024",
    "creators": [{"name": "John Doe", "orcid": "0000-0001-2345-6789"}],
    "publisher": "University Repository",
    "publicationYear": 2024,
    "resourceType": "Dataset"
  }'

# Response
{
  "doi": "10.5555/12345",
  "url": "https://doi.org/10.5555/12345",
  "state": "draft"
}
```

## Troubleshooting

### 401 Unauthorized on Protected Endpoints
**Cause**: Missing or invalid JWT token

**Solution**: Include valid JWT token in Authorization header:
```bash
Authorization: Bearer eyJraWQiOiI...
```

### 403 Forbidden - Invalid JWT
**Cause**: Token audience doesn't match or token expired

**Solution**:
1. Verify token is from correct Cognito User Pool
2. Check token expiration (`exp` claim)
3. Refresh token if expired

### 429 Too Many Requests
**Cause**: Exceeded throttling limits

**Solution**:
1. Implement exponential backoff in client
2. Increase throttling limits if needed
3. Review usage patterns

### CORS Errors in Browser
**Cause**: Origin not in allowed list

**Solution**: Add your origin to `cors_allowed_origins`:
```hcl
cors_allowed_origins = ["https://your-frontend.com"]
```

### Lambda Timeout Errors
**Cause**: Lambda function exceeded timeout

**Solution**: Check Lambda CloudWatch logs and increase timeout if needed

## Security

- **JWT Authentication**: All protected endpoints require valid Cognito JWT tokens
- **CORS**: Restrict origins to trusted domains in production
- **Throttling**: Prevent abuse with configurable rate limits
- **CloudWatch Logging**: Full audit trail of all API requests
- **HTTPS Only**: TLS 1.2+ enforced for custom domains
- **Least Privilege**: Lambda permissions limited to API Gateway invocation

## Performance

- **HTTP API**: Up to 2x faster than REST API (v1)
- **Auto-scaling**: Automatically scales to handle traffic
- **Regional Endpoint**: Low latency for users in deployment region
- **Payload Format 2.0**: Reduced overhead for Lambda integrations

## License

Part of the Aperture Academic Media Repository Platform.
