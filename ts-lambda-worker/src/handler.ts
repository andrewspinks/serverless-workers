import { runWorker } from '@temporalio/lambda-worker';
import * as activities from './activities';

export const handler = runWorker(
  { deploymentName: 'ts-lambda-worker', buildId: 'v1.0' },
  (config) => {
    config.workerOptions.taskQueue = 'lambda-worker-queue';
    // Pre-bundled at build time — avoids webpack overhead on cold starts
    config.workerOptions.workflowBundle = { code: require('./workflow-bundle.js') };
    config.workerOptions.activities = activities;
  },
);
