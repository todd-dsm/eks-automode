#!/usr/bin/env make
# vim: tabstop=8 noexpandtab

# Dynamically discover modules from mods directory
MODULES := $(shell find mods -mindepth 1 -maxdepth 1 -type d | sed 's|mods/||' | sort)

# Module execution order for all-mods and destroy-mods
MODULE_ORDER := network eks prep addons

# Default target when just running 'make'
.DEFAULT_GOAL := help

# Plan file variables
PROJECT_NAME = $(shell grep project terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "project")
FILE_PLAN = /tmp/tf-$(PROJECT_NAME).plan
LOG_PLAN = /tmp/tf-$(PROJECT_NAME)-plan.out

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
	@echo "  make init      - Initialize Terraform"
	@echo "  make plan      - Plan all modules in order"
	@echo "  make apply     - Apply all modules in order"
	@echo "  make all-mods  - Full build (init + plan + apply all modules)"

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

# Plan all modules in order
plan: check-env init fmt all-mods-plan

# Apply all modules in order
apply: check-env init all-mods-apply

# Plan all modules sequentially
all-mods-plan: check-env fmt
	@echo "=== Planning all modules in order ==="
	@for module in $(MODULE_ORDER); do \
		if [ -d "mods/$$module" ]; then \
			echo ""; \
			echo "📋 Planning module: $$module"; \
			echo "────────────────────────────────"; \
			terraform plan -target=module.$$module -out=/tmp/tf-$$module.plan || exit 1; \
			echo "✓ Module $$module planned successfully"; \
		else \
			echo "⚠️  Module directory mods/$$module not found, skipping"; \
		fi; \
	done
	@echo ""
	@echo "✅ All modules planned successfully"

# Apply all modules sequentially
all-mods-apply: check-env
	@echo "=== Applying all modules in order ==="
	@for module in $(MODULE_ORDER); do \
		if [ -d "mods/$$module" ]; then \
			if [ -f "/tmp/tf-$$module.plan" ]; then \
				echo ""; \
				echo "🚀 Applying module: $$module"; \
				echo "────────────────────────────────"; \
				terraform apply -auto-approve /tmp/tf-$$module.plan || exit 1; \
				echo "✅ Module $$module applied successfully"; \
			else \
				echo "❌ Plan file not found for module $$module"; \
				echo "Run 'make plan-$$module' or 'make all-mods-plan' first"; \
				exit 1; \
			fi; \
		else \
			echo "⚠️  Module directory mods/$$module not found, skipping"; \
		fi; \
	done
	@echo ""
	@echo "🎉 All modules applied successfully!"
	@printf '\a'

# Full build process
all-mods: check-env init all-mods-plan all-mods-apply

# Plan specific module
plan-%: check-env fmt
	@if [ -d "mods/$*" ]; then \
		echo "=== Planning module: $* ==="; \
		terraform plan -target=module.$* -out=/tmp/tf-$*.plan; \
		echo "✓ Module plan saved to: /tmp/tf-$*.plan"; \
	else \
		echo "❌ Module directory mods/$* not found"; \
		echo "Available modules: "; \
		find mods -mindepth 1 -maxdepth 1 -type d | sed 's|mods/||' | sort | sed 's/^/  /'; \
		exit 1; \
	fi

# Apply specific module
apply-%: check-env
	@if [ -d "mods/$*" ]; then \
		if [ -f "/tmp/tf-$*.plan" ]; then \
			echo "=== Applying module: $* ==="; \
			terraform apply -auto-approve /tmp/tf-$*.plan; \
			echo "✅ Module $* applied successfully"; \
		else \
			echo "❌ Plan file not found: /tmp/tf-$*.plan"; \
			echo "Run 'make plan-$*' first"; \
			exit 1; \
		fi; \
	else \
		echo "❌ Module directory mods/$* not found"; \
		echo "Available modules: "; \
		find mods -mindepth 1 -maxdepth 1 -type d | sed 's|mods/||' | sort | sed 's/^/  /'; \
		exit 1; \
	fi

