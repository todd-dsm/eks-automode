################################################################################
#   Outputs: Module
################################################################################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "subnet_ids_public" {
  description = "The IDs of the private subnets"
  value       = module.vpc.public_subnets
}


output "subnet_ids_private" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.default_vpc_cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}
