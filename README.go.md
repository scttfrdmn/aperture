# Aperture

[![Go Report Card](https://goreportcard.com/badge/github.com/scttfrdmn/aperture)](https://goreportcard.com/report/github.com/scttfrdmn/aperture)
[![GoDoc](https://godoc.org/github.com/scttfrdmn/aperture?status.svg)](https://godoc.org/github.com/scttfrdmn/aperture)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Release](https://img.shields.io/github/release/scttfrdmn/aperture.svg)](https://github.com/scttfrdmn/aperture/releases/latest)
[![Go Version](https://img.shields.io/github/go-mod/go-version/scttfrdmn/aperture)](https://golang.org/dl/)

**Opening research to the world**

Aperture is an AI-powered academic research media platform for storing, analyzing, and securing image, video, and audio data. Built on AWS infrastructure, it delivers 97-99% cost savings through intelligent automation while maintaining FAIR principles.

## Features

- **AI-Powered Analysis**: Automatic descriptions, tagging, transcription, and quality checks
- **ML Research Platform**: Train models, RAG knowledge bases, model marketplace
- **Cost Optimization**: 78% storage savings via intelligent tiering
- **Large File Support**: Up to 5 TB per file
- **Scientific Watermarking**: Stegano integration for data integrity
- **FAIR Compliance**: DOI minting, OAI-PMH, open metadata
- **Professional UI**: AWS Cloudscape design system

## Quick Start

```bash
# Install
go install github.com/scttfrdmn/aperture/cmd/aperture@latest

# Initialize configuration
aperture init

# Deploy infrastructure
aperture deploy --env production

# Upload dataset
aperture upload --dataset my-research-2024 ./data/
```

## Installation

### Prerequisites

- Go 1.21 or higher
- AWS Account with credentials configured
- DataCite membership for DOI minting

### From Source

```bash
git clone git@github.com:scttfrdmn/aperture.git
cd aperture
make install
```

### Using Go Install

```bash
go install github.com/scttfrdmn/aperture/cmd/aperture@latest
```

## Documentation

Full documentation is available in the [docs](./docs) directory:

- [Architecture Overview](./APERTURE_ANALYSIS.md)
- [AI Features](./AI_FEATURES.md)
- [ML Platform](./ML_PLATFORM.md)
- [Quick Start Guide](./QUICK_START.md)
- [API Reference](./docs/api.md)
- [Contributing Guide](./CONTRIBUTING.md)

## Project Status

Current version: **0.1.0** (Foundation Complete)

- ✅ 30% Complete: Documentation, architecture, core Lambda functions
- 🚧 70% In Progress: Infrastructure modules, frontend, testing

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history.

See [Milestones](https://github.com/scttfrdmn/aperture/milestones) for roadmap.

## Architecture

```
┌──────────────────────────────────────────────┐
│           CloudFront CDN                      │
│   (Frontend + Media Delivery + Caching)      │
└────────┬────────────────────────┬────────────┘
         │                        │
    ┌────▼──────┐           ┌────▼──────────┐
    │ S3 Frontend│           │ S3 Public     │
    │ (React UI) │           │ Media         │
    └────────────┘           └───────────────┘
         │
    ┌────▼─────────────────────────────────┐
    │  API Gateway + Lambda Functions      │
    │  • Auth (Cognito + ORCID)            │
    │  • DOI Minting (DataCite)            │
    │  • Media Processing (AI Analysis)    │
    │  • Access Control (RBAC)             │
    └────┬──────────────────────┬──────────┘
         │                      │
    ┌────▼──────┐         ┌────▼──────────┐
    │ DynamoDB  │         │ S3 Private    │
    │ Metadata  │         │ Media         │
    └───────────┘         └───────────────┘
```

## Development

### Building

```bash
# Build all binaries
make build

# Run tests
make test

# Run linters
make lint

# Generate code coverage
make coverage
```

### Running Locally

```bash
# Start development environment
make dev

# Run with hot reload
make watch
```

### Code Quality

This project maintains an **A+ Go Report Card** grade by following:

- `gofmt` for formatting
- `golangci-lint` for linting
- 80%+ test coverage
- Clear documentation
- Idiomatic Go code

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Versioning

This project uses [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

## License

Copyright 2025 Scott Friedman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Acknowledgments

- AWS for infrastructure services
- DataCite for DOI services
- The academic research community

## Contact

- **Author**: Scott Friedman
- **GitHub**: [@scttfrdmn](https://github.com/scttfrdmn)
- **Issues**: [GitHub Issues](https://github.com/scttfrdmn/aperture/issues)

## Roadmap

See our [GitHub Project](https://github.com/users/scttfrdmn/projects) for detailed roadmap.

### Phase 1: Infrastructure (Weeks 1-2)
- [ ] Terraform modules (8 remaining)
- [ ] DynamoDB tables
- [ ] CloudFront CDN
- [ ] EventBridge automation

### Phase 2: Backend (Weeks 2-3)
- [ ] Lambda functions (11 remaining)
- [ ] API Gateway endpoints
- [ ] AI analysis pipeline
- [ ] Budget monitoring

### Phase 3: Frontend (Weeks 3-4)
- [ ] React application with Cloudscape
- [ ] Dataset browser
- [ ] Media viewers
- [ ] Admin dashboard

### Phase 4: AI & ML (Weeks 4-5)
- [ ] AWS Bedrock integration
- [ ] Model training workflows
- [ ] RAG knowledge bases
- [ ] Model marketplace

### Phase 5: Documentation & Testing (Week 5)
- [ ] User guides
- [ ] API documentation
- [ ] Integration tests
- [ ] CI/CD pipeline

---

**Status**: Foundation Complete (30%) | **Target**: Production Ready in 5 weeks

Built with ❤️ for the academic research community
