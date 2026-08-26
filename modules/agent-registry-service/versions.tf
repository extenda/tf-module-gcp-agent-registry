/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_version = ">= 1.3"

  required_providers {
    # google_agent_registry_service is GA as of hashicorp/google v7.39.0 - no google-nightly needed.
    google = {
      source  = "hashicorp/google"
      version = ">= 7.39.0, < 8"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-agent-registry:agent-registry-service/v0.3.4"
  }
}
