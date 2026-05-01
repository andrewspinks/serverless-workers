import { existsSync, readFileSync } from "fs";
import * as path from "path";
import * as cdk from "aws-cdk-lib";
import { TsLambdaWorkerStack } from "../lib/ts-lambda-worker-stack";

const app = new cdk.App();

// BuildId resolution order: --context buildId=... > VERSION file > "v1.0"
// scripts/deploy.sh passes the bumped version via context; bare `cdk synth`
// falls back to whatever VERSION currently holds.
const versionFile = path.join(__dirname, "..", "VERSION");
const buildId =
  app.node.tryGetContext("buildId") ??
  (existsSync(versionFile) ? readFileSync(versionFile, "utf8").trim() : "v1.0");

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
