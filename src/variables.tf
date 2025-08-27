# Core
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

#EKS

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster-hw-10"
}

variable "instance_type" {
  description = "EC2 instance type for the worker nodes"
  type        = string
  default     = "t2.medium"
}

#VPC
variable "vpc_name" {
  default = "vpc-hw-10"
}

#S3
variable "backend_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
  default     = "hw-5-terraform"
}

#DynamoDB
variable "backend_dynamodb_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-locks"
}
