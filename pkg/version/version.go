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

// Package version provides version information for Aperture.
package version

import "fmt"

// Build information. Populated at build-time via ldflags.
var (
	Version   = "0.1.0"
	Commit    = "none"
	BuildTime = "unknown"
	GoVersion = "unknown"
)

// Info represents version information.
type Info struct {
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	BuildTime string `json:"buildTime"`
	GoVersion string `json:"goVersion"`
}

// Get returns the version information.
func Get() Info {
	return Info{
		Version:   Version,
		Commit:    Commit,
		BuildTime: BuildTime,
		GoVersion: GoVersion,
	}
}

// String returns a human-readable version string.
func (i Info) String() string {
	return fmt.Sprintf("Aperture v%s (commit: %s, built: %s, go: %s)",
		i.Version, i.Commit, i.BuildTime, i.GoVersion)
}