# Destroy specific module
destroy-%: check-env
	@if [ -d "mods/$*" ]; then \
		echo "=== Destroying module: $* ==="; \
		terraform destroy -auto-approve -target=module.$*; \
		echo "✅ Module $* destroyed"; \
	else \
		echo "❌ Module directory mods/$* not found"; \
		echo "Available modules: "; \
		find mods -mindepth 1 -maxdepth 1 -type d | sed 's|mods/||' | sort | sed 's/^/  /'; \
		exit 1; \
	fi

# Destroy all modules in reverse order
destroy-mods: check-env
	@echo "=== Destroying all modules in reverse order ==="
	@reversed_modules=$$(echo "$(MODULE_ORDER)" | tr ' ' '\n' | tac | tr '\n' ' '); \
	for module in $$reversed_modules; do \
		if [ -d "mods/$$module" ]; then \
			echo ""; \
			echo "🔥 Destroying module: $$module"; \
			echo "────────────────────────────────"; \
			terraform destroy -auto-approve -target=module.$$module || exit 1; \
			echo "✅ Module $$module destroyed"; \
		else \
			echo "⚠️  Module directory mods/$$module not found, skipping"; \
		fi; \
	done
	@echo ""
	@echo "💀 All modules destroyed"

# Destroy everything with confirmation (original behavior)
destroy-all: check-env
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
		tee /tmp/tf-$(PROJECT_NAME)-destroy.out
	@if [ -f scripts/janitor-post.sh ]; then \
		echo "Running post-destroy cleanup..."; \
		scripts/janitor-post.sh; \
	fi
	@rm -rf .terraform/ .terraform.lock.hcl
	@echo ""
	@echo "💀 All infrastructure has been destroyed"
	@echo "✓ Log saved to: /tmp/tf-$(PROJECT_NAME)-destroy.out"
	@printf '\a'

# Keep original destroy target as alias to destroy-all
destroy: destroy-all

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

# List available modules (dynamically discovered)
list:
	@echo "=== Available modules ==="
	@if [ -n "$(MODULES)" ]; then \
		for module in $(MODULES); do \
			echo "  • $$module"; \
		done; \
	else \
		echo "  No modules found in mods/ directory"; \
	fi
	@echo ""
	@echo "=== Module execution order ==="
	@for module in $(MODULE_ORDER); do \
		echo "  $(shell printf '%d' $$(echo "$(MODULE_ORDER)" | tr ' ' '\n' | grep -n "$$module" | cut -d: -f1)). $$module"; \
	done

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

# Help - Default target
help:
	@echo ""
	@echo "  AWS EKS Infrastructure Build System (Staged)"
	@echo "  ============================================="
	@echo ""
	@echo "  Quick Start:"
	@echo "    make tfvars <stage|prod> - Generate terraform.tfvars"
	@echo "      EX: make tfvars stage  - for staging terraform.tfvars"
	@echo "    make all-mods            - Full staged build (recommended)"
	@echo ""
	@echo "  Staged Operations:"
	@echo "    make plan                - Plan all modules in order"
	@echo "    make apply               - Apply all modules in order"
	@echo "    make all-mods            - Init + plan + apply all modules"
	@echo "    make destroy-mods        - Destroy all modules (reverse order)"
	@echo ""
	@echo "  Individual Modules:"
	@echo "    make plan-<module>       - Plan specific module"
	@echo "    make apply-<module>      - Apply specific module"
	@echo "    make destroy-<module>    - Destroy specific module"
	@echo ""
	@echo "  Environment:"
	@echo "    make init                - Initialize Terraform"
	@echo "    make show                - Show current environment"
	@echo "    make list                - List available modules & order"
	@echo "    make list-backups        - Show tfvars backup files"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make fmt                 - Format all TF files recursively"
	@echo "    make validate            - Validate configuration"
	@echo "    make destroy-all         - Destroy everything (requires confirmation)"
	@echo "    make clean               - Remove generated files"
	@echo ""
	@echo "  Module execution order: $(MODULE_ORDER)"
	@echo ""

# Dynamic PHONY declarations - simplified approach
.PHONY: tfvars init plan apply all-mods all-mods-plan all-mods-apply destroy destroy-all destroy-mods \
        clean clean-all list list-backups help show validate check-env fmt stage prod
