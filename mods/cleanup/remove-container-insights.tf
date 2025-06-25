########################################################################################################################
# Remove CloudWatch Agent and Fluent Bit for Container Insights
# DOCS: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights-delete-agent.html
########################################################################################################################
# This add-on is documented as installed by default in EKS Auto Mode.
# An extensive shows that's not true; if/when it is, uncomment.
########################################################################################################################
# resource "null_resource" "remove_container_insights" {
#   provisioner "local-exec" {
#     command = <<-EOT
#       # Remove DaemonSets
#       kubectl delete daemonset cloudwatch-agent -n amazon-cloudwatch --ignore-not-found=true
#       kubectl delete daemonset fluent-bit -n amazon-cloudwatch --ignore-not-found=true

#       # Remove ConfigMaps
#       kubectl delete configmap cwagentconfig -n amazon-cloudwatch --ignore-not-found=true
#       kubectl delete configmap fluent-bit-config -n amazon-cloudwatch --ignore-not-found=true

#       # Remove ServiceAccounts
#       kubectl delete serviceaccount cloudwatch-agent -n amazon-cloudwatch --ignore-not-found=true
#       kubectl delete serviceaccount fluent-bit -n amazon-cloudwatch --ignore-not-found=true

#       # Remove RBAC
#       kubectl delete clusterrole cloudwatch-agent-role --ignore-not-found=true
#       kubectl delete clusterrolebinding cloudwatch-agent-role-binding --ignore-not-found=true
#       kubectl delete clusterrole fluent-bit-role --ignore-not-found=true
#       kubectl delete clusterrolebinding fluent-bit-role-binding --ignore-not-found=true

#       echo "✅ Container Insights components removed successfully"
#     EOT
#   }
# }
