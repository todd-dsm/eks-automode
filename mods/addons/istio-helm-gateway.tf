########################################################################################################################
# Istio Ingress Gateway - For External Traffic via AWS NLB
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
    # EKS Auto Mode public subnet IDs for NLB
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-subnets"
      value = join(",", var.subnet_ids_public)
    },
    # Certificate ARN for HTTPS termination
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = var.certificate_arn
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
    kubernetes_namespace.istio_ingress
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
