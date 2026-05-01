import * as path from "path";
import * as cdk from "aws-cdk-lib";
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";

export interface TsLambdaWorkerStackProps extends cdk.StackProps {
  temporalAddress: string;
  temporalNamespace: string;
  temporalTaskQueue: string;
  deploymentName: string;
  buildId: string;
  assumeRoleExternalId: string;
  tlsCertArn?: string;
  tlsKeyArn?: string;
}

// Temporal Cloud staging accounts allowed to assume the invoke role.
// Production accounts (commented in the original SAM template) can be added when needed.
const TEMPORAL_CLOUD_INVOKER_ARNS = [
  "arn:aws:iam::031568301006:role/wci-lambda-invoke",
  "arn:aws:iam::815250390068:role/wci-lambda-invoke",
];

export class TsLambdaWorkerStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: TsLambdaWorkerStackProps) {
    super(scope, id, props);

    const fn = new lambda.Function(this, "WorkerFunction", {
      description: "Temporal worker running on Lambda",
      runtime: lambda.Runtime.NODEJS_22_X,
      architecture: lambda.Architecture.X86_64,
      handler: "handler.handler",
      code: lambda.Code.fromAsset(path.join(__dirname, "..", "dist-lambda")),
      timeout: cdk.Duration.seconds(60),
      memorySize: 256,
      environment: {
        TEMPORAL_ADDRESS: props.temporalAddress,
        TEMPORAL_NAMESPACE: props.temporalNamespace,
        TEMPORAL_TASK_QUEUE: props.temporalTaskQueue,
        TEMPORAL_DEPLOYMENT_NAME: props.deploymentName,
        TEMPORAL_BUILD_ID: props.buildId,
        TEMPORAL_TLS_CERT_ARN: props.tlsCertArn ?? "",
        TEMPORAL_TLS_KEY_ARN: props.tlsKeyArn ?? "",
      },
      // Retain old versions so workflows pinned to prior build IDs keep executing
      // on the Lambda version they were registered against.
      currentVersionOptions: { removalPolicy: cdk.RemovalPolicy.RETAIN },
    });
    const alias = fn.addAlias("current");

    if (props.tlsCertArn && props.tlsKeyArn) {
      fn.role!.attachInlinePolicy(
        new iam.Policy(this, "TLSSecretsPolicy", {
          statements: [
            new iam.PolicyStatement({
              actions: ["secretsmanager:GetSecretValue"],
              resources: [props.tlsCertArn, props.tlsKeyArn],
            }),
          ],
        }),
      );
    }

    const invokeRole = new iam.Role(this, "TemporalCloudInvokeRole", {
      description: "Role Temporal Cloud assumes to invoke this Lambda worker",
      maxSessionDuration: cdk.Duration.hours(1),
      assumedBy: new iam.CompositePrincipal(
        ...TEMPORAL_CLOUD_INVOKER_ARNS.map((arn) => new iam.ArnPrincipal(arn)),
      ).withConditions({
        StringEquals: { "sts:ExternalId": props.assumeRoleExternalId },
      }),
    });
    invokeRole.attachInlinePolicy(
      new iam.Policy(this, "TemporalCloudInvokePolicy", {
        statements: [
          new iam.PolicyStatement({
            actions: ["lambda:InvokeFunction", "lambda:GetFunction"],
            resources: [fn.functionArn, `${fn.functionArn}:*`],
          }),
        ],
      }),
    );

    new cdk.CfnOutput(this, "WorkerFunctionArn", { value: fn.functionArn });
    new cdk.CfnOutput(this, "WorkerFunctionVersionArn", {
      value: fn.currentVersion.functionArn,
    });
    new cdk.CfnOutput(this, "WorkerFunctionAliasArn", { value: alias.functionArn });
    new cdk.CfnOutput(this, "BuildId", { value: props.buildId });
    new cdk.CfnOutput(this, "TemporalDeploymentName", { value: props.deploymentName });
    new cdk.CfnOutput(this, "AssumeRoleExternalId", { value: props.assumeRoleExternalId });
    new cdk.CfnOutput(this, "TemporalCloudInvokeRoleArn", { value: invokeRole.roleArn });
  }
}
