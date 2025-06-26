# ########################################################################################################################
# # Grafana Certificate - Direct Implementation (Provider v6.0.0 Compatible)
# ########################################################################################################################
# resource "aws_acm_certificate" "grafana" {
#   domain_name = "grafana.${var.dns_zone}"

#   # subject_alternative_names = [
#   #   "monitoring.${var.dns_zone}",
#   #   "dashboard.${var.dns_zone}",
#   # ]

#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = merge(var.tags, {
#     Name    = "${var.project}-grafana-cert"
#     Module  = "security"
#     Type    = "acm-certificate"
#     Service = "grafana"
#   })
# }

# # Create Route53 validation records for Grafana certificate
# resource "aws_route53_record" "grafana_cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.grafana.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.selected.zone_id
# }

# # Wait for Grafana certificate validation
# resource "aws_acm_certificate_validation" "grafana" {
#   certificate_arn         = aws_acm_certificate.grafana.arn
#   validation_record_fqdns = [for record in aws_route53_record.grafana_cert_validation : record.fqdn]

#   timeouts {
#     create = "5m"
#   }
# }

# ########################################################################################################################
# # Outputs for compatibility
# ########################################################################################################################
# output "grafana_certificate_arn" {
#   description = "ARN of the validated Grafana certificate"
#   value       = aws_acm_certificate_validation.grafana.certificate_arn
# }
