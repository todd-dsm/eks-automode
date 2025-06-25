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
    * Core Addons:
      * FSx CSI driver
      * Mountpoint for S3 CSI driver
      * Snapshot Controller (Builds in 15m20s)
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
  tags            = local.tags
  depends_on      = [module.network]
}

/*
  ------------------------------------------------------------------------------------------------------------------------
  Readjustments
   * Container Insights Cleanup: Remove CloudWatch Agent and Fluent Bit
  ------------------------------------------------------------------------------------------------------------------------
*/
module "removals" {
  source     = "./mods/cleanup"
  depends_on = [module.eks]
}

/*
  ------------------------------------------------------------------------------------------------------------------------
  EKS Cluster: Helm Addons (Third-Party)
  ------------------------------------------------------------------------------------------------------------------------
*/
module "eks_addons" {
  source            = "./mods/addons"
  project           = var.project
  env_build         = var.env_build
  dns_zone          = var.dns_zone
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name      = module.eks.cluster_name
  tags              = local.tags
  depends_on        = [module.removals]
}
