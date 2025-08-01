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
  version    = "36.2.0"

  values = [
    file("${path.root}/addons/traefik/values.yaml")
  ]

  # # Dynamic values for environment-specific overrides
  set = [
    ########################################################################################################################
    # DNS and Domain Configuration
    ########################################################################################################################
    {
      name  = "globalArguments[0]"
      value = "--certificatesresolvers.letsencrypt.acme.email=admin@${var.dns_zone}"
    },
    ########################################################################################################################
    # NLB service configuration with ACM certificate
    ########################################################################################################################
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = aws_acm_certificate_validation.traefik.certificate_arn
    },
    ########################################################################################################################
    # IRSA annotations for Traefik service account
    ########################################################################################################################
    # {
    #   name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    #   value = aws_acm_certificate.traefik.arn
    # },
  ]

  # Helm release configuration
  timeout         = 600
  cleanup_on_fail = true
  wait            = true
  wait_for_jobs   = true

  depends_on = [
    kubernetes_namespace.traefik,
    module.traefik_irsa,
    aws_acm_certificate_validation.traefik
  ]

  # Lifecycle management
  lifecycle {
    #ignore_changes  = [set, values] # Ignore changes to set and values
    prevent_destroy = false
  }
}
########################################################################################################################
# Traefik Service Account (Terraform-managed)
########################################################################################################################
resource "kubernetes_service_account" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.traefik.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn"     = module.traefik_irsa.iam_role_arn
      "meta.helm.sh/release-name"      = "traefik"
      "meta.helm.sh/release-namespace" = kubernetes_namespace.traefik.metadata[0].name
    }
    labels = {
      "app.kubernetes.io/name"       = "traefik"
      "app.kubernetes.io/instance"   = "traefik"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  depends_on = [
    kubernetes_namespace.traefik,
    module.traefik_irsa
  ]
}

########################################################################################################################
# Traefik Namespace
########################################################################################################################
resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"

    labels = {
      name                                 = "traefik"
      "app.kubernetes.io/name"             = "traefik"
      "app.kubernetes.io/instance"         = "traefik"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}
