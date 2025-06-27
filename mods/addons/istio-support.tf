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
