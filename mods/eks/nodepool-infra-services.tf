# ########################################################################################################################
# # Infrastructure Services NodePool for EKS Auto Mode
# # PURPOSE: Dedicated node pool for infrastructure services (ArgoCD, monitoring, ingress controllers)
# # LOCATION: mods/addons/infrastructure-nodepool.tf
# # DOCS: https://karpenter.sh/docs/concepts/nodepools/
# # DOCS: https://docs.aws.amazon.com/eks/latest/userguide/create-node-pool.html#auto-supported-labels
# # DOCS: https://docs.aws.amazon.com/eks/latest/userguide/create-node-pool.html#_eks_auto_mode_not_supported_labels
# ########################################################################################################################
# resource "kubernetes_manifest" "nodepool_infra_services" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1"
#     kind       = "NodePool"
#     metadata = {
#       name = "infra-services"
#       labels = {
#         "workload" = "infra-services"
#       }
#       annotations = {
#         "description" = "Dedicated NodePool for Infrastructure Services with spot-first strategy"
#       }
#     }
#     spec = {
#       # Conservative disruption for stable infrastructure services
#       disruption = {
#         consolidationPolicy = "WhenEmpty"
#         consolidateAfter    = "60s"
#         budgets = [
#           {
#             nodes = "20%"
#           }
#         ]
#       }

#       # Resource limits for this NodePool
#       limits = {
#         cpu    = "1000"
#         memory = "1000Gi"
#       }

#       # Priority for this NodePool (higher values = higher priority)
#       weight = 20

#       # Template defines the characteristics of nodes in this pool
#       template = {
#         metadata = {
#           # Labels applied to all nodes in this pool
#           labels = {
#             "workload" = "infra-services"
#           }
#         }
#         spec = {
#           # Taints applied to all nodes in this pool for workload isolation
#           taints = [
#             {
#               key    = "infra-services"
#               value = "true"
#               effect = "NoSchedule"
#             }
#           ]
#           # Node lifecycle configuration
#           expireAfter            = "168h" # 7 days for stability
#           terminationGracePeriod = "60s"

#           # Reference to NodeClass for AWS-specific configuration
#           nodeClassRef = {
#             group = "eks.amazonaws.com"
#             kind  = "NodeClass"
#             name  = "default"
#           }

#           # Instance requirements for an EKS Auto Mode NodePool
#           # The labeling is different from a Self-Managed EKS Cluster
#           requirements = [
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot", "on-demand"]
#             },
#             {
#               key      = "eks.amazonaws.com/instance-category"
#               operator = "In"
#               values   = ["m", "c"]
#             },
#             {
#               key      = "eks.amazonaws.com/instance-generation"
#               operator = "Gt"
#               values   = ["4"]
#             },
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values   = ["amd64"]
#             }
#           ]
#         }
#       }
#     }
#   }

#   lifecycle {
#     # Ignore changes to computed fields that Karpenter manages
#     ignore_changes = [
#       manifest["metadata"]["labels"],
#       manifest["metadata"]["annotations"]
#     ]
#   }

#   # Fixes destroy issue: https://bit.ly/3ZZrj2q
#   computed_fields = [
#     "metadata.labels",
#     "metadata.annotations",
#     "spec"
#   ]
# }
