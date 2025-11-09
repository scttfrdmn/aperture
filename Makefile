# Aperture Makefile
# Copyright 2025 Scott Friedman

.PHONY: all build test lint fmt clean install coverage help

# Build variables
BINARY_NAME=aperture
MAIN_PATH=./cmd/aperture
BUILD_DIR=./bin
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "v0.1.0")
COMMIT?=$(shell git rev-parse --short HEAD 2>/dev/null || echo "none")
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
GO_VERSION?=$(shell go version | cut -d' ' -f3)

# Linker flags
LDFLAGS=-ldflags "-X github.com/scttfrdmn/aperture/pkg/version.Version=$(VERSION) \
	-X github.com/scttfrdmn/aperture/pkg/version.Commit=$(COMMIT) \
	-X github.com/scttfrdmn/aperture/pkg/version.BuildTime=$(BUILD_TIME) \
	-X github.com/scttfrdmn/aperture/pkg/version.GoVersion=$(GO_VERSION)"

## all: Build the project
all: clean build

## build: Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## test: Run tests
test:
	@echo "Running tests..."
	go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...

## test-short: Run short tests
test-short:
	@echo "Running short tests..."
	go test -short -v ./...

## coverage: Generate coverage report
coverage: test
	@echo "Generating coverage report..."
	go tool cover -html=coverage.txt -o coverage.html
	@echo "Coverage report: coverage.html"

## lint: Run linters
lint:
	@echo "Running linters..."
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed. Run: brew install golangci-lint" && exit 1)
	golangci-lint run --timeout 5m ./...

## fmt: Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...
	gofmt -s -w .

## vet: Run go vet
vet:
	@echo "Running go vet..."
	go vet ./...

## tidy: Tidy dependencies
tidy:
	@echo "Tidying dependencies..."
	go mod tidy

## clean: Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@rm -f coverage.txt coverage.html
	@go clean

## install: Install the binary
install: build
	@echo "Installing $(BINARY_NAME)..."
	go install $(LDFLAGS) $(MAIN_PATH)

## run: Build and run
run: build
	@echo "Running $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME)

## dev: Run in development mode with hot reload (requires air)
dev:
	@which air > /dev/null || (echo "air not installed. Run: go install github.com/cosmtrek/air@latest" && exit 1)
	air

## docker-build: Build Docker image
docker-build:
	docker build -t aperture:$(VERSION) .

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download

## verify: Verify dependencies
verify:
	@echo "Verifying dependencies..."
	go mod verify

## upgrade: Upgrade dependencies
upgrade:
	@echo "Upgrading dependencies..."
	go get -u ./...
	go mod tidy

## check: Run all checks (fmt, vet, lint, test)
check: fmt vet lint test
	@echo "All checks passed!"

## ci: Run CI checks
ci: check
	@echo "CI checks complete!"

## release: Create a new release (requires VERSION)
release:
	@echo "Creating release $(VERSION)..."
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@git push origin $(VERSION)
	@echo "Release $(VERSION) created!"

## help: Show this help message
help:
	@echo "Aperture - AI-Powered Research Media Platform"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/  /'

.DEFAULT_GOAL := help
