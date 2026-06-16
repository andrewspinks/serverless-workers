from datetime import timedelta

from temporalio import workflow
from temporalio.common import RetryPolicy, VersioningBehavior

with workflow.unsafe.imports_passed_through():
    from .activities import GreetingInput, greet


@workflow.defn(versioning_behavior=VersioningBehavior.PINNED)
class GreetingWorkflow:
    @workflow.run
    async def run(self, input: GreetingInput) -> str:
        kwargs = dict(
            start_to_close_timeout=timedelta(seconds=input.start_to_close_seconds),
            retry_policy=RetryPolicy(maximum_attempts=input.max_attempts),
        )
        if input.heartbeat_timeout_seconds > 0:
            kwargs["heartbeat_timeout"] = timedelta(
                seconds=input.heartbeat_timeout_seconds
            )
        return await workflow.execute_activity(greet, input, **kwargs)
