# output "snapshot_controller_version" {
#   description = "Version of the snapshot-controller addon"
#   value       = data.aws_eks_addon_version.snapshot_controller.version
# }

# output "mountpoint_for_s3_csi_driver_version" {
#   description = "Version of the mountpoint-for-s3-csi-driver addon"
#   value       = data.aws_eks_addon_version.mountpoint_for_s3_csi_driver.version
# }

output "fsx_csi_driver_version" {
  description = "Version of the fsx-csi-driver addon"
  value       = data.aws_eks_addon_version.fsx_csi_driver.version
}
