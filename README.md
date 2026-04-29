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
sam deploy \
    --stack-name py-lambda-worker \
    --resolve-s3 \
    --s3-prefix py-lambda-worker \
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
      AssumeRoleExternalId="python-external-id"
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
