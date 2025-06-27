########################################################################################################################
# SigNoz Support Infrastructure
# Creates namespace and basic resources needed for SigNoz deployment
########################################################################################################################
# Storage Class for SigNoz with Volume Expansion
# Optimized for ClickHouse and other persistent storage requirements
########################################################################################################################
resource "kubernetes_storage_class_v1" "signoz_storage" {
  metadata {
    name = "signoz-ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/description" = "SigNoz optimized EBS storage class with volume expansion"
    }
  }

  # EKS Auto Mode specific provisioner
  storage_provisioner = "ebs.csi.eks.amazonaws.com"

  # Wait for first consumer to bind volume to specific AZ
  volume_binding_mode = "WaitForFirstConsumer"

  # Retain volumes for production data safety
  reclaim_policy = var.env_build == "prod" ? "Retain" : "Delete"

  parameters = {
    # gp3 for better performance with SigNoz workloads
    type      = "gp3"
    encrypted = "true"
    # Optimized IOPS and throughput for ClickHouse
    iops       = "3000"
    throughput = "125"
  }

  # Enable volume expansion - key requirement for SigNoz
  allow_volume_expansion = true
}

# Create dedicated namespace for SigNoz
resource "kubernetes_namespace" "signoz" {
  metadata {
    name = "signoz"

    labels = {
      name                                 = "signoz"
      "app.kubernetes.io/name"             = "signoz"
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}