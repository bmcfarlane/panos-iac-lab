# Separate root from infra — its own provider, its own state.
# The panos v2 provider requires Terraform 1.8+ (higher than the Azure root).

terraform {
  # Provider-defined ACTIONS (used for the native commit) require Terraform 1.14+.
  # (The panos provider itself only needs 1.8+, but the action_trigger syntax is 1.14.)
  required_version = ">= 1.14"

  required_providers {
    panos = {
      source  = "PaloAltoNetworks/panos"
      # The panos_commit action ships in recent 2.0.x builds. If `terraform plan`
      # reports the action type "panos_commit" is unknown, run: terraform init -upgrade
      version = "~> 2.0"
    }
  }
}
