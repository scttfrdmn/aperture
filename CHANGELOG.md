# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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

### Changed
- Updated main.tf to comment out unimplemented modules
- Added DynamoDB table outputs to main configuration
- Updated S3 module configuration in main.tf with proper parameters
- Added cors_allowed_origins variable to main configuration
- Integrated Cognito module with OAuth 2.0 callback URLs
- Added 5 Cognito outputs (user pool ID, ARN, client IDs, domain, OAuth URL)
- Integrated CloudFront module with S3 bucket outputs
- Added CloudFront distribution URLs to outputs

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
