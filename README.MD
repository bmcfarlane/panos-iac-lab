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


Separation of concerns across two root modules — "build the firewall" and "configure
the firewall" are kept in independent Terraform roots with independent state, connected
only by an output handoff.


Secrets hygiene — credentials supplied via environment variables, state and tfvars kept
out of version control, firewall management locked to a single source IP.
