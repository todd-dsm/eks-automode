################################################################################
# EKS: Auto Mode
# DOCS: https://docs.aws.amazon.com/eks/latest/userguide/settings-auto.html
################################################################################
# DOCS: https://docs.aws.amazon.com/eks/latest/userguide/create-auto.html
# REFS: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#example-usage
resource "aws_eks_cluster" "eks_auto" {
  name    = var.project
  version = var.cluster_version

  # IAM Roles
  # DOCS: https://docs.aws.amazon.com/eks/latest/userguide/auto-learn-iam.html
  role_arn = aws_iam_role.auto_eks.arn

  # Built-in NodePools
  # DOCS: https://docs.aws.amazon.com/eks/latest/userguide/set-builtin-node-pools.html
  bootstrap_self_managed_addons = false
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "infra-services"]
    node_role_arn = aws_iam_role.auto_nodes.arn
  }

  # Network Config
  # DOCS: https://docs.aws.amazon.com/eks/latest/userguide/auto-networking.html
  #   EZ: https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  # Storage Config
  #  EBS: https://docs.aws.amazon.com/eks/latest/userguide/create-storage-class.html
  #   EZ: https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-storage.html
  storage_config {
    block_storage {
      enabled = true
    }
  }

  # VPC Config
  # DOCS: https://docs.aws.amazon.com/eks/latest/userguide/auto-vpc-config.html
  #  HCL: https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Explicitly disable observability features
  # observability_config {
  #   enabled = false
  # }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_compute_policy,
    aws_iam_role_policy_attachment.eks_block_storage_policy,
    aws_iam_role_policy_attachment.eks_load_balancing_policy,
    aws_iam_role_policy_attachment.eks_networking_policy,
  ]

  # Admin Auth
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

################################################################################
# EKS:  Related Services
# DOCS: https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html#eks-related-services
# Extended Storage Config
# https://docs.aws.amazon.com/eks/latest/userguide/storage.html
################################################################################
