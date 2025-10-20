#
# Terraform Makefile
#
# Simplifies Terraform workflow with environment-specific configurations
#
.ONESHELL:
.SHELL := /bin/bash
.PHONY: tf-help tf-init tf-plan tf-apply tf-destroy tf-output tf-console tf-validate tf-fmt tf-clean tf-workspace-list tf-workspace-new tf-workspace-select
.EXPORT_ALL_VARIABLES:

# Default environment
ENVIRONMENT ?= lab

# Terraform variables file
TFVARS_FILE := $(ENVIRONMENT).terraform.tfvars

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;36m
RESET := \033[0m

tf-help: ## Show this help message
	@echo "$(BLUE)Terraform Makefile - Environment: $(ENVIRONMENT)$(RESET)"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [ENVIRONMENT=<env>]"
	@echo ""
	@echo "Examples:"
	@echo "  make tf-plan                    # Plan with lab.terraform.tfvars (default)"
	@echo "  make tf-apply ENVIRONMENT=stg   # Apply with stg.terraform.tfvars"
	@echo "  make tf-destroy ENVIRONMENT=prd # Destroy with prd.terraform.tfvars"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "Environments:"
	@echo "  ENVIRONMENT=lab (default)"
	@echo "  ENVIRONMENT=stg"
	@echo "  ENVIRONMENT=prd"

tf-check-tfvars: ## Check if tfvars file exists for the current environment
	@if [ ! -f "$(TFVARS_FILE)" ]; then \
		echo "$(RED)ERROR: $(TFVARS_FILE) not found!$(RESET)"; \
		echo ""; \
		echo "Please create it first:"; \
		echo "  cp terraform.tfvars.example $(TFVARS_FILE)"; \
		echo "  vim $(TFVARS_FILE)"; \
		echo ""; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Using $(TFVARS_FILE)$(RESET)"

tf-check-env: ## Verify required environment variables are set
	@if [ -z "$$HCLOUD_TOKEN" ]; then \
		echo "$(RED)ERROR: HCLOUD_TOKEN is not set$(RESET)"; \
		echo ""; \
		echo "Please export your Hetzner Cloud API token:"; \
		echo "  export HCLOUD_TOKEN='your-token'"; \
		echo ""; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ HCLOUD_TOKEN is set$(RESET)"

tf-init: tf-check-env ## Initialize Terraform (downloads providers)
	@echo "$(BLUE)Initializing Terraform...$(RESET)"
	terraform init

tf-validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(RESET)"
	terraform validate

tf-fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	terraform fmt -recursive

tf-plan: tf-check-env tf-check-tfvars ## Show Terraform execution plan
	@echo "$(BLUE)Planning infrastructure changes for $(ENVIRONMENT)...$(RESET)"
	terraform plan -var-file=$(TFVARS_FILE)

tf-apply: tf-check-env tf-check-tfvars ## Apply Terraform changes
	@echo "$(BLUE)Applying infrastructure changes for $(ENVIRONMENT)...$(RESET)"
	terraform apply -var-file=$(TFVARS_FILE)

tf-apply-auto: tf-check-env tf-check-tfvars ## Apply Terraform changes without confirmation
	@echo "$(YELLOW)WARNING: Auto-applying changes for $(ENVIRONMENT) without confirmation!$(RESET)"
	terraform apply -auto-approve -var-file=$(TFVARS_FILE)

tf-destroy: tf-check-env tf-check-tfvars ## Destroy Terraform-managed infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure for $(ENVIRONMENT)!$(RESET)"
	terraform destroy -var-file=$(TFVARS_FILE)

tf-destroy-auto: tf-check-env tf-check-tfvars ## Destroy infrastructure without confirmation
	@echo "$(RED)WARNING: Auto-destroying infrastructure for $(ENVIRONMENT) without confirmation!$(RESET)"
	terraform destroy -auto-approve -var-file=$(TFVARS_FILE)

tf-output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENVIRONMENT):$(RESET)"
	terraform output

tf-output-json: ## Show Terraform outputs in JSON format
	terraform output -json

tf-show: ## Show Terraform state
	terraform show

tf-console: tf-check-tfvars ## Open Terraform console with environment variables
	@echo "$(BLUE)Opening Terraform console for $(ENVIRONMENT)...$(RESET)"
	@echo "Tip: Try 'var.environment' or 'var.server_type'"
	terraform console -var-file=$(TFVARS_FILE)

tf-refresh: tf-check-env tf-check-tfvars ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state for $(ENVIRONMENT)...$(RESET)"
	terraform refresh -var-file=$(TFVARS_FILE)

tf-state-list: ## List resources in Terraform state
	terraform state list

tf-state-show: ## Show a specific resource (usage: make tf-state-show RESOURCE=hcloud_server.bastion)
	@if [ -z "$(RESOURCE)" ]; then \
		echo "$(RED)ERROR: RESOURCE not specified$(RESET)"; \
		echo "Usage: make tf-state-show RESOURCE=hcloud_server.bastion"; \
		exit 1; \
	fi
	terraform state show $(RESOURCE)

# Inventory management
tf-inventory: ## Show Ansible inventory for current environment
	@echo "$(BLUE)Ansible inventory for $(ENVIRONMENT):$(RESET)"
	terraform output -raw ansible_inventory

