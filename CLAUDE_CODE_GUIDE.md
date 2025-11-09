# Claude Code Implementation Guide
## Academic Media Repository - Complete Build Instructions

This document provides step-by-step instructions for Claude Code to complete the entire academic media repository system.

## Project Overview

An AWS serverless repository for academic image, video, and audio data with:
- FAIR principles compliance
- DOI minting via DataCite
- Intelligent cost-optimized storage tiering
- Automated media processing (thumbnails, proxies, transcription)
- RBAC with ORCID integration
- Budget controls and lifecycle management
- OAI-PMH metadata harvesting

## Current Status

✅ **Completed:**
- Project documentation (README.md)
- Main Terraform configuration
- S3 buckets module with intelligent tiering

🔨 **Remaining Work:**

### 1. Complete Terraform Infrastructure

#### 1.1 DynamoDB Module (`infrastructure/terraform/modules/dynamodb/main.tf`)
Create 4 tables:

**Table 1: Users & Permissions**
```hcl
- Partition key: user_id (string)
- Attributes: orcid, email, role (admin/pi/researcher/reviewer), created_at, last_login
- GSI on orcid for ORCID lookups
- TTL on last_login for inactive user cleanup
```

**Table 2: DOI Registry**
```hcl
- Partition key: doi (string)
- Attributes: dataset_id, s3_location, metadata_json, minted_at, status (draft/published)
- GSI on dataset_id for reverse lookups
```

**Table 3: Access Logs Summary**
```hcl
- Partition key: dataset_id (string)
- Sort key: date (string, YYYY-MM-DD)
- Attributes: access_count, unique_users, egress_gb, cost_usd
- TTL on date for cleanup after 7 years
```

**Table 4: Budget Tracking**
```hcl
- Partition key: month (string, YYYY-MM)
- Attributes: storage_cost, egress_cost, compute_cost, total_cost, alert_sent
```

#### 1.2 Cognito Module (`infrastructure/terraform/modules/cognito/main.tf`)
```hcl
- User pool with email + ORCID attributes
- ORCID SAML/OIDC federation
- User groups: public, authenticated, researcher, pi, admin
- Lambda triggers for pre-signup (ORCID validation)
- MFA optional for admin users
```

#### 1.3 Lambda Module (`infrastructure/terraform/modules/lambda/main.tf`)
Create all Lambda functions with proper IAM roles:
- Use Lambda layers for shared dependencies (boto3, PIL, ffmpeg-python)
- Set appropriate memory and timeout
- Environment variables for bucket names, table names, API keys

**Lambda Functions Needed:**
1. `auth-handler` - Authentication and authorization
2. `doi-minting` - DataCite API integration
3. `presigned-urls` - Generate S3 presigned URLs
4. `access-control` - Check permissions
5. `bulk-upload-coordinator` - Manage multipart uploads
6. `oai-pmh-endpoint` - Metadata harvesting
7. `frame-extraction` - Extract video frames/audio samples
8. `metadata-query` - S3 Select queries
9. `media-processing` - Thumbnail/proxy generation (use FFmpeg Layer)
10. `lifecycle-management` - Tiering and cleanup
11. `budget-alert` - Cost monitoring
12. `transcription-trigger` - AWS Transcribe integration
13. `duplicate-detection` - Perceptual hashing

#### 1.4 API Gateway Module (`infrastructure/terraform/modules/api-gateway/main.tf`)
```hcl
REST API with:
- Cognito authorizer
- Usage plans and API keys for programmatic access
- Request/response models for validation
- CORS configuration
- CloudWatch logging

Endpoints:
POST   /auth/login
POST   /auth/refresh
GET    /datasets
GET    /datasets/{id}
POST   /datasets
PUT    /datasets/{id}
DELETE /datasets/{id}
POST   /datasets/{id}/doi
GET    /datasets/{id}/presigned-url
POST   /datasets/{id}/bulk-upload/initiate
POST   /datasets/{id}/bulk-upload/complete
GET    /datasets/{id}/frames/{frame_number}
GET    /datasets/{id}/audio-segment
GET    /oai-pmh
POST   /admin/users
GET    /admin/budget
GET    /admin/logs
```

