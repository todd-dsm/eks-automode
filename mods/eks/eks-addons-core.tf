########################################################################################################################
# Core EKS Addons Only - Native AWS EKS Addons
########################################################################################################################
# Snapshot Controller
# resource "aws_eks_addon" "snapshot_controller" {
#   cluster_name             = aws_eks_cluster.eks_auto.name
#   addon_name               = "snapshot-controller"
#   addon_version            = data.aws_eks_addon_version.snapshot_controller.version
#   service_account_role_arn = module.snapshot_controller_irsa.iam_role_arn
# }

# Mountpoint for S3 CSI driver - Now with CORRECT name
resource "aws_eks_addon" "mountpoint_for_s3_csi_driver" {
  cluster_name             = aws_eks_cluster.eks_auto.name
  addon_name               = "aws-mountpoint-s3-csi-driver"
  addon_version            = data.aws_eks_addon_version.mountpoint_for_s3_csi_driver.version
  service_account_role_arn = module.mountpoint_for_s3_csi_driver_irsa.iam_role_arn

  depends_on = [
    aws_eks_cluster.eks_auto
  ]
}

# # FSx CSI driver
# resource "aws_eks_addon" "fsx_csi_driver" {
#   cluster_name             = aws_eks_cluster.eks_auto.name
#   addon_name               = "fsx-csi-driver"
#   addon_version            = data.aws_eks_addon_version.fsx_csi_driver.version
#   service_account_role_arn = module.fsx_csi_driver_irsa.iam_role_arn
# }

########################################################################################################################
# Data sources for addon versions
########################################################################################################################
data "aws_eks_addon_version" "snapshot_controller" {
  addon_name         = "snapshot-controller"
  kubernetes_version = aws_eks_cluster.eks_auto.version
  most_recent        = true
}

# Mountpoint for S3 CSI driver - CORRECT name: aws-mountpoint-s3-csi-driver
data "aws_eks_addon_version" "mountpoint_for_s3_csi_driver" {
  addon_name         = "aws-mountpoint-s3-csi-driver"
  kubernetes_version = aws_eks_cluster.eks_auto.version
  most_recent        = true
}

# # FSx CSI driver
# data "aws_eks_addon_version" "fsx_csi_driver" {
#   addon_name         = "fsx-csi-driver"
#   kubernetes_version = aws_eks_cluster.eks_auto.version
#   most_recent        = true
# }
