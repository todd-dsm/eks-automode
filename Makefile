#!/usr/bin/env make
# vim: tabstop=8 noexpandtab

# Module order
MODULES := networking eks-core addons-core addons-apps karpenter

# Default target when just running 'make'
.DEFAULT_GOAL := help

# Plan file variable (extracted from terraform.tfvars)
FILE_PLAN = /tmp/tf-$$(grep my_project terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "project").plan
LOG_PLAN = /tmp/tf-$$(grep my_project terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "project")-plan.out

# Initialize Terraform
init:
	@echo "=== Initializing Terraform ==="
	@if [ ! -f terraform.tfvars ]; then \
		echo "ERROR: terraform.tfvars not found!"; \
		echo "Run 'source build.env <stage|prod>' first"; \
		exit 1; \
	fi
	@terraform init -upgrade
	@echo "✓ Terraform initialized"

# Format Terraform files
fmt:
	@echo "=== Formatting Terraform files ==="
	@terraform fmt -recursive
	@echo "✓ Terraform files formatted"

# Plan entire infrastructure (networking + eks-core only)
plan: check-env fmt
	@echo "=== Planning infrastructure (networking + eks-core) ==="
	@echo "Plan file: $(FILE_PLAN)"
	@echo "Log file: $(LOG_PLAN)"
	@terraform plan -target=module.networking -target=module.eks-core -no-color -out=$(FILE_PLAN) 2>&1 | tee $(LOG_PLAN)
	@echo ""
	@echo "✓ Plan saved to: $(FILE_PLAN)"
	@echo "✓ Log saved to: $(LOG_PLAN)"

# Plan specific module
%-plan: check-env fmt
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
	@printf '\a'

# Apply specific module
%-apply: check-env
	@echo "=== Applying module: $* ==="
	@if [ ! -f /tmp/tf-$*.plan ]; then \
		echo "ERROR: Module plan file not found: /tmp/tf-$*.plan"; \
		echo "Run 'make $*-plan' first"; \
		exit 1; \
	fi
	@terraform apply -auto-approve /tmp/tf-$*.plan
	@echo "✓ Module $* applied"
	@printf '\a'

# All-in-one command (infrastructure only)
all: init plan apply
	@printf '\a'

# Plan individual module (standalone command)
module-%: check-env init fmt
	@echo "=== Planning module: $* ==="
	@terraform plan -target=module.$* -out=/tmp/tf-$*.plan
	@echo ""
	@echo "Review the plan above. To apply, run:"
	@echo "  make $*-apply"

# Destroy specific module
%-destroy: check-env
	@echo "=== Destroying module: $* ==="
	@terraform destroy -target=module.$* -auto-approve
	@echo "✓ Module $* destroyed"
	@printf '\a'

# Complete cleanup - destroy infrastructure AND remove local files
clean: check-env
	@current_env=$$(grep "^env_build" terraform.tfvars | cut -d'"' -f2); \
	current_region=$$(grep "^region" terraform.tfvars | cut -d'"' -f2); \
	confirm_code=$$(openssl rand -hex 3); \
	echo ""; \
	echo "╔═══════════════════════════════════════════════════════╗"; \
	echo "║      ⚠️  COMPLETE CLEANUP (DESTROY + CLEAN) ⚠️         ║"; \
	echo "╚═══════════════════════════════════════════════════════╝"; \
	echo ""; \
	echo "This will:"; \
	echo "  1. Destroy ALL infrastructure in $$current_env"; \
	echo "  2. Remove .terraform/ and .terraform.lock.hcl"; \
	echo "  3. Remove all generated files"; \
	echo ""; \
	echo "Target Environment: $$current_env"; \
	echo "Region: $$current_region"; \
	echo ""; \
	echo "═══════════════════════════════════════════════════════"; \
	echo ""; \
	echo "To confirm complete cleanup, type this code: $$confirm_code"; \
	echo ""; \
	printf "Enter confirmation code: "; \
	read user_code; \
	if [ "$$user_code" != "$$confirm_code" ]; then \
		echo ""; \
		echo "❌ Incorrect code. Cleanup cancelled."; \
		echo "✅ Infrastructure and files remain intact."; \
		exit 1; \
	fi; \
	echo ""; \
	echo "⚠️  Code confirmed. Starting complete cleanup..."; \
	echo ""
	@echo "=== PHASE 1: Destroying infrastructure ==="
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
	@echo "💀 All infrastructure destroyed"
	@echo ""
	@echo "=== PHASE 2: Cleaning local files ==="
	@echo "🧹 Removing Terraform state and generated files..."
	@rm -f terraform.tfvars
	@rm -f /tmp/tf-*.plan
	@rm -f /tmp/tf-*-plan.out
	@rm -f /tmp/terraform.tfvars.bak.*
	@rm -f provider.tf
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfstate*
	@echo "✓ All local files cleaned"
	@echo ""
	@echo "🎉 COMPLETE CLEANUP FINISHED"
	@echo "✓ Infrastructure destroyed and local files cleaned"
	@echo "✓ Log saved to: /tmp/tf-$(shell grep my_project terraform.tfvars | cut -d'"' -f2)-destroy.out"
	@printf '\a'

# Check environment helper
check-env:
	@if [ ! -f terraform.tfvars ]; then \
		echo "ERROR: terraform.tfvars not found!"; \
		echo "Run 'source build.env <stage|prod>' first"; \
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
		echo "Run: source build.env <stage|prod>"; \
	fi

# List modules
list:
	@echo "=== Available modules in order ==="
	@echo "  01. networking"
	@echo "  02. eks-core"
	@echo "  03. addons-core"
	@echo "  04. addons-apps"
	@echo "  05. karpenter"

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
	@echo "  Prerequisites:"
	@echo "    source build.env <stage|prod> - Generate terraform.tfvars"
	@echo ""
	@echo "  Quick Start (Infrastructure Only):"
	@echo "    make all                 - Build networking + eks-core"
	@echo ""
	@echo "  Two-Stage Deployment:"
	@echo "    make all                 - Stage 1: networking + eks-core"
	@echo "    make addons-core-plan    - Stage 2a: plan addons-core" 
	@echo "    make addons-core-apply   - Stage 2b: apply addons-core"
	@echo "    make addons-apps-apply   - Stage 2c: apply addons-apps"
	@echo "    make karpenter-apply     - Stage 2d: apply karpenter"
	@echo ""
	@echo "  Step by Step:"
	@echo "    make init                - Initialize Terraform"
	@echo "    make plan                - Plan networking + eks-core"
	@echo "    make apply               - Apply infrastructure"
	@echo ""
	@echo "  Environment:"
	@echo "    make show                - Show current environment"
	@echo "    make list-backups        - Show tfvars backup files"
	@echo ""
	@echo "  Individual Modules:"
	@echo "    make list                - List available modules in deployment order"
	@echo "    make <module>-plan       - Plan specific module"
	@echo "    make <module>-apply      - Apply specific module"
	@echo "    make <module>-destroy    - Destroy specific module"
	@echo ""
	@echo "  Cleanup:"
	@echo "    make clean               - Destroy ALL infrastructure + clean local files"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make fmt                 - Format all TF files recursively"
	@echo "    make validate            - Validate configuration"
	@echo ""

.PHONY: all init plan apply clean list help show validate check-env fmt \
        list-backups \
        $(addsuffix -plan,$(MODULES)) \
        $(addsuffix -apply,$(MODULES)) \
        $(addsuffix -destroy,$(MODULES)) \
        $(addprefix module-,$(MODULES))
