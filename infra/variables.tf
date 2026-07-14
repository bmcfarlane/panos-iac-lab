variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "panos-iac-lab"
}

variable "region" {
  description = "Azure region. Must support Availability Zones when virtual_machine.zone is set."
  type        = string
  default     = "canadacentral"
}

variable "panos_version" {
  description = "PAN-OS image version for the vmseries-flex / byol image."
  type        = string
}

variable "fw_admin_username" {
  description = "Initial firewall admin username."
  type        = string
  default     = "panadmin"
}

variable "fw_admin_password" {
  description = "Initial firewall admin password."
  type        = string
  sensitive   = true
}

variable "mgmt_allowed_source_ip" {
  description = "The source IP allowed to reach the firewall mgmt interface."
  type        = string
}
