# Ztunnel Validation Commands for EKS Auto Mode

## 🎯 Pre-Validation: Ensure Nodes Exist

```bash
# EKS Auto Mode specific: Ensure nodes are available
kubectl get nodes
# Should show at least 1 node before ztunnel can be scheduled

# If no nodes, deploy a trigger workload first
kubectl create deployment node-trigger --image=busybox:1.35 -- sleep 3600
```

## 📋 Phase 1: Basic Ztunnel Deployment Validation

### 1.1 Verify DaemonSet Status

```bash
# Check ztunnel DaemonSet
kubectl -n istio-system get ds ztunnel

# Expected output (assuming 2 nodes):
# NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR
# ztunnel   2         2         2       2            2           kubernetes.io/os=linux

# If DESIRED=0, no nodes are available (EKS Auto Mode behavior)
```

### 1.2 Verify Pod Status and Logs

```bash
# Check ztunnel pods
kubectl -n istio-system get pods -l app=ztunnel -o wide

# Check logs for successful startup
kubectl -n istio-system logs -l app=ztunnel --tail=20

# Look for these success indicators:
# - "shared proxy mode - in-pod mode enabled"
# - "listener established address=:15020 component=stats"
# - "listener established address=:15021 component=readiness"
```

### 1.3 Verify XDS Connection to Istiod

```bash
# Check ztunnel can connect to istiod
kubectl -n istio-system logs -l app=ztunnel | grep -i xds

# Success indicators:
# ✅ No "XDS client connection error" messages
# ✅ See "xds client connected" or similar

# Failure indicators:
# ❌ "ztunnel requires PILOT_ENABLE_AMBIENT=true"
# ❌ "gRPC connection error connecting to https://istiod.istio-system.svc:15012"
```

## 📋 Phase 2: Ztunnel Functionality Validation

### 2.2 Verify Ztunnel Configuration Reception

```bash
# Check ztunnel received workload configuration
istioctl experimental ztunnel-config workload

# Should show discovered workloads when pods are in ambient mode
# If empty, no ambient workloads exist yet (expected at this stage)
```

## 📋 Phase 3: Ambient Mode Traffic Interception Validation

### 3.1 Deploy Test Application in Ambient Mode

```bash
# Deploy test workload
#   * creates and labels the namespace
#   * creates service
kubectl apply -f testing/ambient-test.yaml

# Wait for pod to be ready
kubectl -n ambient-test wait --for=condition=ready pod -l app=httpbin --timeout=120s
```

### 3.2 Verify Ambient Mode Integration

```bash
# Check ztunnel discovered the ambient workload
istioctl -n ambient-test experimental ztunnel-config workload

# Should show httpbin workload with ambient mode enabled
kubectl apply -f testing/ambient-test.yaml

# Check ztunnel logs for workload addition
kubectl -n istio-system logs -l app=ztunnel | grep -i httpbin

# Look for logs about adding workload to mesh
```

### 3.3 Test Traffic Interception

```bash
# Deploy client in same namespace

kubectl apply -f testing/traffic-interception.yaml

kubectl -n ambient-test wait --for=condition=ready pod -l app=sleep  --timeout=120s

FIXME
```

### 3.4 Verify mTLS Traffic in Ztunnel

```bash
# Check ztunnel access logs for the traffic
kubectl -n istio-system logs -l app=ztunnel | grep -i "access\|connection"

# Look for logs indicating traffic processing:
# - "connection complete" entries
# - Successful proxy operations
```

## 🛠️ EKS Auto Mode Specific Validation

### Check Node Readiness for Ztunnel

```bash
# Verify nodes are properly labeled and ready
kubectl get nodes -o wide --show-labels | grep kubernetes.io/os=linux

# Check node conditions
kubectl describe nodes | grep -A 5 "Conditions:"

# Ensure no taints that prevent ztunnel scheduling
kubectl describe nodes | grep -A 5 "Taints:"
```

### Validate EKS Auto Mode Compatibility

```bash
# Check if running on EKS Auto Mode
kubectl get nodes -o jsonpath='{.items[*].metadata.labels}' | grep -o 'eks.amazonaws.com[^"]*'

# Verify no conflicts with EKS managed components
kubectl get pods -n kube-system | grep -E "(aws-node|kube-proxy|coredns)"
```

## ❌ Common Issues & Solutions

### Issue: Ztunnel pods crash with permission errors

```bash
# Solution: Verify securityContext and capabilities
kubectl -n istio-system describe pod -l app=ztunnel
# Look for security context denials in events
```

### Issue: XDS connection failures to istiod

```bash
# Check istiod is running and has PILOT_ENABLE_AMBIENT=true
kubectl -n istio-system logs -l app=istiod | grep PILOT_ENABLE_AMBIENT
```

### Issue: No workloads visible in ztunnel

```bash
# Verify namespace labeling
kubectl get -n ambient-test --show-labels | grep istio.io/dataplane-mode

# Check CNI is properly configured
kubectl -n istio-system get pods -l k8s-app=istio-cni-node
```

## 🎯 Success Criteria

- ✅ Ztunnel DaemonSet shows DESIRED=CURRENT=READY
- ✅ All ztunnel pods are Running and Ready
- ✅ No XDS connection errors in logs  
- ✅ Health endpoints return "OK"
- ✅ Ambient workloads appear in `istioctl ztunnel-config workload`
- ✅ Traffic flows between ambient workloads
- ✅ Access logs show encrypted traffic processing

When all criteria are met, ztunnel is successfully deployed and ambient mode is functional!
