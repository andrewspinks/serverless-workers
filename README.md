# Serverless AWS Lambda workers

## TypeScript worker
NB: this requires a locally built version of the typescript-sdk. It deploys successfully, but is getting runtime errors. Probably due to how I'm packaging it up.

```sh
cd ts-lambda-worker
pnpm build
sam build --build-in-source
sam deploy --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM 
```

## Python worker

```sh
cd py-lambda-worker
sam build
sam deploy --config-env sa-demo
```

Or using the raw flags (equivalent to what `samconfig.toml` encodes):

```sh
sam deploy \
    --stack-name aspinks-py-lambda-worker \
    --resolve-s3 \
    --s3-prefix aspinks-py-lambda-worker \
    --profile SolutionsArchitecture/AWSAdministratorAccess \
    --confirm-changeset \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region us-east-2 \
    --parameter-overrides \
      TemporalAddress="sa-demo-01.temporal-dev.tmprl-test.cloud:7233" \
      TemporalNamespace="sa-demo-01.temporal-dev" \
      TemporalTaskQueue="py-lambda-worker-queue" \
      TemporalTLSCertArn="arn:aws:secretsmanager:us-east-2:429214323166:secret:temporal/serverless/client-cert-SFwM47" \
      TemporalTLSKeyArn="arn:aws:secretsmanager:us-east-2:429214323166:secret:temporal/serverless/client-key-dTlDRy" \
      AssumeRoleExternalId="python-external-id" \
      BuildId="v1.0"
```

### How versioning works

Each `sam deploy` publishes an immutable Lambda version and outputs its ARN as `WorkerFunctionVersionArn`. You register that ARN with Temporal Cloud as the execution target for a specific `build_id`. Temporal then pins each workflow execution to the Lambda version that first ran it, so rolling forward only affects new executions.

```
BuildId="v1.0"  →  Lambda version 1 ARN  →  registered with Temporal as build v1.0
BuildId="v2.0"  →  Lambda version 2 ARN  →  registered with Temporal as build v2.0
```

Old workflows pinned to v1.0 keep invoking Lambda version 1. New workflows are routed to v2.0.

> **Note**: SAM only publishes a new Lambda version when code or configuration actually changes.
> Always pair a `BuildId` bump with workflow or activity code changes.

### Register a deployment version

After `sam deploy`, run:

```sh
just register-version
```

temporal worker deployment create-version \
    --deployment-name $DEPLOY_NAME \
    --build-id $BUILD_ID \
    --aws-lambda-function-arn $FUNCTION_VERSION_ARN \
    --aws-lambda-assume-role-arn $ROLE_ARN \
    --aws-lambda-assume-role-external-id $EXTERNAL_ID

This queries the CloudFormation stack outputs and prints the `temporal worker deployment create-version` command to run. Copy and execute it to register the new version with Temporal Cloud.

To promote the new version to handle new workflow executions:

```sh
temporal worker deployment set-current \
  --deployment-name py-lambda-worker \
  --build-id v1.0
```

### Deploying a new version

1. Make workflow/activity code changes
2. Bump `BuildId` in `samconfig.toml` (e.g. `v1.0` → `v2.0`)
3. `just sam-build && just deploy`
4. `just register-version` — copy and run the printed command
5. `temporal worker deployment set-current --deployment-name py-lambda-worker --build-id v2.0`

### Local development

```sh
temporal server start-dev          # terminal 1
just run-worker                    # terminal 2 — long-running worker polling locally
just start-workflow                # terminal 3 — trigger a test workflow
```
