# Guide to HW

# Ініціалізація S3-бакету та DynamoDB-таблиці:
```bash
aws s3api create-bucket \
    --bucket hw-5-terraform \
    --region eu-central-1 \
    --create-bucket-configuration LocationConstraint=eu-central-1

aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema            AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region eu-central-1
```

# Ініціалізація Terraform:
```bash
cd ./src
# terraform init
terraform init -migrate-state
terraform init -reconfigure
```

# Підключення Terraform до S3-бакету та DynamoDB-таблиці:
```bash
terraform import module.s3_backend.aws_s3_bucket.this  hw-5-6-terraform
terraform import module.s3_backend.aws_dynamodb_table.this terraform-locks
```
# Check
```bash
terraform state list | grep module.s3_backend
```

# Використання Terraform:
```bash
terraform validate
terraform plan
terraform apply
```

# Перевірка роботи:
```bash
terraform output
terraform output -raw cluster_name
```

# Перевірка нодів:
```bash
kubectl get pods
kubectl get hpa
```

# Видалення ресурсів:
```bash
terraform destroy

cd ../

bash purge-and-delete-s3.sh hw-5-6-terraform eu-central-1
```
