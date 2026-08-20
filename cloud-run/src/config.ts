export interface TemporalConfig {
  address: string;
  namespace: string;
  taskQueue: string;
  deploymentName: string;
  buildId: string;
  environment: string;
  useVersioning: boolean;
  metricsEndpoint?: string;
  apiKey?: string;
}

type Environment = NodeJS.ProcessEnv;

function optionalValue(
  environment: Environment,
  name: string,
): string | undefined {
  const value = environment[name]?.trim();
  return value ? value : undefined;
}

export function loadConfig(
  environment: Environment = process.env,
): TemporalConfig {
  const apiKey = optionalValue(environment, "TEMPORAL_API_KEY");
  const metricsEndpoint = optionalValue(
    environment,
    "TEMPORAL_METRICS_OTEL_URL",
  );

  return {
    address: optionalValue(environment, "TEMPORAL_ADDRESS") ?? "localhost:7233",
    namespace: optionalValue(environment, "TEMPORAL_NAMESPACE") ?? "default",
    taskQueue:
      optionalValue(environment, "TEMPORAL_TASK_QUEUE") ?? "cloud-run-worker",
    deploymentName:
      optionalValue(environment, "TEMPORAL_DEPLOYMENT_NAME") ??
      "cloud-run-worker",
    buildId: optionalValue(environment, "TEMPORAL_BUILD_ID") ?? "local",
    environment:
      optionalValue(environment, "DEPLOYMENT_ENVIRONMENT") ?? "local",
    useVersioning: environment["TEMPORAL_USE_VERSIONING"] === "true",
    ...(metricsEndpoint ? { metricsEndpoint } : {}),
    ...(apiKey ? { apiKey } : {}),
  };
}
