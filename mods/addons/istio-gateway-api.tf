########################################################################################################################
# Modern Istio Gateway using Kubernetes Gateway API
# Infrastructure (Deployment/Service) is automatically provisioned by Istio
########################################################################################################################
# https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/
# https://gateway-api.sigs.k8s.io/guides/
# https://istio.io/latest/docs/setup/additional-setup/gateway/#gateway-deployment-topologies
########################################################################################################################
# Gateway Class for Istio (defines the controller)
resource "kubernetes_manifest" "istio_gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "istio-gateway-class"
      labels = {
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
    }
    spec = {
      controllerName = "istio.io/gateway-controller"
      description    = "Istio Gateway Class for ${var.project}"
    }
  }
}

# Environment-Specific Gateway
resource "kubernetes_manifest" "environment_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "${var.project}-gateway"
      namespace = "istio-system"
      labels = {
        app         = "istio-gateway"
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
      annotations = {
        # ACM certificate at NLB level
        "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"         = aws_acm_certificate.environment_cert.arn
        "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"        = "https"
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"

        # Standard NLB configuration
        "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
        "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      }
    }
    spec = {
      gatewayClassName = kubernetes_manifest.istio_gateway_class.manifest.metadata.name
      listeners = [
        {
          name     = "http"
          hostname = "${var.env_build}.${var.dns_zone}"
          port     = 80
          protocol = "HTTP"
          allowedRoutes = {
            namespaces = { from = "All" }
          }
        },
        {
          name     = "https"
          hostname = "${var.env_build}.${var.dns_zone}"
          port     = 443
          protocol = "HTTP" # Changed from HTTPS - NLB terminates TLS
          allowedRoutes = {
            namespaces = { from = "All" }
          }
          # Remove entire tls block - NLB handles it now
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.istio_gateway_class]
}

########################################################################################################################
# HTTPRoute for HTTPS Redirect (replaces VirtualService)
########################################################################################################################
resource "kubernetes_manifest" "https_redirect" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "${var.project}-https-redirect"
      namespace = "istio-system"
      labels = {
        app         = "istio-gateway"
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
    }
    spec = {
      parentRefs = [
        {
          name        = kubernetes_manifest.environment_gateway.manifest.metadata.name
          namespace   = kubernetes_manifest.environment_gateway.manifest.metadata.namespace
          sectionName = "http"
        }
      ]
      rules = [
        {
          filters = [
            {
              type = "RequestRedirect"
              requestRedirect = {
                scheme     = "https"
                statusCode = 301
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.environment_gateway
  ]
}

########################################################################################################################
# Default HTTPRoute for Health Checks and 404s
########################################################################################################################
resource "kubernetes_manifest" "default_httproute" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "${var.project}-default-routes"
      namespace = "istio-system"
      labels = {
        app         = "istio-gateway"
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
    }
    spec = {
      parentRefs = [
        {
          name        = kubernetes_manifest.environment_gateway.manifest.metadata.name
          namespace   = kubernetes_manifest.environment_gateway.manifest.metadata.namespace
          sectionName = "https"
        }
      ]
      rules = [
        # Health check routes
        {
          matches = [
            {
              path = {
                type  = "Exact"
                value = "/healthz"
              }
            },
            {
              path = {
                type  = "Exact"
                value = "/healthz/ready"
              }
            }
          ]
          backendRefs = [
            {
              name      = "istiod"
              namespace = "istio-system"
              port      = 15021
            }
          ]
        },
        # Default 404 for unmatched routes
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          filters = [
            {
              type = "ExtensionRef"
              extensionRef = {
                group = "networking.istio.io"
                kind  = "EnvoyFilter"
                name  = "default-404"
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.environment_gateway
  ]
}

########################################################################################################################
# in case we need to use the project-wide gateway later
########################################################################################################################
# Data Sources for ACM Certificates
# Wildcard certificate - commented out for now
# data "aws_acm_certificate" "project_cert" {
#   domain      = "*.${var.dns_zone}"
#   types       = ["AMAZON_ISSUED"]
#   most_recent = true
# }

# Primary Gateway Resource (Istio automatically creates Deployment/Service)
# Commented out - using environment-specific pattern only for now
# resource "kubernetes_manifest" "project_gateway" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind       = "Gateway"
#     metadata = {
#       name      = "${var.project}-gateway"
#       namespace = "istio-system"  # Standard namespace for modern approach
#       labels = {
#         app         = "istio-gateway"
#         project     = var.project
#         environment = var.env_build
#         managed-by  = "terraform"
#       }
#       annotations = {
#         # EKS Auto Mode NLB Configuration
#         "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
#         "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
#         "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
#         "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
#         "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol"              = "HTTP"
#         "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"                  = "/healthz/ready"
#         "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"                  = "15021"
#         # Optional: Preserve client IP
#         "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol"                    = "*"
#       }
#     }
#     spec = {
#       gatewayClassName = kubernetes_manifest.istio_gateway_class.manifest.metadata.name
#       listeners = [
#         # HTTP Listener (with redirect to HTTPS)
#         {
#           name     = "http"
#           hostname = "*.${var.dns_zone}"
#           port     = 80
#           protocol = "HTTP"
#           allowedRoutes = {
#             namespaces = {
#               from = "All"
#             }
#           }
#         },
#         # HTTPS Listener
#         {
#           name     = "https"
#           hostname = "*.${var.dns_zone}"
#           port     = 443
#           protocol = "HTTPS"
#           tls = {
#             mode = "Terminate"
#             certificateRefs = [
#               {
#                 name      = kubernetes_secret.gateway_tls_cert.metadata[0].name
#                 namespace = kubernetes_secret.gateway_tls_cert.metadata[0].namespace
#               }
#             ]
#           }
#           allowedRoutes = {
#             namespaces = {
#               from = "All"
#             }
#           }
#         }
#       ]
#     }
#   }

#   depends_on = [
#     kubernetes_manifest.istio_gateway_class,
#     kubernetes_secret.gateway_tls_cert
#   ]
# }

########################################################################################################################
# TLS Certificate Secrets (now in istio-system namespace)
########################################################################################################################
# Wildcard certificate - commented out for now (Pattern B: Service Subdomains)
# resource "kubernetes_secret" "gateway_tls_cert" {
#   metadata {
#     name      = "${var.project}-tls-cert"
#     namespace = "istio-system"
#     labels = {
#       project     = var.project
#       environment = var.env_build
#       managed-by  = "terraform"
#     }
#   }

#   type = "kubernetes.io/tls"

#   data = {
#     "tls.crt" = base64decode(data.aws_acm_certificate.project_cert.certificate)
#     "tls.key" = base64decode(data.aws_acm_certificate.project_cert.private_key)
#   }
# }