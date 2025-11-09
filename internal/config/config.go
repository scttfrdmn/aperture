// Copyright 2025 Scott Friedman
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package config provides configuration management for Aperture.
package config

import (
	"fmt"
	"os"
)

// Config holds the application configuration.
type Config struct {
	// Environment specifies the deployment environment (dev, staging, prod)
	Environment string

	// AWSRegion is the AWS region for deployment
	AWSRegion string

	// DataCitePrefix is the DOI prefix from DataCite
	DataCitePrefix string

	// ProjectName is the name of the project for resource naming
	ProjectName string
}

// Load loads the configuration from environment variables.
// If required variables are not set, it returns default values.
func Load() (*Config, error) {
	cfg := &Config{
		Environment:    getEnv("APERTURE_ENV", "dev"),
		AWSRegion:      getEnv("AWS_REGION", "us-east-1"),
		DataCitePrefix: getEnv("DATACITE_PREFIX", ""),
		ProjectName:    getEnv("APERTURE_PROJECT_NAME", "aperture"),
	}

	// Validate configuration
	if err := cfg.Validate(); err != nil {
		return nil, err
	}

	return cfg, nil
}

// Validate checks if the configuration is valid.
func (c *Config) Validate() error {
	if c.Environment == "" {
		return fmt.Errorf("environment cannot be empty")
	}

	if c.AWSRegion == "" {
		return fmt.Errorf("AWS region cannot be empty")
	}

	return nil
}

// getEnv retrieves an environment variable or returns a default value.
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
