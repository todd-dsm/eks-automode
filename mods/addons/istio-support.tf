########################################################################################################################
# Required Namespaces
########################################################################################################################
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      name                           = "istio-system"
      "istio-injection"              = "disabled"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "istio"
    }
  }
}
