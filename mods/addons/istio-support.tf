########################################################################################################################
# Required Namespaces
########################################################################################################################
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      name                           = "istio-system"
      "istio-injection"              = "disabled"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "istio"
    }
  }
}

resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
    labels = {
      name                           = "istio-ingress"
      "istio-injection"              = "disabled"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "istio"
    }
  }
}

# ########################################################################################################################
# # Example Gateway for External Traffic (can be customized per application)
# ########################################################################################################################
# resource "kubernetes_manifest" "istio_gateway" {
#   count = var.create_example_gateway ? 1 : 0

#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind       = "Gateway"
#     metadata = {
#       name      = "istio-gateway"
#       namespace = kubernetes_namespace.istio_ingress.metadata[0].name
#       labels = {
#         "app.kubernetes.io/managed-by" = "terraform"
#       }
#     }
#     spec = {
#       gatewayClassName = "istio"
#       listeners = [
#         {
#           name     = "http"
#           port     = 80
#           protocol = "HTTP"
#           hostname = "*.${var.dns_zone}"
#         },
#         {
#           name     = "https"
#           port     = 443
#           protocol = "HTTPS"
#           hostname = "*.${var.dns_zone}"
#           tls = {
#             mode = "Terminate"
#             certificateRefs = [
#               {
#                 name      = "istio-tls-secret"
#                 namespace = kubernetes_namespace.istio_ingress.metadata[0].name
#               }
#             ]
#           }
#         }
#       ]
#     }
#   }

#   depends_on = [
#     helm_release.istio_ingress_gateway,
#     null_resource.gateway_api_crds
#   ]
# }
