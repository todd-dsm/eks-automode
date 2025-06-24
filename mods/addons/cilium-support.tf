# ########################################################################################################################
# # Create Gateway Class for Cilium
# ########################################################################################################################
# # resource "kubernetes_manifest" "cilium_gateway_class" {
# #   manifest = {
# #     apiVersion = "gateway.networking.k8s.io/v1"
# #     kind       = "GatewayClass"
# #     metadata = {
# #       name = "cilium"
# #       labels = {
# #         "app.kubernetes.io/managed-by" = "terraform"
# #       }
# #     }
# #     spec = {
# #       controllerName = "io.cilium/gateway-controller"
# #       description    = "Cilium Gateway Class for EKS Auto Mode"
# #     }
# #   }

# #   depends_on = [
# #     helm_release.cilium
# #   ]
# # }

# ########################################################################################################################
# # Validate Cilium Installation
# ########################################################################################################################
# data "kubernetes_service" "cilium_agent" {
#   depends_on = [helm_release.cilium]

#   metadata {
#     name      = "cilium-agent"
#     namespace = "kube-system"
#   }
# }

# data "kubernetes_service" "hubble_relay" {
#   depends_on = [helm_release.cilium]

#   metadata {
#     name      = "hubble-relay"
#     namespace = "kube-system"
#   }
# }

# data "kubernetes_service" "hubble_ui" {
#   depends_on = [helm_release.cilium]

#   metadata {
#     name      = "hubble-ui"
#     namespace = "kube-system"
#   }
# }

# ########################################################################################################################
# # Install Gateway API CRDs (Official Method)
# # Source: https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api
# ########################################################################################################################
# resource "null_resource" "gateway_api_crds" {
#   # Install Gateway API v1.3.0 Standard CRDs
#   provisioner "local-exec" {
#     command = "kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml"
#   }

#   # Verify CRDs are ready before proceeding
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "⏳ Waiting for Gateway API CRDs to be ready..."
#       kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s
#       kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io --timeout=60s
#       kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=60s
#       echo "✅ Gateway API CRDs are ready"
#     EOT
#   }

#   # Clean up on destroy
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOT
#       echo "🧹 Removing Gateway API CRDs..."
#       kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml --ignore-not-found=true
#       echo "✅ Gateway API CRDs removed"
#     EOT
#   }

#   # Trigger recreation if version changes
#   triggers = {
#     gateway_api_version = "v1.3.0"
#   }

#   depends_on = [
#     helm_release.aws_load_balancer_controller
#   ]
# }

# ########################################################################################################################
# # Optional: Verify Installation
# ########################################################################################################################
# # Check that Gateway API CRDs are installed
# data "kubernetes_resources" "gateway_api_crds" {
#   api_version    = "apiextensions.k8s.io/v1"
#   kind           = "CustomResourceDefinition"
#   field_selector = "metadata.name=gatewayclasses.gateway.networking.k8s.io"

#   depends_on = [null_resource.gateway_api_crds]
# }

# ########################################################################################################################
# # Outputs
# ########################################################################################################################
# output "gateway_api_status" {
#   description = "Gateway API installation status"
#   value       = <<-EOT

#     🚪 Gateway API v1.3.0 Installation Complete!
#     ============================================

#     ✅ Installed CRDs:
#     - GatewayClass
#     - Gateway  
#     - HTTPRoute
#     - ReferenceGrant

#     🔍 Verify Installation:
#     kubectl get crd | grep gateway
#     kubectl api-resources | grep gateway

#     📚 Next Steps:
#     1. Install Gateway controller (e.g., Cilium, Istio, etc.)
#     2. Create GatewayClass
#     3. Deploy Gateway and HTTPRoute resources

#   EOT

#   depends_on = [null_resource.gateway_api_crds]
# }
