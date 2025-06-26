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
