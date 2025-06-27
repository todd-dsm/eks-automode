########################################################################################################################
# Variables: Istio Ambient Mode
########################################################################################################################
variable "create_example_gateway" {
  description = "Create example Istio Gateway for testing"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids_public" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "certificate_arn" {
  description = "Certificate ARN"
  type        = string
}