#### 1.5 CloudFront Module (`infrastructure/terraform/modules/cloudfront/main.tf`)
```hcl
- Two origins: Frontend bucket + Public media bucket
- Origin Access Identity (OAI) for S3 access
- Cache behaviors:
  - Frontend: Cache everything (1 year TTL)
  - Media: Cache heavily (30 days TTL)
  - API: No caching
- Custom error pages
- HTTPS only with ACM certificate
- Geo-restriction (optional)
- Real-time logs to S3
```

#### 1.6 EventBridge Module (`infrastructure/terraform/modules/eventbridge/main.tf`)
```hcl
Rules:
1. S3 ObjectCreated → media-processing Lambda (thumbnails, proxies)
2. S3 ObjectCreated (audio) → transcription-trigger Lambda
3. Schedule (daily) → lifecycle-management Lambda
4. Schedule (monthly) → budget-alert Lambda
5. Schedule (daily) → embargo-release-check Lambda
```

#### 1.7 Budgets Module (`infrastructure/terraform/modules/budgets/main.tf`)
```hcl
- AWS Budget for monthly spend
- SNS topic for alerts
- CloudWatch alarms for:
  - Storage > threshold
  - Egress > threshold
  - Lambda invocations > threshold
```

#### 1.8 Athena Module (`infrastructure/terraform/modules/athena/main.tf`)
```hcl
- Glue database for S3 access logs
- Glue crawler (daily) to catalog logs
- Saved queries for:
  - Top 10 accessed datasets
  - Egress by dataset
  - User activity
  - Compliance reports
```

### 2. Lambda Functions Implementation

Create all Lambda functions in `lambda/` directory:

#### 2.1 DOI Minting (`lambda/doi/handler.py`)
```python
# Core functionality:
# 1. Validate dataset metadata completeness
# 2. Generate DataCite XML from JSON-LD metadata
# 3. POST to DataCite API
# 4. Store DOI in DynamoDB
# 5. Update dataset manifest with DOI
# 6. Trigger landing page generation

# Dependencies: requests, boto3, jinja2
# Environment: DATACITE_API_URL, DATACITE_USERNAME, DATACITE_PASSWORD
```

#### 2.2 Media Processing (`lambda/media-processing/handler.py`)
```python
# Core functionality:
# 1. Detect media type (image/video/audio)
# 2. Extract metadata (EXIF, container metadata, BWF)
# 3. Generate thumbnails/previews:
#    - Images: 150px, 500px, 1200px
#    - Video: Thumbnails at 0%, 25%, 50%, 75% + contact sheet
#    - Audio: Waveform PNG, spectrogram
# 4. Generate proxy files:
#    - Video: 480p H.264 + HLS playlist
#    - Audio: 128kbps MP3
# 5. Store outputs in processing bucket
# 6. Update manifest with derivative URLs

# Dependencies: Pillow, ffmpeg-python, exiftool, boto3, mutagen
# Lambda Layer: FFmpeg binary
```

#### 2.3 Bulk Upload Coordinator (`lambda/bulk-upload/handler.py`)
```python
# Core functionality:
# 1. Initiate multipart uploads for all files
# 2. Return presigned URLs for each part
# 3. Track upload progress in DynamoDB
# 4. Verify checksums
# 5. Complete multipart upload
# 6. Trigger media processing pipeline
# 7. Generate manifest

# Handle 10,000+ files efficiently with pagination
```

#### 2.4 Lifecycle Management (`lambda/lifecycle/handler.py`)
```python
# Core functionality:
# 1. Query S3 access logs (via Athena)
# 2. Identify datasets with no access in N days
# 3. Update object tags to trigger lifecycle transitions
# 4. Check for orphaned data (users with last_login > 2 years)
# 5. Send notifications before tiering
# 6. Release embargoes (check DynamoDB for embargo_until)
# 7. Update DOI metadata on status changes

# Runs daily via EventBridge
```

#### 2.5 OAI-PMH Endpoint (`lambda/oai-pmh/handler.py`)
```python
# Core functionality:
# Implement OAI-PMH 2.0 protocol verbs:
# - Identify
# - ListMetadataFormats (Dublin Core, DataCite)
# - ListSets
# - ListIdentifiers
# - ListRecords
# - GetRecord

# Query S3 for manifests, convert to OAI-PMH XML
# Support resumption tokens for large result sets
```

