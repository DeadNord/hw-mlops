variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_state_bucket" {
  description = "S3 bucket containing VPC state"
  type        = string
}

variable "vpc_state_key" {
  description = "Key path to VPC state file"
  type        = string
}

variable "vpc_state_region" {
  description = "Region of the VPC state bucket"
  type        = string
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
  description = "Minimum nodes in CPU node group"
  type        = number
}

variable "cpu_max_size" {
  description = "Maximum nodes in CPU node group"
  type        = number
}

variable "cpu_desired_size" {
  description = "Desired nodes in CPU node group"
  type        = number
}

variable "gpu_min_size" {
  description = "Minimum nodes in GPU node group"
  type        = number
}

variable "gpu_max_size" {
  description = "Maximum nodes in GPU node group"
  type        = number
}

variable "gpu_desired_size" {
  description = "Desired nodes in GPU node group"
  type        = number
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "profile" {
  description = "AWS profile"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}