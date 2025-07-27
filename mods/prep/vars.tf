################################################################################
#   EKS Variables: Module
################################################################################
variable "project" {
  description = "Project name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# variable "env_build" {
#   description = "Environment name (stage/prod)"
#   type        = string
# }

################################################################################
# Discovery: Data Sources
################################################################################
# data "aws_eks_cluster" "eks_cluster" {
#   name = var.project
# }

# data "aws_eks_cluster_auth" "eks_cluster_auth" {
#   name = var.project
# }