#### 2.6 Transcription Trigger (`lambda/transcription/handler.py`)
```python
# Core functionality:
# 1. Triggered by audio file upload
# 2. Start AWS Transcribe job
# 3. Store job ID in DynamoDB
# 4. On completion (separate Lambda):
#    - Fetch WebVTT/SRT transcript
#    - Store in processing bucket
#    - Update manifest with transcript URL
#    - Index transcript for full-text search

# Cost tracking: Record transcription minutes
```

### 3. Frontend Application

Create React frontend in `frontend/src/`:

#### 3.1 Core Components

**App.js** - Main routing
```javascript
Routes:
- / (Home/Browse)
- /dataset/:id (Dataset view)
- /upload (Bulk upload interface)
- /admin (Admin dashboard)
- /login (Cognito auth)
```

**DatasetBrowser.js** - Grid view with filters
```javascript
- Thumbnail grid
- Filters: date, type (image/video/audio), subject, creator
- Search: full-text across metadata
- Pagination
```

**DatasetViewer.js** - Single dataset view
```javascript
- Metadata display (JSON-LD)
- File list with previews
- Video player with HLS.js
- Audio player with waveform
- Image viewer with zoom
- Download buttons (presigned URLs)
- Citation widget
- DOI badge
```

**BulkUploader.js** - Drag-drop interface
```javascript
- Directory upload support
- Progress bars per file
- Chunked multipart upload (5MB chunks)
- Metadata form (shared across files)
- Checksum calculation (Web Crypto API)
- Retry logic for failed parts
```

**AdminDashboard.js**
```javascript
- Budget charts (Chart.js)
- Storage usage by tier
- Top accessed datasets
- User management
- DOI minting queue
```

#### 3.2 Authentication (`src/utils/auth.js`)
```javascript
// Amplify integration with Cognito
// ORCID login flow
// Token refresh
// Role-based UI rendering
```

#### 3.3 API Client (`src/utils/api.js`)
```javascript
// Axios instance with auth headers
// All API Gateway endpoints
// Error handling and retries
```

### 4. Scripts and Utilities

Create helper scripts in `scripts/`:

#### 4.1 `scripts/deploy.sh`
```bash
#!/bin/bash
# Full deployment script
# 1. Build frontend (npm run build)
# 2. Package Lambda functions (zip with dependencies)
# 3. Upload Lambda packages to S3
# 4. terraform init && terraform apply
# 5. Upload frontend to S3
# 6. Invalidate CloudFront cache
```

#### 4.2 `scripts/seed-data.sh`
```bash
# Upload sample datasets for testing
# Generate test users
# Create test DOIs
```

#### 4.3 `scripts/cost-report.py`
```python
# Query AWS Cost Explorer API
# Generate monthly cost breakdown
# Compare actual vs. projected costs
# Export to CSV
```

#### 4.4 `scripts/bulk-download.py`
```python
# Python CLI for researchers
# Download entire dataset with metadata
# Resume interrupted downloads
# Verify checksums
# Usage: python bulk-download.py --doi 10.5555/example.2024.001
```

### 5. Documentation

Create in `docs/`:

#### 5.1 `docs/USER_GUIDE.md`
- How to upload datasets
- Metadata requirements
- Requesting DOIs
- Downloading data
- Citations

#### 5.2 `docs/ADMIN_GUIDE.md`
- User management
- Budget monitoring
- Lifecycle policies configuration
- Backup and disaster recovery

#### 5.3 `docs/API_REFERENCE.md`
- OpenAPI 3.0 specification
- Authentication
- All endpoints with examples
- Error codes

#### 5.4 `docs/METADATA_SCHEMA.md`
- JSON-LD schema documentation
- Required vs. optional fields
- Examples for different media types
- Mapping to DataCite, Dublin Core

#### 5.5 `docs/COST_OPTIMIZATION.md`
- Storage tier comparison
- Best practices for researchers
- Budget forecasting examples

### 6. Testing

Create in `tests/`:

#### 6.1 `tests/integration/test_upload_flow.py`
- End-to-end test: upload → process → mint DOI → publish

#### 6.2 `tests/integration/test_lifecycle.py`
- Test tiering logic
- Test embargo release
- Test orphan detection

#### 6.3 `tests/unit/test_doi_minting.py`
- Mock DataCite API
- Test metadata validation

#### 6.4 `tests/load/test_bulk_upload.py`
- Locust or Artillery test
- Simulate 1000 concurrent uploads

### 7. CI/CD Pipeline

