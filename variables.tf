variable "region" {
  description = "AWS region"
  type        = string
}

variable "profile" {
  description = "AWS profile"
  type        = string
  default     = null
}

variable "backend_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table for state locking"
  type        = string
}

variable "vpc_state_key" {
  description = "Path to VPC state file"
  type        = string
  default     = "vpc/terraform.tfstate"
}

variable "eks_state_key" {
  description = "Path to EKS state file"
  type        = string
  default     = "eks/terraform.tfstate"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.29"
}

variable "cpu_instance_type" {
  description = "Instance type for CPU node group"
  type        = string
}

variable "gpu_instance_type" {
  description = "Instance type for GPU node group"
  type        = string
}

variable "cpu_min_size" {
  description = "Minimum number of nodes in CPU node group"
  type        = number
  default     = 1
}

variable "cpu_max_size" {
  description = "Maximum number of nodes in CPU node group"
  type        = number
  default     = 3
}

variable "cpu_desired_size" {
  description = "Desired number of nodes in CPU node group"
  type        = number
  default     = 2
}

variable "gpu_min_size" {
  description = "Minimum number of nodes in GPU node group"
  type        = number
  default     = 0
}

variable "gpu_max_size" {
  description = "Maximum number of nodes in GPU node group"
  type        = number
  default     = 1
}

variable "gpu_desired_size" {
  description = "Desired number of nodes in GPU node group"
  type        = number
  default     = 0
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways"
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access for the EKS cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access for the EKS cluster endpoint"
  type        = bool
}

variable "billing_mode" {
  description = "Billing mode for DynamoDB table"
  type        = string
}

variable "force_destroy" {
  description = "Whether to force destroy the S3 bucket"
  type        = bool
}