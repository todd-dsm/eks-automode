########################################################################################################################
# IRSAs to Support EKS Addons
# VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/examples/iam-role-for-service-accounts-eks
# SPT: https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/examples/iam-role-for-service-accounts-eks
# DOC: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/
# EXs: https://github.com/terraform-aws-modules/terraform-aws-iam/blob/7825816ce6cb6a2838c0978b629868d24358f5aa/README.md
# ######################################################################################################################
# VPC CNI IRSA
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.58.0"

  role_name_prefix = "${var.project}-vpc-cni-"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  vpc_cni_enable_ipv6   = var.enable_ipv6

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

# EBS CSI Driver IRSA
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "${var.project}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}
