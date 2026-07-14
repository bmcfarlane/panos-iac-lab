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

Clone the repo
```bash
git clone https://github.com/bmcfarlane/panos-iac-lab.git
cd panos-iac-lab
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

### 5. Deploy the firewall (`infra`)
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

- `region` - set the Azure region applicable to your lab (e.g. canadacentral)

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

### 7. Configure the firewall (`config`)
Hand the management IP and credentials to the config root (same terminal session):

```bash
export PANOS_HOSTNAME="<your-pa-vm-managment-IP-here>"
export PANOS_USERNAME="panadmin"
export PANOS_PASSWORD="$TF_VAR_fw_admin_password"

cd ../config
terraform plan             # expect: create the address object + a triggered commit action
terraform apply
```

On a freshly built firewall the address object is genuinely *created*, so the `panos_commit`
action fires automatically on `after_create` — the change is written **and** committed in one
`apply`.

### 8. Verify the commit
In the PAN-OS GUI:

- **Objects → Addresses** — the `web-server` object is present.
- **Commit** button (top-right) — the pending-change indicator is **clear**.
- **Tasks** (bottom-right) — a **Commit** job shows **Completed**, timestamped to your apply.

Back in the terminal, `terraform plan` should report **"No changes."** (Note: "No changes"
alone doesn't prove the *commit* — the Tasks log is the real evidence.)

### 9. Teardown
Two roots, so two destroys. **The `infra` destroy is what stops Azure billing.**

```bash
cd ../config && terraform destroy    # optional; removes the address from candidate config
cd ../infra  && terraform destroy    # deletes the firewall, network, and RG — stops billing
```
> The out-of-band commit does not fire on destroy (`action_trigger` has no destroy event), so a
> config-only destroy leaves the object removal uncommitted — irrelevant here because you then
> delete the whole firewall.
Confirm everything's gone:

```bash
az group show -g <name_prefix>-rg    # should error "not found"
```

After destroying, the local state files are safe to delete (they describe resources that no
longer exist). **Do this only because you destroyed first** — never delete state for live
infrastructure:

```bash
rm -f infra/terraform.tfstate* config/terraform.tfstate*
```

## Security notes

- **State can contain secrets in plaintext.** For example, the firewall admin password is
  written into `infra`'s state after apply — even though you passed it via an environment
  variable, Terraform records the resolved value. State (and its `.backup`) is gitignored via
  the `*.tfstate*` pattern and should use a remote, encrypted backend beyond a throwaway lab.
  Marking a variable `sensitive` only hides it from CLI output — it does **not** encrypt state.
- **No credentials in code.** The admin password and subscription ID are passed via environment
  variables, never committed.
- **Management access is locked to a single IP** via an NSG rule

---
