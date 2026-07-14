# No credentials here. Terraform inherits your `az login` session.
# Provide the subscription with:  export ARM_SUBSCRIPTION_ID="<id>"
# (azurerm v4 requires subscription_id explicitly; the env var is the
#  recommended way so the ID never lands in the repo.)

provider "azurerm" {
  features {} # mandatory empty block
}
