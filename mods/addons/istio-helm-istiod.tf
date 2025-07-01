########################################################################################################################
# Phase 2: Control Plane Foundation
# Step 2b: Istiod
# DOCS: https://istio.io/latest/docs/ambient/install/helm/
########################################################################################################################
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.26.1"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  # Static configuration from values file
  values = [
    file("${path.root}/addons/istio/values-istiod.yaml")
  ]

  # Dynamic Terraform-managed values
  set = [
    {
      name  = "profile"
      value = "ambient"
    }
  ]

  # Installation settings
  wait              = true
  wait_for_jobs     = true
  timeout           = 900 # Control plane can take longer
  create_namespace  = false
  dependency_update = true

  # Lifecycle management
  atomic          = true
  cleanup_on_fail = true
  replace         = false

  depends_on = [
    helm_release.istio_cni
  ]

  lifecycle {
    prevent_destroy = false
  }
}
