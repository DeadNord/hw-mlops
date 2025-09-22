# Automated ML Training Pipeline on AWS

This repository demonstrates how to orchestrate a simple machine learning training workflow using AWS Step Functions, AWS Lambda, Terraform, and GitLab CI. The sample pipeline contains two Lambda-powered stages:

1. **ValidateData** – performs basic validation of the input payload.
2. **LogMetrics** – logs mock training metrics.

The infrastructure is fully reproducible via Terraform and the pipeline can be triggered automatically from GitLab CI/CD.

## Project structure

```
.
├── .gitlab-ci.yml                # CI job that triggers the Step Function
├── README.md                     # Documentation and usage instructions
└── terraform
    ├── lambda
    │   ├── log_metrics.py        # Lambda code for logging metrics
    │   ├── log_metrics.zip       # Packaged Lambda artifact
    │   ├── validate.py           # Lambda code for data validation
    │   └── validate.zip          # Packaged Lambda artifact
    ├── main.tf                   # Terraform resources (IAM, Lambda, Step Function)
    └── variables.tf              # Shared Terraform variables
```

## Prerequisites

- Terraform >= 1.4.0
- AWS CLI configured with credentials that can create IAM, Lambda, and Step Functions resources
- Python 3.10 (to run the Lambda code locally if needed)

## 1. Package the Lambda functions

Terraform expects pre-built `.zip` archives for each Lambda function. Recreate the archives whenever you modify the Python files.

```bash
cd terraform/lambda
zip validate.zip validate.py
zip log_metrics.zip log_metrics.py
cd ../..
```

## 2. Deploy the infrastructure with Terraform

Initialize Terraform and apply the configuration. The default region is `us-east-1`, but you can override it by setting the `aws_region` variable (e.g., using `-var aws_region=eu-central-1`).

```bash
cd terraform
terraform init
terraform apply
```

Terraform provisions:

- An IAM execution role for the Lambda functions
- Two Lambda functions (`mlops-train-validate`, `mlops-train-log-metrics`)
- An IAM execution role for Step Functions
- A Step Functions state machine (`mlops-train-pipeline`) that runs the two Lambda tasks sequentially

Record the ARN of the created state machine—it is required for the CI pipeline and manual executions.

## 3. Manually run the Step Function

You can trigger the workflow directly from the AWS Console or via the AWS CLI:

```bash
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:REGION:ACCOUNT_ID:stateMachine:mlops-train-pipeline \
  --name "manual-$(date +%s)" \
  --input '{"source": "manual", "note": "quick validation run"}'
```

Check the execution history in the Step Functions console to confirm both Lambda steps completed successfully.

## 4. GitLab CI integration

The `.gitlab-ci.yml` file defines a single `train-model` job that starts the Step Function every time code is pushed to the `main` branch.

```yaml
stages:
  - train

train-model:
  stage: train
  image: amazon/aws-cli:2.15.0
  script:
    - echo "🚀 Starting ML pipeline via Step Function"
    - aws stepfunctions start-execution \
      --state-machine-arn "$STEP_FUNCTION_ARN" \
      --name "train-$(date +%s)" \
      --input '{"source":"gitlab-ci","commit":"'"$CI_COMMIT_SHORT_SHA"'"}'
  only:
    - main
```

### Required CI/CD variables

Configure the following variables in the GitLab project settings (either via classic access keys or the recommended OIDC integration):

- `AWS_ACCESS_KEY_ID` – IAM user access key (only if you use static credentials)
- `AWS_SECRET_ACCESS_KEY` – IAM user secret key (only if you use static credentials)
- `AWS_DEFAULT_REGION` – AWS region that hosts the Step Function (e.g., `us-east-1`)
- `STEP_FUNCTION_ARN` – ARN of the `mlops-train-pipeline` state machine created by Terraform

When using GitLab OpenID Connect, replace the static keys with the appropriate `AWS_ROLE_ARN` / `AWS_WEB_IDENTITY_TOKEN_FILE` environment configuration.

## 5. Example JSON payload

The CI job sends the following JSON document to the Step Function:

```json
{
  "source": "gitlab-ci",
  "commit": "<CI_COMMIT_SHORT_SHA>"
}
```

Both Lambda functions receive this payload as input, allowing you to expand the workflow with additional context (e.g., branch, hyperparameters, dataset identifiers).

## Cleanup

Destroy all AWS resources when you finish experimenting:

```bash
cd terraform
terraform destroy
```

This prevents unnecessary AWS charges.
