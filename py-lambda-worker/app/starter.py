import argparse
import asyncio
import os
import time

from temporalio.client import WorkflowFailureError

from .activities import GreetingInput
from .connection import connect
from .workflows import GreetingWorkflow


def _parse_args() -> GreetingInput:
    p = argparse.ArgumentParser(
        description="Start a GreetingWorkflow with tunable long-running-activity settings."
    )
    p.add_argument("--name", default="World")
    p.add_argument("--sleep", type=int, default=90, help="activity sleep seconds")
    p.add_argument("--start-to-close", type=int, default=600, help="start_to_close_timeout seconds")
    p.add_argument("--heartbeat-timeout", type=int, default=0, help="heartbeat_timeout seconds (0=off)")
    p.add_argument("--heartbeat-interval", type=int, default=0, help="heartbeat every N seconds (0=off)")
    p.add_argument("--resume", action="store_true", help="resume from heartbeat details on retry")
    p.add_argument("--max-attempts", type=int, default=3)
    args = p.parse_args()
    return GreetingInput(
        name=args.name,
        sleep_seconds=args.sleep,
        start_to_close_seconds=args.start_to_close,
        heartbeat_timeout_seconds=args.heartbeat_timeout,
        heartbeat_interval_seconds=args.heartbeat_interval,
        resume_from_heartbeat=args.resume,
        max_attempts=args.max_attempts,
    )


async def main() -> None:
    input = _parse_args()
    client = await connect()
    task_queue = os.environ.get("TEMPORAL_TASK_QUEUE", "py-lambda-worker-queue")

    handle = await client.start_workflow(
        GreetingWorkflow.run,
        input,
        id=f"greet-{int(time.time())}",
        task_queue=task_queue,
    )
    print(
        f"Started workflow {handle.id} on task queue {task_queue} with {input};"
        " waiting for result..."
    )
    try:
        print(await handle.result())
    except WorkflowFailureError as e:
        print(f"Workflow failed: {e}")


if __name__ == "__main__":
    asyncio.run(main())
