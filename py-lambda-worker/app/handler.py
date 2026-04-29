from temporalio.common import WorkerDeploymentVersion
from temporalio.contrib.aws.lambda_worker import LambdaWorkerConfig, run_worker

from .activities import greet
from .certs import get_tls_certs
from .workflows import GreetingWorkflow


def configure(config: LambdaWorkerConfig) -> None:
    config.worker_config["workflows"] = [GreetingWorkflow]
    config.worker_config["activities"] = [greet]
    # task_queue is pre-populated from TEMPORAL_TASK_QUEUE env var
    print(f"Configuring worker on task queue: {config.worker_config.get('task_queue')}")
    tls = get_tls_certs()
    if tls:
        config.client_connect_config["tls"] = tls


# run_worker reads TEMPORAL_ADDRESS, TEMPORAL_NAMESPACE, TEMPORAL_TASK_QUEUE
# from env vars automatically via envconfig. configure() is called synchronously
# at module load (cold start); the returned handler is reused on warm invocations.
lambda_handler = run_worker(
    WorkerDeploymentVersion(deployment_name="py-lambda-worker", build_id="v1.0"),
    configure,
)
