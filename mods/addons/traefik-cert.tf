########################################################################################################################
# Traefik Certificate - Direct Terraform Resources (avoiding ACM module bug)
# DOC: https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html
########################################################################################################################
# Route53 Zone Data Source for DNS validation
data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}."
  private_zone = false
}

# ACM Certificate Request
resource "aws_acm_certificate" "traefik" {
  domain_name       = "traefik.${var.dns_zone}"
  validation_method = "DNS"

  #   subject_alternative_names = [
  #     "*.${var.env_build}.${var.dns_zone}",
  #     "api.${var.env_build}.${var.dns_zone}",
  #     "dashboard.${var.env_build}.${var.dns_zone}",
  #   ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name    = "${var.project}-traefik-cert"
    Module  = "security"
    Type    = "acm-certificate"
    Service = "traefik"
  })
}

# DNS Validation Records
resource "aws_route53_record" "traefik_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.traefik.domain_validation_options : dvo.domain_name => {
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
resource "aws_acm_certificate_validation" "traefik" {
  certificate_arn         = aws_acm_certificate.traefik.arn
  validation_record_fqdns = [for record in aws_route53_record.traefik_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

########################################################################################################################
# TLS Certificate Secret (from ACM certificate)
########################################################################################################################
resource "kubernetes_secret" "traefik_tls_cert" {
  metadata {
    name      = "traefik-tls-cert"
    namespace = kubernetes_namespace.traefik.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "traefik"
    }
    annotations = {
      # Reference to ACM certificate ARN for NLB
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = aws_acm_certificate.traefik.arn
    }
  }

  type = "kubernetes.io/tls"

  # Placeholder certificate data - actual TLS termination happens at NLB with ACM
  data = {
    "tls.crt" = base64encode("# Certificate managed by AWS ACM")
    "tls.key" = base64encode("# Private key managed by AWS ACM")
  }

  depends_on = [kubernetes_namespace.traefik]
}
