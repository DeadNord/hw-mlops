variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "force_destroy" {
  description = "Whether to force destroy the S3 bucket"
  type        = bool
}

variable "billing_mode" {
  description = "Billing mode for DynamoDB table"
  type        = string
}
