# # Mountpoint for S3 CSI driver
# # https://github.com/awslabs/mountpoint-s3-csi-driver
# resource "aws_eks_addon" "mountpoint_for_s3_csi_driver" {
#   cluster_name             = aws_eks_cluster.eks_auto.name
#   addon_name               = "aws-mountpoint-s3-csi-driver"
#   addon_version            = data.aws_eks_addon_version.mountpoint_for_s3_csi_driver.version
#   service_account_role_arn = module.mountpoint_for_s3_csi_driver_irsa.iam_role_arn

#   depends_on = [
#     aws_eks_cluster.eks_auto
#   ]
# }

# # Mountpoint for S3 CSI driver - CORRECT name: aws-mountpoint-s3-csi-driver
# data "aws_eks_addon_version" "mountpoint_for_s3_csi_driver" {
#   addon_name         = "aws-mountpoint-s3-csi-driver"
#   kubernetes_version = aws_eks_cluster.eks_auto.version
#   most_recent        = true
# }

# # IRSA for Mountpoint S3 CSI Driver
# module "mountpoint_for_s3_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = ">= 5.58.0"

#   role_name_prefix = "${var.project}-s3-csi-driver-"

#   # Custom policy for S3 access - more secure than full access
#   role_policy_arns = {
#     s3_policy = aws_iam_policy.s3_csi_driver_policy.arn
#   }

#   oidc_providers = {
#     main = {
#       provider_arn               = aws_iam_openid_connect_provider.eks.arn
#       namespace_service_accounts = ["kube-system:s3-csi-driver-sa"]
#     }
#   }

#   tags = var.tags
# }

# # Custom IAM policy for S3 CSI driver (more secure than AmazonS3FullAccess)
# resource "aws_iam_policy" "s3_csi_driver_policy" {
#   name_prefix = "${var.project}-s3-csi-driver-"
#   description = "IAM policy for S3 CSI driver with minimal required permissions"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:ListBucket",
#           "s3:GetBucketLocation",
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ]
#         Resource = [
#           "arn:aws:s3:::*",
#           "arn:aws:s3:::*/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "s3express:CreateSession"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = var.tags
# }
