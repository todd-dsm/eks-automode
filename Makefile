#!/usr/bin/env make
# vim: tabstop=8 noexpandtab

# Module order
MODULES := networking eks-core addons-core addons-apps karpenter

# Default target when just running 'make'
.DEFAULT_GOAL := help

# Plan file variable (extracted from terraform.tfvars)
FILE_PLAN = /tmp/tf-$$(grep my_project terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "project").plan
LOG_PLAN = /tmp/tf-$$(grep my_project terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "project")-plan.out

# Generate terraform.tfvars for specific environment
tfvars:
	@if [ -z "$(filter stage prod,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make tfvars <stage|prod>"; \
		echo ""; \
		echo "Example:"; \
		echo "  make tfvars stage   - Generate terraform.tfvars for staging"; \
		echo "  make tfvars prod    - Generate terraform.tfvars for production"; \
		exit 1; \
	fi

# Environment targets (stage/prod) - these are the actual tfvars generators
stage prod:
	@echo "=== Generating terraform.tfvars for $@ environment ==="
	@if [ -f terraform.tfvars ]; then \
		backup_name="/tmp/terraform.tfvars.bak.$$(date +%Y%m%d-%H%M%S)"; \
		echo "⚠️  Backing up existing terraform.tfvars to $$backup_name"; \
		mv terraform.tfvars "$$backup_name"; \
	fi
	@bash -c 'source build.env $@'
	@echo "✓ Generated: terraform.tfvars"
	@echo "✓ Environment: $@"
	@echo ""
	@echo "Next steps:"
	@echo "  make init   - Initialize Terraform"
	@echo "  make plan   - Plan infrastructure"
	@echo "  make apply  - Apply changes"

# Initialize Terraform
init:
	@echo "=== Initializing Terraform ==="
	@if [ ! -f terraform.tfvars ]; then \
		echo "ERROR: terraform.tfvars not found!"; \
		echo "Run 'make tfvars <stage|prod>' first"; \
		exit 1; \
	fi
	@terraform init -upgrade
	@echo "✓ Terraform initialized"

# Format Terraform files
fmt:
	@echo "=== Formatting Terraform files ==="
	@terraform fmt -recursive
	@echo "✓ Terraform files formatted"

# Plan entire infrastructure
plan: check-env fmt
	@echo "=== Planning infrastructure ==="
	@echo "Plan file: $(FILE_PLAN)"
	@echo "Log file: $(LOG_PLAN)"
	@terraform plan -no-color -out=$(FILE_PLAN) 2>&1 | tee $(LOG_PLAN)
	@echo ""
	@echo "✓ Plan saved to: $(FILE_PLAN)"
	@echo "✓ Log saved to: $(LOG_PLAN)"

# Plan specific module
plan-%: check-env fmt
	@echo "=== Planning module: $* ==="
	@terraform plan -target=module.$* -out=/tmp/tf-$*.plan
	@echo "✓ Module plan saved to: /tmp/tf-$*.plan"

# Apply the saved plan
apply: check-env
	@echo "=== Applying infrastructure ==="
	@if [ ! -f $(FILE_PLAN) ]; then \
		echo "ERROR: Plan file not found: $(FILE_PLAN)"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	fi
	@terraform apply -auto-approve $(FILE_PLAN)
	@echo "=== SUCCESS: Infrastructure deployed ==="

# Apply specific module
apply-%: check-env
	@echo "=== Applying module: $* ==="
	@if [ ! -f /tmp/tf-$*.plan ]; then \
		echo "ERROR: Module plan file not found: /tmp/tf-$*.plan"; \
		echo "Run 'make plan-$*' first"; \
		exit 1; \
	fi
	@terraform apply -auto-approve /tmp/tf-$*.plan
	@echo "✓ Module $* applied"

# All-in-one command
all: init plan apply

# Plan individual module (standalone command)
module-%: check-env init fmt
	@echo "=== Planning module: $* ==="
	@terraform plan -target=module.$* -out=/tmp/tf-$*.plan
	@echo ""
	@echo "Review the plan above. To apply, run:"
	@echo "  make apply-$*"

# Destroy with random confirmation code
destroy: check-env
	@current_env=$$(grep "^env_build" terraform.tfvars | cut -d'"' -f2); \
	current_region=$$(grep "^region" terraform.tfvars | cut -d'"' -f2); \
	confirm_code=$$(openssl rand -hex 3); \
	echo ""; \
	echo "╔═══════════════════════════════════════════════════════╗"; \
	echo "║          ⚠️  INFRASTRUCTURE DESTRUCTION ⚠️              ║"; \
	echo "╚═══════════════════════════════════════════════════════╝"; \
	echo ""; \
	echo "Target Environment: $$current_env"; \
	echo "Region: $$current_region"; \
	echo ""; \
	echo "═══════════════════════════════════════════════════════"; \
	echo ""; \
	echo "To confirm destroy operation, type this code: $$confirm_code"; \
	echo ""; \
	printf "Enter confirmation code: "; \
	read user_code; \
	if [ "$$user_code" != "$$confirm_code" ]; then \
		echo ""; \
		echo "❌ Incorrect code. Destruction cancelled."; \
		echo "✅ Infrastructure remains intact."; \
		exit 1; \
	fi; \
	echo ""; \
	echo "⚠️  Code confirmed. Starting destruction..."; \
	echo ""
	@if [ -f scripts/janitor-pre.sh ]; then \
		echo "Running pre-destroy cleanup..."; \
		scripts/janitor-pre.sh; \
	fi
	@echo "🔥 Destroying all infrastructure..."
	@terraform apply -destroy -auto-approve -no-color 2>&1 | \
		tee /tmp/tf-$(shell grep my_project terraform.tfvars | cut -d'"' -f2)-destroy.out
	@if [ -f scripts/janitor-post.sh ]; then \
		echo "Running post-destroy cleanup..."; \
		scripts/janitor-post.sh; \
	fi
	@rm -rf .terraform/ .terraform.lock.hcl
	@echo ""
	@echo "💀 All infrastructure has been destroyed"
	@echo "✓ Log saved to: /tmp/tf-$(shell grep my_project terraform.tfvars | cut -d'"' -f2)-destroy.out"

# Check environment helper
check-env:
	@if [ ! -f terraform.tfvars ]; then \
		echo "ERROR: terraform.tfvars not found!"; \
		echo "Run 'make tfvars <stage|prod>' first"; \
		exit 1; \
	fi

# Show current environment
show:
	@if [ -f terraform.tfvars ]; then \
		echo "=== Active Configuration ==="; \
		echo ""; \
		grep -E "^(env_build|project|region|vpc_cidr)" terraform.tfvars | sed 's/^/  /'; \
		echo ""; \
	else \
		echo "No terraform.tfvars found."; \
		echo "Run: make tfvars <stage|prod>"; \
	fi

# Utilities
clean:
	@echo "=== Cleaning generated files ==="
	@rm -f terraform.tfvars
	@rm -f /tmp/tf-*.plan
	@rm -f /tmp/tf-*-plan.out
	@rm -f /tmp/terraform.tfvars.bak.*
	@rm -f provider.tf
	@echo "✓ Cleaned"

clean-all: clean
	@echo "=== Removing Terraform files ==="
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfstate*
	@echo "✓ All Terraform files removed"

# List modules
list:
	@echo "=== Available modules ==="
	@for m in $(MODULES); do echo "  • $$m"; done

# List tfvars backups
list-backups:
	@echo "=== Available terraform.tfvars backups ==="
	@if ls /tmp/terraform.tfvars.bak.* 1> /dev/null 2>&1; then \
		ls -la /tmp/terraform.tfvars.bak.* | awk '{print "  • " $$9 " (" $$6 " " $$7 " " $$8 ")"}'; \
	else \
		echo "  No backups found in /tmp"; \
	fi

# Validate configuration
validate: init
	@terraform validate
	@terraform fmt -check -recursive
	@echo "✓ Configuration valid"

# Help - Default target
help:
	@echo ""
	@echo "  AWS EKS Infrastructure Build System"
	@echo "  ==================================="
	@echo ""
	@echo "  Quick Start:"
	@echo "    make tfvars <stage|prod> - Generate terraform.tfvars"
	@echo "      EX: make tfvars stage  - for staging terraform.tfvars"
	@echo "    make all                 - Build everything"
	@echo ""
	@echo "  Step by Step:"
	@echo "    make init                - Initialize Terraform"
	@echo "    make plan                - Plan entire infrastructure"
	@echo "    make apply               - Apply infrastructure"
	@echo ""
	@echo "  Environment:"
	@echo "    make show                - Show current environment"
	@echo "    make list-backups        - Show tfvars backup files"
	@echo ""
	@echo "  Modules:"
	@echo "    make list                - List available modules"
	@echo "    make plan-<name>         - Plan specific module"
	@echo "    make apply-<name>        - Apply specific module"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make fmt                 - Format all TF files recursively"
	@echo "    make validate            - Validate configuration"
	@echo "    make destroy             - Destroy infrastructure (requires code)"
	@echo "    make clean               - Remove generated files"
	@echo ""

.PHONY: tfvars all init plan apply destroy clean clean-all list help show validate check-env fmt \
        list-backups stage prod \
        $(addprefix plan-,$(MODULES)) \
        $(addprefix apply-,$(MODULES)) \
        $(addprefix module-,$(MODULES))
