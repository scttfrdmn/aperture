# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- React Frontend with AWS Cloudscape Design System (Issue #8)
  - Modern web interface for dataset management
  - User authentication with AWS Cognito and ORCID
  - Dataset browse page with search and filtering
  - Dataset detail page with metadata and file listing
  - Upload page with multi-file support and metadata form
  - DOI management interface for minting and managing DOIs
  - User profile page with permissions display
  - Role-based access control (admins, researchers, reviewers, users)
  - TypeScript for type safety
  - Vite for fast development and optimized builds
  - AWS Amplify integration for Cognito authentication
  - Axios API service with interceptors
  - Protected routes with authentication checks
  - Responsive layout with AWS Cloudscape components
  - Environment configuration templates
  - Comprehensive 300+ line README with setup instructions
- CI/CD Pipeline with GitHub Actions workflows (Issue #15)
  - CI workflow for automated testing on push/PR
    - Terraform validation for all 7 modules
    - Python Lambda syntax checking and linting
    - Documentation verification (README, CHANGELOG)
    - Security scanning with Checkov
  - Terraform PR workflow for plan preview
    - Automatic Terraform plan on PR
    - Plan results posted as PR comments
    - Format, init, validate, and plan status
  - Deployment workflow for infrastructure management
    - Manual deployment with environment selection (dev/staging/prod)
    - Support for plan, apply, and destroy operations
    - AWS OIDC authentication (no access keys needed)
    - Manual approval required for destroy operations
    - Artifact uploads (plans, outputs)
  - Environment configuration templates
    - dev.tfvars.example, staging.tfvars.example, prod.tfvars.example
    - Separate environments directory structure
    - .gitignore updated to protect secrets
  - Comprehensive 400+ line CI/CD documentation
    - Setup instructions for AWS OIDC and GitHub secrets
    - Usage examples for all workflows
    - Security best practices
    - Troubleshooting guide
- API Gateway Terraform module with HTTP API (v2) for REST endpoints (Issue #26)
  - HTTP API (API Gateway v2) with 70% cost savings vs REST API (v1)
  - Cognito JWT authorizer for protected endpoints
  - 9 API routes exposing Lambda functions
    - Authentication: login (public), refresh (public), logout (protected), verify (protected)
    - Presigned URLs: generate (protected), batch (protected)
    - DOI management: mint (protected), update (protected), delete (protected)
  - CORS configuration for web client access
  - API throttling (500 burst, 1000 req/sec)
  - CloudWatch access logging with JSON formatting (90-day retention)
  - Lambda permissions for API Gateway invocation
  - Optional custom domain support with ACM
  - Auto-deploy stage configuration
  - Comprehensive 300+ line module documentation
  - Cost estimate: ~$1.50/month for 1M requests
- API Gateway outputs in main.tf (endpoint, invoke URL, routes, summary)
- Lambda Functions Terraform module with 3 serverless backend functions (Issue #5)
  - Auth Lambda for user authentication with AWS Cognito
    - Operations: login, refresh, logout, verify
    - JWT token validation and management
    - Runtime: Python 3.11, Timeout: 30s, Memory: 256 MB
  - Presigned URLs Lambda for temporary S3 access with RBAC
    - Single and batch URL generation (up to 100 URLs)
    - Access control for public/private/restricted/embargoed buckets
    - Dataset-specific permission checking via DynamoDB
    - Embargo date validation for time-based access control
    - Access logging to DynamoDB for audit trails
    - Runtime: Python 3.11, Timeout: 30s, Memory: 256 MB
  - DOI Minting Lambda for DataCite integration
    - Operations: mint, update, delete DOIs
    - DataCite API integration for DOI lifecycle management
    - DynamoDB registry for DOI tracking
    - Runtime: Python 3.11, Timeout: 60s, Memory: 512 MB
  - IAM roles with least-privilege policies for each function
  - CloudWatch log groups with 90-day retention
  - Terraform archive provider for Lambda packaging
  - API Gateway integration support (optional)
  - Comprehensive 160+ line module documentation
  - Cost estimate: ~$21.50/month for 1M requests
- Lambda function outputs in main.tf (ARNs and summary)
- EventBridge Terraform module for event-driven workflows (Issue #4)
  - Custom event bus for Aperture platform events
  - S3 object creation triggers for automatic media processing
  - Scheduled rules for daily lifecycle management (2 AM UTC)
  - Scheduled rules for weekly budget reports (Monday 9 AM UTC)
  - CloudWatch alarm monitoring with SNS routing
  - DynamoDB stream monitoring for DOI registry changes
  - Custom application events (publication workflow, failed jobs)
  - Event archive with configurable retention (default 90 days)
  - Dead Letter Queue support for failed event handling
  - IAM roles for Step Functions and SNS integration
  - CloudWatch logging for all EventBridge events
  - Comprehensive 500+ line documentation with examples
- S3 Buckets Terraform module with 7 purpose-specific buckets
  - Public Media bucket for datasets with DOIs
  - Private Media bucket for restricted access datasets
  - Restricted Media bucket for datasets with access controls
  - Embargoed Media bucket for datasets under embargo
  - Processing bucket for temporary media processing (7-day auto-expiration)
  - Logs bucket for S3 access logs and CloudTrail logs (7-year retention)
  - Frontend bucket for React application hosting
- Intelligent tiering configuration for media buckets
  - Automatic transition to Archive Access tier after 90 days
  - Automatic transition to Deep Archive Access tier after 180 days
  - 78% cost savings vs S3 Standard for long-term storage
- Lifecycle policies for all buckets
  - Immediate transition to intelligent tiering for media buckets
  - Noncurrent version expiration (90 days for media, 30 days for frontend)
  - Processing bucket cleanup after 7 days
  - Logs retention for 7 years (2555 days)
- CORS configuration for web access to media and frontend buckets
- Access logging enabled by default (logs stored in dedicated logs bucket)
- Versioning enabled for all media buckets and frontend bucket
- CORS allowed origins configuration variable
- 7 S3 bucket outputs in main.tf for module integration
- Cognito User Pool Terraform module with ORCID federation
  - OpenID Connect integration with ORCID (sandbox and production support)
  - 4 RBAC groups (admins, researchers, reviewers, users)
  - Password policy configuration (12+ characters, complexity requirements)
  - MFA support via TOTP and SMS
  - Advanced security features (compromised credentials detection)
  - Risk-based authentication with account takeover protection
  - Web app client and API client configurations
  - Custom domain support with ACM certificate integration
  - CloudWatch logging for security monitoring
- ORCID authentication integration variables in main.tf
- DynamoDB Terraform module with 4 tables
  - Users and Permissions table with email and ORCID indexes
  - DOI Registry table with dataset and status indexes
  - Access Logs table with user and date indexes (90-day TTL)
  - Budget Tracking table with account and category indexes
- Auto-scaling configuration for provisioned capacity mode
- Point-in-time recovery enabled by default
- Server-side encryption with optional KMS support
- Comprehensive module documentation with usage examples
- Updated main.tf to integrate DynamoDB module
- GitHub Issue #17 for Globus Auth integration roadmap
- GitHub Issue #19 for S3 buckets module tracking
- CloudFront CDN Terraform module with 2 optimized distributions
  - Public Media distribution for research datasets and media files
  - Frontend distribution for React application with SPA routing
- Origin Access Control (OAC) for secure S3 access
- Optimized cache behaviors for different content types
  - Large media files (videos): 7-day cache with Range request support
  - Thumbnails/processed media: 30-day cache
  - Metadata JSON files: 1-hour cache
  - Frontend static assets: 30-day cache with versioning support
  - SPA routes: Smart routing with index.html fallback
- S3 bucket policies automatically configured for CloudFront access
- CloudFront access logging to dedicated S3 logs bucket
- Custom domain support with ACM certificate integration
- Geographic restrictions support (whitelist/blacklist)
- IPv6 enabled by default
- HTTP/2 and HTTP/3 support
- Automatic compression for text-based content
- Cost optimization with PriceClass_100 (North America and Europe)
- Optional Origin Shield for additional caching layer
- 4 CloudFront outputs in main.tf (distribution IDs and URLs)
- Updated main.tf to integrate EventBridge module

### Changed
- Updated main.tf to comment out unimplemented modules
- Added DynamoDB table outputs to main configuration
- Updated S3 module configuration in main.tf with proper parameters
- Added cors_allowed_origins variable to main configuration
- Integrated Cognito module with OAuth 2.0 callback URLs
- Added 5 Cognito outputs (user pool ID, ARN, client IDs, domain, OAuth URL)
- Integrated CloudFront module with S3 bucket outputs
- Added CloudFront distribution URLs to outputs
- Integrated Lambda module with Cognito, S3, and DynamoDB dependencies
- Added 4 Lambda function outputs (auth, presigned URLs, DOI minting, summary)
- Integrated API Gateway module with Cognito and Lambda functions
- Added 5 API Gateway outputs (endpoint, invoke URL, ID, routes, summary)

### Deprecated

### Removed

### Fixed

### Security
- Enabled encryption at rest for all DynamoDB tables
- Added point-in-time recovery for data protection

## [0.1.0] - 2025-11-09

### Added
- Initial commit
- Project foundation and documentation
- Core architecture design
- AI-powered research media platform concept

[Unreleased]: https://github.com/scttfrdmn/aperture/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/scttfrdmn/aperture/releases/tag/v0.1.0
