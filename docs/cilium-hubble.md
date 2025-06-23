# Cilium CNI Installation

Cilium v1.17.5 is installed as the primary CNI for the EKS cluster, providing advanced networking, security, and observability features.

## Architecture

```shell
EKS Cluster
├── Cilium Agent (DaemonSet)
├── Cilium Operator (Deployment)
├── Hubble Relay (Deployment)
└── Hubble UI (Deployment)
```

## Files

| File | Purpose |
|------|---------|
| `addons/cilium/values.yaml` | Helm values configuration |
| `addons/cilium/network-policies.yaml` | Optional network policies |
| `cilium.tf` | Terraform Helm release |
| `cilium-irsa.tf` | IAM Role for Service Accounts |
| `provider-helm.tf` | Helm provider configuration |
| `cilium-outputs.tf` | Deployment outputs |

## Features Enabled

### Core CNI Features
- **ENI Mode**: AWS-native IP address management
- **Kube-proxy Replacement**: eBPF-based load balancing
- **Native Routing**: Optimized for AWS VPC routing
- **Network Policies**: L3/L4 and L7 traffic filtering

### Observability (Hubble)
- **Flow Monitoring**: Real-time network traffic visibility
- **Service Map**: Automatic service dependency mapping
- **Metrics**: Prometheus-compatible metrics
- **UI Dashboard**: Web-based traffic visualization

### Security
- **Identity-based Security**: Workload identity enforcement
- **Encryption**: Optional cluster-wide encryption
- **Network Policies**: Fine-grained traffic control
- **IRSA Integration**: AWS IAM roles for secure API access

### AWS Integration (IRSA)
- **ENI Management**: Automatic network interface provisioning
- **IP Address Management**: Dynamic IP allocation/deallocation
- **Route Table Updates**: Native VPC routing optimization
- **Security Group Integration**: Automatic security group management

## Deployment

### Prerequisites

1. EKS cluster must be running
2. Worker nodes must be available
3. kube-system namespace exists
4. VPC and subnet information available for IRSA policy conditions

### AWS Permissions (IRSA)

Cilium requires AWS API permissions for ENI management. The included IRSA configuration provides:

**ENI Management Permissions:**
- Create, attach, detach, and delete network interfaces
- Modify network interface attributes
- Tag management for lifecycle automation

**Discovery Permissions:**
- Describe instances, subnets, VPCs, and security groups
- List available IP addresses and network resources

**Route Management Permissions:**
- Create and manage routes for native VPC routing
- Optimize traffic paths within the VPC

The IRSA role is automatically applied to Cilium service accounts via Helm annotations.

### Install

```shell
# Ensure providers are available
terraform init

# Plan the deployment
terraform plan -target=helm_release.cilium

# Apply Cilium installation
terraform apply -target=helm_release.cilium

# Optionally apply network policies
kubectl apply -f addons/cilium/network-policies.yaml
```

### Verify Installation

```shell
# Check Helm release
helm list -n kube-system

# Check pod status
kubectl get pods -n kube-system -l k8s-app=cilium

# Check Cilium status (requires cilium CLI)
cilium status --wait
```

## Accessing Hubble UI

### Method 1: Port Forward (Development)

```shell
kubectl port-forward -n kube-system svc/hubble-ui 12000:8080
# Open http://localhost:12000
```

### Method 2: LoadBalancer Service (Production)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hubble-ui-loadbalancer
  namespace: kube-system
spec:
  type: LoadBalancer
  selector:
    k8s-app: hubble-ui
  ports:
  - port: 80
    targetPort: 8081
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
```

### Method 3: Ingress (Production)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hubble-ui-ingress
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/scheme: "internal"
spec:
  rules:
  - host: hubble.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hubble-ui
            port:
              number: 80
```

## Network Policies

### Apply Pre-configured Policies

```shell
# Apply the provided network policies
kubectl apply -f addons/cilium/network-policies.yaml
```

### Enable Default Deny (Recommended)

The provided policies file includes a default deny-all ingress policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### Custom Policies

Edit `addons/cilium/network-policies.yaml` to add your own policies, or create new files:

