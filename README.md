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

## 6. Bootstrap the ML Ops stack via ArgoCD

Apply the application-of-applications manifest from this repository. It points ArgoCD at the `mlops-experiments/argocd/applications/` directory so every component manifest committed there becomes part of the stack automatically. За потреби змініть поле `targetRevision` у маніфесті, щоб синхронізувати іншу гілку репозиторію.

```bash
kubectl apply -f application/mlflow-application.yaml
kubectl get applications -n infra-tools
```

## 7. Confirm ArgoCD synchronization

Після створення застосунку `mlops-stack` ArgoCD автоматично розгорне дочірні застосунки `minio`, `mlflow-postgres`, `mlflow` та `pushgateway`. Стежте за статусом через UI або командою:

```bash
kubectl get applications -n infra-tools
```

Переходьте далі, коли всі застосунки матимуть стан `Healthy/Synced`.

## 8. Перевірте стани подів та сервісів

Після синхронізації впевніться, що всі компоненти готові:

```bash
kubectl get pods -n application
kubectl get pods -n monitoring
kubectl get svc -n application
kubectl get svc -n monitoring
```

В ArgoCD усі застосунки мають бути в статусі `Healthy/Synced`.

## 9. Налаштуйте port-forward для MLflow, MinIO та PushGateway

Для локального запуску експериментів відкрийте доступ до необхідних сервісів:

```bash
# MLflow Tracking UI
kubectl -n application port-forward svc/mlflow 5000:5000

# MinIO S3 endpoint
kubectl -n application port-forward svc/minio 9000:9000

# (за потреби) Prometheus PushGateway
kubectl -n monitoring port-forward svc/pushgateway-prometheus-pushgateway 9091:9091
```

## 10. Підготуйте локальне середовище для експериментів

```bash
cd mlops-experiments/experiments
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Створіть файл `.env` поряд із `train_and_push.py` зі змінними середовища:

```env
MLFLOW_TRACKING_URI=http://localhost:5000
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
MLFLOW_S3_ENDPOINT_URL=http://localhost:9000
PUSHGATEWAY_URL=http://pushgateway.monitoring.svc.cluster.local:9091
```

Оновіть значення під свій кластер, якщо потрібно.

## 11. Запустіть `train_and_push.py`

1. Переконайтеся, що port-forward активні.
2. Запустіть експеримент:

   ```bash
   python train_and_push.py
   ```

Скрипт виконає декілька прогонів з різними параметрами, залогує їх у MLflow, надішле метрики `mlflow_accuracy` та `mlflow_loss` у PushGateway і збереже найкращу модель у `mlops-experiments/best_model/`.

## 12. Перегляньте результати в MLflow та Grafana

- MLflow UI: відкрийте <http://localhost:5000> і знайдіть експеримент **Iris Grid Search**.
- Grafana → Explore → Prometheus: виконайте запити `mlflow_accuracy` та `mlflow_loss`, щоб побачити метрики з лейблом `run_id`.

Додайте власні скриншоти інтерфейсів до `docs/screenshots/mlflow-ui.png` і `docs/screenshots/grafana-explore.png`.

## 13. Виконайте додаткові перевірки

```bash
kubectl get events -n application --sort-by=.metadata.creationTimestamp | tail
kubectl -n monitoring exec deploy/pushgateway-prometheus-pushgateway --   wget -qO- http://localhost:9091/metrics | grep mlflow
```

## 14. Destroy infrastructure

```bash
terraform destroy -auto-approve
```
