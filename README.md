# Terraform AWS VPC and EKS Infrastructure

This project provisions a complete environment on AWS using Terraform. It includes a backend for storing state in S3 with DynamoDB locking, a VPC network, and an EKS cluster.

## Preparation

1. Install Terraform (>=1.6), AWS CLI and kubectl.
2. Configure AWS credentials (profile or environment variables).
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust variables.

## 1. Initialize terraform

```bash
terraform init -reconfigure
terraform validate
terraform fmt
terraform plan
```

## 2. Create terraform state

```bash
terraform apply
```

## 3. Access the cluster

```bash
aws eks update-kubeconfig --region eu-central-1 --name $(terraform output -raw cluster_name)
kubectl get nodes
kubectl get pods --all-namespaces
```

## 4. Destroy infrastructure

```bash
terraform destroy
# cd eks && terraform destroy -var-file=../terraform.tfvars -auto-approve
# cd ../vpc && terraform destroy -var-file=../terraform.tfvars -auto-approve
# cd ../backend && terraform destroy -var-file=../terraform.tfvars -auto-approve
```
