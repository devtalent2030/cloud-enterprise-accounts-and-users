# ------------------------------------------------------------------------------
# Cloud Enterprise Accounts & Users - Runner Makefile
# Works from repo root to run Terraform in any module folder.
#
# Examples:
#   make plan   MODULE=gcp/gcp-centralizing-users TFVARS=terraform.tfvars
#   make apply  MODULE=gcp/gcp-centralizing-users
#   make destroy MODULE=gcp/gcp-centralizing-users
#
# Optional guard (refuse to run on wrong project):
#   make apply MODULE=gcp/gcp-centralizing-users GCP_EXPECTED_PROJECT=identity-sec-1756031328
#
# Convenience for your current setup:
#   KEY=~/.secrets/workspace_admin.json
#   PROJECT_ID=identity-sec-1756031328
# ------------------------------------------------------------------------------

SHELL := /bin/bash

# ========= Defaults you can override at call =========
MODULE ?= gcp/gcp-centralizing-users
TFVARS ?= terraform.tfvars

# Optional guardrails
GCP_EXPECTED_PROJECT ?=
AWS_EXPECTED_ACCOUNT ?=
AZURE_EXPECTED_SUBSCRIPTION ?=

# Optional file checks (e.g., SA key for googleworkspace provider)
REQUIRED_KEY ?=

