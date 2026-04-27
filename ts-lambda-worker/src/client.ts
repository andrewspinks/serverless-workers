import { Client } from '@temporalio/client';
import { greetingWorkflow } from './workflows';

async function run(): Promise<void> {
  const client = new Client();
  const result = await client.workflow.execute(greetingWorkflow, {
    workflowId: `greet-${Date.now()}`,
    taskQueue: 'lambda-worker-queue',
    args: ['World'],
  });
  console.log(result);
}

run().catch(console.error);
