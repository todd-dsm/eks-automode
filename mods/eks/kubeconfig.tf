########################################################################################################################
# Kubeconfig Creation via Script (replaces kubeconfig.tf)
########################################################################################################################
resource "null_resource" "kubeconfig_script" {
  # Only trigger when cluster endpoint changes (indicating new cluster)
  triggers = {
    cluster_endpoint = aws_eks_cluster.eks_auto.endpoint
    cluster_name     = aws_eks_cluster.eks_auto.name
  }

  # Create kubeconfig using script
  provisioner "local-exec" {
    command = "${path.root}/scripts/create-kubeconfig.sh ${aws_eks_cluster.eks_auto.name} ${data.aws_region.current.id}"

    working_dir = path.root

    environment = {
      project = var.project
      region  = data.aws_region.current.id
    }
  }

  depends_on = [aws_eks_cluster.eks_auto]
}
