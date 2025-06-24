########################################################################################################################
# Gateway API Setup - Simple kubectl apply approach
########################################################################################################################
resource "null_resource" "gateway_api_setup" {
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
      
      echo "✅ Gateway API setup complete"
    EOT
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🧹 Removing Gateway API resources..."
      kubectl delete -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml --ignore-not-found=true
      kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml --ignore-not-found=true
      echo "✅ Gateway API cleanup complete"
    EOT
  }

  # Trigger recreation if versions change
  triggers = {
    gateway_api_version = "v1.2.1"
    traefik_version     = "v3.4"
  }
}