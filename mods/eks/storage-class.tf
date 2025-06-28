########################################################################################################################
# General Storage Class Configuration
# Uses gp2 for cost optimization while testing
########################################################################################################################
resource "kubernetes_storage_class_v1" "storage_class_default" {
  metadata {
    name = "auto-ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  # EKS Auto Mode specific provisioner
  storage_provisioner = "ebs.csi.eks.amazonaws.com"

  # Wait for first consumer to bind volume to specific AZ
  volume_binding_mode = "WaitForFirstConsumer"

  # Reclaim policy - Delete for test environments, Retain for production
  reclaim_policy = "Delete"

  parameters = {
    # gp2 is cheapest for small test volumes
    type      = "gp2"
    encrypted = "true"
    # fsType defaults to ext4 if not specified
  }

  # Allow volume expansion for flexibility
  allow_volume_expansion = true

  depends_on = [
    null_resource.kubeconfig_manager
  ]
}

########################################################################################################################
# Optional: Create additional StorageClasses for different use cases
########################################################################################################################
# High-performance StorageClass (commented out - uncomment if needed)
# resource "kubernetes_storage_class_v1" "storage_class_performance" {
#   metadata {
#     name = "auto-ebs-performance"
#   }
# 
#   storage_provisioner = "ebs.csi.eks.amazonaws.com"
#   volume_binding_mode = "WaitForFirstConsumer"
#   reclaim_policy      = "Delete"
# 
#   parameters = {
#     type = "gp3"
#     iops = "3000"
#     throughput = "125"
#     encrypted = "true"
#   }
# 
#   allow_volume_expansion = true
# }
