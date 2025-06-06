# Terraform Core Child Module Helpers

locals {
  # The regex is used to parse the workspace name into its components, the components are used to set the region, zone, and environment variables.
  # This requires structured workspace names, the structured workspace names are defined by the regex.

  # Examples:
  # main-sandbox -> region = null, zone = null, environment = sandbox
  # us-east1-sandbox -> region = us-east1, zone = null, environment = sandbox
  # us-east1-foo-sandbox -> region = us-east1, zone = null, system = foo, environment = sandbox
  # us-east1-a-sandbox -> region = us-east1, zone = a, environment = sandbox
  # us-east1-a-foo-sandbox -> region = us-east1, zone = a, system = foo, environment = sandbox

  environment_regex = "-(non-production|sandbox|production)$"
  region_regex      = "^(us-[a-z]+\\d+)"
  zone_regex        = "^us-[a-z]+\\d+-([abcd])"

  env = local.environment != null ? lookup(local.env_map, local.environment, "none") : null

  env_map = {
    "non-production" = "nonprod"
    "production"     = "prod"
    "sandbox"        = "sb"
  }

  environment = local.parsed_workspace.environment

  parsed_workspace = (
    local.workspace == "default" ?
    {

      # We use mock providers when testing Terraform child modules, these values align with the test naming conventions.

      environment = "mock-environment"
      region      = "mock-region"
      zone        = "mock-zone"
    } :
    {
      environment = try(regex(local.environment_regex, local.workspace)[0], null)
      region      = try(regex(local.region_regex, local.workspace)[0], null)
      zone        = try(regex(local.zone_regex, local.workspace)[0], null)
    }
  )

  region = local.parsed_workspace.region

  workspace = var.workspace != null ? var.workspace : terraform.workspace
  zone      = local.parsed_workspace.zone
}

output "env" {
  description = "The short name for the environment for example prod, nonprod, sb"
  value       = local.env
}

output "environment" {
  description = "The environment name for example production, non-production, sandbox"
  value       = local.environment
}

output "region" {
  description = "The region where resources will be deployed"
  value       = local.region
}

output "zone" {
  description = "The zone where resources will be deployed"
  value       = local.zone
}

variable "workspace" {
  description = "This is used for tests to set the workspace name. Do not set this variable in any other context"
  type        = string
  default     = null
}
