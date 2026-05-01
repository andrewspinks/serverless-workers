import * as cdk from "aws-cdk-lib";
import { TsLambdaWorkerStack } from "../lib/ts-lambda-worker-stack";

const app = new cdk.App();
const buildId = app.node.tryGetContext("buildId") ?? "v1.0";
const deploymentName = "ts-lambda-worker";

new TsLambdaWorkerStack(app, "TsLambdaWorker-default", {
  env: { region: "us-east-1" },
  temporalAddress: "localhost:7233",
  temporalNamespace: "default",
  temporalTaskQueue: "lambda-worker-queue",
  deploymentName,
  buildId,
  assumeRoleExternalId: "dummy-external-id",
});

new TsLambdaWorkerStack(app, "TsLambdaWorker-sa-demo", {
  env: { region: "us-east-2" },
  stackName: "aspinks-ts-lambda-worker",
  temporalAddress: "sa-demo-01.temporal-dev.tmprl-test.cloud:7233",
  temporalNamespace: "sa-demo-01.temporal-dev",
  temporalTaskQueue: "lambda-worker-queue-2",
  deploymentName,
  buildId,
  assumeRoleExternalId: "python-external-id",
  tlsCertArn:
    "arn:aws:secretsmanager:us-east-2:429214323166:secret:temporal/serverless/client-cert-SFwM47",
  tlsKeyArn:
    "arn:aws:secretsmanager:us-east-2:429214323166:secret:temporal/serverless/client-key-dTlDRy",
});
