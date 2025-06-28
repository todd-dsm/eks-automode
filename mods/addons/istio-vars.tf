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
