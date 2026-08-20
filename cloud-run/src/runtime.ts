import { DefaultLogger, Runtime } from "@temporalio/worker";
import type { TemporalConfig } from "./config";

export function installRuntime(config: TemporalConfig): void {
  Runtime.install({
    logger: new DefaultLogger("INFO"),
    telemetryOptions: {
      logging: {
        filter: { core: "INFO", other: "WARN" },
        forward: {},
      },
      ...(config.metricsEndpoint
        ? {
            metrics: {
              metricPrefix: "temporal_",
              globalTags: {
                environment: config.environment,
                namespace: config.namespace,
                task_queue: config.taskQueue,
                deployment_name: config.deploymentName,
                build_id: config.buildId,
              },
              otel: {
                url: config.metricsEndpoint,
                metricsExportInterval: "10 seconds",
                useSecondsForDurations: true,
                temporality: "cumulative" as const,
              },
            },
          }
        : {}),
    },
  });
}
