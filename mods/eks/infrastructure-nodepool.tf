########################################################################################################################
# Infrastructure Services NodePool for EKS Auto Mode
# PURPOSE: Dedicated node pool for infrastructure services (ArgoCD, monitoring, ingress controllers)
# LOCATION: mods/addons/infrastructure-nodepool.tf
# DOCS: https://karpenter.sh/docs/concepts/nodepools/
########################################################################################################################
resource "kubernetes_manifest" "nodepool_infras_services" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "infra-services"
      labels = {
        "workload" = "infra-services"
      }
      annotations = {
        "description" = "Dedicated NodePool for Infrastructure Services with spot-first strategy"
      }
    }
    spec = {
      # Conservative disruption for stable infrastructure services
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "60s"
        budgets = [
          {
            nodes = "20%"
          }
        ]
      }

      # Resource limits for this NodePool
      limits = {
        cpu    = "1000"
        memory = "1000Gi"
      }

      # Priority for this NodePool (higher values = higher priority)
      weight = 20

      # Template defines the characteristics of nodes in this pool
      template = {
        metadata = {
          # Labels applied to all nodes in this pool
          labels = {
            "workload" = "infra-services"
          }
        }
        spec = {
          # Taints applied to all nodes in this pool for workload isolation
          taints = [
            {
              key    = "infra-services"
              effect = "NoSchedule"
            }
          ]
          # Node lifecycle configuration
          expireAfter            = "168h" # 7 days for stability
          terminationGracePeriod = "60s"

          # Reference to NodeClass for AWS-specific configuration
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }

          # Instance requirements for this NodePool
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["m", "c"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["4"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            }
          ]
        }
      }
    }
  }
}
