# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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

### Changed
- Updated main.tf to comment out unimplemented modules
- Added DynamoDB table outputs to main configuration

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