# ========= Colors =========
RESET := \033[0m
BOLD  := \033[1m
FG_CYAN := \033[36m
FG_GREEN := \033[32m
FG_YELLOW := \033[33m
FG_RED := \033[31m
FG_GRAY := \033[90m

define banner
	@printf "$(BOLD)$(FG_CYAN)▶ %s$(RESET) $(FG_GRAY)[dir=%s var=%s]$(RESET)\n" "$(1)" "$(2)" "$(3)"
endef

define ensure_dir
	@test -d "$(1)" || { printf "$(FG_RED)Error: directory '%s' not found.$(RESET)\n" "$(1)"; exit 1; }
endef

define ensure_file_if_set
	@if [ -n "$(1)" ] && [ ! -f "$(1)" ]; then \
	  printf "$(FG_RED)Error: required file not found: %s$(RESET)\n" "$(1)"; exit 1; \
	fi
endef

# ========= Preflight: GCP =========
gcp-preflight:
	@set -e; \
	command -v gcloud >/dev/null || { echo "$(FG_RED)gcloud CLI not found$(RESET)"; exit 1; }; \
	command -v terraform >/dev/null || { echo "$(FG_RED)terraform not found$(RESET)"; exit 1; }; \
	PROJECT=$$(gcloud config get-value project 2>/dev/null); \
	ACCOUNT=$$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null); \
	if [ -z "$$PROJECT" ]; then echo "$(FG_RED)No active GCP project set (gcloud config set project …)$(RESET)"; exit 1; fi; \
	if [ -z "$$ACCOUNT" ]; then echo "$(FG_RED)No active GCP credentials (gcloud auth login)$(RESET)"; exit 1; fi; \
	printf "$(FG_GREEN)GCP OK$(RESET): project=%s account=%s\n" "$$PROJECT" "$$ACCOUNT"; \
	if [ -n "$(GCP_EXPECTED_PROJECT)" ] && [ "$$PROJECT" != "$(GCP_EXPECTED_PROJECT)" ]; then \
	  echo "$(FG_RED)Refusing: expected project $(GCP_EXPECTED_PROJECT), got $$PROJECT$(RESET)"; exit 1; \
	fi; \
	$(call ensure_file_if_set,$(REQUIRED_KEY))

# ========= Terraform wrappers (generic to any MODULE) =========
init: ## terraform init in MODULE
	$(call ensure_dir,$(MODULE))
	$(call banner,terraform init,$(MODULE),$(TFVARS))
	@terraform -chdir=$(MODULE) init

plan: ## terraform plan (uses TFVARS)
	$(call ensure_dir,$(MODULE))
	$(call banner,terraform plan,$(MODULE),$(TFVARS))
	@terraform -chdir=$(MODULE) plan -var-file=$(abspath $(TFVARS))

apply: ## terraform apply -auto-approve (uses TFVARS)
	$(call ensure_dir,$(MODULE))
	$(call banner,terraform apply,$(MODULE),$(TFVARS))
	@terraform -chdir=$(MODULE) apply -auto-approve -var-file=$(abspath $(TFVARS))

destroy: ## terraform destroy -auto-approve (uses TFVARS)
	$(call ensure_dir,$(MODULE))
	$(call banner,terraform destroy,$(MODULE),$(TFVARS))
	@terraform -chdir=$(MODULE) destroy -auto-approve -var-file=$(abspath $(TFVARS))

fmt: ## terraform fmt -recursive (whole repo)
	@printf "$(FG_CYAN)terraform fmt -recursive$(RESET)\n"
	@terraform fmt -recursive

validate: ## terraform validate in MODULE
	$(call ensure_dir,$(MODULE))
	$(call banner,terraform validate,$(MODULE),$(TFVARS))
	@terraform -chdir=$(MODULE) validate

# ========= Quality-of-life for your GCP centralizing-users module =========
# Use these when MODULE=gcp/gcp-centralizing-users and REQUIRED_KEY=~/.secrets/workspace_admin.json

gcp-info: ## Print current gcloud identity & project
	@PROJECT=$$(gcloud config get-value project 2>/dev/null); \
	ACCOUNT=$$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null); \
	printf "$(FG_GREEN)gcloud$(RESET): project=%s account=%s\n" "$$PROJECT" "$$ACCOUNT"

outputs: ## Show Terraform outputs in MODULE (safe for passwords if defined as sensitive)
	$(call ensure_dir,$(MODULE))
	@terraform -chdir=$(MODULE) output

# ========= Org Policy toggles (project-level SA key creation) =========
# These mirror what you ran manually. They scope the constraint to the active gcloud project.

gcp-allow-sa-keys: ## Temporarily allow SA key creation at project level (for identity project only)
	@set -euo pipefail; \
	PROJECT=$$(gcloud config get-value project 2>/dev/null); \
	PNUM=$$(gcloud projects describe $$PROJECT --format='value(projectNumber)'); \
	printf "$(FG_YELLOW)Enabling orgpolicy API if needed…$(RESET)\n"; \
	gcloud services enable orgpolicy.googleapis.com --project "$$PROJECT" >/dev/null; \
	TMP=/tmp/iam-disable-sa-keycreation-project-override.yaml; \
	printf '%s\n' \
	  "name: projects/$$PNUM/policies/iam.disableServiceAccountKeyCreation" \
	  "spec:" \
	  "  rules:" \
	  "  - enforce: false" > $$TMP; \
	printf "$(FG_CYAN)Applying policy override on project %s (number %s)…$(RESET)\n" "$$PROJECT" "$$PNUM"; \
	gcloud org-policies set-policy $$TMP >/dev/null; \
	gcloud org-policies describe iam.disableServiceAccountKeyCreation --project="$$PROJECT" --effective

gcp-deny-sa-keys: ## Re-enable the guardrail (deny SA key creation at project level)
	@set -euo pipefail; \
	PROJECT=$$(gcloud config get-value project 2>/dev/null); \
	PNUM=$$(gcloud projects describe $$PROJECT --format='value(projectNumber)'); \
	TMP=/tmp/iam-disable-sa-keycreation-project-override.yaml; \
	printf '%s\n' \
	  "name: projects/$$PNUM/policies/iam.disableServiceAccountKeyCreation" \
	  "spec:" \
	  "  rules:" \
	  "  - enforce: true" > $$TMP; \
	printf "$(FG_CYAN)Restoring deny on project %s (number %s)…$(RESET)\n" "$$PROJECT" "$$PNUM"; \
	gcloud org-policies set-policy $$TMP >/dev/null; \
	gcloud org-policies describe iam.disableServiceAccountKeyCreation --project="$$PROJECT" --effective

# ========= Nice presets for your common module paths =========
# (You can still pass MODULE/TFVARS explicitly; these just save typing.)

gcp-centralizing-users: ## Shortcut: set MODULE & sensible defaults, then print info
	@echo "MODULE=gcp/gcp-centralizing-users"; \
	echo "TFVARS=gcp/gcp-centralizing-users/terraform.tfvars"; \
	echo "Use: make plan/apply MODULE=gcp/gcp-centralizing-users TFVARS=gcp/gcp-centralizing-users/terraform.tfvars REQUIRED_KEY=$$HOME/.secrets/workspace_admin.json"

gcp-region-locking: ## Shortcut hint
	@echo "MODULE=gcp/region-locking"; \
	echo "TFVARS=gcp/region-locking/terraform.tfvars"

gcp-project-structure: ## Shortcut hint
	@echo "MODULE=gcp/scalable-project-structure"; \
	echo "TFVARS=gcp/scalable-project-structure/terraform.tfvars"

# ========= Help =========
help: ## Show help
	@printf "\n$(BOLD)Available targets$(RESET)\n"
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(FG_GREEN)make %-22s$(RESET) $(FG_YELLOW)%s$(RESET)\n", $$1, $$2}'
	@printf "\n$(FG_GRAY)Examples$(RESET):\n"
	@printf "  make plan   MODULE=gcp/gcp-centralizing-users TFVARS=gcp/gcp-centralizing-users/terraform.tfvars REQUIRED_KEY=$$HOME/.secrets/workspace_admin.json\n"
	@printf "  make apply  MODULE=gcp/gcp-centralizing-users GCP_EXPECTED_PROJECT=identity-sec-1756031328 REQUIRED_KEY=$$HOME/.secrets/workspace_admin.json\n"
	@printf "  make outputs MODULE=gcp/gcp-centralizing-users\n"
	@printf "  make gcp-allow-sa-keys   && make apply MODULE=gcp/gcp-centralizing-users ... && make gcp-deny-sa-keys\n\n"

.PHONY: gcp-preflight init plan apply destroy fmt validate outputs gcp-info \
        gcp-allow-sa-keys gcp-deny-sa-keys \
        gcp-centralizing-users gcp-region-locking gcp-project-structure help
.DEFAULT_GOAL := help
