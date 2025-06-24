########################################################################################################################
# Traefik Gateway API Resources
# DOCS: https://doc.traefik.io/traefik/providers/kubernetes-gateway/
########################################################################################################################

# Create GatewayClass for Traefik
resource "kubernetes_manifest" "traefik_gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "traefik"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/component"  = "gateway-class"
      }
    }
    spec = {
      controllerName = "traefik.io/gateway-controller"
      description    = "Traefik Gateway Class for EKS Auto Mode"
    }
  }

  depends_on = [
    null_resource.gateway_api_setup,
    helm_release.traefik
  ]
}

########################################################################################################################
# Main Gateway Resource
########################################################################################################################
resource "kubernetes_manifest" "traefik_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "traefik-gateway"
      namespace = kubernetes_namespace.traefik.metadata[0].name
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/component"  = "gateway"
      }
    }
    spec = {
      gatewayClassName = kubernetes_manifest.traefik_gateway_class.manifest.metadata.name
      listeners = [
        {
          name     = "http"
          port     = 80
          protocol = "HTTP"
          hostname = "*.${var.dns_zone}"
        },
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = "*.${var.dns_zone}"
          tls = {
            mode = "Terminate"
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.traefik_gateway_class
  ]
}

########################################################################################################################
# HTTPRoute for Traefik Dashboard (if enabled)
########################################################################################################################
resource "kubernetes_manifest" "traefik_dashboard_route" {
  count = var.enable_traefik_dashboard ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "traefik-dashboard"
      namespace = kubernetes_namespace.traefik.metadata[0].name
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/component"  = "dashboard-route"
      }
    }
    spec = {
      parentRefs = [
        {
          name = kubernetes_manifest.traefik_gateway.manifest.metadata.name
        }
      ]
      hostnames = [
        aws_acm_certificate.traefik.domain_name,
        "dashboard.${var.env_build}.${var.dns_zone}"
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "traefik"
              port = 9000
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.traefik_gateway,
    aws_acm_certificate_validation.traefik
  ]
}
