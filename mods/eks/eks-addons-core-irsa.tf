########################################################################################################################
# IRSAs to Support EKS Addons
# VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/examples/iam-role-for-service-accounts-eks
# SPT: https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/examples/iam-role-for-service-accounts-eks
# DOC: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/
# EXs: https://github.com/terraform-aws-modules/terraform-aws-iam/blob/7825816ce6cb6a2838c0978b629868d24358f5aa/README.md
# ######################################################################################################################
# # IRSA for FSx CSI Driver - builds in 25s
# ########################################################################################################################
module "fsx_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.58.0"

  role_name_prefix = "${var.project}-fsx-csi-driver-"

  # Use AWS managed policy for FSx access
  role_policy_arns = {
    fsx_policy = "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["kube-system:fsx-csi-controller-sa"]
    }
  }

  tags = var.tags
}

# ########################################################################################################################
# # IRSA for Mountpoint S3 CSI Driver
# ########################################################################################################################
module "mountpoint_for_s3_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.58.0"

  role_name_prefix = "${var.project}-s3-csi-driver-"

  # Custom policy for S3 access - more secure than full access
  role_policy_arns = {
    s3_policy = aws_iam_policy.s3_csi_driver_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["kube-system:s3-csi-driver-sa"]
    }
  }

  tags = var.tags
}

# Custom IAM policy for S3 CSI driver (more secure than AmazonS3FullAccess)
resource "aws_iam_policy" "s3_csi_driver_policy" {
  name_prefix = "${var.project}-s3-csi-driver-"
  description = "IAM policy for S3 CSI driver with minimal required permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3express:CreateSession"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}


#######################################################################################################################
# These add-ons are included in the EKS Auto Mode by default
# VPC CNI plugin
# CoreDNS
# kube-proxy
# EBS storage capability (not the full EBS CSI driver addon)
# AWS Load Balancer Controller
# Karpenter for node management

# Not Included & Managed:
# Any app-specific add-ons
# AWS EFS CSI driver
# Observability Stack Components
#  - AWS Distro for OpenTelemetry (ADOT)
#  - AWS X-Ray
#  - AWS CloudWatch Container Insights
#  - AWS CloudWatch Logs
#  - AWS CloudWatch Metrics
#  - AWS CloudWatch Events
#  - AWS CloudWatch Alarms
