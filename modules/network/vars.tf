################################################################################
#   Network Variables: Module
################################################################################
variable "project" {
  description = "Project name"
  type        = string
}

variable "env_build" {
  description = "Environment name (stage/prod)"
  type        = string
}

variable "tags" {
  description = "Global Tags"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "azs" {
  description = "Discovered Availability zones"
  type        = list(string)
}
