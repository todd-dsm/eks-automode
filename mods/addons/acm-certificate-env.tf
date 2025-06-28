# ACM Certificate for Environment-Specific Domain
resource "aws_acm_certificate" "environment_cert" {
  domain_name       = "${var.env_build}.${var.dns_zone}"
  validation_method = "DNS"

  #   subject_alternative_names = [
  #     "*.${var.env_build}.${var.dns_zone}"  # For subdomains like api.stage.ptest.us
  #   ]

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

# DNS Validation Records
resource "aws_route53_record" "environment_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.environment_cert.domain_validation_options : dvo.domain_name => {
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

# Certificate Validation
resource "aws_acm_certificate_validation" "environment_cert" {
  certificate_arn         = aws_acm_certificate.environment_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.environment_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Route53 Zone Data Source
data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}."
  private_zone = false
}

# Environment-specific certificate
data "aws_acm_certificate" "environment_cert" {
  domain      = "${var.env_build}.${var.dns_zone}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
