# EKS Auto Mode Infrastructure Services Deployment Guide

## PURPOSE: Optimal Compute Strategy for Infrastructure Services

This guide provides a comprehensive strategy for deploying long-running infrastructure services (Istio, Vault, SigNoz) on AWS EKS Auto Mode clusters while maintaining cost optimization and meeting 1-minute scaling requirements.

## GOALS

1. **Meet 1-minute scaling requirements** for infrastructure services
2. **Minimize costs** through intelligent spot instance usage
3. **Maintain high availability** for critical infrastructure components
4. **Simplify operations** by leveraging EKS Auto Mode capabilities

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    EKS Auto Mode Cluster                    │
├─────────────────────────┬───────────────────────────────────┤
│   System NodePool       │        General-Purpose NodePool   │
│   (CriticalAddonsOnly)  │        (Default - No Taints)      │
│   • CoreDNS             │        • Your Applications        │
│   • kube-proxy          │        • General Workloads        │
│   • AWS VPC CNI         │                                   │
│   • EBS CSI Driver      │                                   │
├─────────────────────────┴───────────────────────────────────┤
│              Infrastructure Services NodePool               │
│              (Custom - Spot Optimized)                      │
│              • Istio Control Plane                          │
│              • HashiCorp Vault                              │
│              • SigNoz Observability                         │
│              • etc.                                         │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

### Ordinal Requirements

1. EKS Auto Mode cluster with Kubernetes 1.29+
2. Karpenter enabled (comes with Auto Mode)
3. Three availability zones for high availability
4. Proper subnet tagging for Auto Mode
5. kubectl and AWS CLI configured

### Technical Requirements

- **Scaling**: Sub-minute node provisioning (30-60 seconds)
- **Cost**: 60-75% reduction through spot instances
- **Availability**: 99.9% uptime for infrastructure services
- **Isolation**: Dedicated nodes for infrastructure workloads

## Implementation

### Infrastructure NodePool Configuration

Save this as `infrastructure-nodepool.yaml`:

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: infrastructure-services
  annotations:
    description: "Dedicated NodePool for Infrastructure Services with spot-first strategy"
spec:
  # Template for node configuration
  template:
    metadata:
      labels:
        workload-type: "infrastructure"
        karpenter.sh/nodepool: "infrastructure-services"
    spec:
      requirements:
        # Prioritize spot instances for cost savings
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["spot", "on-demand"]  # Spot first, fallback to on-demand
        
        # Use stable instance families suitable for infrastructure
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: 
            # Memory optimized for infrastructure services
            - "r5.large"      # 2 vCPU, 16 GiB
            - "r5.xlarge"     # 4 vCPU, 32 GiB
            - "r5a.large"     # AMD variant - often cheaper
            - "r5a.xlarge"
            - "r6i.large"     # Latest generation
            - "r6i.xlarge"
            # Compute optimized alternatives
            - "c5.xlarge"     # 4 vCPU, 8 GiB
            - "c5.2xlarge"    # 8 vCPU, 16 GiB
            - "c5a.xlarge"    # AMD variant
            - "c5a.2xlarge"
            # General purpose for flexibility
            - "m5.large"      # 2 vCPU, 8 GiB
            - "m5.xlarge"     # 4 vCPU, 16 GiB
            - "m5a.large"     # AMD variant
            - "m5a.xlarge"
        
        # Architecture requirement
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        
        # Ensure we use general-purpose pool base
        - key: "eks.amazonaws.com/nodegroup"
          operator: In
          values: ["general-purpose"]
      
      # Taint for infrastructure isolation
      taints:
        - key: "infrastructure"
          value: "true"
          effect: "NoSchedule"
      
      # User data for node initialization
      userData: |
        #!/bin/bash
        echo "vm.max_map_count=262144" >> /etc/sysctl.conf
        sysctl -p
      
      # Instance store for ephemeral storage
      instanceStorePolicy: RAID0
      
      # Node class reference for EKS Auto Mode
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: default
  
  # Disruption settings optimized for infrastructure stability
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 600s  # 10 minutes for stability
    expireAfter: 7d  # Refresh spot instances weekly
    budgets:
    - nodes: "20%"  # Don't disrupt more than 20% at once
  
  # Resource limits for the NodePool
  limits:
    cpu: "2000"
    memory: "8000Gi"
  
  # Weight for scheduling preference
  weight: 100
