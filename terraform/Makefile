#
# Terraform Makefile
#
# Simplifies Terraform workflow with environment-specific configurations
#
.ONESHELL:
.SHELL := /bin/bash
.PHONY: help init plan apply destroy output console validate fmt clean workspace-list workspace-new workspace-select
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

help: ## Show this help message
	@echo "$(BLUE)Terraform Makefile - Environment: $(ENVIRONMENT)$(RESET)"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [ENVIRONMENT=<env>]"
	@echo ""
	@echo "Examples:"
	@echo "  make plan                    # Plan with lab.terraform.tfvars (default)"
	@echo "  make apply ENVIRONMENT=stg   # Apply with stg.terraform.tfvars"
	@echo "  make destroy ENVIRONMENT=prd # Destroy with prd.terraform.tfvars"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "Environments:"
	@echo "  ENVIRONMENT=lab (default)"
	@echo "  ENVIRONMENT=stg"
	@echo "  ENVIRONMENT=prd"

check-tfvars: ## Check if tfvars file exists for the current environment
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

check-env: ## Verify required environment variables are set
	@if [ -z "$$HCLOUD_TOKEN" ]; then \
		echo "$(RED)ERROR: HCLOUD_TOKEN is not set$(RESET)"; \
		echo ""; \
		echo "Please export your Hetzner Cloud API token:"; \
		echo "  export HCLOUD_TOKEN='your-token'"; \
		echo ""; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ HCLOUD_TOKEN is set$(RESET)"

init: check-env ## Initialize Terraform (downloads providers)
	@echo "$(BLUE)Initializing Terraform...$(RESET)"
	terraform init

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(RESET)"
	terraform validate

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	terraform fmt -recursive

plan: check-env check-tfvars ## Show Terraform execution plan
	@echo "$(BLUE)Planning infrastructure changes for $(ENVIRONMENT)...$(RESET)"
	terraform plan -var-file=$(TFVARS_FILE)

apply: check-env check-tfvars ## Apply Terraform changes
	@echo "$(BLUE)Applying infrastructure changes for $(ENVIRONMENT)...$(RESET)"
	terraform apply -var-file=$(TFVARS_FILE)

apply-auto: check-env check-tfvars ## Apply Terraform changes without confirmation
	@echo "$(YELLOW)WARNING: Auto-applying changes for $(ENVIRONMENT) without confirmation!$(RESET)"
	terraform apply -auto-approve -var-file=$(TFVARS_FILE)

destroy: check-env check-tfvars ## Destroy Terraform-managed infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure for $(ENVIRONMENT)!$(RESET)"
	terraform destroy -var-file=$(TFVARS_FILE)

destroy-auto: check-env check-tfvars ## Destroy infrastructure without confirmation
	@echo "$(RED)WARNING: Auto-destroying infrastructure for $(ENVIRONMENT) without confirmation!$(RESET)"
	terraform destroy -auto-approve -var-file=$(TFVARS_FILE)

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENVIRONMENT):$(RESET)"
	terraform output

output-json: ## Show Terraform outputs in JSON format
	terraform output -json

show: ## Show Terraform state
	terraform show

console: check-tfvars ## Open Terraform console with environment variables
	@echo "$(BLUE)Opening Terraform console for $(ENVIRONMENT)...$(RESET)"
	@echo "Tip: Try 'var.environment' or 'var.server_type'"
	terraform console -var-file=$(TFVARS_FILE)

refresh: check-env check-tfvars ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state for $(ENVIRONMENT)...$(RESET)"
	terraform refresh -var-file=$(TFVARS_FILE)

state-list: ## List resources in Terraform state
	terraform state list

state-show: ## Show a specific resource (usage: make state-show RESOURCE=hcloud_server.bastion)
	@if [ -z "$(RESOURCE)" ]; then \
		echo "$(RED)ERROR: RESOURCE not specified$(RESET)"; \
		echo "Usage: make state-show RESOURCE=hcloud_server.bastion"; \
		exit 1; \
	fi
	terraform state show $(RESOURCE)

graph: ## Generate Terraform dependency graph
	terraform graph | dot -Tpng > graph.png
	@echo "$(GREEN)Graph generated: graph.png$(RESET)"

# Workspace management
workspace-list: ## List Terraform workspaces
	@echo "$(BLUE)Available workspaces:$(RESET)"
	terraform workspace list

