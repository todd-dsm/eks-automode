########################################################################################################################
# EKS Cluster Outputs
########################################################################################################################
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.eks_auto.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certficate authority"
  value       = aws_eks_cluster.eks_auto.certificate_authority[0].data
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks_auto.name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "cert_issued" {
  description = "Certificate issued by (not imported into) ACM"
  value       = data.aws_acm_certificate.amazon_issued.status
}

########################################################################################################################

# output "cluster_version" {
#   description = "EKS cluster version"
#   value       = aws_eks_cluster.eks_auto.version
# }

# output "oidc_provider_arn" {
#   description = "OIDC provider ARN"
#   value       = aws_eks_cluster.eks_auto.oidc_provider_arn
# }

########################################################################################################################
# Addons Outputs
########################################################################################################################

# output "vpc_cni_irsa_arn" {
#   value = module.vpc_cni_irsa.iam_role_arn
# }

# output "ebs_csi_driver_irsa_arn" {
#   value = module.ebs_csi_driver_irsa.iam_role_arn
# }
# output "aws_load_balancer_controller_irsa_arn" {
#   value = module.aws_load_balancer_controller_irsa.iam_role_arn
# }

# output "argocd_irsa_arn" {
#   value = module.argocd_irsa.iam_role_arn
# }

# output "oidc_provider_arn" {
#   value = aws_iam_openid_connect_provider.eks.arn
# }


# output "argocd_server_url" {
#   description = "ArgoCD server URL (when using LoadBalancer)"
#   value       = "http://$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
# }

# output "argocd_admin_password_command" {
#   description = "Command to get ArgoCD admin password"
#   value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
# }
########################################################################################################################
# IRSA Role ARNs
########################################################################################################################
# output "vpc_cni_irsa_role_arn" {
#   description = "VPC CNI IRSA role ARN"
#   value       = module.vpc_cni_irsa.iam_role_arn
# }

# output "ebs_csi_driver_irsa_role_arn" {
#   description = "EBS CSI driver IRSA role ARN"
#   value       = module.ebs_csi_driver_irsa.iam_role_arn
# }

# output "aws_load_balancer_controller_irsa_role_arn" {
#   description = "AWS Load Balancer Controller IRSA role ARN"
#   value       = module.aws_load_balancer_controller_irsa.iam_role_arn
# }

# output "argocd_irsa_role_arn" {
#   description = "ArgoCD IRSA role ARN"
#   value       = module.argocd_irsa.iam_role_arn
# }