tf-inventory-save: ## Save Ansible inventory to file
	@echo "$(BLUE)Saving inventory to ../ansible/inventories/$(ENVIRONMENT)/hosts.ini$(RESET)"
	@mkdir -p ../ansible/inventories/$(ENVIRONMENT)
	terraform output -raw ansible_inventory > ../ansible/inventories/$(ENVIRONMENT)/hosts.ini
	@echo "$(GREEN)✓ Inventory saved$(RESET)"

# Environment setup helpers
tf-setup-lab: ## Create lab.terraform.tfvars from example
	@if [ -f "lab.terraform.tfvars" ]; then \
		echo "$(YELLOW)lab.terraform.tfvars already exists$(RESET)"; \
	else \
		cp terraform.tfvars.example lab.terraform.tfvars; \
		echo "$(GREEN)✓ Created lab.terraform.tfvars from example$(RESET)"; \
		echo "$(YELLOW)Please edit lab.terraform.tfvars with your settings$(RESET)"; \
	fi

tf-setup-stg: ## Create stg.terraform.tfvars template
	@if [ -f "stg.terraform.tfvars" ]; then \
		echo "$(YELLOW)stg.terraform.tfvars already exists$(RESET)"; \
	else \
		cat > stg.terraform.tfvars <<-'EOF'; \
		# Staging Environment Configuration\n\
		environment = "stg"\n\
		location    = "fsn1"              # Falkenstein\n\
		server_type = "cpx31"             # 4 vCPU, 8GB RAM\n\
		bastion_server_type = "cpx11"\n\
		allowed_cidrs = ["0.0.0.0/0"]\n\
		ssh_keys = []\n\
		EOF\n\
		echo "$(GREEN)✓ Created stg.terraform.tfvars$(RESET)"; \
		echo "$(YELLOW)Please edit stg.terraform.tfvars with your settings$(RESET)"; \
	fi

tf-setup-prd: ## Create prd.terraform.tfvars template
	@if [ -f "prd.terraform.tfvars" ]; then \
		echo "$(YELLOW)prd.terraform.tfvars already exists$(RESET)"; \
	else \
		cat > prd.terraform.tfvars <<-'EOF'; \
		# Production Environment Configuration\n\
		environment = "prd"\n\
		location    = "hel1"              # Helsinki\n\
		server_type = "cpx51"             # 16 vCPU, 32GB RAM\n\
		bastion_server_type = "cpx21"     # 4 vCPU, 8GB RAM\n\
		allowed_cidrs = ["YOUR_IP/32"]    # Restrict to your IP!\n\
		ssh_keys = ["prod-ssh-key"]       # Use existing SSH key\n\
		EOF\n\
		echo "$(GREEN)✓ Created prd.terraform.tfvars$(RESET)"; \
		echo "$(RED)⚠ IMPORTANT: Edit prd.terraform.tfvars and restrict allowed_cidrs!$(RESET)"; \
	fi

# Cleanup
tf-clean: ## Remove Terraform cache and temporary files
	@echo "$(BLUE)Cleaning Terraform cache...$(RESET)"
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f graph.png
	@echo "$(GREEN)✓ Cleaned$(RESET)"

tf-clean-all: tf-clean ## Remove all Terraform files including state (DANGEROUS!)
	@echo "$(RED)WARNING: This will remove ALL Terraform state files!$(RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -f terraform.tfstate*; \
		rm -rf .terraform.d; \
		echo "$(GREEN)✓ All Terraform files removed$(RESET)"; \
	else \
		echo "$(YELLOW)Cancelled$(RESET)"; \
	fi

# Quick deployment workflows
tf-deploy-lab: ## Full workflow: init -> plan -> apply for lab
	@$(MAKE) ENVIRONMENT=lab tf-init
	@$(MAKE) ENVIRONMENT=lab tf-plan
	@$(MAKE) ENVIRONMENT=lab tf-apply
	@$(MAKE) ENVIRONMENT=lab tf-inventory-save

tf-deploy-stg: ## Full workflow: init -> plan -> apply for staging
	@$(MAKE) ENVIRONMENT=stg tf-workspace-select WORKSPACE=stg || $(MAKE) ENVIRONMENT=stg tf-workspace-new WORKSPACE=stg
	@$(MAKE) ENVIRONMENT=stg tf-init
	@$(MAKE) ENVIRONMENT=stg tf-plan
	@$(MAKE) ENVIRONMENT=stg tf-apply
	@$(MAKE) ENVIRONMENT=stg tf-inventory-save

tf-deploy-prd: ## Full workflow: init -> plan -> apply for production
	@$(MAKE) ENVIRONMENT=prd tf-workspace-select WORKSPACE=prd || $(MAKE) ENVIRONMENT=prd tf-workspace-new WORKSPACE=prd
	@$(MAKE) ENVIRONMENT=prd tf-init
	@$(MAKE) ENVIRONMENT=prd tf-plan
	@$(MAKE) ENVIRONMENT=prd tf-apply
	@$(MAKE) ENVIRONMENT=prd tf-inventory-save

# Version info
tf-version: ## Show Terraform version
	terraform version
