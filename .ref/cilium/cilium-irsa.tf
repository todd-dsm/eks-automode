# ########################################################################################################################
# # Cilium IRSA (IAM Role for Service Account)
# # Cilium needs AWS API permissions for ENI management in EKS
# # VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# # TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks
# ########################################################################################################################
# # Cilium IRSA Role
# module "cilium_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = ">= 5.48.0"

#   role_name        = "${var.project}-cilium"
#   role_description = "IRSA role for Cilium CNI to manage ENIs and AWS resources"

#   # Cilium service accounts that need AWS permissions
#   oidc_providers = {
#     main = {
#       provider_arn = var.oidc_provider_arn
#       namespace_service_accounts = [
#         "kube-system:cilium",
#         "kube-system:cilium-operator"
#       ]
#     }
#   }

#   # Custom policy for Cilium ENI management
#   role_policy_arns = {
#     cilium_eni_policy = aws_iam_policy.cilium_eni_management.arn
#   }

#   tags = merge(var.tags, {
#     Name      = "${var.project}-cilium-irsa"
#     Module    = "networking"
#     Component = "cilium-irsa"
#   })
# }

# ########################################################################################################################
# # IAM Policy for Cilium ENI Management
# ########################################################################################################################
# resource "aws_iam_policy" "cilium_eni_management" {
#   name_prefix = "${var.project}-cilium-eni-"
#   description = "IAM policy for Cilium to manage ENIs and AWS networking resources"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "CiliumENIManagement"
#         Effect = "Allow"
#         Action = [
#           # ENI Management
#           "ec2:AttachNetworkInterface",
#           "ec2:CreateNetworkInterface",
#           "ec2:DeleteNetworkInterface",
#           "ec2:DetachNetworkInterface",
#           "ec2:ModifyNetworkInterfaceAttribute",
#           "ec2:DescribeNetworkInterfaces",

#           # Instance and Subnet Information
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeVpcs",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DescribeSecurityGroups",

#           # Tagging for ENI Lifecycle Management
#           "ec2:CreateTags",
#           "ec2:DeleteTags",
#           "ec2:DescribeTags"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "CiliumRoutingManagement"
#         Effect = "Allow"
#         Action = [
#           # Route Table Management (for native routing)
#           "ec2:DescribeRouteTables",
#           "ec2:CreateRoute",
#           "ec2:DeleteRoute",
#           "ec2:ReplaceRoute"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "ec2:vpc" = var.vpc_arn
#           }
#         }
#       }
#     ]
#   })

#   tags = merge(var.tags, {
#     Name      = "${var.project}-cilium-eni-policy"
#     Module    = "networking"
#     Component = "cilium-policy"
#   })
# }

# ########################################################################################################################
# # Outputs for Cilium Service Account Annotation
# ########################################################################################################################
# # output "cilium_irsa_role_arn" {
# #   description = "ARN of the Cilium IRSA role"
# #   value       = module.cilium_irsa.iam_role_arn
# # }

# # output "cilium_service_account_annotation" {
# #   description = "Annotation to add to Cilium service accounts"
# #   value = {
# #     "eks.amazonaws.com/role-arn" = module.cilium_irsa.iam_role_arn
# #   }
# # }
