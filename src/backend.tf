terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "hw-5-terraform" # ← ваше ім’я бакета
    key            = "lesson-5/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
