# ACM Certificate Management - Direct Resource Implementation

## Overview

This implementation uses direct Terraform `aws_acm_certificate` resources instead of the `terraform-aws-modules/acm/aws` module due to compatibility issues with AWS Provider v6.0.0. The direct approach provides better reliability and control over certificate lifecycle management.

## Architecture

```text
ACM Certificate Creation Flow:
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ aws_acm_certificate │───▶│ aws_route53_record   │───▶│ aws_acm_certificate │
│ (DNS validation)    │    │ (validation records) │    │ _validation         │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
          │                           │                           │
          ▼                           ▼                           ▼
    Creates cert with          Automatically creates        Waits for DNS
    PENDING_VALIDATION         _acm-challenge CNAME         validation to
    status                     records in Route53          complete
```

## Implementation Files

### Certificate Definitions

| File | Purpose | Certificates Created |
|------|---------|---------------------|
| `mods/eks/cert-base.tf` | Environment-specific certificate | `stage.ptest.us`, `api.stage.ptest.us`, `app.stage.ptest.us` |
| `mods/eks/cert-grafana.tf` | Grafana/monitoring certificate | `grafana.ptest.us`, `monitoring.ptest.us`, `dashboard.ptest.us` |

### Configuration Details

#### Environment Certificate (`cert-base.tf`)

```hcl
# Primary certificate for the environment
resource "aws_acm_certificate" "environment" {
  domain_name = "${var.env_build}.${var.dns_zone}"  # stage.ptest.us
  
  subject_alternative_names = [
    "api.${var.env_build}.${var.dns_zone}",         # api.stage.ptest.us  
    "app.${var.env_build}.${var.dns_zone}",         # app.stage.ptest.us
  ]

  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}
```

#### Grafana Certificate (`cert-grafana.tf`)

```hcl
# Dedicated certificate for monitoring services
resource "aws_acm_certificate" "grafana" {
  domain_name = "grafana.${var.dns_zone}"          # grafana.ptest.us
  
  subject_alternative_names = [
    "monitoring.${var.dns_zone}",                  # monitoring.ptest.us
    "dashboard.${var.dns_zone}",                   # dashboard.ptest.us
  ]

  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}
```

#### Automatic DNS Validation

Both certificates use automatic Route53 DNS validation:

```hcl
# Creates validation records automatically
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
```

## Certificate Management

### Status Monitoring

```bash
# Check all certificate statuses
aws acm list-certificates \
  --query 'CertificateSummaryList[?contains(DomainName, `ptest.us`)].{Domain:DomainName,Status:Status,Expiry:NotAfter}' \
  --output table

# Monitor specific certificates
watch -n 30 'aws acm list-certificates \
  --query "CertificateSummaryList[?contains(DomainName, \`stage.ptest.us\`) || contains(DomainName, \`grafana.ptest.us\`)].{Domain:DomainName,Status:Status}" \
  --output table'
```

### Validation Record Verification

```bash
# Check DNS validation records in Route53
aws route53 list-resource-record-sets \
  --hosted-zone-id ZPEASGC9BUTW5 \
  --query 'ResourceRecordSets[?contains(Name, `_acm-challenge`)]'

# Verify DNS resolution
dig _acm-challenge.stage.ptest.us CNAME
```

### Certificate Details

```bash
# Get certificate ARN from Terraform
terraform output certificate_arn
terraform output grafana_certificate_arn

# Describe certificate details
aws acm describe-certificate --certificate-arn <certificate-arn>
```

## Terraform Operations

### Apply Strategy

Apply certificates in phases to handle dependencies:

```bash
# Phase 1: Create certificates (PENDING_VALIDATION status)
terraform apply \
  -target=aws_acm_certificate.environment \
  -target=aws_acm_certificate.grafana

# Phase 2: Create validation DNS records
terraform apply \
  -target=aws_route53_record.cert_validation \
  -target=aws_route53_record.grafana_cert_validation

# Phase 3: Wait for validation completion
terraform apply \
  -target=aws_acm_certificate_validation.environment \
  -target=aws_acm_certificate_validation.grafana
```

### Complete Apply

```bash
# Apply all certificate resources at once
terraform apply \
  -target=aws_acm_certificate.environment \
  -target=aws_route53_record.cert_validation \
  -target=aws_acm_certificate_validation.environment \
  -target=aws_acm_certificate.grafana \
  -target=aws_route53_record.grafana_cert_validation \
  -target=aws_acm_certificate_validation.grafana
```

## Outputs and Integration

### Available Outputs

```hcl
# Certificate ARNs for use in other resources
output "certificate_arn" {
  value = aws_acm_certificate_validation.environment.certificate_arn
}

output "grafana_certificate_arn" {
  value = aws_acm_certificate_validation.grafana.certificate_arn
}

output "certificate_status" {
  value = aws_acm_certificate.environment.status
}
```

### Usage in Other Resources

```hcl
# Example: ALB Listener with certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.environment.certificate_arn
}

# Example: CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.environment.certificate_arn
    ssl_support_method  = "sni-only"
  }
}
```

## Troubleshooting

