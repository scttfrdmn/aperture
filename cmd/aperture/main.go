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

package main

import (
	"fmt"
	"os"

	"github.com/scttfrdmn/aperture/internal/config"
)

// Version is set via ldflags during build
var (
	Version   = "dev"
	Commit    = "none"
	BuildTime = "unknown"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	// Display version information
	fmt.Printf("Aperture v%s (commit: %s, built: %s)\n", Version, Commit, BuildTime)
	fmt.Println("Opening research to the world")
	fmt.Println()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	fmt.Printf("Configuration loaded: %s environment\n", cfg.Environment)
	fmt.Println()
	fmt.Println("Aperture is ready to serve the academic research community!")
	fmt.Println()
	fmt.Println("Next steps:")
	fmt.Println("  1. Run 'aperture init' to initialize your configuration")
	fmt.Println("  2. Run 'aperture deploy' to deploy infrastructure")
	fmt.Println("  3. Run 'aperture upload' to upload your first dataset")
	fmt.Println()
	fmt.Println("For more information, visit: https://github.com/scttfrdmn/aperture")

	return nil
}
