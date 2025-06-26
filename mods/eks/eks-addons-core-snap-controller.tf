########################################################################################################################
# Core EKS Addons - Snapshot Controller 
#   * This one takes 15m20s to build.
#   * Enable when needed; db work, etc.
########################################################################################################################
# https://github.com/kubernetes-csi/external-snapshotter
# resource "aws_eks_addon" "snapshot_controller" {
#   cluster_name             = aws_eks_cluster.eks_auto.name
#   addon_name               = "snapshot-controller"
#   addon_version            = data.aws_eks_addon_version.snapshot_controller.version
#   service_account_role_arn = module.snapshot_controller_irsa.iam_role_arn
# }

# # Snapshot Controller IRSA
# module "snapshot_controller_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.58.0"

#   role_name_prefix = "${var.project}-snapshot-controller-"

#   oidc_providers = {
#     main = {
#       provider_arn               = aws_iam_openid_connect_provider.eks.arn
#       namespace_service_accounts = ["kube-system:snapshot-controller"]
#     }
#   }

#   tags = var.tags
# }

# # Data sources for addon versions
# data "aws_eks_addon_version" "snapshot_controller" {
#   addon_name         = "snapshot-controller"
#   kubernetes_version = aws_eks_cluster.eks_auto.version
#   most_recent        = true
# }

# # Output Version
# output "snapshot_controller_version" {
#   description = "Version of the snapshot-controller addon"
#   value       = data.aws_eks_addon_version.snapshot_controller.version
# }