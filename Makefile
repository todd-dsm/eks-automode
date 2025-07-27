#!/usr/bin/env make
# vim: tabstop=8 noexpandtab

# Module deployment order (infrastructure first, then addons)
INFRA_MODULES := network eks
ADDON_MODULES := addons-core addons-apps karpenter
ALL_MODULES := $(INFRA_MODULES) $(ADDON_MODULES)

# Default target when just running 'make'
.DEFAULT_GOAL := help

# Plan file variable (using environment variable from build.env)
FILE_PLAN = /tmp/tf-$(project).plan
LOG_PLAN = /tmp/tf-$(project)-plan.out

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

# Plan infrastructure only (networking + eks-core)
plan: infras

# Plan and save infrastructure modules only  
infras: check-env fmt
	@echo "=== Planning infrastructure (network + eks) ==="
	@echo "Plan file: $(FILE_PLAN)"
	@echo "Log file: $(LOG_PLAN)"
	@echo ""
	@echo "🔍 Planning network + eks modules..."
	@terraform plan \
		-target=module.network \
		-target=module.eks \
		-no-color \
		-out=$(FILE_PLAN) \
		2>&1 | tee $(LOG_PLAN)
	@echo ""
	@echo "✓ Infrastructure plan saved to: $(FILE_PLAN)"
	@echo "✓ Log saved to: $(LOG_PLAN)"
	@echo ""
	@echo "📋 Next Steps:"
	@echo "  make apply    - Deploy infrastructure (network + eks only)"
	@echo "  After infrastructure is ready:"
	@echo "  make addons   - Deploy all addons"
	@printf '\a'

# Plan with verbose output showing existing resources
plan-verbose: check-env fmt
	@echo "=== Planning infrastructure with verbose output ==="
	@echo ""
	@echo "🔍 Current resources in networking + eks-core modules:"
	@terraform state list | grep -E "(module\.networking|module\.eks-core)" || echo "No resources found"
	@echo ""
	@echo "🔍 Planning changes (with refresh)..."
	@terraform plan \
		-target=module.networking \
		-target=module.eks-core \
		-refresh=true \
		-no-color
	@printf '\a'

# Plan specific module
%-plan: check-env fmt
	@echo "=== Planning module: $* ==="
	@terraform plan -target=module.$* -out=/tmp/tf-$*.plan
	@echo "✓ Module plan saved to: /tmp/tf-$*.plan"
	@echo "✓ To apply: make $*-apply"

# Apply infrastructure only (network + eks)
apply: check-env
	@echo "=== Applying infrastructure (network + eks) ==="
	@if [ ! -f $(FILE_PLAN) ]; then \
		echo "ERROR: Plan file not found: $(FILE_PLAN)"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	fi
	@terraform apply \
		-target=module.network \
		-target=module.eks \
		-auto-approve \
		$(FILE_PLAN)
	@echo ""
	@echo "🎉 SUCCESS: Infrastructure deployed!"
	@echo "📋 Next Steps:"
	@echo "  make addons            - Deploy all addons"
	@echo "  make addons-core-plan  - Plan essential addons only"
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

# Deploy all addons (requires infrastructure to exist)
addons: check-env fmt
	@echo "=== Deploying all addons (requires running EKS cluster) ==="
	@echo "📋 Checking if infrastructure exists..."
	@if ! terraform show -json | grep -q '"mode":"managed".*"type":"aws_eks_cluster"'; then \
		echo "❌ ERROR: EKS cluster not found!"; \
		echo "Deploy infrastructure first: make all"; \
		exit 1; \
	fi
	@echo "✅ EKS cluster found, proceeding with addons..."
	@echo ""
	@echo "🚀 Deploying addons-core..."
	@terraform plan -target=module.addons-core -out=/tmp/tf-addons-core.plan
	@terraform apply -auto-approve /tmp/tf-addons-core.plan
	@echo ""
	@echo "🚀 Deploying addons-apps..."
	@terraform plan -target=module.addons-apps -out=/tmp/tf-addons-apps.plan
	@terraform apply -auto-approve /tmp/tf-addons-apps.plan
	@echo ""
	@echo "🚀 Deploying karpenter..."
	@terraform plan -target=module.karpenter -out=/tmp/tf-karpenter.plan
	@terraform apply -auto-approve /tmp/tf-karpenter.plan
	@echo ""
	@echo "🎉 SUCCESS: All addons deployed!"
	@printf '\a'

