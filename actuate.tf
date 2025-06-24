/*
  ------------------------------------------------------------------------------------------------------------------------
  Networking
   * VPC, flow logs, et al.
   * VPC Endpoints, commented out
  ------------------------------------------------------------------------------------------------------------------------
*/
module "network" {
  source    = "./mods/network"
  project   = var.project
  env_build = var.env_build
  vpc_cidr  = var.vpc_cidr
  azs       = local.azs
  tags      = local.tags
}
/*
  ------------------------------------------------------------------------------------------------------------------------
  EKS Cluster: Fully Managed
  ------------------------------------------------------------------------------------------------------------------------
*/
module "eks" {
  source          = "./mods/eks"
  project         = var.project
  env_build       = var.env_build
  cluster_version = var.cluster_version
  subnet_ids      = module.network.private_subnet_ids
  dns_zone        = var.dns_zone
  zone_private    = var.zone_private
  depends_on      = [module.network]
}
/*
  ------------------------------------------------------------------------------------------------------------------------
  EKS Cluster: Helm Addons (Third-Party)
  ------------------------------------------------------------------------------------------------------------------------
*/
# module "eks_addons" {
#   source            = "./mods/addons"
#   project           = var.project
#   env_build         = var.env_build
#   cluster_name      = module.eks.cluster_name
#   oidc_provider_arn = module.eks.oidc_provider_arn
#   vpc_id            = module.network.vpc_id
#   vpc_arn           = module.network.vpc_arn
#   dns_zone          = var.dns_zone
#   vpc_cidr          = var.vpc_cidr
#   depends_on        = [module.eks]
# }
