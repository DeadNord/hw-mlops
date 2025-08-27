data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.vpc_state_bucket
    key    = var.vpc_state_key
    region = var.vpc_state_region
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    cpu = {
      instance_types = [var.cpu_instance_type]
      min_size       = var.cpu_min_size
      max_size       = var.cpu_max_size
      desired_size   = var.cpu_desired_size
    }
    gpu = {
      instance_types = [var.gpu_instance_type]
      min_size       = var.gpu_min_size
      max_size       = var.gpu_max_size
      desired_size   = var.gpu_desired_size
    }
  }

  tags = var.tags
}