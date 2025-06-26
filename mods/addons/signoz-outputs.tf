# ########################################################################################################################
# # Verification - Check SigNoz deployment status
# ########################################################################################################################
# resource "null_resource" "signoz_verification" {
#   # Verify SigNoz is running properly
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "🔍 Verifying SigNoz deployment..."

#       # Wait for pods to be ready
#       kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=signoz -n signoz --timeout=600s

#       # Check service status
#       kubectl get pods,svc -n signoz

#       echo "✅ SigNoz verification complete"
#       echo ""
#       echo "🌐 Access SigNoz UI via port-forward:"
#       echo "kubectl port-forward -n signoz svc/signoz-frontend 3301:3301"
#       echo "Then open: http://localhost:3301"
#     EOT
#   }

#   triggers = {
#     helm_revision = helm_release.signoz.revision
#   }

#   depends_on = [helm_release.signoz]
# }

# output "signoz_endpoints" {
#   description = "SigNoz service endpoints for application instrumentation"
#   value = {
#     ui_service       = "signoz-frontend.signoz.svc.cluster.local:3301"
#     otel_grpc        = "signoz-otel-collector.signoz.svc.cluster.local:4317"
#     otel_http        = "signoz-otel-collector.signoz.svc.cluster.local:4318"
#     query_service    = "signoz-query-service.signoz.svc.cluster.local:8080"
#   }
# }
