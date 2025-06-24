# ########################################################################################################################
# # Traefik Outputs
# ########################################################################################################################
# output "traefik_namespace" {
#   description = "Namespace where Traefik is deployed"
#   value       = kubernetes_namespace.traefik.metadata[0].name
# }

# output "traefik_certificate_arn" {
#   description = "ARN of the Traefik ACM certificate"
#   value       = aws_acm_certificate_validation.traefik.certificate_arn
# }

# output "traefik_certificate_domain" {
#   description = "Primary domain of the Traefik certificate"
#   value       = aws_acm_certificate.traefik.domain_name
# }

# output "traefik_gateway_class" {
#   description = "Name of the Traefik GatewayClass"
#   value       = kubernetes_manifest.traefik_gateway_class.manifest.metadata.name
# }

# output "traefik_gateway_name" {
#   description = "Name of the main Traefik Gateway"
#   value       = kubernetes_manifest.traefik_gateway.manifest.metadata.name
# }

# output "traefik_service_url" {
#   description = "Instructions for accessing Traefik"
#   value       = <<-EOT
#     Traefik Gateway API Setup Complete!

#     📦 Gateway API: v1.2.1 installed
#     🔐 Traefik RBAC: v3.4 installed

#     📋 Gateway Information:
#     - GatewayClass: ${kubernetes_manifest.traefik_gateway_class.manifest.metadata.name}
#     - Gateway: ${kubernetes_manifest.traefik_gateway.manifest.metadata.name}
#     - Namespace: ${kubernetes_namespace.traefik.metadata[0].name}
#     - Certificate: ${aws_acm_certificate_validation.traefik.certificate_arn}
#     - Dashboard: ${var.enable_traefik_dashboard ? "Enabled" : "Disabled"}

#     🌐 Access URLs:${var.enable_traefik_dashboard ? "\n    - Dashboard: https://${aws_acm_certificate.traefik.domain_name}" : ""}

#     🔍 Verify Installation:
#     kubectl get gatewayclasses
#     kubectl get gateways -n ${kubernetes_namespace.traefik.metadata[0].name}
#     kubectl get httproutes -n ${kubernetes_namespace.traefik.metadata[0].name}

#     📚 Use the '${kubernetes_manifest.traefik_gateway_class.manifest.metadata.name}' GatewayClass in your applications
#   EOT
# }

# output "traefik_irsa_role_arn" {
#   description = "ARN of the Traefik IRSA role"
#   value       = module.traefik_irsa.iam_role_arn
# }
