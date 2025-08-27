#########################################
# Root: подключаем готовые модули
#########################################
# Backend
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.backend_bucket
  table_name  = var.backend_dynamodb_table
}

# VPC
module "vpc" {
  source             = "./modules/vpc"                                     # Шлях до модуля VPC
  vpc_cidr_block     = "10.0.0.0/16"                                       # CIDR блок для VPC
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]       # Публічні підмережі
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]       # Приватні підмережі
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"] # Зони доступності
  vpc_name           = var.vpc_name                                        # Ім'я VPC
}

# EKS
module "eks" {
  source        = "./modules/eks"
  cluster_name  = var.cluster_name          # Назва кластера
  subnet_ids    = module.vpc.public_subnets # ID підмереж
  instance_type = var.instance_type         # Тип інстансів
  desired_size  = 2                         # Бажана кількість нодів
  max_size      = 3                         # Максимальна кількість нодів
  min_size      = 1                         # Мінімальна кількість нодів
}

data "aws_eks_cluster" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}