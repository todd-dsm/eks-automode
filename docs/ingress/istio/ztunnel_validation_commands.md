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
kubectl get ds ztunnel -n istio-system

# Expected output (assuming 2 nodes):
# NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR
# ztunnel   2         2         2       2            2           kubernetes.io/os=linux

# If DESIRED=0, no nodes are available (EKS Auto Mode behavior)
```

### 1.2 Verify Pod Status and Logs
```bash
# Check ztunnel pods
kubectl get pods -n istio-system -l app=ztunnel -o wide

# Check logs for successful startup
kubectl logs -n istio-system -l app=ztunnel --tail=20

# Look for these success indicators:
# - "shared proxy mode - in-pod mode enabled"
# - "listener established address=:15020 component=stats"
# - "listener established address=:15021 component=readiness"
```

### 1.3 Verify XDS Connection to Istiod
```bash
# Check ztunnel can connect to istiod
kubectl logs -n istio-system -l app=ztunnel | grep -i xds

# Success indicators:
# ✅ No "XDS client connection error" messages
# ✅ See "xds client connected" or similar

# Failure indicators:
# ❌ "ztunnel requires PILOT_ENABLE_AMBIENT=true"
# ❌ "gRPC connection error connecting to https://istiod.istio-system.svc:15012"
```

## 📋 Phase 2: Ztunnel Functionality Validation

### 2.1 Health Check Endpoints
```bash
# Test ztunnel health endpoints
kubectl exec -n istio-system daemonset/ztunnel -- \
  curl -s http://localhost:15020/healthz/ready

# Should return: "OK"

kubectl exec -n istio-system daemonset/ztunnel -- \
  curl -s http://localhost:15021/healthz/ready

# Should return readiness status
```

### 2.2 Verify Ztunnel Configuration Reception
```bash
# Check ztunnel received workload configuration
istioctl experimental ztunnel-config workload

# Should show discovered workloads when pods are in ambient mode
# If empty, no ambient workloads exist yet (expected at this stage)
```

### 2.3 Verify Network Listeners
```bash
# Check ztunnel listening ports
kubectl exec -n istio-system daemonset/ztunnel -- netstat -tlnp

# Expected listeners:
# 127.0.0.1:15000  (admin interface)
# :15001           (inbound traffic)
# :15006           (inbound traffic)  
# :15008           (HBONE tunnel)
# :15020           (stats)
# :15021           (readiness)
```

## 📋 Phase 3: Ambient Mode Traffic Interception Validation

### 3.1 Deploy Test Application in Ambient Mode
```bash
# Create test namespace with ambient labeling
kubectl create namespace ambient-test
kubectl label namespace ambient-test istio.io/dataplane-mode=ambient

# Deploy test workload
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: ambient-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
      - name: httpbin
        image: kennethreitz/httpbin:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: ambient-test
spec:
  selector:
    app: httpbin
  ports:
  - port: 8000
    targetPort: 80
EOF

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=httpbin -n ambient-test --timeout=120s
```

### 3.2 Verify Ambient Mode Integration
```bash
# Check ztunnel discovered the ambient workload
istioctl experimental ztunnel-config workload -n ambient-test

# Should show httpbin workload with ambient mode enabled

# Check ztunnel logs for workload addition
kubectl logs -n istio-system -l app=ztunnel | grep -i httpbin

# Look for logs about adding workload to mesh
```

### 3.3 Test Traffic Interception
```bash
# Deploy client in same namespace
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
  namespace: ambient-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: curlimages/curl:latest
        command: ["/bin/sleep", "3600"]
EOF

kubectl wait --for=condition=ready pod -l app=sleep -n ambient-test --timeout=120s

# Test internal communication (should be mTLS via ztunnel)
kubectl exec -n ambient-test deployment/sleep -- \
  curl -s http://httpbin:8000/get

# Should succeed and return JSON response
```

### 3.4 Verify mTLS Traffic in Ztunnel
```bash
# Check ztunnel access logs for the traffic
kubectl logs -n istio-system -l app=ztunnel | grep -i "access\|connection"

# Look for logs indicating traffic processing:
# - "connection complete" entries
# - Successful proxy operations
```

## 📋 Phase 4: Advanced Ztunnel Validation

### 4.1 Metrics and Observability
```bash
# Check ztunnel metrics endpoint
kubectl exec -n istio-system daemonset/ztunnel -- \
  curl -s http://localhost:15020/stats/prometheus | head -20

# Verify key metrics are present:
# - istio_tcp_connections_opened_total
# - istio_tcp_connections_closed_total
# - istio_tcp_sent_bytes_total
# - istio_tcp_received_bytes_total
```

### 4.2 Admin Interface Inspection
```bash
# Access ztunnel admin interface
kubectl exec -n istio-system daemonset/ztunnel -- \
  curl -s http://localhost:15000/

# Check workload status
kubectl exec -n istio-system daemonset/ztunnel -- \
  curl -s http://localhost:15000/workloads

# Should show registered ambient workloads
```

### 4.3 Validate Certificate Management
```bash
# Check ztunnel certificate status
kubectl exec -n istio-system daemonset/ztunnel -- \
  curl -s http://localhost:15000/certs

# Should show valid certificates for workload identities
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
kubectl describe pod -n istio-system -l app=ztunnel
# Look for security context denials in events
```

### Issue: XDS connection failures to istiod
```bash
# Check istiod is running and has PILOT_ENABLE_AMBIENT=true
kubectl logs -n istio-system -l app=istiod | grep PILOT_ENABLE_AMBIENT

# Verify network connectivity
kubectl exec -n istio-system daemonset/ztunnel -- \
  nc -zv istiod.istio-system.svc 15012
```

### Issue: No workloads visible in ztunnel
```bash
# Verify namespace labeling
kubectl get ns ambient-test --show-labels | grep istio.io/dataplane-mode

# Check CNI is properly configured
kubectl get pods -n istio-system -l k8s-app=istio-cni-node
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