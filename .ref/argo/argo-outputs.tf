########################################################################################################################
# ArgoCD: Important Information
########################################################################################################################
output "argocd_credentials_file" {
  description = "Location of temporary credentials file"
  value       = local_file.argocd_credentials.filename
}
