########################################################################################################################
# Core EKS Addons Only - Native AWS EKS Addons
########################################################################################################################
# FSx CSI driver
# https://github.com/aws/aws-fsx-csi-driver
resource "aws_eks_addon" "fsx_csi_driver" {
  cluster_name             = aws_eks_cluster.eks_auto.name
  addon_name               = "aws-fsx-csi-driver"
  addon_version            = data.aws_eks_addon_version.fsx_csi_driver.version
  service_account_role_arn = module.fsx_csi_driver_irsa.iam_role_arn

  depends_on = [
    aws_eks_cluster.eks_auto,
    module.fsx_csi_driver_irsa
  ]
}

# Mountpoint for S3 CSI driver
# https://github.com/awslabs/mountpoint-s3-csi-driver
resource "aws_eks_addon" "mountpoint_for_s3_csi_driver" {
  cluster_name             = aws_eks_cluster.eks_auto.name
  addon_name               = "aws-mountpoint-s3-csi-driver"
  addon_version            = data.aws_eks_addon_version.mountpoint_for_s3_csi_driver.version
  service_account_role_arn = module.mountpoint_for_s3_csi_driver_irsa.iam_role_arn

  depends_on = [
    aws_eks_cluster.eks_auto
  ]
}

########################################################################################################################
# Data sources for addon versions
########################################################################################################################
# FSx CSI driver
data "aws_eks_addon_version" "fsx_csi_driver" {
  addon_name         = "aws-fsx-csi-driver"
  kubernetes_version = aws_eks_cluster.eks_auto.version
  most_recent        = true
}

# Mountpoint for S3 CSI driver - CORRECT name: aws-mountpoint-s3-csi-driver
data "aws_eks_addon_version" "mountpoint_for_s3_csi_driver" {
  addon_name         = "aws-mountpoint-s3-csi-driver"
  kubernetes_version = aws_eks_cluster.eks_auto.version
  most_recent        = true
}
