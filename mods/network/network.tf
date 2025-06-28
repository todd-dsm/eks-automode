########################################################################################################################
# VPC Network Resources
# VER: https://github.com/terraform-aws-modules/terraform-aws-vpc/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
# GHR: https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples
########################################################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 6.0.1"

  name            = var.project
  cidr            = var.vpc_cidr
  azs             = var.azs
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 3, k)]
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 3, k + 3)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  create_egress_only_igw = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # IPv6 Support
  # enable_ipv6                                    = true
  # public_subnet_ipv6_prefixes                    = [0, 1, 2]
  # public_subnet_assign_ipv6_address_on_creation  = false
  # private_subnet_ipv6_prefixes                   = [3, 4, 5]
  # private_subnet_assign_ipv6_address_on_creation = false

  # Drop VPC Flow Logs
  enable_flow_log                       = true
  vpc_flow_log_iam_role_name            = "${var.project}-vpc-flow-log"
  vpc_flow_log_iam_role_use_name_prefix = false
  create_flow_log_cloudwatch_log_group  = true
  create_flow_log_cloudwatch_iam_role   = true
  flow_log_max_aggregation_interval     = 60

  # Tag Subnets: Public
  public_subnet_tags = merge(var.tags, {
    Name                     = "${var.project}-public"
    Module                   = "networking"
    "kubernetes.io/role/elb" = 1
  })

  # Tag Subnets: Private
  private_subnet_tags = merge(var.tags, {
    Name                              = "${var.project}-private"
    Module                            = "networking"
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.project
  })

  # Tag VPC
  tags = merge(var.tags, {
    Name                     = "${var.project}-vpc"
    Module                   = "networking"
    "karpenter.sh/discovery" = var.project
  })
}
