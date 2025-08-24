# Centralizing Users on Google Cloud with Google Workspace & Terraform

## Overview
This project demonstrates how to **bridge Google Workspace identity** with **Google Cloud IAM** using Terraform.  
It provisions **users, groups, memberships, and IAM bindings** in a secure, auditable, and repeatable way.

By following this repo, you can:
- Provision **Google Workspace users** with randomized, one-time passwords.
- Manage **groups** as the unit of authorization (instead of binding individuals directly).
- Bind groups to Google Cloud projects with **least privilege** (`roles/viewer` by default).
- Enforce enterprise security guardrails like **org policies** and **Domain-wide Delegation**.

This isn’t just a lab exercise — it’s how mature organizations scale **identity and access** securely.

---

##  Architecture

```

```
            +---------------------------+
            |  Google Workspace (IdP)   |
            |   - Users (Jane, John)    |
            |   - Group (Payments Team) |
            +-------------+-------------+
                          |
    Terraform (Service Account with Domain-wide Delegation)
                          |
            +-------------v-------------+
            | Google Cloud (IAM plane)  |
            |   - Group → roles/viewer  |
            |   - Bound to project(s)   |
            +---------------------------+
```

```

**Key principle:** Workspace owns people, Cloud IAM sees only groups.

---

##  Prerequisites
- Verified Google Workspace domain (e.g., `example.com`)
- Super Admin access to Workspace
- Google Cloud Organization & Project with billing enabled
- Terraform v1.5+ installed locally

---

##  Security Controls
- **Service Account Key Creation Disabled Org-Wide**  
  Temporarily overridden at project scope to mint a single key → moved to `~/.secrets/` → guardrail re-enabled.
- **Domain-wide Delegation (DWD)**  
  Service account OAuth client ID authorized in Admin Console with only the required scopes:
```

[https://www.googleapis.com/auth/admin.directory.user](https://www.googleapis.com/auth/admin.directory.user),
[https://www.googleapis.com/auth/admin.directory.group](https://www.googleapis.com/auth/admin.directory.group)

```
- **Least Privilege**  
Group receives `roles/viewer`. Elevations (e.g., `roles/editor`) must be applied separately and scoped to dev-only projects.

---

##  File Structure
```

gcp-centralizing-users/
├── main.tf              # Users, groups, IAM bindings
├── variables.tf         # Input variables
├── terraform.tfvars     # Environment-specific values
├── provider.tf          # Providers: google + googleworkspace
└── README.md            # This file

````

---

##  Example terraform.tfvars

```hcl
service_account_key_path = "/Users/you/.secrets/workspace_admin.json"
customer_id             = "C0123abc45"
impersonated_user_email = "admin@example.com"

identity_project_id = "identity-sec-1234567890"
target_project_id   = "dev-project-12345"

users = {
  "jane.doe@example.com" = { given_name = "Jane", family_name = "Doe" }
  "john.smith@example.com" = { given_name = "John", family_name = "Smith" }
}

team_name        = "Payments Team"
team_description = "Read-only access for the Payments team"
team_email       = "payments-team@example.com"
````

---

## ▶ Usage

```bash
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars -auto-approve
```

Retrieve one-time passwords for the new users:

```bash
terraform output -json passwords | jq -r '.[] | to_entries[] | "\(.key): \(.value)"'
```

---

## 🛠️ Common Pitfalls & Fixes

* **Error: Key creation not allowed**
  Org policy blocked SA key creation. Temporarily disable it *at project level only*, mint the key, then re-enable.

* **Error: insufficientPermissions**
  Domain-wide delegation not configured correctly. Ensure the service account OAuth client ID is added in Admin Console with both scopes.

* **Group domain invalid**
  Ensure `team_email` uses a verified Workspace domain.

* **Passwords output empty**
  You may be running from the wrong folder. `auth/` only bootstraps the service account; run from `gcp-centralizing-users/`.

---

##  Real-World Use Cases

* **Team Onboarding**
  Provision new hires, group them, and grant project access in one Terraform apply.
  Offboarding = remove them from the group → access revoked everywhere.

* **Contractor Access**
  Temporary accounts grouped under `contractors@yourdomain.com` with read-only project access.
  Easy cleanup when contracts end.

* **Audit Readiness (SOC 2, ISO 27001)**
  Demonstrate exactly who has access:

  * Workspace shows group membership
  * Cloud IAM shows group binding
  * Git history shows when/why access changed

---

##  Why This Matters

This repo is a **blueprint for enterprise identity management**:

* Identity lives in Workspace
* Cloud IAM references groups, not individuals
* Every binding is auditable and code-reviewed
* Security guardrails are enforced end-to-end

This is how organizations scale from **10 → 10,000 users** without drowning in IAM chaos.

---

##  License

MIT — free to use, adapt, and improve.

---

 **Pro Tip:** Fork this into a reusable `terraform-module-team-onboarding` and you’ll have a plug-and-play pattern for onboarding entire departments with a single `terraform apply`.

```

