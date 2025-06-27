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

**✅ Stop here if any issues with CRDs or webhooks**

## 📋 Phase 2: Control Plane Foundation

### Step 3: Istio CNI Plugin  
```bash
# Deploy CNI (required before istiod in ambient mode)
terraform apply -target=helm_release.istio_cni

# Verify CNI DaemonSet
kubectl get pods -n istio-system -l k8s-app=istio-cni-node
kubectl logs -n istio-system -l k8s-app=istio-cni-node

# Check CNI is ready on all nodes
kubectl get nodes
kubectl get ds istio-cni-node -n istio-system
```

**✅ Critical: CNI must be working before istiod**

### Step 4: Istiod (Control Plane)
```bash
# Deploy control plane
terraform apply -target=helm_release.istiod

# Verify istiod is ready
kubectl get pods -n istio-system -l app=istiod
kubectl logs -n istio-system -l app=istiod

# Check istiod can communicate with API server
istioctl proxy-status
```

**✅ Verify control plane is healthy before data plane**

## 📋 Phase 3: Ambient Data Plane

### Step 5: Ztunnel (Node Proxy)
```bash
# Deploy ztunnel DaemonSet  
terraform apply -target=helm_release.ztunnel

# Verify ztunnel on all nodes
kubectl get pods -n istio-system -l app=ztunnel
kubectl logs -n istio-system -l app=ztunnel

# Check ztunnel can connect to istiod
istioctl experimental ztunnel-config workload
```

**✅ Core ambient functionality ready - test before gateway**

### Step 6: Test Ambient Mode (Before Gateway)
```bash
# Deploy test namespace and app
kubectl apply -f examples/istio-ambient-demo.yaml

# Verify ambient mode is working
kubectl get ns ambient-demo --show-labels
kubectl exec -n ambient-demo deployment/sleep -- curl httpbin:8000/get

# Check ztunnel is managing workloads
istioctl experimental ztunnel-config workload -n ambient-demo
```

## 📋 Phase 4: External Traffic (Optional)

### Step 7: Istio Gateway (Last)
```bash
# Deploy ingress gateway
terraform apply -target=helm_release.istio_ingress_gateway

# Verify gateway and NLB creation
kubectl get pods -n istio-ingress
kubectl get svc istio-ingress -n istio-ingress

# Wait for AWS NLB to be ready (can take 2-3 minutes)
kubectl get svc istio-ingress -n istio-ingress -w
```

### Step 8: Test External Access
```bash
# Get NLB endpoint
NLB_HOSTNAME=$(kubectl get svc istio-ingress -n istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test external access (if HTTPRoute is configured)
curl -H "Host: httpbin.yourdomain.com" http://$NLB_HOSTNAME/get
```

## 🛠️ Makefile Targets for Careful Testing

Add these to your Makefile for step-by-step deployment:

```makefile
# Phase 1: Foundation
istio-base:
	@echo "=== Phase 1: Deploying Istio Base ==="
	terraform apply -target=kubernetes_namespace.istio_system -target=kubernetes_namespace.istio_ingress
	terraform apply -target=null_resource.gateway_api_crds
	terraform apply -target=helm_release.istio_base
	@echo "✅ Phase 1 complete - verify CRDs before proceeding"

# Phase 2: Control Plane
istio-control-plane:
	@echo "=== Phase 2: Deploying Control Plane ==="
	terraform apply -target=helm_release.istio_cni
	@echo "⏳ Waiting for CNI to be ready..."
	kubectl rollout status daemonset/istio-cni-node -n istio-system --timeout=300s
	terraform apply -target=helm_release.istiod
	@echo "✅ Phase 2 complete - control plane ready"

# Phase 3: Data Plane  
istio-data-plane:
	@echo "=== Phase 3: Deploying Ambient Data Plane ==="
	terraform apply -target=helm_release.ztunnel
	@echo "⏳ Waiting for ztunnel to be ready..."
	kubectl rollout status daemonset/ztunnel -n istio-system --timeout=300s
	@echo "✅ Phase 3 complete - ambient mode ready"

# Phase 4: Gateway (Optional)
istio-gateway:
	@echo "=== Phase 4: Deploying Ingress Gateway ==="
	terraform apply -target=helm_release.istio_ingress_gateway
	@echo "⏳ Waiting for gateway and NLB..."
	kubectl rollout status deployment/istio-ingress -n istio-ingress --timeout=300s
	@echo "✅ Phase 4 complete - external access ready"

# Complete workflow
istio-deploy-careful: istio-base istio-control-plane istio-data-plane istio-test istio-gateway
	@echo "🎉 Istio Ambient Mode deployed successfully!"
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
kubectl describe svc istio-ingress -n istio-ingress
kubectl get events -n istio-ingress --sort-by='.lastTimestamp'
```

## 🎯 Why This Order Matters

1. **Gateway API CRDs** → Required by Istio components
2. **Base CRDs** → Foundation for all Istio resources  
3. **CNI Plugin** → Must be ready before istiod in ambient mode
4. **Istiod** → Control plane needs CNI to manage ambient workloads
5. **Ztunnel** → Data plane needs control plane configuration
6. **Gateway** → External access can be added last (optional)

This careful approach lets you isolate and fix issues at each layer!