#!/usr/bin/env bash
set -euo pipefail

# Normalize to py-lambda-worker/ regardless of where the script is called from
cd "$(dirname "$0")/.."

# STACK_NAME / AWS_REGION come from the active mise environment (MISE_ENV=staging|prod).
# AWS_PROFILE is read from the environment by the aws CLI; --region is passed explicitly so
# describe-stacks targets the right region (a wrong region would silently return no outputs).
: "${STACK_NAME:?set MISE_ENV=staging|prod (STACK_NAME missing)}"
: "${AWS_REGION:?set MISE_ENV=staging|prod (AWS_REGION missing)}"

query_output() {
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" \
    --output text
}
query_param() {
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Parameters[?ParameterKey=='$1'].ParameterValue" \
    --output text
}

FUNCTION_VERSION_ARN=$(query_output WorkerFunctionVersionArn)
ROLE_ARN=$(query_output TemporalCloudInvokeRoleArn)
BUILD_ID=$(query_output BuildId)
DEPLOY_NAME=$(query_param TemporalDeploymentName)
EXTERNAL_ID=$(query_param AssumeRoleExternalId)

cat <<EOF

Run this to register the deployed version with Temporal Cloud:

temporal worker deployment create-version \\
  --deployment-name $DEPLOY_NAME \\
  --build-id $BUILD_ID \\
  --aws-lambda-function-arn $FUNCTION_VERSION_ARN \\
  --aws-lambda-assume-role-arn $ROLE_ARN \\
  --aws-lambda-assume-role-external-id $EXTERNAL_ID

EOF
