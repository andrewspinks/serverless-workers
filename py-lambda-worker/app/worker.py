import asyncio
import os

from temporalio.client import Client
from temporalio.worker import Worker

from .activities import greet
from .workflows import GreetingWorkflow


async def main() -> None:
    address = os.environ.get("TEMPORAL_ADDRESS", "localhost:7233")
    namespace = os.environ.get("TEMPORAL_NAMESPACE", "default")
    task_queue = os.environ.get("TEMPORAL_TASK_QUEUE", "py-lambda-worker-queue")

    client = await Client.connect(address, namespace=namespace)
    worker = Worker(
        client,
        task_queue=task_queue,
        workflows=[GreetingWorkflow],
        activities=[greet],
    )
    print(f"Starting worker on task queue: {task_queue}")
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())
