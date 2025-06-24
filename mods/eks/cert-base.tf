########################################################################################################################
# AWS Certificate Manager Route53 DNS validation
# VER: https://github.com/terraform-aws-modules/terraform-aws-acm/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest/examples/complete-dns-validation
# DOC: https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html
# EXs: https://github.com/terraform-aws-modules/terraform-aws-acm/tree/master/examples/complete-dns-validation
# ######################################################################################################################
# Environment-Specific Base Certificate
########################################################################################################################
module "acm_environment" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0.0"

  #domain_name = "${var.env_build}.${var.dns_zone}"
  zone_id = data.aws_route53_zone.selected.zone_id

  # subject_alternative_names = [
  #   "api.${var.env_build}.${var.dns_zone}",
  #   "app.${var.env_build}.${var.dns_zone}",
  # ]

  wait_for_validation = true
  validation_method   = "DNS"

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.env_build}-cert"
    Module      = "security"
    Type        = "acm-certificate"
    Environment = var.env_build
  })
}

########################################################################################################################
# Route53 Zone Data Source for DNS validation
data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}."
  private_zone = var.zone_private
}

# Find a certificate issued by (not imported into) ACM
data "aws_acm_certificate" "amazon_issued" {
  domain      = var.dns_zone
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
