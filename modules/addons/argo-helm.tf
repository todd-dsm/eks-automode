########################################################################################################################
# Third-Party Addons: ArgoCD
# CHRT: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
# PROJ: https://argoproj.github.io/argo-helm/
# VERS: https://github.com/argoproj/argo-helm/releases?q=argo-cd-&expanded=true
########################################################################################################################
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "7.7.18"

  set = [
    ########################################################################################################################
    # FIX 1: Drastically Reduced Resource Requests (Node has limited memory)
    ########################################################################################################################
    # Server resources - MAJOR REDUCTION
    {
      name  = "server.resources.requests.cpu"
      value = "25m" # Reduced from 100m
    },
    {
      name  = "server.resources.requests.memory"
      value = "32Mi" # Reduced from 128Mi
    },
    {
      name  = "server.resources.limits.cpu"
      value = "100m" # Reduced from 500m
    },
    {
      name  = "server.resources.limits.memory"
      value = "128Mi" # Reduced from 512Mi
    },

    # Controller resources - MAJOR REDUCTION
    {
      name  = "controller.resources.requests.cpu"
      value = "50m" # Reduced from 250m
    },
    {
      name  = "controller.resources.requests.memory"
      value = "64Mi" # Reduced from 256Mi
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "200m" # Reduced from 500m
    },
    {
      name  = "controller.resources.limits.memory"
      value = "256Mi" # Reduced from 512Mi
    },

    # Redis resources - MAJOR REDUCTION
    {
      name  = "redis.resources.requests.cpu"
      value = "25m" # Reduced from 100m
    },
    {
      name  = "redis.resources.requests.memory"
      value = "16Mi" # Reduced from 64Mi
    },
    {
      name  = "redis.resources.limits.cpu"
      value = "50m" # Reduced from 200m
    },
    {
      name  = "redis.resources.limits.memory"
      value = "32Mi" # Reduced from 128Mi
    },

    # Repo server resources - MAJOR REDUCTION
    {
      name  = "repoServer.resources.requests.cpu"
      value = "25m" # Reduced from 100m
    },
    {
      name  = "repoServer.resources.requests.memory"
      value = "32Mi" # Reduced from 128Mi
    },
    {
      name  = "repoServer.resources.limits.cpu"
      value = "100m" # Reduced from 300m
    },
    {
      name  = "repoServer.resources.limits.memory"
      value = "64Mi" # Reduced from 256Mi
    },

    ########################################################################################################################
    # FIX 2: Use ClusterIP Service (Avoid LoadBalancer timeout issues)
    ########################################################################################################################
    {
      name  = "server.service.type"
      value = "ClusterIP" # Changed from LoadBalancer to avoid NLB timeout
    },

    ########################################################################################################################
    # FIX 3: Minimal Replica Configuration
    ########################################################################################################################
    {
      name  = "server.replicas"
      value = "1" # Reduced from 2
    },
    {
      name  = "controller.replicas"
      value = "1"
    },
    {
      name  = "repoServer.replicas"
      value = "1" # Reduced from 2
    },

    ########################################################################################################################
    # FIX 4: Disable Resource-Heavy Features Initially
    ########################################################################################################################
    {
      name  = "applicationSet.enabled"
      value = "false" # Disable to reduce resource usage
    },
    {
      name  = "notifications.enabled"
      value = "false" # Disable to reduce resource usage
    },
    {
      name  = "dex.enabled"
      value = "false"
    },
    {
      name  = "redis-ha.enabled"
      value = "false"
    },

    # Disable metrics initially
    {
      name  = "server.metrics.enabled"
      value = "false"
    },
    {
      name  = "controller.metrics.enabled"
      value = "false"
    },
    {
      name  = "repoServer.metrics.enabled"
      value = "false"
    },

    ########################################################################################################################
    # Basic Configuration
    ########################################################################################################################
    {
      name  = "global.domain"
      value = "argocd.${var.dns_zone}"
    },
    ########################################################################################################################
    # Set Admin Password via Helm
    ########################################################################################################################
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = bcrypt(random_password.argocd_admin_password.result)
    },
  ]

  # Ignore changes to values that ArgoCD might modify
  lifecycle {
    ignore_changes  = [set, values]
    prevent_destroy = false
  }

  ########################################################################################################################
  # FIX 5: Increased Timeout and CRD Handling
  ########################################################################################################################
  timeout           = 1200 # 20 minutes instead of 10
  wait              = true
  wait_for_jobs     = false # Don't wait for jobs to complete
  atomic            = true  # Keep atomic for rollback safety
  cleanup_on_fail   = true
  skip_crds         = true # Skip CRDs to avoid conflicts with existing installations
  disable_crd_hooks = true

  depends_on = [
    kubernetes_namespace.argocd
  ]
}
