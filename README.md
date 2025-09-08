# Terraform AWS VPC and EKS Infrastructure

This project provisions a complete environment on AWS using Terraform. It includes a backend for storing state in S3 with DynamoDB locking, a VPC network, an EKS cluster, and an ArgoCD installation for GitOps deployments.

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
terraform apply -auto-approve
```

## 3. Access the cluster

```bash
aws eks update-kubeconfig --region eu-central-1 --name $(terraform output -raw cluster_name)
kubectl get nodes
kubectl get pods --all-namespaces
```

## 4. Deploy ArgoCD

```bash
cd ./agrocd
terraform init -reconfigure
terraform fmt -check
terraform validate
terraform apply -auto-approve -var-file=../terraform.tfvars
kubectl get pods -n infra-tools
```

## 5. Open ArgoCD UI

Open <http://localhost:8080> in your browser.

```bash
cd ../
kubectl -n infra-tools port-forward svc/argocd-server 8080:443
```

Log in with user `admin` and the password fetched via:

```bash
kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 6. Configure MLflow chart repository

Ensure the `repoURL` in `applications/mlflow-application.yaml` points to the Bitnami chart repository:

```bash
https://github.com/DeadNord/hw-mlops.git
```

## 7. Deploy MLflow Application

The ArgoCD Application definition resides in [applications/mlflow-application.yaml](applications/mlflow-application.yaml).

Open <http://localhost:5000> in your browser.

```bash
kubectl apply -f application/mlflow-application.yaml
kubectl get pods -n mlflow
kubectl -n mlflow port-forward svc/mlflow-service 5000:5000
```

## 8. Destroy infrastructure

```bash
terraform destroy -auto-approve
```
