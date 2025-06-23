########################################################################################################################
# Automatically manages kubeconfig file in "$HOME/.kube"
########################################################################################################################
resource "null_resource" "kubeconfig_manager" {
  # Triggers for recreation - including file existence
  triggers = {
    cluster_endpoint = aws_eks_cluster.eks_auto.endpoint
    cluster_name     = aws_eks_cluster.eks_auto.name
    kubeconfig_path  = local.kubeconfig_path
    region           = data.aws_region.current.id
    project          = var.project
    # This trigger will change when the file doesn't exist
    file_exists = fileexists(local.kubeconfig_path) ? "exists" : "missing"
  }

  # Create kubeconfig on cluster creation/update
  provisioner "local-exec" {
    command = <<-EOT
      echo "📝 Creating kubeconfig for EKS cluster: ${self.triggers.cluster_name}"
      echo "📁 Target path: ${self.triggers.kubeconfig_path}"
      echo "🌍 Region: ${self.triggers.region}"
      
      # Ensure .kube directory exists
      mkdir -p ~/.kube
      
      # Generate kubeconfig using AWS CLI with explicit values
      aws eks update-kubeconfig \
        --region "${self.triggers.region}" \
        --name "${self.triggers.cluster_name}" \
        --kubeconfig "${self.triggers.kubeconfig_path}" \
        --alias "${self.triggers.project}"
      
      # Verify file was created
      if [ -f "${self.triggers.kubeconfig_path}" ]; then
        echo "✅ Kubeconfig created successfully: ${self.triggers.kubeconfig_path}"
        chmod 600 "${self.triggers.kubeconfig_path}"
        echo "🔧 Set context with: kubectl config use-context ${self.triggers.project}"
        echo "🔧 Or use directly: export KUBECONFIG=${self.triggers.kubeconfig_path}"
      else
        echo "❌ Failed to create kubeconfig file"
        exit 1
      fi
    EOT
  }

  # # Clean up kubeconfig on destroy
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = <<-EOT
  #     echo "🧹 Cleaning up kubeconfig: ${self.triggers.kubeconfig_path}"

  #     # Remove the kubeconfig file
  #     if [ -f "${self.triggers.kubeconfig_path}" ]; then
  #       rm -f "${self.triggers.kubeconfig_path}"
  #       echo "✅ Kubeconfig removed: ${self.triggers.kubeconfig_path}"
  #     else
  #       echo "ℹ️  Kubeconfig file not found: ${self.triggers.kubeconfig_path}"
  #     fi
  #   EOT
  # }

  # depends_on = [aws_eks_cluster.eks_auto]
}

########################################################################################################################
# Variables and Data Sources
########################################################################################################################
locals {
  kubeconfig_path = pathexpand("~/.kube/${var.project}.ktx")
}
