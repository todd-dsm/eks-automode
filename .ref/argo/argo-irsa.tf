########################################################################################################################
# IRSAs to Support EKS Addons
# VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/examples/iam-role-for-service-accounts-eks
# SPT: https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/examples/iam-role-for-service-accounts-eks
# DOC: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/
# EXs: https://github.com/terraform-aws-modules/terraform-aws-iam/blob/7825816ce6cb6a2838c0978b629868d24358f5aa/README.md
# ######################################################################################################################
# ArgoCD IRSA (for external secrets, if needed)
module "argocd_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "${var.project}-argocd-"

  # Add specific policies as needed for your ArgoCD setup
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["argocd:argocd-server", "argocd:argocd-application-controller"]
    }
  }

  tags = var.tags
}
