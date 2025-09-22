terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ----------------------
# IAM role for Lambda functions
# ----------------------
resource "aws_iam_role" "lambda_exec" {
  name = "mlops-train-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ----------------------
# Lambda functions used by the pipeline
# ----------------------
resource "aws_lambda_function" "validate" {
  function_name = "mlops-train-validate"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "validate.handler"
  runtime       = "python3.10"

  filename         = "${path.module}/lambda/validate.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/validate.zip")
}

resource "aws_lambda_function" "log_metrics" {
  function_name = "mlops-train-log-metrics"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "log_metrics.handler"
  runtime       = "python3.10"

  filename         = "${path.module}/lambda/log_metrics.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/log_metrics.zip")
}

# ----------------------
# IAM role for Step Functions state machine
# ----------------------
resource "aws_iam_role" "step_functions_exec" {
  name = "mlops-train-step-functions-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_functions_invoke_lambda" {
  name = "mlops-train-step-functions-invoke-lambda"
  role = aws_iam_role.step_functions_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.validate.arn,
          aws_lambda_function.log_metrics.arn
        ]
      }
    ]
  })
}

# ----------------------
# Step Functions state machine orchestrating the workflow
# ----------------------
resource "aws_sfn_state_machine" "training_pipeline" {
  name     = "mlops-train-pipeline"
  role_arn = aws_iam_role.step_functions_exec.arn

  definition = jsonencode({
    Comment = "Automated ML training pipeline with validation and metric logging"
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type     = "Task"
        Resource = aws_lambda_function.validate.arn
        Next     = "LogMetrics"
      }
      LogMetrics = {
        Type     = "Task"
        Resource = aws_lambda_function.log_metrics.arn
        End      = true
      }
    }
  })
}
