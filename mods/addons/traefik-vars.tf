# Variables: Traefik
########################################################################################################################
variable "enable_traefik_dashboard" {
  description = "Enable Traefik dashboard access"
  type        = bool
  default     = true
}

variable "traefik_replicas" {
  description = "Number of Traefik replicas"
  type        = number
  default     = 1
}

########################################################################################################################
# Variables: Traefik (Add to existing vars.tf)
########################################################################################################################
# variable "traefik_certificate_arn" {
#   description = "ARN of the ACM certificate for Traefik"
#   type        = string
#   default     = ""
# }
