########################################################################################################################
# Phase 3: Ambient Data Plane
# Step  3: Ztunnel - (Node Proxy)
# DOCS: https://istio.io/latest/docs/ambient/install/helm/
########################################################################################################################
resource "helm_release" "ztunnel" {
  name       = "ztunnel"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "ztunnel"
  version    = "1.26.1"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  # Static configuration from values file
  values = [
    file("${path.root}/addons/istio/values-ztunnel.yaml")
  ]

  #   # Dynamic Terraform-managed values
  #   set = [
  #     {
  #       name  = "global.istioNamespace"
  #       value = kubernetes_namespace.istio_system.metadata[0].name
  #     },
  #   ]

  # Installation settings
  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  create_namespace  = false
  dependency_update = true

  # Lifecycle management
  atomic          = true
  cleanup_on_fail = true
  replace         = false

  depends_on = [
    helm_release.istiod
  ]

  lifecycle {
    ignore_changes  = [values]
    prevent_destroy = false
  }
}
