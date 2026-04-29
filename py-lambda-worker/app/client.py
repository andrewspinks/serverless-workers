import asyncio
import time

from temporalio.client import Client

from .workflows import GreetingWorkflow


async def main() -> None:
    client = await Client.connect("localhost:7233")
    result = await client.execute_workflow(
        GreetingWorkflow.run,
        "World",
        id=f"greet-{int(time.time())}",
        task_queue="py-lambda-worker-queue",
    )
    print(result)


if __name__ == "__main__":
    asyncio.run(main())