```shell
# Apply custom policies
kubectl apply -f my-custom-policies.yaml
```

## Monitoring Integration

### Prometheus ServiceMonitor

Enable in `values.yaml`:

```yaml
prometheus:
  serviceMonitor:
    enabled: true
    labels:
      release: prometheus  # Match your Prometheus operator
```

### Grafana Dashboards

Cilium provides pre-built Grafana dashboards:

1. **Cilium Metrics**: General CNI metrics
2. **Cilium Operator**: Operator-specific metrics  
3. **Hubble**: Network flow metrics

Dashboard IDs:
- Cilium Metrics: `7457`
- Cilium Operator: `7456`
- Hubble: `7458`

## Troubleshooting

### Common Issues

#### Cilium Pods Not Starting

```shell
# Check node readiness
kubectl get nodes

# Check pod logs
kubectl logs -n kube-system -l k8s-app=cilium

# Check events
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

#### IRSA Issues

```shell
# Check service account annotations
kubectl get serviceaccount -n kube-system cilium -o yaml
kubectl get serviceaccount -n kube-system cilium-operator -o yaml

# Check if IAM role exists
aws iam get-role --role-name [PROJECT_NAME]-cilium

# Check ENI permissions
kubectl logs -n kube-system -l k8s-app=cilium | grep -i "eni\|permission\|denied"

# Verify OIDC provider
aws eks describe-cluster --name [CLUSTER_NAME] --query 'cluster.identity.oidc'
```

#### Network Connectivity Issues

```shell
# Install Cilium CLI
brew install cilium-cli

# Run connectivity test
cilium connectivity test
```

#### Hubble Not Working

```shell
# Check Hubble relay status
kubectl get pods -n kube-system -l k8s-app=hubble-relay

# Port forward and test
cilium hubble port-forward&
cilium hubble observe --last 10
```

### Debug Commands

```shell
# Check Cilium configuration
kubectl get configmap -n kube-system cilium-config -o yaml

# View Cilium endpoints
kubectl get cep -A

# Check identity allocation
kubectl get ciliumidentities

# View network policies
kubectl get cnp,ccnp -A
```

### Performance Tuning

#### High Traffic Environments

Update `addons/cilium/values.yaml`:

```yaml
resources:
  limits:
    cpu: 8000m
    memory: 8Gi
  requests:
    cpu: 2000m
    memory: 2Gi

# Enable bandwidth manager
bandwidthManager:
  enabled: true
  bbr: true

# Tune connection tracking
config:
  conntrackGCInterval: "30s"
```

#### Memory Optimization

```yaml
# Reduce Hubble buffer size for lower memory usage
hubble:
  eventQueueSize: 1000
  flowBufferSize: 100

# Disable unnecessary features
monitor:
  enabled: false
```

## Configuration Updates

### Updating Values

1. Modify `addons/cilium/values.yaml`
2. Run `terraform plan` to preview changes
3. Apply with `terraform apply`

### Upgrading Cilium

1. Update chart version in `cilium.tf`
2. Check [upgrade notes]
3. Apply changes: `terraform apply`

### Production Hardening

```yaml
# Enable encryption
encryption:
  enabled: true
  type: "wireguard"

# Disable debug features
debug:
  enabled: false

# Enable strict mode
kubeProxyReplacement: "strict"

# Restrict API access
apiserver:
  enabled: true
  serviceType: "ClusterIP"  # Don't expose externally
```

### Network Segmentation

```yaml
# Enable L7 proxy for HTTP/gRPC policies
l7Proxy: true

# Enable DNS policies
dnsPolicyUnloadOnShutdown: false
```

## References

- [Cilium Documentation](https://docs.cilium.io/)
- [EKS CNI Comparison](https://aws.amazon.com/blogs/containers/amazon-eks-networking-options/)
- [Upgrade Notes](https://docs.cilium.io/en/stable/operations/upgrade/)
## Security Considerations
- [Hubble Documentation](https://docs.cilium.io/en/stable/gettingstarted/hubble/)
- [Network Policy Recipes](https://github.com/cilium/cilium/tree/master/examples/policies)
