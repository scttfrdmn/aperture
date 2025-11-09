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

package config

import (
	"os"
	"testing"
)

func TestLoad(t *testing.T) {
	tests := []struct {
		name    string
		envVars map[string]string
		want    *Config
		wantErr bool
	}{
		{
			name: "default values",
			envVars: map[string]string{
				"APERTURE_ENV": "dev",
				"AWS_REGION":   "us-east-1",
			},
			want: &Config{
				Environment: "dev",
				AWSRegion:   "us-east-1",
				ProjectName: "aperture",
			},
			wantErr: false,
		},
		{
			name: "custom values",
			envVars: map[string]string{
				"APERTURE_ENV":          "prod",
				"AWS_REGION":            "us-west-2",
				"DATACITE_PREFIX":       "10.5555",
				"APERTURE_PROJECT_NAME": "custom-aperture",
			},
			want: &Config{
				Environment:    "prod",
				AWSRegion:      "us-west-2",
				DataCitePrefix: "10.5555",
				ProjectName:    "custom-aperture",
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Set environment variables
			for key, value := range tt.envVars {
				os.Setenv(key, value)
			}

			// Clean up after test
			defer func() {
				for key := range tt.envVars {
					os.Unsetenv(key)
				}
			}()

			got, err := Load()
			if (err != nil) != tt.wantErr {
				t.Errorf("Load() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr {
				if got.Environment != tt.want.Environment {
					t.Errorf("Load() Environment = %v, want %v", got.Environment, tt.want.Environment)
				}
				if got.AWSRegion != tt.want.AWSRegion {
					t.Errorf("Load() AWSRegion = %v, want %v", got.AWSRegion, tt.want.AWSRegion)
				}
				if got.DataCitePrefix != tt.want.DataCitePrefix {
					t.Errorf("Load() DataCitePrefix = %v, want %v", got.DataCitePrefix, tt.want.DataCitePrefix)
				}
				if got.ProjectName != tt.want.ProjectName {
					t.Errorf("Load() ProjectName = %v, want %v", got.ProjectName, tt.want.ProjectName)
				}
			}
		})
	}
}

func TestValidate(t *testing.T) {
	tests := []struct {
		name    string
		config  *Config
		wantErr bool
	}{
		{
			name: "valid config",
			config: &Config{
				Environment: "dev",
				AWSRegion:   "us-east-1",
			},
			wantErr: false,
		},
		{
			name: "empty environment",
			config: &Config{
				Environment: "",
				AWSRegion:   "us-east-1",
			},
			wantErr: true,
		},
		{
			name: "empty AWS region",
			config: &Config{
				Environment: "dev",
				AWSRegion:   "",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
