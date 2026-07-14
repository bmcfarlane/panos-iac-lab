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



