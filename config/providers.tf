# No credentials here. The provider reads them from environment variables:
#   export PANOS_HOSTNAME=$(cd ../01-infra && terraform output -raw fw_mgmt_ip)
#   export PANOS_USERNAME="panadmin"
#   export PANOS_PASSWORD='...'          (or PANOS_API_KEY='...')

provider "panos" {
  # The lab firewall presents a self-signed management certificate, so skip verification.
  skip_verify_certificate = true
}
