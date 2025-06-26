########################################################################################################################
# Traefik IRSA for AWS Load Balancer Integration
# VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/examples/iam-role-for-service-accounts-eks
########################################################################################################################
module "traefik_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "${var.project}-traefik-"

  # Traefik needs AWS permissions for NLB/ALB integration
  role_policy_arns = {
    policy = aws_iam_policy.traefik_aws_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["traefik:traefik"]
    }
  }

  tags = var.tags
}

########################################################################################################################
# Custom IAM Policy for Traefik AWS Integration
########################################################################################################################
resource "aws_iam_policy" "traefik_aws_policy" {
  name_prefix = "${var.project}-traefik-"
  description = "IAM policy for Traefik AWS integration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TraefikELBAccess"
        Effect = "Allow"
        Action = [
          # ELB permissions for service type LoadBalancer
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",

          # EC2 permissions for NLB/ALB
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",

          # Route53 permissions for external-dns integration (optional)
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
      {
        Sid    = "TraefikRoute53RecordAccess"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
        Condition = {
          StringEquals = {
            "route53:ChangeAction" = ["UPSERT", "DELETE"]
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.project}-traefik-policy"
    Module    = "networking"
    Component = "traefik"
  })
}
