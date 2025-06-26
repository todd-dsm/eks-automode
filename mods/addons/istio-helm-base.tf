########################################################################################################################
# Istio Base - CRDs and Base Resources
# HELM: https://istio.io/latest/docs/ambient/install/helm/
# REPO: https://istio.io/latest/docs/setup/install/helm/
########################################################################################################################
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.26.1" # Latest stable version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  # No dynamic values needed for base chart - all config in values.yaml
  values = [
    file("${path.root}/addons/istio/values-base.yaml")
  ]

  # Critical settings for base chart
  set = [
    {
      name  = "global.istioNamespace"
      value = kubernetes_namespace.istio_system.metadata[0].name
    }
  ]

  # Installation settings
  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  create_namespace  = false # Namespace created separately
  dependency_update = true

  # Lifecycle management
  atomic          = true
  cleanup_on_fail = true
  replace         = false

  depends_on = [
    kubernetes_namespace.istio_system
  ]

  lifecycle {
    # ignore_changes  = [values]
    prevent_destroy = false
  }
}