```

### Deployment Templates for Infrastructure Services

#### Istio Control Plane

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
  namespace: istio-system
spec:
  replicas: 3
  template:
    spec:
      # Infrastructure node scheduling
      tolerations:
      - key: "infrastructure"
        value: "true"
        effect: "NoSchedule"
      nodeSelector:
        workload-type: "infrastructure"
      
      # High availability configuration
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: istiod
            topologyKey: topology.kubernetes.io/zone
      
      # Resource allocation
      containers:
      - name: discovery
        resources:
          requests:
            cpu: "500m"
            memory: "2Gi"
          limits:
            cpu: "2000m"
            memory: "4Gi"
      
      # Pod disruption budget
      priorityClassName: system-cluster-critical
```

#### HashiCorp Vault

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: vault
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: vault
  namespace: vault
spec:
  replicas: 5  # HA configuration
  template:
    spec:
      tolerations:
      - key: "infrastructure"
        value: "true"
        effect: "NoSchedule"
      nodeSelector:
        workload-type: "infrastructure"
      
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: vault
            topologyKey: topology.kubernetes.io/zone
      
      containers:
      - name: vault
        resources:
          requests:
            cpu: "250m"
            memory: "1Gi"
          limits:
            cpu: "1000m"
            memory: "2Gi"
      
      # Persistent storage
      volumeClaimTemplates:
      - metadata:
          name: vault-storage
        spec:
          accessModes: ["ReadWriteOnce"]
          storageClassName: gp3
          resources:
            requests:
              storage: 10Gi
```

#### SigNoz Observability

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: signoz
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: signoz-clickhouse
  namespace: signoz
spec:
  replicas: 3
  template:
    spec:
      tolerations:
      - key: "infrastructure"
        value: "true"
        effect: "NoSchedule"
      nodeSelector:
        workload-type: "infrastructure"
      
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: clickhouse
            topologyKey: topology.kubernetes.io/zone
      
      containers:
      - name: clickhouse
        resources:
          requests:
            cpu: "1000m"
            memory: "4Gi"
          limits:
            cpu: "4000m"
            memory: "8Gi"
      
      volumeClaimTemplates:
      - metadata:
          name: clickhouse-storage
        spec:
          accessModes: ["ReadWriteOnce"]
          storageClassName: gp3
          resources:
            requests:
              storage: 100Gi
```

### Regular Application Deployment (No Special Configuration Needed)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-application
  namespace: default
spec:
  replicas: 3
  template:
    spec:
      # No tolerations = automatically schedules on general-purpose nodes
      containers:
      - name: app
        image: my-app:latest
        resources:
          requests:
            cpu: "100m"
            memory: "256Mi"
```

## Testing Documentation

### Verify NodePool Creation

```shell
% kubectl apply -f infrastructure-nodepool.yaml
% kubectl get nodepool infrastructure-services -o wide
```

**Expected Results:**
```
NAME                      NODES   READY   WEIGHT   CPU    MEMORY
infrastructure-services   0       True    100      2000   8000Gi
```

### Deploy Infrastructure Services

```shell
% kubectl apply -f istio-deployment.yaml
% kubectl apply -f vault-deployment.yaml
% kubectl apply -f signoz-deployment.yaml
```

### Verify Pod Placement

```shell
% kubectl get pods -A -o wide | grep -E "(istio|vault|signoz)"
```

**Expected Results:**
```
istio-system   istiod-xxx    1/1   Running   ip-10-x-x-x.ec2.internal   <none>   infrastructure
vault          vault-0       1/1   Running   ip-10-x-x-x.ec2.internal   <none>   infrastructure
signoz         clickhouse-0  1/1   Running   ip-10-x-x-x.ec2.internal   <none>   infrastructure
```

### Check Spot vs On-Demand Distribution

```shell
% kubectl get nodes -l workload-type=infrastructure \
  -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.labels.karpenter\.sh/capacity-type}{"\n"}{end}'
```

**Expected Results:**

```shell
ip-10-0-1-123.ec2.internal spot
ip-10-0-2-456.ec2.internal spot
ip-10-0-3-789.ec2.internal on-demand
```

### Test Scaling Performance

```shell
% kubectl scale deployment istiod -n istio-system --replicas=10
% time kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s
```

**Expected Results:**

- Scaling completes within 30-60 seconds
- New nodes provisioned automatically
- Pods distributed across availability zones

### Monitor Costs

```shell
% aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --filter file://spot-filter.json
```

## Cost Optimization Formula

```text
Total Monthly Cost = 
  (Baseline Nodes × 730 hours × Spot Price) +
  (Burst Nodes × Active Hours × Spot Price) +
  (On-Demand Fallback × Hours × On-Demand Price) +
  (12% × Total Instance Cost × Auto Mode Premium)

