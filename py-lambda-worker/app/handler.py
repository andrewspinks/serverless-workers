import os
from datetime import timedelta

from temporalio.common import WorkerDeploymentVersion
from temporalio.contrib.aws.lambda_worker import LambdaWorkerConfig, run_worker
from temporalio.contrib.aws.lambda_worker.otel import apply_defaults

from .activities import greet
from .temporal_cloud_auth import get_api_key
from .workflows import GreetingWorkflow

_deployment_name = os.environ.get("TEMPORAL_DEPLOYMENT_NAME", "py-lambda-worker")
_build_id = os.environ.get("TEMPORAL_BUILD_ID", "v1.0")


def configure(config: LambdaWorkerConfig) -> None:
    config.worker_config["workflows"] = [GreetingWorkflow]
    config.worker_config["activities"] = [greet]

    # Worker-side shutdown knobs (the docs' "worker stop timeout" == graceful_shutdown_timeout).
    # work_time per invocation = lambda_remaining - shutdown_deadline_buffer; after it elapses the
    # worker drains for up to graceful_shutdown_timeout, then shutdown hooks run.
    graceful = float(os.environ.get("WORKER_GRACEFUL_SHUTDOWN_SECONDS", "5"))
    buffer = float(
        os.environ.get("WORKER_SHUTDOWN_DEADLINE_BUFFER_SECONDS", str(graceful + 2))
    )
    config.worker_config["graceful_shutdown_timeout"] = timedelta(seconds=graceful)
    config.shutdown_deadline_buffer = timedelta(seconds=buffer)

    print(
        f"Configuring worker on task queue: {config.worker_config.get('task_queue')}"
        f" deployment={_deployment_name} build_id={_build_id}"
        f" graceful={graceful}s buffer={buffer}s"
    )

    def _log_shutdown() -> None:
        print(f"[shutdown hook] worker drained; graceful={graceful}s buffer={buffer}s")

    config.shutdown_hooks.append(_log_shutdown)

    api_key = get_api_key()
    if api_key:
        # TLS is auto-enabled by the SDK when an api_key is set (Temporal Cloud).
        config.client_connect_config["api_key"] = api_key
    apply_defaults(config)


# run_worker reads TEMPORAL_ADDRESS, TEMPORAL_NAMESPACE, TEMPORAL_TASK_QUEUE
# from env vars automatically via envconfig. configure() is called synchronously
# at module load (cold start); the returned handler is reused on warm invocations.
lambda_handler = run_worker(
    WorkerDeploymentVersion(deployment_name=_deployment_name, build_id=_build_id),
    configure,
)
