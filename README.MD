# Palo Alto IaC Lab

A hands-on lab demonstrating how Terraform — and Infrastructure as Code (IaC) more
broadly — applies to a domain a traditional network engineer already knows: firewall
configuration. It deploys a Palo Alto VM-Series firewall in Azure and then manages its
configuration declaratively, treating firewall policy the way you'd treat application code.

Built as a self-directed learning project, with significant use of AI assistance (Claude)
for research, verification against upstream sources, and code review.

---

## What it demonstrates

The infrastructure is almost incidental; the point is the IaC mental model, shown on
familiar network gear rather than abstract cloud resources:


Declarative (stateful) IaC vs. imperative config push — you describe the desired end
state; Terraform computes and applies the difference, rather than you pushing commands.


The core workflow: init → plan → apply → destroy, and reading a plan before approving it.


Separation of concerns across two root modules: "build the firewall" and "configure
the firewall" are kept in independent Terraform roots with independent state, connected
only by an output handoff.


Secrets hygiene — credentials supplied via environment variables, state and tfvars kept
out of version control, firewall management locked to a single source IP.


## Instructions for Use

### 1. Install the Tools

The tools were downloaded to my Macbook using Brew Package Manager and the instructions for this section reflect that. You can probably get these tools from other means on other platforms.

```bash
brew install azure-cli
brew tap hashicorp/tap && brew install hashicorp/tap/terraform
```

### 2. Log into Azure

```bash
az login
```

Then select the subscription this lab should build into:

```bash
az account list --output table                 # all subscriptions you can access
az account set --subscription "<name-or-id>"   # pick the lab one
az account show                                # confirm the active subscription
```

> Wrong tenant? `az login --tenant <tenant-id>` forces a specific one.

### 3. Permissions

Your Azure identity needs rights to create resources — typically **Contributor** on the
subscription or the target resource group. If you already do portal admin you almost certainly
have this; it's the first thing to check if `terraform apply` fails with an authorization error.

### 4. Accept the BYOL image terms (once per subscription)

The firewall uses the BYOL image, so accept its terms before deploying:
```bash
az vm image terms accept --publisher paloaltonetworks --offer vmseries-flex --plan byol
```

### 5. — Deploy the firewall (`infra`)
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at least:

- `panos_version` — a valid **byol** image version. List them with:
  ```bash
  az vm image list -o table --all --publisher paloaltonetworks --offer vmseries-flex
  ```
  Use a version from a row whose SKU is `byol` (ignore `bundle*`). A 10.2.x build (e.g.
  `10.2.1014`) comfortably fits the default `Standard_D3_v2` size; 11.x/12.x images want more
  memory, so bump the VM size if you choose one.

- `mgmt_allowed_source_ip` — **your** workstation's public IP as a `/32` (e.g. `203.0.113.45/32`).
  This is the only source allowed to reach the firewall's management interface.

Set the secrets as environment variables (never in a file):

```bash
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export TF_VAR_fw_admin_password='<a-strong-firewall-admin-password>'
```

Then run the workflow, reading the plan before approving:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan         # type 'yes'; takes many minutes to complete, may appear hung
terraform apply         
```

### 6. Verify the firewall is reachable

Azure reporting "apply complete" is **not** the same as PAN-OS being ready — the firewall's
management plane takes several more minutes to boot.

```bash
terraform output -raw fw_mgmt_ip      # the management public IP
```

Is the management port up yet? (refused/timeout for the first few minutes is normal)
```bash
nc -vz -w 5 <mgmt-ip> 443
```

Once port 443 answers, browse to `https://<mgmt-ip>`, accept the self-signed certificate
warning, and log in as `panadmin` with the password you set. Confirm the PAN-OS version on the
dashboard matches your `panos_version`.

