# ########################################################################################################################
# # VPC Endpoints for Kubernetes Cost Optimization
# # VER: https://github.com/terraform-aws-modules/terraform-aws-vpc/releases
# # TFR: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest/submodules/vpc-endpoints
# # GHR: https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/vpc-endpoints
# ########################################################################################################################
# module "vpc_endpoints" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = ">= 5.21.0"

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   # Let the module create and manage the security group
#   create_security_group      = true
#   security_group_name        = "${var.project}-vpc-endpoints"
#   security_group_description = "Security group for VPC endpoints - HTTPS only"

#   endpoints = {
#     ################################################################################
#     # Core Kubernetes Infrastructure
#     ################################################################################
#     ec2 = {
#       service             = "ec2"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-ec2"
#         Service = "EC2 API (Karpenter auto-scaling)"
#         Tier    = "Core Infrastructure"
#       }
#     }

#     autoscaling = {
#       service             = "autoscaling"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-autoscaling"
#         Service = "Auto Scaling (Karpenter)"
#         Tier    = "Core Infrastructure"
#       }
#     }

#     sts = {
#       service             = "sts"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-sts"
#         Service = "Security Token Service (IRSA)"
#         Tier    = "Core Infrastructure"
#       }
#     }

#     ################################################################################
#     # Off-cluster Access (Storage, Load Balancing, Container Registry)
#     ################################################################################
#     ebs = {
#       service             = "ebs"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-ebs"
#         Service = "Elastic Block Store (PVs)"
#         Tier    = "Off-cluster Access"
#       }
#     }

#     s3 = {
#       service      = "s3"
#       service_type = "Gateway"
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       # Minimal policy - IRSA handles specific bucket permissions
#       policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#           {
#             Effect    = "Allow"
#             Principal = "*"
#             Action = [
#               "s3:GetBucketLocation",
#               "s3:ListAllMyBuckets"
#             ]
#             Resource = "*"
#           }
#         ]
#       })
#       tags = {
#         Name    = "${var.project}-s3"
#         Service = "S3 Gateway (FREE) - Use IRSA for bucket access"
#         Tier    = "Off-cluster Access"
#       }
#     }

#     elasticloadbalancing = {
#       service             = "elasticloadbalancing"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-elb"
#         Service = "Elastic Load Balancing (Ingress Controllers)"
#         Tier    = "Off-cluster Access"
#       }
#     }

#     ecr_dkr = {
#       service             = "ecr.dkr"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-ecr-dkr"
#         Service = "ECR Docker Registry"
#         Tier    = "Off-cluster Access"
#       }
#     }

#     ecr_api = {
#       service             = "ecr.api"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-ecr-api"
#         Service = "ECR API"
#         Tier    = "Off-cluster Access"
#       }
#     }

#     ################################################################################
#     # Observability & Operations
#     ################################################################################
#     logs = {
#       service             = "logs"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-logs"
#         Service = "CloudWatch Logs"
#         Tier    = "Observability"
#       }
#     }

#     monitoring = {
#       service             = "monitoring"
#       service_type        = "Interface"
#       subnet_ids          = module.vpc.private_subnets
#       private_dns_enabled = true
#       tags = {
#         Name    = "${var.project}-monitoring"
#         Service = "CloudWatch Monitoring"
#         Tier    = "Observability"
#       }
#     }

#     ################################################################################
#     # Additional AWS Services (Enable as needed)
#     ################################################################################
#     # Uncomment these as specific requirements arise
#     # rds = {
#     #   service             = "rds"
#     #   service_type        = "Interface"
#     #   subnet_ids          = module.vpc.private_subnets
#     #   private_dns_enabled = true
#     #   tags = {
#     #     Name    = "${var.project}-rds"
#     #     Service = "RDS (Aurora/PostgreSQL)"
#     #     Tier    = "Additional Services"
#     #   }
#     # }

#     # ssm = {
#     #   service             = "ssm"
#     #   service_type        = "Interface"
#     #   subnet_ids          = module.vpc.private_subnets
#     #   private_dns_enabled = true
#     #   tags = {
#     #     Name    = "${var.project}-ssm"
#     #     Service = "Systems Manager"
#     #     Tier    = "Additional Services"
#     #   }
#     # }

#     # secretsmanager = {
#     #   service             = "secretsmanager"
#     #   service_type        = "Interface"
#     #   subnet_ids          = module.vpc.private_subnets
#     #   private_dns_enabled = true
#     #   tags = {
#     #     Name    = "${var.project}-secrets"
#     #     Service = "Secrets Manager"
#     #     Tier    = "Additional Services"
#     #   }
#     # }
#   }

#   # Global tags for all endpoints
#   tags = merge(var.tags, {
#     Name   = "${var.project}-vpc-endpoints"
#     Module = "networking"
#     Type   = "vpc-endpoints"
#   })

#   # Timeouts for endpoint operations
#   timeouts = {
#     create = "10m"
#     update = "10m"
#     delete = "10m"
#   }
# }