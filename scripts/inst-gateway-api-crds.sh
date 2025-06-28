#!/usr/bin/env bash
###############################################################################
# PURPOSE:  installs gateway api CRDs; calledi during the Terraform build, in
#           file istio-gateway-api-crds.tf
#    EXEC:  command = "scripts/install-gateway-api-crds.sh"
###############################################################################
set -e

# functions
source scripts/lib/printer.func

# Use the kubeconfig created by Terraform
#export KUBECONFIG="$HOME/.kube/${project}.ktx"

print_req "🔧 Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

print_req "⏳ Waiting for CRDs to be ready..."
kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io --timeout=60s
kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=60s

print_pass "✅ Gateway API CRDs ready!"
