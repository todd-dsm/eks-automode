
# # FSx CSI driver
# # https://github.com/aws/aws-fsx-csi-driver
# resource "aws_eks_addon" "fsx_csi_driver" {
#   cluster_name             = aws_eks_cluster.eks_auto.name
#   addon_name               = "aws-fsx-csi-driver"
#   addon_version            = data.aws_eks_addon_version.fsx_csi_driver.version
#   service_account_role_arn = module.fsx_csi_driver_irsa.iam_role_arn

#   depends_on = [
#     aws_eks_cluster.eks_auto,
#     module.fsx_csi_driver_irsa
#   ]
# }

# # FSx CSI driver
# data "aws_eks_addon_version" "fsx_csi_driver" {
#   addon_name         = "aws-fsx-csi-driver"
#   kubernetes_version = aws_eks_cluster.eks_auto.version
#   most_recent        = true
# }

# # IRSA for FSx CSI Driver - builds in 25s
# module "fsx_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = ">= 5.58.0"

#   role_name_prefix = "${var.project}-fsx-csi-driver-"

#   # Use AWS managed policy for FSx access
#   role_policy_arns = {
#     fsx_policy = "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
#   }

#   oidc_providers = {
#     main = {
#       provider_arn               = aws_iam_openid_connect_provider.eks.arn
#       namespace_service_accounts = ["kube-system:fsx-csi-controller-sa"]
#     }
#   }

#   tags = var.tags
# }