### Common Issues

#### Certificate Stuck in PENDING_VALIDATION

```bash
# Check validation records exist
aws route53 list-resource-record-sets \
  --hosted-zone-id ZPEASGC9BUTW5 \
  --query 'ResourceRecordSets[?contains(Name, `_acm-challenge`)]'

# Verify DNS propagation
dig _acm-challenge.stage.ptest.us CNAME
nslookup _acm-challenge.stage.ptest.us
```

#### Validation Timeout

```bash
# Check Route53 zone configuration
terraform console
> data.aws_route53_zone.selected

# Verify zone delegation
dig NS ptest.us
```

#### Certificate Not Found

```bash
# List all certificates
aws acm list-certificates

# Check specific certificate status
aws acm describe-certificate --certificate-arn <arn>
```

### Manual Validation Record Creation

If automatic creation fails:

```bash
# Get validation values
aws acm describe-certificate --certificate-arn <arn> \
  --query 'Certificate.DomainValidationOptions[0]'

# Create record manually in Route53 console or CLI
aws route53 change-resource-record-sets \
  --hosted-zone-id ZPEASGC9BUTW5 \
  --change-batch file://validation-record.json
```

## Security Considerations

### Certificate Rotation

- Certificates auto-renew 60 days before expiration
- Monitor expiration dates with CloudWatch alarms
- Test renewal process in staging environment

### Access Control

```hcl
# IAM policy for certificate management
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:RequestCertificate",
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/ZPEASGC9BUTW5"
    }
  ]
}
```

## Migration from ACM Module

### What Changed

| Aspect | ACM Module | Direct Resources |
|--------|------------|------------------|
| **Resource Names** | `module.eks.module.acm_environment.aws_acm_certificate.this[0]` | `aws_acm_certificate.environment` |
| **State Management** | Module handles state | Direct Terraform state |
| **Validation** | Module-managed | Explicit `aws_acm_certificate_validation` |
| **DNS Records** | Module-created | Explicit `aws_route53_record` resources |
| **Provider Compatibility** | Broken with v6.0.0 | Compatible with all versions |

### Breaking Changes

- Certificate ARN output path changed
- State resource paths changed
- Validation timing is more explicit

### Compatibility Layer

The implementation includes compatibility outputs to minimize breaking changes:

```hcl
# Maintains compatibility with existing references
locals {
  environment_certificate_arn = aws_acm_certificate_validation.environment.certificate_arn
}
```

## Performance and Cost

### Validation Time

- DNS validation typically completes in 2-5 minutes
- Timeout configured for 5 minutes maximum
- Route53 record propagation is usually instant

### Cost Impact

- ACM certificates are free for AWS services
- Route53 queries: ~$0.40 per million queries
- No additional costs compared to module approach

## Best Practices

### Certificate Naming

```hcl
tags = merge(var.tags, {
  Name        = "${var.project}-${var.env_build}-cert"
  Module      = "security"
  Type        = "acm-certificate"
  Environment = var.env_build
  Purpose     = "application-frontend"  # Add purpose for clarity
})
```

### Domain Organization

- Use environment-specific subdomains: `stage.domain.com`, `prod.domain.com`
- Group related services under common certificate SANs
- Separate monitoring/admin interfaces with dedicated certificates

### Lifecycle Management

```hcl
lifecycle {
  create_before_destroy = true
  # Prevent accidental deletion
  prevent_destroy = true  # Enable for production
}
```

## Future Considerations

### Multi-Region Deployment

For CloudFront or multi-region ALBs:

```hcl
# Certificate must be in us-east-1 for CloudFront
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cloudfront" {
  provider    = aws.virginia
  domain_name = var.domain_name
  # ... rest of configuration
}
```

### Wildcard Certificates

Consider wildcard certificates for development environments:

```hcl
resource "aws_acm_certificate" "wildcard" {
  domain_name = "*.${var.env_build}.${var.dns_zone}"
  # Covers all subdomains: api.stage.domain.com, app.stage.domain.com, etc.
}
```

### Certificate Monitoring

Implement CloudWatch alarms for certificate expiration:

```hcl
resource "aws_cloudwatch_metric_alarm" "certificate_expiry" {
  alarm_name        = "acm-certificate-expiry-${var.env_build}"
  alarm_description = "Certificate expiring soon"
  
  metric_name = "DaysToExpiry"
  namespace   = "AWS/CertificateManager"
  statistic   = "Minimum"
  
  dimensions = {
    CertificateArn = aws_acm_certificate.environment.arn
  }
  
  comparison_threshold = "30"  # Alert 30 days before expiry
  threshold           = 30
  evaluation_periods  = 1
  period             = 86400   # Daily check
}
```

---

## Summary

This direct resource implementation provides:

✅ **Reliability**: No module dependencies or compatibility issues  
✅ **Transparency**: Clear resource relationships and state management  
✅ **Control**: Fine-grained control over certificate lifecycle  
✅ **Compatibility**: Works with all AWS provider versions  
✅ **Maintainability**: Easier to debug and modify than module wrapper  

The approach is production-ready and more robust than the original ACM module implementation.