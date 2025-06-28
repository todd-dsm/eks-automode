########################################################################################################################
# SigNoz IRSA (IAM Role for Service Account)
# Provides AWS permissions for SigNoz components to access AWS services
# VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks
########################################################################################################################
module "signoz_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5.0"

  role_name_prefix = "${var.project}-signoz-"
  role_description = "IRSA role for SigNoz observability platform"

  # SigNoz service accounts that need AWS permissions
  # Note: Let Helm chart create service accounts, we'll annotate them
  oidc_providers = {
    main = {
      provider_arn = var.oidc_provider_arn
      namespace_service_accounts = [
        "signoz:signoz" # Main service account created by Helm chart
      ]
    }
  }

  # AWS managed policies for observability
  role_policy_arns = {
    cloudwatch_agent = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    xray_daemon      = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
    custom_policy    = aws_iam_policy.signoz_observability.arn
  }

  tags = merge(var.tags, {
    Name      = "${var.project}-signoz-irsa"
    Module    = "observability"
    Component = "signoz-irsa"
  })
}

########################################################################################################################
# Custom IAM Policy for SigNoz AWS Integrations
########################################################################################################################
resource "aws_iam_policy" "signoz_observability" {
  name_prefix = "${var.project}-signoz-"
  description = "Custom policy for SigNoz to access AWS observability services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SigNozCloudWatchAccess"
        Effect = "Allow"
        Action = [
          # CloudWatch Logs
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",

          # CloudWatch Metrics
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",

          # CloudWatch Events
          "events:PutEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "SigNozS3Access"
        Effect = "Allow"
        Action = [
          # S3 for long-term storage and backups
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project}-signoz-*",
          "arn:aws:s3:::${var.project}-signoz-*/*"
        ]
      },
      {
        Sid    = "SigNozEKSAccess"
        Effect = "Allow"
        Action = [
          # EKS cluster information for k8s metrics
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Sid    = "SigNozEC2Access"
        Effect = "Allow"
        Action = [
          # EC2 metadata for infrastructure metrics
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.project}-signoz-policy"
    Module    = "observability"
    Component = "signoz-policy"
  })
}

########################################################################################################################
# Service Account Annotation for IRSA
# Annotate the service account created by Helm chart with IRSA role
########################################################################################################################
# resource "kubernetes_annotations" "signoz_service_account" {
#   api_version = "v1"
#   kind        = "ServiceAccount"

#   metadata {
#     name      = "signoz" # Default service account name from Helm chart
#     namespace = kubernetes_namespace.signoz.metadata[0].name
#   }

#   depends_on = [
#     module.signoz_irsa.iam_role_arn
#   ]
# }