workspace-new: ## Create new workspace (usage: make workspace-new WORKSPACE=stg)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)ERROR: WORKSPACE not specified$(RESET)"; \
		echo "Usage: make workspace-new WORKSPACE=stg"; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating workspace: $(WORKSPACE)$(RESET)"
	terraform workspace new $(WORKSPACE)

workspace-select: ## Select workspace (usage: make workspace-select WORKSPACE=stg)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)ERROR: WORKSPACE not specified$(RESET)"; \
		echo "Usage: make workspace-select WORKSPACE=stg"; \
		exit 1; \
	fi
	@echo "$(BLUE)Selecting workspace: $(WORKSPACE)$(RESET)"
	terraform workspace select $(WORKSPACE)

workspace-show: ## Show current workspace
	@echo "$(BLUE)Current workspace:$(RESET)"
	terraform workspace show

workspace-delete: ## Delete workspace (usage: make workspace-delete WORKSPACE=old-env)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)ERROR: WORKSPACE not specified$(RESET)"; \
		echo "Usage: make workspace-delete WORKSPACE=old-env"; \
		exit 1; \
	fi
	@echo "$(RED)Deleting workspace: $(WORKSPACE)$(RESET)"
	terraform workspace delete $(WORKSPACE)

# Inventory management
inventory: ## Show Ansible inventory for current environment
	@echo "$(BLUE)Ansible inventory for $(ENVIRONMENT):$(RESET)"
	terraform output -raw ansible_inventory

inventory-save: ## Save Ansible inventory to file
	@echo "$(BLUE)Saving inventory to ../ansible/inventories/$(ENVIRONMENT)/hosts.ini$(RESET)"
	@mkdir -p ../ansible/inventories/$(ENVIRONMENT)
	terraform output -raw ansible_inventory > ../ansible/inventories/$(ENVIRONMENT)/hosts.ini
	@echo "$(GREEN)✓ Inventory saved$(RESET)"

# Environment setup helpers
setup-lab: ## Create lab.terraform.tfvars from example
	@if [ -f "lab.terraform.tfvars" ]; then \
		echo "$(YELLOW)lab.terraform.tfvars already exists$(RESET)"; \
	else \
		cp terraform.tfvars.example lab.terraform.tfvars; \
		echo "$(GREEN)✓ Created lab.terraform.tfvars from example$(RESET)"; \
		echo "$(YELLOW)Please edit lab.terraform.tfvars with your settings$(RESET)"; \
	fi

setup-stg: ## Create stg.terraform.tfvars template
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

setup-prd: ## Create prd.terraform.tfvars template
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
clean: ## Remove Terraform cache and temporary files
	@echo "$(BLUE)Cleaning Terraform cache...$(RESET)"
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f graph.png
	@echo "$(GREEN)✓ Cleaned$(RESET)"

clean-all: clean ## Remove all Terraform files including state (DANGEROUS!)
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
deploy-lab: ## Full workflow: init -> plan -> apply for lab
	@$(MAKE) ENVIRONMENT=lab init
	@$(MAKE) ENVIRONMENT=lab plan
	@$(MAKE) ENVIRONMENT=lab apply
	@$(MAKE) ENVIRONMENT=lab inventory-save

deploy-stg: ## Full workflow: init -> plan -> apply for staging
	@$(MAKE) ENVIRONMENT=stg workspace-select WORKSPACE=stg || $(MAKE) ENVIRONMENT=stg workspace-new WORKSPACE=stg
	@$(MAKE) ENVIRONMENT=stg init
	@$(MAKE) ENVIRONMENT=stg plan
	@$(MAKE) ENVIRONMENT=stg apply
	@$(MAKE) ENVIRONMENT=stg inventory-save

deploy-prd: ## Full workflow: init -> plan -> apply for production
	@$(MAKE) ENVIRONMENT=prd workspace-select WORKSPACE=prd || $(MAKE) ENVIRONMENT=prd workspace-new WORKSPACE=prd
	@$(MAKE) ENVIRONMENT=prd init
	@$(MAKE) ENVIRONMENT=prd plan
	@$(MAKE) ENVIRONMENT=prd apply
	@$(MAKE) ENVIRONMENT=prd inventory-save

# Version info
version: ## Show Terraform version
	terraform version
