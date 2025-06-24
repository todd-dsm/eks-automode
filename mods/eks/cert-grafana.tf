########################################################################################################################
# Grafana Certificate
########################################################################################################################
module "acm_grafana" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0.0"

  domain_name = "grafana.${var.dns_zone}"
  zone_id     = data.aws_route53_zone.selected.zone_id

  subject_alternative_names = [
    "monitoring.${var.dns_zone}",
    "dashboard.${var.dns_zone}",
  ]

  wait_for_validation = true
  validation_method   = "DNS"

  tags = merge(var.tags, {
    Name    = "${var.project}-grafana-cert"
    Module  = "security"
    Type    = "acm-certificate"
    Service = "grafana"
  })
}
