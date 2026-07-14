#################
# Resource Group
#################

resource "azurerm_resource_group" "lab" {
  name     = "${var.name_prefix}-rg"
  location = var.region
}

#####################
# Network Components
#####################

resource "azurerm_virtual_network" "lab" {
  name                = "${var.name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "mgmt" {
  name                 = "${var.name_prefix}-mgmt-snet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "untrust" {
  name                 = "${var.name_prefix}-untrust-snet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

#################################
# Network Security Group on MGMT
#################################

resource "azurerm_network_security_group" "mgmt" {
  name                = "${var.name_prefix}-mgmt-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_network_security_rule" "mgmt_https" {
  name                        = "allow-https-from-admin"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = var.mgmt_allowed_source_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab.name
  network_security_group_name = azurerm_network_security_group.mgmt.name
}

resource "azurerm_network_security_rule" "mgmt_ssh" {
  name                        = "allow-ssh-from-admin"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.mgmt_allowed_source_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab.name
  network_security_group_name = azurerm_network_security_group.mgmt.name
}

resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

###################
# The PA-VM itself
###################

module "vmseries" {
  source  = "PaloAltoNetworks/swfw-modules/azurerm//modules/vmseries"
  version = "3.5.1"

  name                = "${var.name_prefix}-fw"
  resource_group_name = azurerm_resource_group.lab.name
  region              = var.region

  # NOTE: disable_password_authentication DEFAULTS TO TRUE in this module.
  # It must be explicitly false to log in with a password.
  authentication = {
    username                        = var.fw_admin_username
    password                        = var.fw_admin_password
    disable_password_authentication = false
  }

  # publisher ("paloaltonetworks"), offer ("vmseries-flex") and sku ("byol")
  # are already the module's defaults — stated here for clarity.
  # enable_marketplace_plan = true (default) makes the module emit the required
  # marketplace `plan {}` block for you.
  image = {
    version                 = var.panos_version
    publisher               = "paloaltonetworks"
    offer                   = "vmseries-flex"
    sku                     = "byol"
    enable_marketplace_plan = true
  }

  # `zone` and `disk_name` have no optional() wrapper in the module's type
  # schema, so both must be supplied even though the prose calls disk_name
  # optional. zone = "1" requires a zone-capable region (canadacentral is).
  # Set zone = null and supply avset_id instead in a non-zonal region.
  virtual_machine = {
    size              = "Standard_D3_v2" # module default; verify against the VM-Series Deployment Guide
    zone              = "1"
    disk_name         = "${var.name_prefix}-fw-osdisk"
    disk_type         = "StandardSSD_LRS"
    bootstrap_options = "type=dhcp-client"
  }

  # ORDER MATTERS. The first interface is always management.
  interfaces = [
    {
      name      = "${var.name_prefix}-fw-mgmt"
      subnet_id = azurerm_subnet.mgmt.id
      ip_configurations = {
        primary-ip = {
          name             = "primary-ip"
          primary          = true
          create_public_ip = true
          public_ip_name   = "${var.name_prefix}-fw-mgmt-pip"
        }
      }
    },
    {
      name      = "${var.name_prefix}-fw-untrust"
      subnet_id = azurerm_subnet.untrust.id
      ip_configurations = {
        primary-ip = {
          name             = "primary-ip"
          primary          = true
          create_public_ip = false
        }
      }
    },
  ]

  depends_on = [azurerm_subnet_network_security_group_association.mgmt]
}
