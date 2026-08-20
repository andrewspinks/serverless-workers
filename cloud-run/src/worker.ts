import { readFileSync } from "node:fs";
import { join } from "node:path";
import { NativeConnection, Worker } from "@temporalio/worker";
import * as activities from "./activities";
import { loadConfig } from "./config";
import { installRuntime } from "./runtime";

async function run(): Promise<void> {
  const config = loadConfig();
  installRuntime(config);

  const connection = await NativeConnection.connect({
    address: config.address,
    ...(config.apiKey ? { apiKey: config.apiKey, tls: true } : {}),
  });

  const worker = await Worker.create({
    connection,
    namespace: config.namespace,
    taskQueue: config.taskQueue,
    workflowBundle: {
      code: readFileSync(join(__dirname, "workflow-bundle.js"), "utf8"),
    },
    activities,
    ...(config.useVersioning
      ? {
          workerDeploymentOptions: {
            version: {
              deploymentName: config.deploymentName,
              buildId: config.buildId,
            },
            useWorkerVersioning: true,
            defaultVersioningBehavior: "PINNED" as const,
          },
        }
      : {}),
  });

  console.log(
    `Starting worker: namespace=${config.namespace} taskQueue=${config.taskQueue}` +
      (config.useVersioning
        ? ` deployment=${config.deploymentName} buildId=${config.buildId}`
        : " versioning=off"),
  );

  try {
    await worker.run();
  } finally {
    await connection.close();
  }
}

run().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
