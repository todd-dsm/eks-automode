/* 
  Variables: Global
*/
variable "project" {
  description = "Project name"
  type        = string
}

variable "env_build" {
  description = "Environment name (stage/prod)"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket for terraform state"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "dns_zone" {
  description = "DNS zone"
  type        = string
}

variable "zone_private" {
  description = "Private zone"
  type        = bool
}

# Variables: Networking -------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

# Variables: EKS --------------------------------------------------------------

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}