# All-in-one infrastructure command (networking + eks-core only)
all: init infras apply
	@echo ""
	@echo "🎉 Infrastructure deployment complete!"
	@echo "📋 To deploy addons: make addons"
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
	@current_env=$$(grep "^env_build" terraform.tfvars | cut -d'"' -f2); \
	confirm_code=$$(openssl rand -hex 2); \
	echo ""; \
	echo "⚠️  DESTROYING MODULE: $*"; \
	echo "Environment: $$current_env"; \
	echo ""; \
	echo "To confirm destroy, type: $$confirm_code"; \
	printf "Enter code: "; \
	read user_code; \
	if [ "$$user_code" != "$$confirm_code" ]; then \
		echo "❌ Incorrect code. Destroy cancelled."; \
		exit 1; \
	fi
	@echo "🔥 Destroying module: $*"
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
		tee /tmp/tf-$(project)-destroy.out
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
	@echo "✓ Log saved to: /tmp/tf-$(project)-destroy.out"
	@printf '\a'

# Check environment helper
check-env:
	@if [ ! -f terraform.tfvars ]; then \
		echo "ERROR: terraform.tfvars not found!"; \
		echo "Run 'source build.env <stage|prod>' first"; \
		exit 1; \
	fi
	@if [ -z "$(project)" ]; then \
		echo "ERROR: project environment variable not set!"; \
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

# List modules in deployment order
list:
	@echo "=== Module Deployment Order ==="
	@echo ""
	@echo "Stage 1: Infrastructure (network + eks)"
	@echo "  01. network       - VPC, subnets, security groups"
	@echo "  02. eks           - EKS cluster and core components"
	@echo ""
	@echo "Stage 2: Addons (requires running EKS cluster)"
	@echo "  03. addons-core   - Essential cluster addons (LB controller, etc.)"
	@echo "  04. addons-apps   - Application addons (Istio, ArgoCD, etc.)"
	@echo "  05. karpenter     - Auto-scaling components"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  make all          - Deploy Stage 1 (infrastructure)"
	@echo "  make addons       - Deploy Stage 2 (all addons)"

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
	@echo "  Two-Stage Deployment:"
	@echo "    make all                 - Stage 1: Infrastructure (network + eks)"
	@echo "    make addons              - Stage 2: All addons (requires running cluster)"
	@echo ""
	@echo "  Stage 1: Infrastructure Only"
	@echo "    make init                - Initialize Terraform"
	@echo "    make plan                - Plan infrastructure (network + eks)"
	@echo "    make infras              - Plan infrastructure modules sequentially"
	@echo "    make apply               - Apply infrastructure"
	@echo ""
	@echo "  Stage 2: Individual Addon Modules"
	@echo "    make addons-core-plan    - Plan essential addons"
	@echo "    make addons-core-apply   - Apply essential addons"
	@echo "    make addons-apps-plan    - Plan application addons (Istio, ArgoCD)"
	@echo "    make addons-apps-apply   - Apply application addons"
	@echo "    make karpenter-plan      - Plan auto-scaling"
	@echo "    make karpenter-apply     - Apply auto-scaling"
	@echo ""
	@echo "  Environment:"
	@echo "    make show                - Show current environment"
	@echo "    make list                - Show module deployment order"
	@echo "    make list-backups        - Show tfvars backup files"
	@echo ""
	@echo "  Individual Module Operations:"
	@echo "    make <module>-plan       - Plan specific module"
	@echo "    make <module>-apply      - Apply specific module"
	@echo "    make <module>-destroy    - Destroy specific module"
	@echo ""
	@echo "  Cleanup:"
	@echo "    make clean               - Destroy ALL + clean local files"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make fmt                 - Format all TF files"
	@echo "    make validate            - Validate configuration"
	@echo ""
	@echo "  Why Two Stages?"
	@echo "    Kubernetes addons (Istio Gateway, etc.) need a running cluster"
	@echo "    for validation during 'terraform plan'. Infrastructure must"
	@echo "    exist before addons can be planned and applied."
	@echo ""

.PHONY: all init plan infras apply addons clean list help show validate check-env fmt \
        list-backups \
        $(addsuffix -plan,$(ALL_MODULES)) \
        $(addsuffix -apply,$(ALL_MODULES)) \
        $(addsuffix -destroy,$(ALL_MODULES)) \
        $(addprefix module-,$(ALL_MODULES))
