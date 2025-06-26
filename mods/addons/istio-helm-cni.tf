########################################################################################################################
# Istio CNI - Required for Ambient Mode
# DOCS: https://istio.io/latest/docs/ambient/install/helm/
########################################################################################################################
resource "helm_release" "istio_cni" {
  name       = "istio-cni"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "cni"
  version    = "1.26.1"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  # Static values from file
  values = [
    file("${path.root}/addons/istio/values-cni.yaml")
  ]

  #   # Dynamic Terraform-managed values
  #   set = [
  #     {
  #       name  = "profile"
  #       value = "ambient"
  #     }
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
    helm_release.istio_base
  ]

  lifecycle {
    # ignore_changes  = [values]
    prevent_destroy = false
  }
}
