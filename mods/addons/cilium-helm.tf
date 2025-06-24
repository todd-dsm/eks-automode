# ########################################################################################################################
# # Cilium CNI Installation via Helm
# # VER: https://github.com/cilium/cilium/releases
# # HELM: https://github.com/cilium/cilium/tree/main/install/kubernetes/cilium
# # DOCS: https://docs.cilium.io/en/stable/installation/k8s-install-helm/
# ########################################################################################################################
# # Cilium Helm Release
# resource "helm_release" "cilium" {
#   name       = "cilium"
#   repository = "https://helm.cilium.io/"
#   chart      = "cilium"
#   version    = "1.17.5"
#   namespace  = "kube-system"

#   # Use pre-existing values file
#   values = [
#     file("${path.root}/addons/cilium/values.yaml")
#   ]

#   set = [
#     # Additional values for environment-specific overrides
#     {
#       name  = "cluster.name"
#       value = var.project
#     },

#     {
#       name  = "cluster.id"
#       value = "1" # Unique cluster ID for mesh scenarios
#     },

#     # IRSA annotations for Cilium service account
#     {
#       name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#       value = module.cilium_irsa.iam_role_arn
#     },

#     # IRSA annotations for Cilium operator service account
#     {
#       name  = "operatorServiceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#       value = module.cilium_irsa.iam_role_arn
#     },

#     # EKS-specific node selector for system workloads
#     {
#       name  = "nodeSelector.kubernetes\\.io/os"
#       value = "linux"
#     },
#   ]

#   # Wait for deployment to be ready
#   wait          = true
#   wait_for_jobs = true
#   timeout       = 600 # 10 minutes

#   # Lifecycle management
#   create_namespace = false # kube-system already exists
#   replace          = false
#   force_update     = false

#   # Dependencies - ensure IRSA role and EKS cluster are ready
#   depends_on = [
#     module.cilium_irsa,
#     # Add your EKS cluster resource reference here
#     # Example: module.eks_cluster
#   ]

#   # Cleanup on destroy
#   cleanup_on_fail = true

#   # Ignore changes to values that Cilium might modify
#   lifecycle {
#     ignore_changes  = [set] # values
#     prevent_destroy = false
#   }
# }
