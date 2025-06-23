/*
  --------------------------------------------------------------------------------------------------------------------
  provider.tf gets replaced when sourcing-in variables.
    This file exists to provide a single, non-destructive space to configure
    the plumbing for AuthN with the EKS cluster.
  --------------------------------------------------------------------------------------------------------------------
*/
# AuthN: Helm <> EKS so Helm Can Install Charts
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

# # Configure Kubernetes provider for EKS
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Lookup cluster auth info
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.cluster_name
}
