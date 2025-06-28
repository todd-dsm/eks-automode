# Istio Gateway Architecture for EKS Auto Mode

This document describes the modern Istio Gateway implementation using the Kubernetes Gateway API for traffic ingress in EKS Auto Mode clusters.

## Traffic Flow Architecture

```shell
Internet Traffic Flow (HTTPS: stage.ptest.us)
┌─────────────────────────────────────────────────────────────────────────────┐
│                                EXTERNAL                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Route53 DNS                                      │
│  stage.ptest.us → k8s-istiosys-gitopsde-xxx.elb.us-east-1.amazonaws.com     │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       AWS Network Load Balancer                             │
│  • TLS Termination (ACM Certificate)                                        │
│  • Cross-Zone Load Balancing                                                │
│  • Health Checks: /healthz/ready:15021                                      │
│  • Ports: 80 (HTTP), 443 (HTTPS)                                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼ (Plain HTTP after TLS termination)
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Kubernetes Service                                │
│  Name: gitops-demo-stage-gateway-istio                                      │
│  Type: LoadBalancer                                                         │
│  Selector: istio=ingress, app=istio-gateway                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Istio Gateway Deployment                             │
│  Name: gitops-demo-stage-gateway-istio                                      │
│  Namespace: istio-system                                                    │
│  • Envoy Proxy Pods                                                         │
│  • Listens on: 8080 (HTTP), 8443 (HTTPS)                                    │
│  • Managed by: Istio Gateway Controller                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Gateway API Resources                            │
│  • GatewayClass: istio                                                     │
│  • Gateway: gitops-demo-stage-gateway                                      │
│  • HTTPRoute: HTTPS redirect, health checks, 404 defaults                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Application HTTPRoutes                              │
│  • Route traffic to backend services                                       │
│  • Path-based routing (/api, /app, etc.)                                   │
│  • Header-based routing                                                     │
│  • Traffic policies (retries, timeouts)                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EKS Auto Mode Nodes                                │
│  • Automatic Node Provisioning                                             │
│  • Karpenter-managed Scaling                                               │
│  • Application Pods with Istio Sidecars                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Configuration Differences: EKS vs EKS Auto Mode

### Traditional EKS Configuration

```hcl
# Manual Infrastructure Management
resource "helm_release" "istio_gateway" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-ingress"
  
  # Manual service configuration
  values = [file("gateway-values.yaml")]
}

# Manual Load Balancer Annotations
resource "kubernetes_service" "istio_nlb" {
  metadata {
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      # Manual certificate management
    }
  }
}

# Separate namespace management
resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}
```

### EKS Auto Mode Configuration (Modern Approach)

```hcl
# Automatic Infrastructure via Gateway API
resource "kubernetes_manifest" "project_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      namespace = "istio-system"  # Standard namespace
      annotations = {
        # ACM certificate handled automatically
        "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = aws_acm_certificate.cert.arn
        "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
      }
    }
    spec = {
      gatewayClassName = "istio"
      listeners = [
        {
          name     = "https"
          port     = 443
          protocol = "HTTP"  # Plain HTTP - NLB terminates TLS
          hostname = "stage.ptest.us"
        }
      ]
    }
  }
}

# No manual Helm charts needed - Istio auto-creates:
# - Deployment
# - Service  
# - Pods
# - Load Balancer
```

### Key Differences

| Aspect | Traditional EKS | EKS Auto Mode |
|--------|----------------|---------------|
| **Infrastructure Management** | Manual Helm charts | Automatic via Gateway API |
| **TLS Termination** | Multiple options | ACM at NLB (recommended) |
| **Namespace Strategy** | Custom (`istio-ingress`) | Standard (`istio-system`) |
| **Service Creation** | Manual resource definition | Auto-created by Istio |
| **Load Balancer** | Manual annotations | Gateway annotations |
| **Certificate Management** | Kubernetes secrets | ACM integration |
| **Scaling** | Manual HPA configuration | Auto-managed by EKS |
| **Node Management** | Manual node groups | Automatic with Karpenter |
| **Upgrades** | Manual Helm upgrades | Automatic with EKS |

## Component Architecture

### Gateway API Resources

```yaml
# GatewayClass (defines the controller)
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller

