import { Client, Connection } from "@temporalio/client";
import { loadConfig } from "./config";
import { greetingWorkflow } from "./workflows";

async function run(): Promise<void> {
  const config = loadConfig();
  const name = process.argv[2] ?? "World";
  const connection = await Connection.connect({
    address: config.address,
    ...(config.apiKey ? { apiKey: config.apiKey, tls: true } : {}),
  });
  const client = new Client({ connection, namespace: config.namespace });

  try {
    const workflowId = `cloud-run-greeting-${Date.now()}`;
    console.log(`Starting ${workflowId} on ${config.taskQueue}`);
    const result = await client.workflow.execute(greetingWorkflow, {
      workflowId,
      taskQueue: config.taskQueue,
      args: [name],
    });
    console.log(result);
  } finally {
    await connection.close();
  }
}

run().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
