########################################################################################################################
# Traefik & Gateway API CRDs Installation
#  * Intended to be the final step in EKS module
#  * Ensures CRDs are available before 'addons' module runs
########################################################################################################################
resource "null_resource" "gateway_api_crds" {
  # Install Gateway API CRDs and Traefik RBAC
  provisioner "local-exec" {
    command = <<-EOT
      echo "📦 Installing Kubernetes Gateway API CRDs..."
      kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
      
      echo "🔐 Installing Traefik RBAC for Gateway API..."
      kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml
      
      echo "⏳ Waiting for CRDs to be ready..."
      kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=120s
      kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io --timeout=120s
      kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=120s
      
      echo "✅ Gateway API CRDs ready for addons module"
    EOT
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🧹 Removing Gateway API CRDs..."
      kubectl delete -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml --ignore-not-found=true
      kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml --ignore-not-found=true
      echo "✅ Gateway API CRDs cleanup complete"
    EOT
  }

  # Run after cluster is ready
  depends_on = [
    aws_eks_cluster.eks_auto,
    null_resource.kubeconfig_manager
  ]

  # Trigger recreation if versions change
  triggers = {
    cluster_endpoint    = aws_eks_cluster.eks_auto.endpoint
    gateway_api_version = "v1.2.1"
    traefik_version     = "v3.4"
  }
}
