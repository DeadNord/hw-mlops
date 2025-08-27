module "vpc" {
  source = "./vpc"

  name             = var.vpc_name
  cidr             = var.vpc_cidr
  azs              = var.availability_zones
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  region           = var.region
  profile          = var.profile
}

module "eks" {
  source = "./eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cpu_instance_type = var.cpu_instance_type
  gpu_instance_type = var.gpu_instance_type

  cpu_min_size     = var.cpu_min_size
  cpu_max_size     = var.cpu_max_size
  cpu_desired_size = var.cpu_desired_size

  gpu_min_size     = var.gpu_min_size
  gpu_max_size     = var.gpu_max_size
  gpu_desired_size = var.gpu_desired_size

  vpc_state_bucket = var.backend_bucket
  vpc_state_key    = var.vpc_state_key
  vpc_state_region = var.region
  region           = var.region
  profile          = var.profile
}