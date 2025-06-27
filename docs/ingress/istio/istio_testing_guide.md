# Istio Ambient Mode Testing Guide

This guide walks you through testing your Istio Ambient Mode deployment on EKS Auto Mode.

## Prerequisites

- EKS Auto Mode cluster deployed
- Istio Ambient Mode components installed via Terraform
- `kubectl` configured to access your cluster
- `istioctl` CLI tool installed

## Installation Verification

### 1. Check Component Status

```bash
# Verify all Istio pods are running
kubectl get pods -n istio-system
kubectl get pods -n istio-ingress

# Expected output should show:
# istio-system: istiod, istio-cni-node (DaemonSet), ztunnel (DaemonSet)
# istio-ingress: istio-ingress gateway pods
```

### 2. Verify Installation with istioctl

```bash
# Download and install istioctl (if not already installed)
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-1.26.1/bin:$PATH

# Verify the installation
istioctl verify-install

# Check proxy status
istioctl proxy-status
```

### 3. Check Gateway External Endpoint

```bash
# Get the AWS NLB endpoint for Istio Gateway
kubectl get svc istio-ingress -n istio-ingress

# Should show an external LoadBalancer IP/hostname
```

## Deploy Test Application

### 1. Deploy the Example Application

```bash
# Deploy the ambient demo application
kubectl apply -f examples/istio-ambient-demo.yaml

# Verify deployment
kubectl get pods -n ambient-demo
kubectl get svc -n ambient-demo
```

### 2. Verify Ambient Mode is Active

```bash
# Check that the namespace is in ambient mode
kubectl get namespace ambient-demo -o yaml | grep istio.io/dataplane-mode

# Verify Istio system namespaces do NOT have ambient labels (this is correct)
kubectl get ns istio-system istio-ingress --show-labels | grep -v dataplane-mode

# Check ztunnel workload configuration
istioctl experimental ztunnel-config workload -n ambient-demo
```

## Test Layer 4 Security (Ambient Mode Core Feature)

### 1. Test Internal Communication

```bash
# Test communication between services in ambient mode
kubectl exec -n ambient-demo deployment/sleep -- curl -s httpbin:8000/get

# This should work - ambient mode provides automatic mTLS
```

### 2. Test Authorization Policies

```bash
# The deployed AuthorizationPolicy should allow GET requests
kubectl exec -n ambient-demo deployment/sleep -- curl -s httpbin:8000/get

# Try a denied method (should be blocked by the policy)
kubectl exec -n ambient-demo deployment/sleep -- curl -s -X DELETE httpbin:8000/delete
```

### 3. Monitor Traffic with ztunnel

```bash
# Check ztunnel logs to see traffic processing
kubectl logs -n istio-system -l app=ztunnel --tail=50

# Look for traffic between workloads
```

## Test External Access via Gateway

### 1. Configure DNS (if using real domain)

```bash
# Get the NLB hostname
NLB_HOSTNAME=$(kubectl get svc istio-ingress -n istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "NLB Hostname: $NLB_HOSTNAME"

# Create DNS record pointing httpbin.yourdomain.com to $NLB_HOSTNAME
```

### 2. Test External Access

```bash
# Test via port-forward (for quick testing)
kubectl port-forward -n istio-ingress svc/istio-ingress 8080:80

# In another terminal:
curl -H "Host: httpbin.yourdomain.com" http://localhost:8080/get

# Or test directly via NLB (if DNS is configured)
curl http://httpbin.yourdomain.com/get
```

## Layer 7 Features (Waypoint Proxies)

Ambient mode starts with L4 security. For L7 features, you can deploy waypoint proxies:

### 1. Deploy Waypoint Proxy for a Service

```bash
# Create a waypoint proxy for the httpbin service
istioctl waypoint generate --for service httpbin -n ambient-demo | kubectl apply -f -

# Verify waypoint deployment
kubectl get pods -n ambient-demo -l gateway.istio.io/waypoint-for=service
```

### 2. Apply L7 Policies

```yaml
# Example L7 authorization policy (apply after waypoint is running)
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-l7-authz
  namespace: ambient-demo
spec:
  targetRef:
    kind: Service
    name: httpbin
  rules:
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/get", "/headers"]
```

## Monitoring and Observability

### 1. Check Metrics

```bash
# Access istiod metrics
kubectl port-forward -n istio-system svc/istiod 15014:15014

# In another terminal:
curl http://localhost:15014/metrics | grep istio
```

### 2. Analyze Configuration

```bash
# Analyze mesh configuration for issues
istioctl analyze

# Check specific workload configuration
istioctl proxy-config cluster deployment/httpbin.ambient-demo
```

## Troubleshooting

### Common Issues

#### 1. Pods Not in Ambient Mode

```bash
# Check if namespace is labeled correctly
kubectl get namespace ambient-demo --show-labels

# Check ztunnel logs for errors
kubectl logs -n istio-system -l app=ztunnel
```

#### 2. Traffic Not Working

```bash
# Verify CNI installation
kubectl get pods -n istio-system -l k8s-app=istio-cni-node

# Check istiod logs
kubectl logs -n istio-system -l app=istiod
```

#### 3. Gateway Not Accessible

```bash
# Check gateway pod status
kubectl get pods -n istio-ingress

# Verify service annotations for AWS Load Balancer Controller
kubectl get svc istio-ingress -n istio-ingress -o yaml
```

### Debug Commands

```bash
# Get detailed ztunnel configuration
istioctl experimental ztunnel-config all

# Check workload entries
kubectl get workloadentries -A

# Verify gateway configuration
istioctl proxy-config listeners deployment/istio-ingress.istio-ingress
```

## Performance Testing

### Load Testing with Ambient Mode

```bash
# Deploy a load testing tool
kubectl run -i --tty load-test --image=busybox --restart=Never -- sh

# Inside the pod, run load tests
while true; do wget -q -O- http://httpbin.ambient-demo:8000/get; done
```

### Monitor Resource Usage

```bash
# Check ztunnel resource usage
kubectl top pods -n istio-system -l app=ztunnel

# Monitor overall cluster resources
kubectl top nodes
```

## Cleanup

```bash
# Remove test application
kubectl delete namespace ambient-demo

# Istio will be cleaned up when Terraform destroy is run
```

## Next Steps

1. **Production Readiness**: Configure appropriate resource limits and monitoring
2. **Security Policies**: Implement comprehensive authorization policies
3. **Observability**: Integrate with your monitoring stack (Prometheus, Grafana)
4. **Traffic Management**: Implement advanced routing and fault injection
5. **Multi-cluster**: Expand to multi-cluster mesh if needed

## References

- [Istio Ambient Mode Documentation](https://istio.io/latest/docs/ambient/)
- [EKS Best Practices for Istio](https://aws.github.io/aws-eks-best-practices/networking/servicemesh/)
- [Istio Configuration Reference](https://istio.io/latest/docs/reference/config/)