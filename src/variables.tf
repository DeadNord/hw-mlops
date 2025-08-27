variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "backend_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
  default     = "hw-5-terraform"
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-locks"
}
