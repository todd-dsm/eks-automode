################################################################################
#  EKS: Access Entries
# DOCS: https://docs.aws.amazon.com/eks/latest/userguide/creating-access-entries.html
# NOTE: could really use a list of users.
################################################################################
# DOCS: https://docs.aws.amazon.com/eks/latest/userguide/creating-access-entries.html
#  TFM: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry
# SELF
resource "aws_eks_access_entry" "aws_eks_access_entry" {
  cluster_name  = aws_eks_cluster.eks_auto.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

# Taylor
resource "aws_eks_access_entry" "taylor" {
  cluster_name  = aws_eks_cluster.eks_auto.name
  principal_arn = data.aws_iam_user.taylor.arn
  type          = "STANDARD"
}

# TFM: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association
# Add Admins to Cluster
resource "aws_eks_access_policy_association" "cluster_admins" {
  for_each = local.cluster_admins

  cluster_name  = aws_eks_cluster.eks_auto.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}

# Define admins
# FIXME: sloppy, this is also in var-locals-disco.tf
data "aws_iam_user" "taylor" {
  user_name = "taylor"
}

locals {
  cluster_admins = {
    self   = data.aws_caller_identity.current.arn
    taylor = data.aws_iam_user.taylor.arn
  }
}
