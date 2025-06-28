# Istio Ambient Mode - Careful Deployment & Testing Order

## 🎯 Testing Strategy: Deploy One Component at a Time

For safe testing and troubleshooting, deploy and verify each component before proceeding to the next.

## 📋 Phase 1: Foundation (Gateway API + Base)

### Step 1: Gateway API CRDs

```bash
# Deploy ONLY the Gateway API CRDs first
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# Verify CRDs are ready
kubectl get crd | grep gateway
kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s
```

### Step 2: Istio Base (CRDs)

```bash
# Deploy only istio-base
terraform apply -target=helm_release.istio_base

# Verify base installation
helm list -n istio-system
kubectl get crd | grep istio
kubectl get validatingwebhookconfiguration | grep istio
```

✅ **Stop here if any issues with CRDs or webhooks**

## 📋 Phase 2: Control Plane Foundation

### Step 3: Istio CNI Plugin

```bash
# Deploy CNI (required before istiod in ambient mode)
terraform apply -target=helm_release.istio_cni

# Verify CNI DaemonSet
kubectl -n istio-system get pods -l k8s-app=istio-cni-node
kubectl -n istio-system logs -l k8s-app=istio-cni-node

# Check CNI is ready on all nodes
kubectl get nodes
kubectl -n istio-system get ds istio-cni-node
```

✅ **Critical: CNI must be working before istiod**

### Step 4: Istiod (Control Plane)

```bash
# Deploy control plane
terraform apply -target=helm_release.istiod

# Verify istiod is ready
kubectl -n istio-system get pods -l app=istiod
kubectl -n istio-system logs -l app=istiod

# Check istiod can communicate with API server
istioctl proxy-status
```

✅ **Verify control plane is healthy before data plane**

## 📋 Phase 3: Ambient Data Plane

### Step 5: Ztunnel (Node Proxy)

```bash
# Deploy ztunnel DaemonSet
terraform apply -target=helm_release.ztunnel

# Verify ztunnel on all nodes
kubectl -n istio-system get pods -l app=ztunnel
kubectl -n istio-system     logs -l app=ztunnel

# Check ztunnel can connect to istiod
istioctl experimental ztunnel-config workload
```

✅ **Core ambient functionality ready - test before gateway**

### Step 6: Test Ambient Mode (Before Gateway)

```bash
# Deploy test namespace and app
kubectl apply -f testing/ambient-test.yaml

# Verify ambient mode is working
kubectl get ns ambient-test --show-labels
kubectl -n ambient-test exec deployment/sleep -- curl httpbin:8000/get

# Check ztunnel is managing workloads
istioctl -n ambient-test experimental ztunnel-config workload
```

## 📋 Phase 4: External Traffic (Optional)

```text

                This will be described in istio gateway testing.

```

## ⚠️ Common Issues & Troubleshooting

### After Each Phase, Check:

**Phase 1 Issues:**

```bash
# If CRDs fail to install
kubectl get crd | grep -E "(gateway|istio)"
kubectl describe crd gatewayclasses.gateway.networking.k8s.io
```

**Phase 2 Issues:**

```bash
# If CNI pods crash
kubectl describe pods -n istio-system -l k8s-app=istio-cni-node
kubectl logs -n istio-system -l k8s-app=istio-cni-node --previous
```

**Phase 3 Issues:**

```bash
# If ztunnel can't connect to istiod
kubectl logs -n istio-system -l app=ztunnel | grep -i error
istioctl proxy-status
```

**Phase 4 Issues:**

```bash
# If NLB doesn't get external IP
kubectl -n istio-ingress describe svc istio-ingress
kubectl -n istio-ingress get events --sort-by='.lastTimestamp'
```

## 🎯 Why This Order Matters

1. **Gateway API CRDs** → Required by Istio components
2. **Base CRDs** → Foundation for all Istio resources
3. **CNI Plugin** → Must be ready before istiod in ambient mode
4. **Istiod** → Control plane needs CNI to manage ambient workloads
5. **Ztunnel** → Data plane needs control plane configuration
6. **Gateway** → External access can be added last (optional)

This careful approach lets you isolate and fix issues at each layer!