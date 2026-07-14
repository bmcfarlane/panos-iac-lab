# The seam between the two Terraform roots. config (the panos provider)
# consumes mgmt_ip_address as PANOS_HOSTNAME.
#
#   terraform output -raw fw_mgmt_ip
#
# This is the sanctioned way to pass a value from one root to another without
# coupling them into a single state file.

output "fw_mgmt_ip" {
  description = "VM-Series management IP (public, since create_public_ip = true on the mgmt interface)."
  value       = module.vmseries.mgmt_ip_address["primary-ip"].public_ip
}

output "fw_admin_username" {
  description = "Initial admin username, for convenience when exporting PANOS_USERNAME."
  value       = var.fw_admin_username
}
