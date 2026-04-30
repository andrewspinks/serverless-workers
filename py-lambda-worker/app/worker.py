import asyncio
import os

from temporalio.client import Client
from temporalio.common import WorkerDeploymentVersion
from temporalio.worker import Worker, WorkerDeploymentConfig

from .activities import greet
from .workflows import GreetingWorkflow


async def main() -> None:
    address = os.environ.get("TEMPORAL_ADDRESS", "localhost:7233")
    namespace = os.environ.get("TEMPORAL_NAMESPACE", "default")
    task_queue = os.environ.get("TEMPORAL_TASK_QUEUE", "py-lambda-worker-queue")
    deployment_name = os.environ.get("TEMPORAL_DEPLOYMENT_NAME", "py-lambda-worker")
    build_id = os.environ.get("TEMPORAL_BUILD_ID", "v1.0")

    client = await Client.connect(address, namespace=namespace)
    worker = Worker(
        client,
        task_queue=task_queue,
        workflows=[GreetingWorkflow],
        activities=[greet],
        deployment_config=WorkerDeploymentConfig(
            version=WorkerDeploymentVersion(
                deployment_name=deployment_name,
                build_id=build_id,
            ),
            use_worker_versioning=True,
        ),
    )
    print(
        f"Starting worker on task queue: {task_queue}"
        f" deployment={deployment_name} build_id={build_id}"
    )
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())
