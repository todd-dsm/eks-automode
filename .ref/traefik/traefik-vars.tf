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

# variable "traefik_certificate_domain" {
#   description = "Primary domain of the Traefik certificate"
#   type        = string
# }

# variable "traefik_certificate_sans" {
#   description = "Subject alternative names for Traefik certificate"
#   type        = list(string)
# }

variable "gateway_api_crds_ready" {
  description = "Dependency to ensure Gateway API CRDs are installed"
  type        = any
  default     = null
}