"""Lambda function that performs input validation for the training pipeline."""

def handler(event, context):
    """Mock validation step."""
    print("✅ Validating input data...")
    validation_report = {
        "status": "valid",
        "details": "Sample validation succeeded",
        "received": event,
    }
    return validation_report