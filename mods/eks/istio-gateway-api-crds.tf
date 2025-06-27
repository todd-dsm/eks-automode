########################################################################################################################
# Phase 1: Ingress
# STEP-1a:Install Gateway API CRDs (Required for Istio Gateway API support)
########################################################################################################################
resource "null_resource" "gateway_api_crds" {
  # Install Gateway API v1.3.0 CRDs
  provisioner "local-exec" {
    command = <<-EOT
      echo "📦 Installing Gateway API CRDs for Istio..."
      kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
      echo "⏳ Waiting for Gateway API CRDs to be ready..."
      kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s
      kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io --timeout=60s
      kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=60s
      echo "✅ Gateway API CRDs are ready"
    EOT
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🧹 Removing Gateway API CRDs..."
      kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml --ignore-not-found=true
      echo "✅ Gateway API CRDs removed"
    EOT
  }

  triggers = {
    gateway_api_version = "v1.3.0"
    cluster_endpoint    = aws_eks_cluster.eks_auto.endpoint
  }
}
