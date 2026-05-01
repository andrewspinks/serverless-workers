import type { Context } from 'aws-lambda';
import { readFileSync } from 'fs';
import { runWorker } from '@temporalio/lambda-worker';
import type { LambdaHandler } from '@temporalio/lambda-worker';
import * as activities from './activities';
import { getTLSCerts } from './certs';

// Read at module load time (cold start) — avoids re-reading on warm invocations.
// CWD on Lambda is /var/task, where workflow-bundle.js is deployed alongside handler.js.
const workflowBundleCode = readFileSync('./workflow-bundle.js', 'utf8');

let handlerPromise: Promise<LambdaHandler> | undefined;

async function createHandler(): Promise<LambdaHandler> {
  const tls = await getTLSCerts();
  const deploymentName = process.env['TEMPORAL_DEPLOYMENT_NAME'] ?? 'ts-lambda-worker';
  const buildId = process.env['TEMPORAL_BUILD_ID'] ?? 'v1.0';
  return runWorker(
    { deploymentName, buildId },
    (config) => {
      config.workerOptions.taskQueue = process.env['TEMPORAL_TASK_QUEUE'] ?? 'lambda-worker-queue';
      config.workerOptions.workflowBundle = { code: workflowBundleCode };
      config.workerOptions.activities = activities;
      if (tls) {
        config.connectionOptions = { ...config.connectionOptions, tls };
      }
    },
  );
}

export const handler = async (event: unknown, context: Context): Promise<void> =>
  (await (handlerPromise ??= createHandler()))(event, context);
