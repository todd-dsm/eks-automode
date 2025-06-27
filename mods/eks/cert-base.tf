########################################################################################################################
# AWS Certificate Manager - Direct Implementation (Provider v6.0.0 Compatible)
# Replaces the problematic ACM module with direct resources
########################################################################################################################

# Create ACM Certificate with DNS validation
resource "aws_acm_certificate" "environment" {
  domain_name = "${var.env_build}.${var.dns_zone}"

  # subject_alternative_names = [
  #   "api.${var.env_build}.${var.dns_zone}",
  #   "app.${var.env_build}.${var.dns_zone}",
  # ]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.env_build}-cert"
    Module      = "security"
    Type        = "acm-certificate"
    Environment = var.env_build
  })
}

# Create Route53 validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.environment.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "environment" {
  certificate_arn         = aws_acm_certificate.environment.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

########################################################################################################################
# Route53 Zone Data Source for DNS validation
########################################################################################################################
data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}."
  private_zone = var.zone_private
}

# Find existing certificates (for reference)
data "aws_acm_certificate" "amazon_issued" {
  domain      = var.dns_zone
  types       = ["AMAZON_ISSUED"]
  most_recent = true

  depends_on = [aws_acm_certificate_validation.environment]
}

########################################################################################################################
# Compatibility outputs (so other modules don't break)
########################################################################################################################
# Output the validated certificate ARN (replaces module output)
output "certificate_arn" {
  description = "ARN of the validated certificate"
  value       = aws_acm_certificate_validation.environment.certificate_arn
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.environment.status
}

# Compatibility output for any references to module.acm_environment.certificate_arn
locals {
  # This allows other code to reference the certificate ARN
  environment_certificate_arn = aws_acm_certificate_validation.environment.certificate_arn
}
