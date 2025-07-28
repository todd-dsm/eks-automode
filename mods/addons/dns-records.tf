# Update dns-records.tf
data "kubernetes_service" "gateway_service" {
  metadata {
    name      = "gitops-demo-stage-gateway-istio"
    namespace = "istio-system"
  }

  depends_on = [kubernetes_manifest.environment_gateway]
}

# Create the DNS record
resource "aws_route53_record" "environment_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.env_build}.${var.dns_zone}"
  type    = "CNAME"
  ttl     = 300
  records = [trimspace(data.local_file.gateway_hostname.content)]

  depends_on = [data.local_file.gateway_hostname]
}

output "dns_record_zone_id" {
  value = aws_route53_record.environment_cname.zone_id
}

# Get the load balancer hostname using kubectl
resource "null_resource" "get_gateway_hostname" {
  provisioner "local-exec" {
    command = <<-EOT
      # Wait for load balancer to be ready
      echo "Waiting for load balancer to be ready..."
      timeout 300 bash -c '
        while true; do
          HOSTNAME=$(kubectl get svc -n istio-system -l app=istio-gateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}" 2>/dev/null)
          if [[ -n "$HOSTNAME" && "$HOSTNAME" != "null" ]]; then
            echo "$HOSTNAME" > /tmp/gateway-hostname.txt
            echo "Load balancer ready: $HOSTNAME"
            break
          fi
          echo "Waiting for load balancer..."
          sleep 10
        done
      '
    EOT
  }

  depends_on = [kubernetes_manifest.environment_gateway]

  triggers = {
    gateway_id = kubernetes_manifest.environment_gateway.manifest.metadata.name
  }
}

# Read the hostname from the file
data "local_file" "gateway_hostname" {
  filename   = "/tmp/gateway-hostname.txt"
  depends_on = [null_resource.get_gateway_hostname]
}

# # Route53 record pointing to the Gateway load balancer
# resource "aws_route53_record" "environment_cname" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = "${var.env_build}.${var.dns_zone}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [
#     data.kubernetes_service.gateway_service.status.load_balancer.ingress.0.hostname
#   ]

#   depends_on = [data.kubernetes_service.gateway_service]
# }

# # Data source to find the automatically-created service
# data "kubernetes_service" "gateway_service" {
#   metadata {
#     name      = "gitops-demo-stage-gateway-istio" # Use the exact name from kubectl
#     namespace = "istio-system"
#   }

#   depends_on = [kubernetes_manifest.environment_gateway]
# }

output "gateway_service" {
  value = data.kubernetes_service.gateway_service
}

# # Route53 zone data source (if not already defined)
# data "aws_route53_zone" "selected" {
#   name         = "${var.dns_zone}."
#   private_zone = false
# }
