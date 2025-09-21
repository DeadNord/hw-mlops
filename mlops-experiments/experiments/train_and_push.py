"""Train Iris classifiers, log to MLflow, and push metrics to PushGateway.
Now with a big hyper-parameter grid and many repeated runs.
"""

from __future__ import annotations

import itertools
import os
import random
import shutil
import tempfile
import time
from pathlib import Path
from typing import Dict, List, Optional

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


# ---------------------------- Config from env ---------------------------- #
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
EXPERIMENT_NAME = os.getenv("MLFLOW_EXPERIMENT_NAME", "Iris Grid Search (wide)")
PUSHGATEWAY_URL = os.getenv(
    "PUSHGATEWAY_URL", "http://pushgateway.monitoring.svc.cluster.local:9091"
)
JOB_NAME = os.getenv("PUSHGATEWAY_JOB", "mlflow_experiments")

# Глобальные «рычаги» длительности:
MAX_RUNS = int(os.getenv("MAX_RUNS", "400"))  # верхний предел числа запусков
N_SEEDS = int(os.getenv("N_SEEDS", "5"))  # сколько разных random_state


# Сетки (можно переопределить строками вида "0.001,0.003,0.01")
def _floats(env_name: str, default: str) -> List[float]:
    raw = os.getenv(env_name, default).replace(" ", "")
    return [float(x) for x in raw.split(",") if x]


def _ints(env_name: str, default: str) -> List[int]:
    raw = os.getenv(env_name, default).replace(" ", "")
    return [int(float(x)) for x in raw.split(",") if x]  # поддержка "400.0"


LEARNING_RATES = _floats("LR_LIST", "0.001,0.003,0.01,0.03,0.05,0.07,0.1")
EPOCHS_LIST = _ints("EPOCHS_LIST", "50,100,200,400")
ALPHAS_LIST = _floats("ALPHAS_LIST", "1e-05,1e-04,1e-03")
PENALTIES = os.getenv("PENALTIES", "l2,elasticnet").replace(" ", "").split(",")
L1_RATIOS = _floats("L1_RATIOS", "0.15,0.5")  # используется только для elasticnet

# ------------------------------------------------------------------------ #


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
    except PushGatewayException as exc:  # pragma: no cover
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


def _grid() -> List[Dict[str, Optional[float]]]:
    """Build a wide grid and (optionally) downsample to MAX_RUNS."""
    combos: List[Dict[str, Optional[float]]] = []

    for lr, epochs, alpha, penalty in itertools.product(
        LEARNING_RATES, EPOCHS_LIST, ALPHAS_LIST, PENALTIES
    ):
        if penalty == "elasticnet":
            for l1 in L1_RATIOS:
                for seed in range(N_SEEDS):
                    combos.append(
                        dict(
                            learning_rate=lr,
                            epochs=epochs,
                            alpha=alpha,
                            penalty=penalty,
                            l1_ratio=l1,
                            seed=seed,
                        )
                    )
        else:
            for seed in range(N_SEEDS):
                combos.append(
                    dict(
                        learning_rate=lr,
                        epochs=epochs,
                        alpha=alpha,
                        penalty=penalty,
                        l1_ratio=None,
                        seed=seed,
                    )
                )

    # Сэмплинг, чтобы не улететь в тысячи запусков по умолчанию
    random.seed(42)
    if len(combos) > MAX_RUNS:
        combos = random.sample(combos, MAX_RUNS)

    return combos


def main() -> None:
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    mlflow.set_experiment(EXPERIMENT_NAME)

    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42, stratify=iris.target
    )

    results: List[Dict[str, float]] = []

    for i, params in enumerate(_grid(), start=1):
        epochs = int(params["epochs"])
        learning_rate = float(params["learning_rate"])
        alpha = float(params["alpha"])
        penalty = str(params["penalty"])
        l1_ratio = None if params["l1_ratio"] is None else float(params["l1_ratio"])
        seed = int(params["seed"])

        run_name = f"lr={learning_rate}-ep={epochs}-alpha={alpha}-pen={penalty}"
        if penalty == "elasticnet":
            run_name += f"-l1={l1_ratio}"
        run_name += f"-seed={seed}"

        t0 = time.perf_counter()
        with mlflow.start_run(run_name=run_name) as run:
            run_id = run.info.run_id
            mlflow.log_params(
                {
                    "learning_rate": learning_rate,
                    "epochs": epochs,
                    "alpha": alpha,
                    "penalty": penalty,
                    "l1_ratio": l1_ratio,
                    "seed": seed,
                }
            )

            clf_kwargs = dict(
                loss="log_loss",
                learning_rate="constant",
                eta0=learning_rate,
                max_iter=epochs,
                tol=1e-4,  # маленький tol, чтобы не останавливаться слишком рано
                alpha=alpha,
                penalty=penalty,
                random_state=seed,
                average=False,
            )

            if penalty == "elasticnet" and l1_ratio is not None:
                clf_kwargs["l1_ratio"] = l1_ratio

            clf = SGDClassifier(**clf_kwargs)

            clf.fit(X_train, y_train)
            y_pred = clf.predict(X_test)
            y_proba = clf.predict_proba(X_test)

            acc = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_proba)
            train_time = time.perf_counter() - t0

            mlflow.log_metrics(
                {"accuracy": acc, "loss": loss, "train_time_sec": train_time}
            )
            mlflow.sklearn.log_model(clf, artifact_path="model")

            print(
                f"✅ [{i:04d}] {run_id} | acc={acc:.4f} loss={loss:.4f} "
                f"| {train_time:.3f}s"
            )

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
        raise RuntimeError("No runs were executed, check configuration.")

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
        src = Path(local_model_path)
        if src.is_dir():
            shutil.copytree(src, destination, dirs_exist_ok=True)
        else:
            shutil.copy2(src, destination)

    print(f"📦 Best model artifacts copied to {destination}")


if __name__ == "__main__":
    main()
