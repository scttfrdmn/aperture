# Contributing to Aperture

Thank you for your interest in contributing to Aperture! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/scttfrdmn/aperture/issues)
2. If not, create a new issue using the bug report template
3. Include:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, Go version, etc.)
   - Relevant logs or screenshots

### Suggesting Enhancements

1. Check if the enhancement has already been suggested
2. Create a new issue using the feature request template
3. Clearly describe the enhancement and its benefits
4. Include use cases and examples

### Pull Requests

1. Fork the repository
2. Create a new branch from `develop`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes following our coding standards
4. Write or update tests
5. Run the test suite:
   ```bash
   make test
   ```
6. Run linters:
   ```bash
   make lint
   ```
7. Commit your changes using conventional commits:
   ```bash
   git commit -m "feat: add new feature"
   ```
8. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
9. Open a pull request against the `develop` branch

## Development Setup

### Prerequisites

- Go 1.21 or higher
- Git
- Make
- golangci-lint (for linting)

### Getting Started

1. Clone the repository:
   ```bash
   git clone git@github.com:scttfrdmn/aperture.git
   cd aperture
   ```

2. Install dependencies:
   ```bash
   make deps
   ```

3. Build the project:
   ```bash
   make build
   ```

4. Run tests:
   ```bash
   make test
   ```

## Coding Standards

### Go Code Style

- Follow the [Effective Go](https://golang.org/doc/effective_go.html) guidelines
- Use `gofmt` for formatting (run `make fmt`)
- Follow idiomatic Go practices
- Write clear, self-documenting code
- Add comments for exported functions and types

### Code Quality

This project maintains an **A+ Go Report Card** grade. All contributions must:

- Pass all linters (`make lint`)
- Have 80%+ test coverage
- Include unit tests for new features
- Update documentation as needed
- Follow existing code patterns

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

Examples:
```
feat: add DOI minting support
fix: resolve memory leak in media processing
docs: update README with installation instructions
test: add unit tests for config package
```

## Testing

### Writing Tests

- Place test files next to the code they test (`*_test.go`)
- Use table-driven tests when appropriate
- Test both success and error cases
- Mock external dependencies

### Running Tests

```bash
# Run all tests
make test

# Run tests with coverage
make coverage

# Run specific package tests
go test ./internal/config/...
```

## Documentation

### Code Documentation

- Add godoc comments for all exported functions, types, and packages
- Include examples in documentation where helpful
- Keep README.md up to date

### API Documentation

- Update OpenAPI specs when changing APIs
- Document breaking changes clearly
- Provide migration guides for major version changes

## Version Control

### Branching Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `fix/*` - Bug fixes
- `release/*` - Release preparation

### Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** - Incompatible API changes
- **MINOR** - Backwards-compatible functionality
- **PATCH** - Backwards-compatible bug fixes

## Release Process

1. Update version in `pkg/version/version.go`
2. Update CHANGELOG.md
3. Create release branch
4. Run full test suite
5. Create and push tag:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```
6. GitHub Actions will build and publish the release

## Getting Help

- [GitHub Issues](https://github.com/scttfrdmn/aperture/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/scttfrdmn/aperture/discussions) - General questions and discussions
- [Documentation](./docs) - Project documentation

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for their contributions
- GitHub's contributor graph
- Release notes for significant contributions

Thank you for contributing to Aperture!
