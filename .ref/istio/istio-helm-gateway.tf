########################################################################################################################
# Phase 3: External Traffic (Optional)
# Step  4: Istio Ingress Gateway via AWS Load Balancer Controller
# DOCS: https://istio.io/latest/docs/ambient/install/helm/
########################################################################################################################
resource "helm_release" "istio_ingress_gateway" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.26.1"
  namespace  = kubernetes_namespace.istio_ingress.metadata[0].name

  # Static configuration from values file
  values = [
    file("${path.root}/addons/istio/values-gateway.yaml")
  ]

  # Dynamic Terraform-managed values for AWS NLB integration
  set = [
    # Certificate ARN for HTTPS termination
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = var.certificate_arn
    },
    {
      name  = "podLabels.environment"
      value = var.env_build
    },
    {
      name  = "podLabels.project"
      value = var.project
    }
  ]

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
    helm_release.ztunnel,
  ]

  lifecycle {
    ignore_changes  = [values]
    prevent_destroy = false
  }
}

########################################################################################################################
# Data Sources for Public Subnets (for NLB placement)
########################################################################################################################
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}
