# Standalone NGFW (no Panorama), so the object lives in a vsys:
#   location = { vsys = { name = "vsys1" } }

resource "panos_address" "web_server" {
  location = {
    vsys = { name = "vsys1" }
  }

  name        = "web-server"
  ip_netmask  = "10.0.1.100/32"
  description = "Managed by Terraform - v2"

  # Native v2 commit: the panos provider writes to the CANDIDATE config but
  # doesn't commit. This trigger invokes the panos_commit ACTION after the
  # address is created or updated, making the change part of the running config.
  #
  # NOTE: action_trigger supports create/update events only — there is no
  # destroy event yet, so this does NOT commit on `terraform destroy`.
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.panos_commit.this]
    }
  }
}

# The commit action itself. All attributes are optional; it commits on the
# firewall the provider is configured against (your PANOS_HOSTNAME).
action "panos_commit" "this" {
  config {
    description = "Terraform commit"
  }
}
