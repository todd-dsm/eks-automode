########################################################################################################################
# Install Gateway API CRDs via Script
########################################################################################################################
resource "null_resource" "gateway_api_crds" {
  provisioner "local-exec" {
    command = "scripts/inst-gateway-api-crds.sh"
    environment = {
      project = var.project
    }
  }

  triggers = {
    gateway_api_version = "v1.3.0"
    cluster_name        = aws_eks_cluster.eks_auto.name
  }

  depends_on = [
    aws_eks_cluster.eks_auto,
    null_resource.kubeconfig_manager
  ]
}
