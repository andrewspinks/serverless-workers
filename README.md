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
sam deploy --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM 
```

After deploying, note the outputs from `sam deploy`:
- `WorkerFunctionArn` — Lambda function ARN
- `TemporalCloudInvokeRoleArn` — IAM role ARN to register with Temporal Cloud

### Register the deployment version

```sh
DEPNAME=py-lambda-worker
FUNCTION_ARN=<WorkerFunctionArn>
ROLE_ARN=<TemporalCloudInvokeRoleArn>
EXTERNAL_ID=python-external-id

temporal worker deployment create-version \
  --deployment-name $DEPNAME \
  --build-id v1.0 \
  --aws-lambda-function-arn $FUNCTION_ARN \
  --aws-lambda-assume-role-arn $ROLE_ARN \
  --aws-lambda-assume-role-external-id $EXTERNAL_ID
```
