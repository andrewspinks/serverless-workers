import asyncio
import os
import time

from .connection import connect
from .workflows import GreetingWorkflow


async def main() -> None:
    client = await connect()
    task_queue = os.environ.get("TEMPORAL_TASK_QUEUE", "py-lambda-worker-queue")

    handle = await client.start_workflow(
        GreetingWorkflow.run,
        "World",
        id=f"greet-{int(time.time())}",
        task_queue=task_queue,
    )
    print(f"Started workflow {handle.id} on task queue {task_queue}; waiting for result...")
    print(await handle.result())


if __name__ == "__main__":
    asyncio.run(main())
