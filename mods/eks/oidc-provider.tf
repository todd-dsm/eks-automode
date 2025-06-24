# modules/eks/oidc-provider.tf

########################################################################################################################
# OIDC Provider for IRSA
# Required for IAM Roles for Service Accounts (IRSA) functionality
########################################################################################################################

# Get the OIDC issuer thumbprint
data "tls_certificate" "eks_oidc_issuer" {
  url = aws_eks_cluster.eks_auto.identity[0].oidc[0].issuer
}

# Create the OIDC provider
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_issuer.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_auto.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.project}-eks-oidc-provider"
  })
}
