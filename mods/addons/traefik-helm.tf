########################################################################################################################
# Traefik Ingress Controller with Gateway API Support
# CHART: https://github.com/traefik/traefik-helm-chart
# DOCS: https://doc.traefik.io/traefik/
# GATEWAY: https://doc.traefik.io/traefik/providers/kubernetes-gateway/
########################################################################################################################
# Traefik Helm Release
########################################################################################################################
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = kubernetes_namespace.traefik.metadata[0].name
  version    = "32.1.1"

  # Use external values file
  values = [
    file("${path.root}/addons/traefik/values.yaml")
  ]

  # Dynamic values for environment-specific overrides
  set = [
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = aws_acm_certificate_validation.traefik.certificate_arn
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.traefik_irsa.iam_role_arn
    },
    {
      name  = "deployment.replicas"
      value = var.traefik_replicas
    },
    {
      name  = "api.dashboard"
      value = var.enable_traefik_dashboard
    }
  ]

  # Helm release configuration
  timeout         = 600
  cleanup_on_fail = true
  wait            = true
  wait_for_jobs   = true

  depends_on = [
    kubernetes_namespace.traefik,
    module.traefik_irsa,
    aws_acm_certificate_validation.traefik,
    null_resource.gateway_api_setup
  ]
}

# Create dedicated namespace for Traefik
resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"

    labels = {
      name                                 = "traefik"
      "app.kubernetes.io/name"             = "traefik"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    }
  }
}