# Gateway (defines listeners and load balancer)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gitops-demo-stage-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    port: 443
    protocol: HTTP
    hostname: stage.ptest.us

# HTTPRoute (defines traffic routing)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-routes
spec:
  parentRefs:
  - name: gitops-demo-stage-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: api-service
      port: 80
```

### Auto-Created Infrastructure

When you deploy a Gateway resource, Istio automatically creates:

```bash
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitops-demo-stage-gateway-istio
  namespace: istio-system
spec:
  replicas: 1
  selector:
    matchLabels:
      istio: ingress
      app: istio-gateway

# Service (with NLB annotations)
apiVersion: v1
kind: Service
metadata:
  name: gitops-demo-stage-gateway-istio
  namespace: istio-system
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:...
spec:
  type: LoadBalancer
  selector:
    istio: ingress
```

## DNS and Certificate Management

### ACM Certificate Integration

```hcl
# Certificate Resource
resource "aws_acm_certificate" "environment_cert" {
  domain_name       = "stage.ptest.us"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.environment_cert.domain_validation_options : 
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  ttl     = 60
}
```

### DNS CNAME Record

```hcl
# Dynamic hostname from Gateway service
resource "null_resource" "get_gateway_hostname" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl get svc -n istio-system -l app=istio-gateway \
        -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}" \
        > /tmp/gateway-hostname.txt
    EOT
  }
}

resource "aws_route53_record" "environment_cname" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "stage.ptest.us"
  type    = "CNAME"
  ttl     = 300
  records = [trimspace(data.local_file.gateway_hostname.content)]
}
```

## Security Considerations

### TLS Configuration

- **TLS Termination**: AWS NLB with ACM certificates
- **Certificate Rotation**: Automatic via ACM
- **Cipher Suites**: AWS-managed security standards
- **HTTPS Redirect**: Configured via HTTPRoute

### Network Security

- **VPC Integration**: Private subnets for nodes
- **Security Groups**: Automatic EKS-managed groups
- **Network Policies**: Istio-based micro-segmentation
- **Service Mesh**: mTLS between services

### Access Control

- **RBAC**: Kubernetes role-based access
- **IRSA**: IAM roles for service accounts
- **Gateway Access**: Controlled via allowedRoutes

## Monitoring and Observability

### Built-in Metrics

- **Gateway Metrics**: Envoy proxy metrics on port 15020
- **Health Checks**: `/healthz/ready` endpoint
- **Traffic Metrics**: Request rates, latency, errors

### Integration Points

```bash
# Prometheus metrics
curl http://gateway-pod:15020/stats/prometheus

# Health status
curl https://stage.ptest.us/healthz

# Istio proxy status
istioctl proxy-status
```

## Future Considerations

### Wildcard Certificate Pattern

When ready to support multiple subdomains (`api.stage.ptest.us`, `grafana.stage.ptest.us`):

```hcl
# Uncomment wildcard certificate sections
domain_name = "*.ptest.us"

# Update Gateway listeners
listeners = [
  {
    name     = "wildcard-https"
    port     = 443 
    protocol = "HTTP"
    hostname = "*.ptest.us"
  }
]
```

### Multi-Environment Strategy

- **Environment Isolation**: Separate Gateways per environment
- **Shared Services**: Cross-environment service communication
- **Certificate Management**: Environment-specific or wildcard strategies
- **DNS Strategy**: Subdomain vs path-based routing

This architecture provides a modern, scalable foundation for ingress traffic management in EKS Auto Mode, leveraging AWS-native services while maintaining the flexibility and power of Istio's service mesh capabilities.