Example (10 nodes average):
- Spot instances (80%): 8 nodes × $0.10/hour × 730 = $584
- On-demand fallback (20%): 2 nodes × $0.40/hour × 730 = $584
- Auto Mode premium: $1,168 × 0.12 = $140
- Total: $1,308/month (vs $2,920 all on-demand)
- Savings: 55%
```

## Key Architectural Decisions

### Why Not System NodePool?

The system NodePool with `CriticalAddonsOnly` is reserved for:

- CoreDNS
- kube-proxy
- AWS VPC CNI
- EBS CSI Driver
- Other EKS-managed components

Infrastructure services like Istio, Vault, and SigNoz should run on dedicated nodes for proper isolation and resource management.

### Spot Instance Strategy

- **15+ instance types** for maximum availability
- **AMD variants** (r5a, c5a, m5a) for better pricing
- **7-day rotation** to refresh instances
- **20% disruption budget** for stability

### Natural Workload Separation

```text
┌─────────────────┐      ┌─────────────────┐
│ Regular Apps    │      │ Infrastructure  │
│ (No tolerations)│      │ (Tolerations)   │
└────────┬────────┘      └────────┬────────┘
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│ General-Purpose │      │ Infrastructure  │
│ NodePool        │      │ NodePool        │
│ (No taints)     │      │ (Tainted)       │
└─────────────────┘      └─────────────────┘
```

## Production Deployment Timeline

### Week 1-2: Assessment

- Review current infrastructure requirements
- Calculate expected costs
- Plan migration strategy

### Week 3-4: Pilot Implementation

- Deploy infrastructure NodePool
- Migrate one service (e.g., Istio)
- Monitor performance and costs

### Week 5-6: Full Migration

- Deploy remaining services
- Configure monitoring and alerts
- Optimize resource allocations

### Week 7-8: Optimization

- Fine-tune instance types
- Adjust scaling parameters
- Document procedures

## Terraform Implementation

```hcl
# Infrastructure NodePool via Terraform
resource "kubectl_manifest" "infrastructure_nodepool" {
  yaml_body = file("${path.module}/infrastructure-nodepool.yaml")
  
  depends_on = [
    aws_eks_cluster.main,
    aws_eks_addon.karpenter
  ]
}

# Deploy infrastructure services
resource "helm_release" "istio" {
  name       = "istio"
  namespace  = "istio-system"
  chart      = "istio/base"
  
  values = [
    yamlencode({
      global = {
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [{
                matchExpressions = [{
                  key      = "workload-type"
                  operator = "In"
                  values   = ["infrastructure"]
                }]
              }]
            }
          }
        }
        tolerations = [{
          key      = "infrastructure"
          value    = "true"
          effect   = "NoSchedule"
        }]
      }
    })
  ]
}
```

## Monitoring and Alerts

### Key Metrics to Track

1. **Spot interruption rate**: Should be <5% monthly
2. **Node provisioning time**: Target <60 seconds
3. **Cost per service**: Track infrastructure vs application costs
4. **Resource utilization**: Aim for 60-80% CPU/memory usage

### CloudWatch Alarms

```yaml
SpotInterruptionRate:
  MetricName: SpotInstanceInterruptions
  Statistic: Sum
  Period: 3600
  EvaluationPeriods: 1
  Threshold: 2
  ComparisonOperator: GreaterThanThreshold

NodeProvisioningTime:
  MetricName: NodeReadyTime
  Statistic: Average
  Period: 300
  EvaluationPeriods: 2
  Threshold: 60
  ComparisonOperator: GreaterThanThreshold
```

## Conclusion

This architecture provides:

- **55-75% cost savings** through intelligent spot usage
- **30-60 second scaling** meeting the 1-minute requirement
- **High availability** through multi-AZ deployment
- **Simple operations** with automatic workload separation

The infrastructure NodePool pattern ensures critical services have dedicated resources while maintaining cost efficiency through spot instances. Regular applications naturally schedule on general-purpose nodes without any configuration changes.