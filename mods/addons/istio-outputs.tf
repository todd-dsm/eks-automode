########################################################################################################################
# Istio Deployment Outputs
########################################################################################################################
# output "istio_ingress_gateway_status" {
#   description = "Istio ingress gateway service status"
#   value = {
#     name      = helm_release.istio_ingress_gateway.name
#     namespace = helm_release.istio_ingress_gateway.namespace
#     status    = helm_release.istio_ingress_gateway.status
#   }
# }

# output "istio_ingress_gateway_loadbalancer" {
#   description = "Istio ingress gateway LoadBalancer details"
#   value = {
#     service_name = "istio-ingress"
#     namespace    = kubernetes_namespace.istio_ingress.metadata[0].name
#     command      = "kubectl get svc istio-ingress -n ${kubernetes_namespace.istio_ingress.metadata[0].name} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
#   }
# }

# output "istio_ambient_deployment_status" {
#   description = "Istio Ambient Mode deployment summary"
#   value = {
#     base_status     = helm_release.istio_base.status
#     cni_status      = helm_release.istio_cni.status
#     istiod_status   = helm_release.istiod.status
#     ztunnel_status  = helm_release.ztunnel.status
#     gateway_status  = helm_release.istio_ingress_gateway.status
#   }
# }

# output "istio_access_instructions" {
#   description = "Instructions for accessing and using Istio"
#   value = <<-EOT
#     🌐 Istio Ambient Mode Deployment Complete!
#     =========================================

#     📦 Components Deployed:
#     - ✅ Istio Base (CRDs)
#     - ✅ Istio CNI (Ambient Mode)
#     - ✅ Istiod (Control Plane)
#     - ✅ Ztunnel (Node Proxy)
#     - ✅ Istio Ingress Gateway (NLB)

#     🔍 Verify Installation:
#     kubectl get pods -n istio-system
#     kubectl get pods -n istio-ingress

#     🌍 Get Gateway External IP:
#     kubectl get svc istio-ingress -n istio-ingress

#     📚 Next Steps:
#     1. Label namespaces for ambient mode:
#        kubectl label namespace <your-namespace> istio.io/dataplane-mode=ambient

#     2. Create HTTPRoute for your applications:
#        kubectl apply -f your-httproute.yaml

#     3. Monitor with istioctl:
#        istioctl proxy-status
#        istioctl analyze
#   EOT
# }

# output "istio_verification_commands" {
#   description = "Commands to verify Istio installation"
#   value = <<-EOT
#     # Check all Istio components
#     kubectl get pods -n istio-system
#     kubectl get pods -n istio-ingress

#     # Verify Istio installation
#     istioctl verify-install

#     # Check gateway external endpoint
#     kubectl get svc istio-ingress -n istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

#     # Enable ambient mode for a namespace
#     kubectl label namespace default istio.io/dataplane-mode=ambient

#     # Check ztunnel logs
#     kubectl logs -n istio-system -l app=ztunnel

#     # Monitor ambient mesh status
#     istioctl experimental ztunnel-config workload
#   EOT
# }
