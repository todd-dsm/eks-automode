# Makefile Usage

Simplified AWS EKS infrastructure deployment with Terraform using a two-stage approach.

## Quick Start

```bash
source build.env stage  # Generate environment config
make all                # Stage 1: Deploy infrastructure (networking + eks-core)
make addons             # Stage 2: Deploy all addons (requires running cluster)
```

## Two-Stage Deployment Architecture

The deployment is intentionally split into two stages to handle Terraform validation requirements:

### Stage 1: Infrastructure (No Kubernetes API Required)

```bash
source build.env stage  # Generate environment config
make all                # Deploy networking + eks-core
```

**Modules deployed:** `networking`, `eks-core`

- VPC, subnets, security groups
- EKS cluster and core AWS-managed components
- No Kubernetes API validation required

### Stage 2: Addons (Requires Running EKS Cluster)

```bash
make addons             # Deploy all addons automatically
# OR deploy individually:
make addons-core-plan   # Plan essential addons
make addons-core-apply  # Deploy essential addons
make addons-apps-plan   # Plan application addons
make addons-apps-apply  # Deploy application addons (Istio, ArgoCD)
make karpenter-plan     # Plan auto-scaling
make karpenter-apply    # Deploy auto-scaling
```

**Modules deployed:** `addons-core`, `addons-apps`, `karpenter`

- AWS Load Balancer Controller, Cilium CNI
- Istio service mesh, ArgoCD GitOps
- Karpenter node auto-scaling

**Why Two Stages?** Kubernetes manifests (like Istio Gateway) require a running cluster for validation during `terraform plan`. The infrastructure must exist before addons can be planned.

## Core Workflow

### 1. Generate Environment Configuration

```bash
source build.env stage  # Creates terraform.tfvars for staging
source build.env prod   # Creates terraform.tfvars for production
```

- Automatically backs up existing `terraform.tfvars`
- Generates `provider.tf` and environment-specific variables
- Required before any Terraform operations

### 2. Deploy Infrastructure (Stage 1)

```bash
make all             # Full infrastructure workflow: init → plan → apply
# OR step-by-step:
make init            # Initialize Terraform backend
make plan            # Plan infrastructure changes (networking + eks-core only)
make apply           # Apply saved plan
```

**What gets deployed:**

- Networking: VPC, subnets, NAT gateway, flow logs
- EKS Core: Cluster, node groups, IRSA, certificates

### 3. Deploy Addons (Stage 2)

```bash
make addons                  # Deploy all addons automatically
# OR individual control:
make list                    # Show available modules in deployment order
make addons-core-plan        # Plan essential cluster addons
make addons-core-apply       # Apply essential addons
make addons-apps-plan        # Plan application addons
make addons-apps-apply       # Apply application addons
make karpenter-plan          # Plan auto-scaling
make karpenter-apply         # Apply auto-scaling components
```

### 4. Module-Specific Operations

```bash
make networking-plan         # Plan just networking module
make networking-apply        # Apply networking module
make eks-core-destroy        # Destroy specific module (with confirmation)
```

**Available modules:** `networking`, `eks-core`, `addons-core`, `addons-apps`, `karpenter`

## Stage-Specific Commands

### Infrastructure Stage Commands

```bash
make plan        # Plans networking + eks-core only
make apply       # Applies networking + eks-core only
make all         # Complete infrastructure workflow (init → plan → apply)
```

### Addon Stage Commands

```bash
make addons      # Deploys all addon modules (addons-core + addons-apps + karpenter)
```

### Individual Module Commands

```bash
make <module>-plan     # Plan specific module
make <module>-apply    # Apply specific module
make <module>-destroy  # Destroy specific module (with confirmation)
```

## Utilities

```bash
make list            # Show modules in deployment order with descriptions
make show            # Show current environment config
make fmt             # Format all Terraform files
make validate        # Validate configuration
make list-backups    # Show terraform.tfvars backup files
```

## Cleanup

```bash
make clean           # ⚠️  NUCLEAR: Destroy ALL infrastructure + remove local files
```

**Warning:** `make clean` destroys everything and requires confirmation code.

## Shell Efficiency

Pattern designed for easy shell history editing:

```bash
make networking-plan    # Type this
# CTRL+w deletes "plan"
make networking-apply   # Add "apply"
```

## Audio Alerts

The Makefile includes ASCII BEL alerts (`\a`) that trigger system notifications when these operations complete:

- `make apply` - Infrastructure deployment (networking + eks-core)
- `make addons` - All addons deployment
- `make *-apply` - Module-specific deployments  
- `make *-destroy` - Module destruction
- `make clean` - Complete cleanup
- `make all` - Infrastructure workflow completion

## Files Generated

- `terraform.tfvars` - Environment-specific variables (via `build.env`)
- `provider.tf` - Terraform backend configuration (via `build.env`)
- `.terraform/` - Terraform state and providers
- `.terraform.lock.hcl` - Provider version lock
- `/tmp/tf-*.plan` - Terraform plan files

## Backend Storage

State files stored in S3: `s3://{bucket}/{environment}/base-infras-state`

- Stage: `s3://vcircuits-gitops-demo/stage/base-infras-state`
- Prod: `s3://vcircuits-gitops-demo/prod/base-infras-state`

## Module Execution Order

### Stage 1: Infrastructure (No K8s API Required)

1. **networking** - VPC, subnets, security groups, flow logs
2. **eks-core** - EKS cluster, node groups, IRSA, certificates

### Stage 2: Addons (Requires Running EKS Cluster)

3. **addons-core** - Essential cluster addons (LB controller, Cilium CNI)
4. **addons-apps** - Application addons (Istio service mesh, ArgoCD GitOps)
5. **karpenter** - Auto-scaling components

## Deployment Examples

### New Environment Deployment

```bash
# Generate config and deploy infrastructure
source build.env stage
make all

# Wait for cluster to be ready (~10-15 minutes)
# Then deploy addons
make addons
```

### Update Existing Environment

```bash
# Update infrastructure only
source build.env stage
make plan
make apply

# Update specific addon
make addons-apps-plan
make addons-apps-apply
```

### Troubleshooting Failed Addon Deployment

```bash
# Infrastructure is working, addon failed
make addons-core-plan    # Check what's wrong
make addons-core-apply   # Retry specific addon
```

## Error Handling

The Makefile includes several safety checks:

1. **Environment Check:** Ensures `terraform.tfvars` exists before operations
2. **Plan File Check:** Ensures plan exists before apply
3. **Cluster Check:** Verifies EKS cluster exists before deploying addons
4. **Confirmation Codes:** Required for destructive operations

## Performance Notes

- **Infrastructure deployment:** ~10-15 minutes
- **Addon deployment:** ~5-10 minutes
- **Total deployment time:** ~15-25 minutes
- **Parallel module execution:** Not supported (dependency order required)
