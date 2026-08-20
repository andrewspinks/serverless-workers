import assert from "node:assert/strict";
import test from "node:test";
import { loadConfig } from "./config";

void test("uses local defaults", () => {
  assert.deepEqual(loadConfig({}), {
    address: "localhost:7233",
    namespace: "default",
    taskQueue: "cloud-run-worker",
    deploymentName: "cloud-run-worker",
    buildId: "local",
    environment: "local",
    useVersioning: false,
  });
});

void test("loads cloud and telemetry settings", () => {
  assert.deepEqual(
    loadConfig({
      TEMPORAL_ADDRESS: "example.tmprl.cloud:7233",
      TEMPORAL_NAMESPACE: "example.namespace",
      TEMPORAL_TASK_QUEUE: "greetings",
      TEMPORAL_DEPLOYMENT_NAME: "greeting-worker",
      TEMPORAL_BUILD_ID: "2026.08.20",
      TEMPORAL_API_KEY: "secret",
      TEMPORAL_USE_VERSIONING: "true",
      TEMPORAL_METRICS_OTEL_URL: "http://127.0.0.1:4317",
      DEPLOYMENT_ENVIRONMENT: "demo",
    }),
    {
      address: "example.tmprl.cloud:7233",
      namespace: "example.namespace",
      taskQueue: "greetings",
      deploymentName: "greeting-worker",
      buildId: "2026.08.20",
      environment: "demo",
      useVersioning: true,
      metricsEndpoint: "http://127.0.0.1:4317",
      apiKey: "secret",
    },
  );
});
