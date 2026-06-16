import asyncio
from dataclasses import dataclass

from temporalio import activity


@dataclass
class GreetingInput:
    """Knobs for the GreetingWorkflow / greet activity, passed in from the starter.

    Everything timing-related lives here so experiments can be run by starting a workflow
    with different numbers — no redeploy needed. See the experiment matrix in the plan.
    """

    name: str = "World"
    sleep_seconds: int = 90
    # Generous by default; with heartbeating the server detects a dead worker via
    # heartbeat_timeout instead of waiting this whole window.
    start_to_close_seconds: int = 600
    heartbeat_timeout_seconds: int = 0  # 0 -> no heartbeat timeout
    heartbeat_interval_seconds: int = 0  # 0 -> don't heartbeat
    resume_from_heartbeat: bool = False
    max_attempts: int = 3


@activity.defn
async def greet(input: GreetingInput) -> str:
    """Sleep for input.sleep_seconds, optionally heartbeating progress each interval.

    On worker graceful drain the activity's asyncio task is cancelled, so the sleep below
    raises CancelledError — we log where we stopped and re-raise. When resume_from_heartbeat
    is set and a previous attempt recorded heartbeat details, we pick up where it left off.
    """
    start = 0
    details = activity.info().heartbeat_details
    if input.resume_from_heartbeat and details:
        start = int(details[0])
        activity.logger.info(
            f"resuming from {start}s (attempt {activity.info().attempt})"
        )

    elapsed = start
    try:
        for elapsed in range(start, input.sleep_seconds):
            await asyncio.sleep(1)
            if (
                input.heartbeat_interval_seconds > 0
                and (elapsed + 1) % input.heartbeat_interval_seconds == 0
            ):
                activity.heartbeat(elapsed + 1)
    except asyncio.CancelledError:
        activity.logger.warning(f"cancelled during graceful drain at {elapsed}s")
        raise

    return (
        f"Hello, {input.name}! (slept {input.sleep_seconds}s, "
        f"attempt {activity.info().attempt}, from Lambda)"
    )
