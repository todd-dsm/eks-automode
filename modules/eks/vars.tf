################################################################################
#   EKS Variables: Module
################################################################################
variable "project" {
  description = "Project name"
  type        = string
}

variable "env_build" {
  description = "Environment name (stage/prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets"
  type        = list(string)
}

# addons
variable "enable_ipv6" {
  description = "Enable IPv6 support for VPC CNI"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Discovery: Data Sources
################################################################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
