variable "bucket_name" {
  type        = string
  description = "S3 bucket for Terraform state"
}

variable "table_name" {
  type        = string
  description = "DynamoDB table for state locking"
}

variable "force_destroy" {
  type        = bool
  description = "Allow automatic bucket deletion with contents"
  default     = false
}
