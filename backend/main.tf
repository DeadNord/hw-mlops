terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_dynamodb_table" "locks" {
  name         = var.dynamodb_table_name
  billing_mode = var.billing_mode
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
