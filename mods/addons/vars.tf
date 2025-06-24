################################################################################
# Module Variables: AWS LB Controller
################################################################################
variable "project" {
  description = "Project name"
  type        = string
}

variable "env_build" {
  description = "Environment name (stage/prod)"
  type        = string
}

variable "dns_zone" {
  description = "DNS zone for ArgoCD LoadBalancer service"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# variable "vpc_id" {
#   description = "VPC ID"
#   type        = string
# }
