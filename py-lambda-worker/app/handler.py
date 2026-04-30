import os

from temporalio.common import WorkerDeploymentVersion
from temporalio.contrib.aws.lambda_worker import LambdaWorkerConfig, run_worker

from .activities import greet
from .certs import get_tls_certs
from .workflows import GreetingWorkflow

_deployment_name = os.environ.get("TEMPORAL_DEPLOYMENT_NAME", "py-lambda-worker")
_build_id = os.environ.get("TEMPORAL_BUILD_ID", "v1.0")


def configure(config: LambdaWorkerConfig) -> None:
    config.worker_config["workflows"] = [GreetingWorkflow]
    config.worker_config["activities"] = [greet]
    print(
        f"Configuring worker on task queue: {config.worker_config.get('task_queue')}"
        f" deployment={_deployment_name} build_id={_build_id}"
    )
    tls = get_tls_certs()
    if tls:
        config.client_connect_config["tls"] = tls


# run_worker reads TEMPORAL_ADDRESS, TEMPORAL_NAMESPACE, TEMPORAL_TASK_QUEUE
# from env vars automatically via envconfig. configure() is called synchronously
# at module load (cold start); the returned handler is reused on warm invocations.
lambda_handler = run_worker(
    WorkerDeploymentVersion(deployment_name=_deployment_name, build_id=_build_id),
    configure,
)
