########################################################################################################################
# Discovered Variables: Global
########################################################################################################################
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_availability_zones" "available" {}

data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}."
  private_zone = var.zone_private
}

locals {
  region          = var.region
  cluster_version = "1.29"
  # Networking
  vpc_cidr      = var.vpc_cidr
  cni_ip_family = "ipv4"
  azs           = slice(data.aws_availability_zones.available.names, 0, 3)

  builder    = regex("arn:${local.part}:iam::\\d+:user/(.*)", data.aws_caller_identity.current.arn)[0]
  user_arn   = split("/", data.aws_caller_identity.current.arn)[0]
  acct_no    = data.aws_caller_identity.current.account_id
  part       = data.aws_partition.current.partition
  dns_suffix = data.aws_partition.current.dns_suffix

  tags = {
    project     = var.project
    environment = var.env_build
    builder     = local.builder
  }
}
