########################################################################################################################
# Outputs: EKS Third-Party Addons
########################################################################################################################
# output "lbc_irsa_role_arn" {
#   description = "AWS Load Balancer Controller IRSA role ARN"
#   value       = module.aws_load_balancer_controller_irsa.iam_role_arn
# }

########################################################################################################################
# ArgoCD: Important Information
########################################################################################################################
output "argocd_credentials_file" {
  description = "Location of temporary credentials file"
  value       = local_file.argocd_credentials.filename
}

########################################################################################################################
# Cilium CNI Outputs
########################################################################################################################
# output "cilium_release_name" {
#   description = "Name of the Cilium Helm release"
#   value       = helm_release.cilium.name
# }

# output "cilium_release_version" {
#   description = "Version of the Cilium Helm chart deployed"
#   value       = helm_release.cilium.version
# }

# output "cilium_namespace" {
#   description = "Namespace where Cilium is deployed"
#   value       = helm_release.cilium.namespace
# }

# output "cilium_status" {
#   description = "Status of the Cilium Helm release"
#   value       = helm_release.cilium.status
# }

# ########################################################################################################################
# # IRSA Outputs
# ########################################################################################################################

# output "cilium_irsa_role_arn" {
#   description = "ARN of the Cilium IRSA role for AWS API access"
#   value       = module.cilium_irsa.iam_role_arn
# }

# output "cilium_irsa_role_name" {
#   description = "Name of the Cilium IRSA role"
#   value       = module.cilium_irsa.iam_role_name
# }

# ########################################################################################################################
# # Hubble Observability Outputs
# ########################################################################################################################

# output "hubble_relay_service" {
#   description = "Hubble Relay service information"
#   value = {
#     name      = data.kubernetes_service.hubble_relay.metadata[0].name
#     namespace = data.kubernetes_service.hubble_relay.metadata[0].namespace
#     ports     = data.kubernetes_service.hubble_relay.spec[0].port
#   }
# }

# output "hubble_ui_service" {
#   description = "Hubble UI service information"
#   value = {
#     name      = data.kubernetes_service.hubble_ui.metadata[0].name
#     namespace = data.kubernetes_service.hubble_ui.metadata[0].namespace
#     ports     = data.kubernetes_service.hubble_ui.spec[0].port
#   }
# }

########################################################################################################################
# Access Instructions
########################################################################################################################
output "hubble_ui_access_instructions" {
  description = "Instructions for accessing Hubble UI"
  value       = <<-EOT
    To access Hubble UI:

    1. Port forward to Hubble UI:
       kubectl port-forward -n kube-system svc/hubble-ui 12000:80

    2. Open browser to:
       http://localhost:12000

    3. Or create an ingress/LoadBalancer service for external access
  EOT
}

output "cilium_cli_commands" {
  description = "Useful Cilium CLI commands for monitoring"
  value       = <<-EOT
    Check Cilium status:
      cilium status

    Test connectivity:
      cilium connectivity test

    View Hubble flows:
      cilium hubble port-forward&
      cilium hubble observe

    Monitor network policies:
      cilium hubble observe --verdict DENIED

    Check IRSA configuration:
      kubectl get serviceaccount -n kube-system cilium -o yaml
      kubectl get serviceaccount -n kube-system cilium-operator -o yaml
  EOT
}

# ########################################################################################################################
# # Monitoring and Metrics
# ########################################################################################################################
# output "cilium_metrics_endpoints" {
#   description = "Cilium metrics endpoints for monitoring"
#   value = {
#     cilium_agent = {
#       port = 9090
#       path = "/metrics"
#     }
#     cilium_operator = {
#       port = 6942
#       path = "/metrics"
#     }
#     hubble = {
#       port = 4244
#       path = "/metrics"
#     }
#   }
# }
