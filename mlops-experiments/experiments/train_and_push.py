"""Train Iris classifiers, log results to MLflow, and push metrics to Prometheus PushGateway."""

from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path
from typing import Dict, List

from dotenv import load_dotenv
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

try:  # prometheus-client>=0.19 removed PushGatewayException
    from prometheus_client.exposition import PushGatewayException
except ImportError:  # pragma: no cover - depends on library version
    PushGatewayException = Exception

load_dotenv()

import mlflow
from sklearn.datasets import load_iris
from sklearn.linear_model import SGDClassifier
from sklearn.metrics import accuracy_score, log_loss
from sklearn.model_selection import train_test_split

MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
EXPERIMENT_NAME = os.getenv("MLFLOW_EXPERIMENT_NAME", "Iris Grid Search")
PUSHGATEWAY_URL = os.getenv(
    "PUSHGATEWAY_URL", "http://pushgateway.monitoring.svc.cluster.local:9091"
)
JOB_NAME = os.getenv("PUSHGATEWAY_JOB", "mlflow_experiments")

PARAM_GRID: List[Dict[str, float]] = [
    {"learning_rate": 0.01, "epochs": 100},
    {"learning_rate": 0.05, "epochs": 150},
    {"learning_rate": 0.1, "epochs": 200},
]


def _push_metrics(run_id: str, accuracy: float, loss: float) -> None:
    """Push metrics for a single run to the configured PushGateway."""
    registry = CollectorRegistry()
    accuracy_gauge = Gauge(
        "mlflow_accuracy",
        "Accuracy collected from MLflow runs",
        ["run_id"],
        registry=registry,
    )
    loss_gauge = Gauge(
        "mlflow_loss",
        "Log loss collected from MLflow runs",
        ["run_id"],
        registry=registry,
    )

    accuracy_gauge.labels(run_id=run_id).set(accuracy)
    loss_gauge.labels(run_id=run_id).set(loss)

    try:
        push_to_gateway(PUSHGATEWAY_URL, job=JOB_NAME, registry=registry)
        print(f"📤 Metrics pushed to PushGateway for run {run_id}")
    except PushGatewayException as exc:  # pragma: no cover - network dependent
        print(f"⚠️  Failed to push metrics for run {run_id}: {exc}")


def _prepare_best_model_dir(best_model_dir: Path) -> None:
    best_model_dir.mkdir(parents=True, exist_ok=True)
    for item in best_model_dir.iterdir():
        if item.name == ".gitkeep":
            continue
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()


def main() -> None:
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    mlflow.set_experiment(EXPERIMENT_NAME)

    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42, stratify=iris.target
    )

    results: List[Dict[str, float]] = []

    for params in PARAM_GRID:
        epochs = int(params["epochs"])
        learning_rate = float(params["learning_rate"])

        with mlflow.start_run(run_name=f"lr={learning_rate}-epochs={epochs}") as run:
            run_id = run.info.run_id
            mlflow.log_params({"learning_rate": learning_rate, "epochs": epochs})

            classifier = SGDClassifier(
                loss="log_loss",
                learning_rate="constant",
                eta0=learning_rate,
                max_iter=epochs,
                tol=1e-3,
                random_state=42,
            )

            classifier.fit(X_train, y_train)
            y_pred = classifier.predict(X_test)
            y_proba = classifier.predict_proba(X_test)

            acc = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_proba)

            mlflow.log_metrics({"accuracy": acc, "loss": loss})
            mlflow.sklearn.log_model(classifier, artifact_path="model")

            print(f"✅ Run {run_id} completed — accuracy: {acc:.4f}, loss: {loss:.4f}")

            _push_metrics(run_id, acc, loss)

            results.append(
                {
                    "run_id": run_id,
                    "accuracy": acc,
                    "loss": loss,
                    "learning_rate": learning_rate,
                    "epochs": epochs,
                }
            )

    if not results:
        raise RuntimeError("No runs were executed, check parameter grid configuration.")

    best_run = max(results, key=lambda item: item["accuracy"])
    print(
        "🏆 Best run:"
        f" {best_run['run_id']} with accuracy={best_run['accuracy']:.4f}"
        f" and loss={best_run['loss']:.4f}"
    )

    project_root = Path(__file__).resolve().parents[1]
    best_model_dir = project_root / "best_model"
    _prepare_best_model_dir(best_model_dir)

    with tempfile.TemporaryDirectory() as tmp_dir:
        local_model_path = mlflow.artifacts.download_artifacts(
            run_id=best_run["run_id"], artifact_path="model", dst_path=tmp_dir
        )
        destination = best_model_dir / "model"
        if Path(local_model_path).is_dir():
            shutil.copytree(local_model_path, destination, dirs_exist_ok=True)
        else:
            shutil.copy2(local_model_path, destination)

    print(f"📦 Best model artifacts copied to {destination}")


if __name__ == "__main__":
    main()
