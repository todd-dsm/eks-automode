#!/usr/bin/env bash
###############################################################################
# PURPOSE:  Creates kubeconfig file for EKS cluster
#           Called during Terraform build or manually after cluster creation
#    EXEC:  scripts/create-kubeconfig.sh
# EXAMPLE:  scripts/create-kubeconfig.sh gitops-demo-stage us-east-1
###############################################################################
set -e

# Functions
source scripts/lib/printer.func

# Get parameters from environment or arguments
CLUSTER_NAME="${1:-${project}}"
REGION="${2:-${region}}"

# Validate required parameters
if [[ -z "$CLUSTER_NAME" ]]; then
    print_error "ERROR: Cluster name not provided. Set \$project or pass as first argument."
fi

if [[ -z "$REGION" ]]; then
    print_error "ERROR: Region not provided. Set \$region or pass as second argument."
fi

# Set kubeconfig path
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_PATH="$KUBECONFIG_DIR/${CLUSTER_NAME}.ktx"

print_goal "Creating kubeconfig for EKS cluster: $CLUSTER_NAME"

print_req "📁 Ensuring .kube directory exists..."
if [[ ! -d "$KUBECONFIG_DIR" ]]; then
    mkdir -p "$KUBECONFIG_DIR"
fi

print_req "🌍 Region: $REGION"
print_req "📝 Target path: $KUBECONFIG_PATH"

# Check if kubeconfig already exists and is valid
if [[ -f "$KUBECONFIG_PATH" ]]; then
    print_req "⚠️  Kubeconfig already exists, checking if valid..."

    # Test if existing kubeconfig works
    if KUBECONFIG="$KUBECONFIG_PATH" kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then
        print_req "✅ Existing kubeconfig is valid and working"
        print_req "🔧 To use: export KUBECONFIG=$KUBECONFIG_PATH"
        print_req "🔧 Or use context: kubectl config use-context $CLUSTER_NAME"
        exit 0
    else
        print_req "⚠️  Existing kubeconfig is invalid, recreating..."
    fi
fi

print_req "🔧 Generating kubeconfig using AWS CLI..."

# Generate kubeconfig using AWS CLI
if aws eks update-kubeconfig \
    --region "$REGION" \
    --name "$CLUSTER_NAME" \
    --kubeconfig "$KUBECONFIG_PATH" \
    --alias "$CLUSTER_NAME"; then

    print_req "✅ Kubeconfig generated successfully"
else
    print_error "❌ Failed to generate kubeconfig"
fi

# Set proper permissions
chmod 600 "$KUBECONFIG_PATH"
print_req "🔒 Set secure permissions (600) on kubeconfig file"

# Verify the kubeconfig works
print_req "🧪 Testing kubeconfig connectivity..."
if KUBECONFIG="$KUBECONFIG_PATH" kubectl cluster-info --request-timeout=30s >/dev/null 2>&1; then
    print_pass "✅ Kubeconfig is working correctly"
else
    print_error "❌ Kubeconfig test failed - cluster may not be ready yet"
fi

print_req "🎉 Kubeconfig setup complete!"
print_req ""
print_req "To use this kubeconfig:"
print_req "  export KUBECONFIG=$KUBECONFIG_PATH"
print_req "  kubectl cluster-info"
print_req ""
print_req "Or use the context:"
print_req "  kubectl config use-context $CLUSTER_NAME"
print_req "  kubectl cluster-info"
