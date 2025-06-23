########################################################################################################################
# Third-Party Addons: aws-load-balancer-controller
########################################################################################################################
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  # version    = "1.8.1" # Specify version for Stability in Production

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.aws_load_balancer_controller_irsa.iam_role_arn
    },

    # Enable NLB support (this controller handles both ALB and NLB)
    {
      name  = "enableServiceMutatorWebhook"
      value = "true" # Required for NLB service annotations
    },
    # # Default ingress class (for ALB when needed)
    # {
    #   name  = "defaultIngressClass"
    #   value = "alb"
    # },
  ]

  lifecycle {
    ignore_changes  = [set, values]
    prevent_destroy = false
  }

  # Add timeout and wait configurations
  # timeout       = 600 # 10 minutes (default: 300 seconds)
  wait          = true # Wait for all resources to be ready
  wait_for_jobs = true # Wait for jobs to complete

  # Additional reliability settings
  atomic          = true # Rollback on failure
  cleanup_on_fail = true # Clean up on failure
}
