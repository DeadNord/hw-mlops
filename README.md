# Terraform AWS VPC and EKS Infrastructure

This project provisions a complete environment on AWS using Terraform. It includes a backend for storing state in S3 with DynamoDB locking, a VPC network, and an EKS cluster.

## Preparation

1. Install Terraform (>=1.6), AWS CLI and kubectl.
2. Configure AWS credentials (profile or environment variables).
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust variables.

## 1. Provision backend (S3 + DynamoDB)

```bash
cd backend
terraform init
terraform fmt
terraform validate
terraform plan  -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars -auto-approve
```

Save the outputs for later:

```bash
terraform output -raw backend_bucket
terraform output -raw backend_dynamodb_table
```

## 2. Create VPC

```bash
cd ../vpc
terraform init \
  -backend-config="bucket=hw-5-6-terraform-state-bucket" \
  -backend-config="key=vpc/terraform.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="use_lockfile=true"
terraform validate
terraform plan  -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars -auto-approve
```

## 3. Create EKS cluster

```bash
cd ../eks
terraform init \
  -backend-config="bucket=hw-5-6-terraform-state-bucket" \
  -backend-config="key=eks/terraform.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="use_lockfile=true"
terraform validate
terraform plan  -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars -auto-approve
```

## 4. Access the cluster

```bash
cd ../
aws eks --region eu-central-1 update-kubeconfig --name $(terraform output -raw cluster_name)
kubectl get nodes
```

## 5. Destroy infrastructure

```bash
cd eks && terraform destroy -var-file=../terraform.tfvars -auto-approve
cd ../vpc && terraform destroy -var-file=../terraform.tfvars -auto-approve
cd ../backend && terraform destroy -var-file=../terraform.tfvars -auto-approve
```
