output "backend_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3_bucket.s3_bucket_id
}

output "backend_dynamodb_table" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.locks.name
}
