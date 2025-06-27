# ########################################################################################################################
# # ArgoCD Dynamic Password Generation for ArgoCD Admin
# ########################################################################################################################
resource "random_password" "argocd_admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true

  # Ensure password has at least one of each character type
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1

  # Avoid ambiguous characters
  override_special = "!@#$%&*()-_=+[]{}"
}

########################################################################################################################
# ArgoCD Initial Configuration (Optional)
########################################################################################################################
# Create initial admin secret with dynamically generated password
resource "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "argocd-initial-admin-secret"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  # Use dynamically generated password
  data = {
    password = bcrypt(random_password.argocd_admin_password.result)
  }

  type = "Opaque"

  depends_on = [helm_release.argocd]
}

resource "local_file" "argocd_credentials" {
  content = <<-EOT
    ArgoCD Credentials
    ==================
    URL: https://argocd.${var.dns_zone}
    Username: admin  
    Password: ${random_password.argocd_admin_password.result}
    
    Access via port-forward:
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    Then: https://localhost:8080
    
    ⚠️  DELETE THIS FILE AFTER USE
  EOT

  filename             = "/tmp/argocd-credentials.txt"
  file_permission      = "0600" # Only readable by owner
  directory_permission = "0755" # Only readable by owner
}

# Create dedicated namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      name                     = "argocd"
      "app.kubernetes.io/name" = "argocd"
    }
  }
}

# ########################################################################################################################
# # Example Gateway for ArgoCD (replacing LoadBalancer service)
# ########################################################################################################################
# resource "kubernetes_manifest" "argocd_gateway" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind       = "Gateway"
#     metadata = {
#       name      = "argocd-gateway"
#       namespace = "argocd"
#       labels = {
#         "app.kubernetes.io/managed-by" = "terraform"
#       }
#     }
#     spec = {
#       gatewayClassName = "cilium"
#       listeners = [
#         {
#           name     = "http"
#           port     = 80
#           protocol = "HTTP"
#         },
#         {
#           name     = "https"
#           port     = 443
#           protocol = "HTTPS"
#           tls = {
#             mode = "Terminate"
#             certificateRefs = [
#               {
#                 name = "argocd-tls"  # You'll need to create this certificate
#               }
#             ]
#           }
#         }
#       ]
#     }
#   }

#   depends_on = [
#     kubernetes_manifest.cilium_gateway_class
#   ]
# }

# ########################################################################################################################
# # HTTPRoute for ArgoCD
# ########################################################################################################################
# resource "kubernetes_manifest" "argocd_httproute" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind       = "HTTPRoute"
#     metadata = {
#       name      = "argocd-route"
#       namespace = "argocd"
#       labels = {
#         "app.kubernetes.io/managed-by" = "terraform"
#       }
#     }
#     spec = {
#       parentRefs = [
#         {
#           name = "argocd-gateway"
#         }
#       ]
#       hostnames = [
#         "argocd.${var.dns_zone}"
#       ]
#       rules = [
#         {
#           matches = [
#             {
#               path = {
#                 type  = "PathPrefix"
#                 value = "/"
#               }
#             }
#           ]
#           backendRefs = [
#             {
#               name = "argocd-server"
#               port = 80
#             }
#           ]
#         }
#       ]
#     }
#   }

#   depends_on = [
#     kubernetes_manifest.argocd_gateway
#   ]
# }
