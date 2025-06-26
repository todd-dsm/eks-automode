########################################################################################################################
# Traefik Gateway API Resources
########################################################################################################################
# Gateway Class for Traefik
resource "kubernetes_manifest" "traefik_gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "traefik"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/name"       = "traefik"
      }
    }
    spec = {
      controllerName = "traefik.io/gateway-controller"
      description    = "Traefik Gateway Class for EKS Auto Mode"
    }
  }

  depends_on = [helm_release.traefik]
}

########################################################################################################################
# Default Gateway for Traefik
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
        "app.kubernetes.io/name"       = "traefik"
      }
    }
    spec = {
      gatewayClassName = "traefik"
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
            certificateRefs = [
              {
                name = "traefik-tls-cert"
                kind = "Secret"
              }
            ]
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.traefik_gateway_class,
    kubernetes_secret.traefik_tls_cert
  ]
}

########################################################################################################################
# Traefik Dashboard HTTPRoute
########################################################################################################################
resource "kubernetes_manifest" "traefik_dashboard_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "traefik-dashboard"
      namespace = kubernetes_namespace.traefik.metadata[0].name
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/name"       = "traefik"
      }
    }
    spec = {
      parentRefs = [
        {
          name      = "traefik-gateway"
          namespace = kubernetes_namespace.traefik.metadata[0].name
        }
      ]
      hostnames = [
        "traefik.${var.dns_zone}"
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
    helm_release.traefik
  ]
}
