/*
  ------------------------------------------------------------------------------------------------------------------------
  Outputs: GLOBAL PROJECT INFORMATION
  ------------------------------------------------------------------------------------------------------------------------
*/
# Target Region
# output "region" {
#   description = "Required Region"
#   value       = var.region
# }

# output "project_name" {
#   description = "Project Name"
#   value       = var.project
# }

# output "state_bucket" {
#   description = "Terraform State Bucket"
#   value       = var.state_bucket
# }


# output "oidc_provider_arn" {
#   value = module.eks.oidc_provider_arn
# }

# output "vpc_id" {
#   value = module.network.vpc_id
# }

# output "lbc_irsa_role_arn" {
#   value = module.eks_addons.lbc_irsa_role_arn
# }

/*
  ------------------------------------------------------------------------------------------------------------------------
  Outputs: ACM Certificates
  ------------------------------------------------------------------------------------------------------------------------
*/
# output "cert_status" {
#   value = module.eks.cert_issued
# }

/*
  ------------------------------------------------------------------------------------------------------------------------
  Outputs: EKS Addons
  ------------------------------------------------------------------------------------------------------------------------
*/
# output "snapshot_controller_version" {
#   description = "Version of the snapshot-controller addon"
#   value       = module.eks.snapshot_controller_version
# }

# output "mountpoint_for_s3_csi_driver_version" {
#   description = "Version of the mountpoint-for-s3-csi-driver addon"
#   value       = module.eks.mountpoint_for_s3_csi_driver_version
# }

output "fsx_csi_driver_version" {
  description = "Version of the fsx-csi-driver addon"
  value       = module.eks.fsx_csi_driver_version
}

# output "vpc_cni_irsa_arn" {
#   value = module.eks.vpc_cni_irsa_arn
# }

# output "aws_load_balancer_controller_irsa_arn" {
#   value = module.eks.aws_load_balancer_controller_irsa_arn
# }

# output "argocd_irsa_arn" {
#   value = module.eks.argocd_irsa_arn
# }

# output "ebs_csi_driver_irsa_arn" {
#   value = module.eks.ebs_csi_driver_irsa_arn
# }

# output "oidc_provider_arn" {
#   value = module.eks.oidc_provider_arn
# }

/*
  ------------------------------------------------------------------------------------------------------------------------
  Outputs: Networking Information
  ------------------------------------------------------------------------------------------------------------------------
*/
# VPC Outputs
# output "vpc_id" {
#   description = "Current ID of the VPC"
#   value       = module.network.vpc_id
# }

# # Discovered vs Resultant AZS
# output "azs_discod" {
#   description = "Discovered list of Availability Zones"
#   value       = local.azs
# }

# output "azs_configured" {
#   description = "Configured list of Availability Zones"
#   value       = module.network.configured_azs
# }

# output "vpc_cidr_block" {
#   description = "Current CIDR block of the VPC"
#   value       = module.network.vpc_cidr_block
# }

# output "private_subnets" {
#   description = "Current list of IDs of private subnets"
#   value       = module.network.private_subnets
# }

# output "public_subnets" {
#   description = "Current list of IDs of public subnets"
#   value       = module.network.public_subnets
# }

/*
  ------------------------------------------------------------------------------------------------------------------------
  Outputs: VPC Endpoints
  ------------------------------------------------------------------------------------------------------------------------
*/
# Retrieve a list vpc_endpoints_ids
# output "vpc_endpoints_ids" {
#   value = module.network.vpc_endpoints_ids
# }

# output "vpc_endpoints_security_group_id" {
#   value = module.network.vpc_endpoints_security_group_id
# }

# # Retrieve a cost estimate for vpc_endpoints
# # ENABLE FOR A QUICK FLEX!
# output "vpc_endpoints_cost_estimate" {
#   value = module.network.vpc_endpoints_cost_estimate
# }

# Retrieve a list of vpc_endpoints_dns_entries
# output "vpc_endpoints_dns_entries" {
#   value = module.network.vpc_endpoints_dns_entries
# }

# DEBUGGING: These are ALL vpc_endpoints outputs
# output "vpc_endpoints" {
#   value = module.network.vpc_endpoints
# }