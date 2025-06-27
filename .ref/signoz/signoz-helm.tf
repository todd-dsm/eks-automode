# ########################################################################################################################
# # SigNoz Observability Platform Deployment
# # CHART: https://github.com/SigNoz/charts/tree/main/charts/signoz
# # DOCS: https://signoz.io/docs/install/kubernetes/
# # VERS: https://github.com/SigNoz/charts/releases
# ########################################################################################################################
# resource "helm_release" "signoz" {
#   name       = "signoz"
#   repository = "https://charts.signoz.io"
#   chart      = "signoz"
#   namespace  = kubernetes_namespace.signoz.metadata[0].name
#   version    = "0.84.0" # Latest stable version

#   # Use pre-configured values file
#   values = [
#     file("${path.root}/addons/signoz/values.yaml")
#   ]

#   #   set = [
#   #     ########################################################################################################################
#   #     # Terraform-Referenced Parameters Only
#   #     ########################################################################################################################
#   #     {
#   #       name  = "global.clusterName"
#   #       value = "gitops-demo"
#   #     },
#   #     # {
#   #     #   name  = "clickhouse.cluster.name"
#   #     #   value = "signoz" # may not be more than 15 bytes for ClickHouse
#   #     # }
#   #   ]

#   # Lifecycle management
#   lifecycle {
#     ignore_changes  = [set, values]
#     prevent_destroy = false
#   }

#   ########################################################################################################################
#   # Deployment Configuration
#   ########################################################################################################################
#   timeout       = 1800 # 30 minutes for ClickHouse initialization
#   wait          = true
#   wait_for_jobs = true
#   #atomic            = true
#   cleanup_on_fail   = true
#   skip_crds         = false # SigNoz needs its CRDs
#   disable_crd_hooks = false

#   depends_on = [
#     kubernetes_namespace.signoz,
#     kubernetes_storage_class_v1.signoz_storage,
#     module.signoz_irsa
#   ]
# }

# ########################################################################################################################
# # Verification - Check SigNoz deployment status
# ########################################################################################################################
# # resource "null_resource" "signoz_verification" {
# #   # Verify SigNoz is running properly
# #   provisioner "local-exec" {
# #     command = <<-EOT
# #       echo "🔍 Verifying SigNoz deployment..."

# #       # Wait for pods to be ready
# #       kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=signoz -n signoz --timeout=600s

# #       # Check service status
# #       kubectl get pods,svc -n signoz

# #       echo "✅ SigNoz verification complete"
# #       echo ""
# #       echo "🌐 Access SigNoz UI via port-forward:"
# #       echo "kubectl port-forward -n signoz svc/signoz-frontend 3301:3301"
# #       echo "Then open: http://localhost:3301"
# #     EOT
# #   }

# #   triggers = {
# #     helm_revision = helm_release.signoz.revision
# #   }

# #   depends_on = [helm_release.signoz]
# # }
