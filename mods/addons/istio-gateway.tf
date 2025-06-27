########################################################################################################################
# Istio Gateway Resources for EKS Auto Mode with Network Load Balancer
# https://istio.io/latest/docs/setup/additional-setup/gateway/
# https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
# https://istio.io/latest/docs/reference/config/networking/gateway/
########################################################################################################################
# Primary Gateway Resource for the Project
resource "kubernetes_manifest" "project_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "${var.project}-gateway"
      namespace = "istio-ingress"
      labels = {
        app         = "istio-gateway"
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
    }
    spec = {
      selector = {
        istio = "ingress"
      }
      servers = [
        # HTTP Server (with HTTPS redirect)
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = ["*.${var.dns_zone}"]
          tls = {
            httpsRedirect = true
          }
        },
        # HTTPS Server
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          hosts = ["*.${var.dns_zone}"]
          tls = {
            mode           = "SIMPLE"
            credentialName = "${var.project}-tls-cert"
          }
        }
      ]
    }
  }

  depends_on = [helm_release.istio_gateway]
}

########################################################################################################################
# Environment-Specific Gateway (Optional - for multi-env routing)
########################################################################################################################
resource "kubernetes_manifest" "environment_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "${var.project}-${var.env_build}-gateway"
      namespace = "istio-ingress"
      labels = {
        app         = "istio-gateway"
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
    }
    spec = {
      selector = {
        istio = "ingress"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = ["${var.env_build}.${var.dns_zone}"]
          tls = {
            httpsRedirect = true
          }
        },
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          hosts = ["${var.env_build}.${var.dns_zone}"]
          tls = {
            mode           = "SIMPLE"
            credentialName = "${var.project}-${var.env_build}-tls-cert"
          }
        }
      ]
    }
  }

  depends_on = [helm_release.istio_gateway]
}

########################################################################################################################
# Network Load Balancer Service Configuration
########################################################################################################################
resource "kubernetes_service" "istio_nlb" {
  metadata {
    name      = "${var.project}-istio-nlb"
    namespace = "istio-ingress"
    annotations = {
      # EKS Auto Mode NLB Configuration
      "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol"              = "HTTP"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"                  = "/healthz/ready"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"                  = "15021"
      # Optional: Preserve client IP
      "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol"                    = "*"
    }
    labels = {
      app         = "istio-ingress-nlb"
      project     = var.project
      environment = var.env_build
      managed-by  = "terraform"
    }
  }

  spec {
    type = "LoadBalancer"
    
    selector = {
      app   = "istio-ingress"
      istio = "ingress"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8443
      protocol    = "TCP"
    }

    external_traffic_policy = "Local"  # Preserve source IP
  }

  depends_on = [helm_release.istio_gateway]
}

########################################################################################################################
# TLS Certificate Secret (using ACM certificate data)
########################################################################################################################
resource "kubernetes_secret" "gateway_tls_cert" {
  metadata {
    name      = "${var.project}-tls-cert"
    namespace = "istio-ingress"
    labels = {
      project     = var.project
      environment = var.env_build
      managed-by  = "terraform"
    }
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = base64decode(data.aws_acm_certificate.project_cert.certificate)
    "tls.key" = base64decode(data.aws_acm_certificate.project_cert.private_key)
  }

  depends_on = [kubernetes_namespace.istio_ingress]
}

# Environment-specific certificate
resource "kubernetes_secret" "environment_tls_cert" {
  metadata {
    name      = "${var.project}-${var.env_build}-tls-cert"
    namespace = "istio-ingress"
    labels = {
      project     = var.project
      environment = var.env_build
      managed-by  = "terraform"
    }
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = base64decode(data.aws_acm_certificate.environment_cert.certificate)
    "tls.key" = base64decode(data.aws_acm_certificate.environment_cert.private_key)
  }

  depends_on = [kubernetes_namespace.istio_ingress]
}

########################################################################################################################
# Data Sources for ACM Certificates
########################################################################################################################
data "aws_acm_certificate" "project_cert" {
  domain      = "*.${var.dns_zone}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "environment_cert" {
  domain      = "${var.env_build}.${var.dns_zone}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

########################################################################################################################
# Default VirtualService for Health Checks
########################################################################################################################
resource "kubernetes_manifest" "health_check_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1"
    kind       = "VirtualService"
    metadata = {
      name      = "${var.project}-healthcheck"
      namespace = "istio-ingress"
      labels = {
        app         = "istio-gateway"
        project     = var.project
        environment = var.env_build
        managed-by  = "terraform"
      }
    }
    spec = {
      hosts = ["*"]
      gateways = [
        "${var.project}-gateway",
        "${var.project}-${var.env_build}-gateway"
      ]
      http = [
        {
          match = [
            {
              uri = {
                exact = "/healthz"
              }
            },
            {
              uri = {
                exact = "/healthz/ready"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "istio-ingress.istio-ingress.svc.cluster.local"
                port = {
                  number = 15021
                }
              }
            }
          ]
        },
        # Default 404 response for unmatched routes
        {
          match = [
            {
              uri = {
                prefix = "/"
              }
            }
          ]
          fault = {
            abort = {
              percentage = {
                value = 100
              }
              httpStatus = 404
            }
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.project_gateway,
    kubernetes_manifest.environment_gateway
  ]
}