Create `.github/workflows/deploy.yml` (or GitLab CI):
```yaml
on: [push]
jobs:
  test:
    - Run unit tests
    - Run integration tests
  deploy-staging:
    - Deploy to staging environment
    - Run smoke tests
  deploy-prod:
    - Manual approval
    - Deploy to production
```

## Implementation Order

**Phase 1 (Week 1): Core Infrastructure**
1. Complete all Terraform modules
2. Deploy to AWS
3. Verify all resources created

**Phase 2 (Week 2): Essential Lambda Functions**
1. DOI minting
2. Presigned URLs
3. Media processing
4. Access control

**Phase 3 (Week 3): Frontend MVP**
1. Authentication
2. Dataset browser
3. Dataset viewer
4. Basic upload

**Phase 4 (Week 4): Advanced Features**
1. Bulk upload
2. Transcription
3. Lifecycle management
4. Admin dashboard

**Phase 5 (Week 5): Documentation & Testing**
1. All documentation
2. Integration tests
3. Load testing
4. Security audit

## Key Design Decisions

### Why This Architecture?

1. **Serverless = No server management, auto-scaling**
2. **S3 Intelligent Tiering = 78% cost savings over 5 years**
3. **Lambda = Pay per request, not per hour**
4. **EventBridge = Decoupled async processing**
5. **DynamoDB = Fast lookups, scales to billions of records**
6. **CloudFront = $85 vs $900 for 100hr streaming**

### Trade-offs

1. **Cold starts**: Lambda cold starts ~1-2s. Mitigate with provisioned concurrency for critical functions.
2. **Lambda limits**: 15min max, 10GB memory. Use Step Functions for longer workflows.
3. **S3 consistency**: Eventual consistency for new objects. Not an issue for our use case.

### Security Best Practices

1. All S3 buckets private, access via presigned URLs
2. Cognito for authentication, JWT tokens
3. Least privilege IAM roles
4. Encryption at rest (S3-SSE) and in transit (HTTPS)
5. CloudTrail logging all API calls
6. Regular security audits

## Budget Estimates

### Scenario: Mid-sized university repository

**Storage:**
- 100 TB initial upload
- 20 TB/year growth
- 80% of data older than 1 year (Glacier)
- Monthly cost: ~$500-800

**Compute:**
- 1000 uploads/month (media processing)
- 10,000 dataset views/month
- Monthly cost: ~$100-150

**Egress:**
- 10 TB/month downloads (via CloudFront)
- Monthly cost: ~$850

**Total: ~$1,500-1,800/month** for 100 TB active repository

Compare to:
- Dedicated servers: $3,000-5,000/month
- Commercial services: $5,000-10,000/month
- Zenodo/Figshare: Free but limited (50GB)

## Development Environment Setup

```bash
# Prerequisites
- AWS Account with admin access
- Terraform >= 1.0
- Node.js >= 18
- Python >= 3.11
- Docker (for local Lambda testing)

# Setup
git clone <repo>
cd academic-data-repo

# Install dependencies
cd frontend && npm install && cd ..
cd lambda/doi && pip install -r requirements.txt -t . && cd ../..

# Configure AWS credentials
aws configure

# Initialize Terraform
cd infrastructure/terraform
terraform init

# Deploy (will prompt for variables)
terraform apply

# Deploy frontend
cd ../../frontend
npm run build
aws s3 sync build/ s3://$(terraform output -raw frontend_bucket_id)
```

## Next Steps for Claude Code

1. **Start with DynamoDB module** - Foundational for all other services
2. **Then Cognito module** - Auth needed for API Gateway
3. **Then Lambda module** - Most complex, will take several iterations
4. **Then API Gateway** - Ties Lambdas together
5. **Frontend can be developed in parallel** once API is stable

## Questions to Ask the User

Before starting, clarify:
1. AWS region preference?
2. DataCite credentials (can add later)?
3. Custom domain name?
4. Monthly budget limit?
5. Any specific institutional SSO requirements beyond ORCID?

## Tips for Claude Code

- **Use Terraform workspaces** for dev/staging/prod
- **Test Lambdas locally** with SAM CLI before deploying
- **Start small**: Deploy minimal viable version, then iterate
- **Monitor costs**: Set up billing alerts immediately
- **Document as you go**: Update this file with any changes

Good luck! This is an ambitious but achievable project. The value to the academic community will be immense.
