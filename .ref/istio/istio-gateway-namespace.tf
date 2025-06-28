########################################################################################################################
# Istio Ingress Namespace
# Must be created and labeled properly for the Istio ingress gateway to work
########################################################################################################################
resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
    labels = {
      name                           = "istio-ingress"
      "istio-injection"              = "enabled"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "istio"
    }
  }
}
