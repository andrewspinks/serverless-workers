#!/usr/bin/env bash
set -euo pipefail

# Normalize to py-lambda-worker/ regardless of where the script is called from
cd "$(dirname "$0")/.."

# Config comes from the active mise environment — select one with MISE_ENV, e.g.
#   MISE_ENV=staging mise run deploy
# AWS_PROFILE is read from the environment by the aws & sam CLIs. AWS_REGION must be passed
# explicitly via --region: `sam deploy` does NOT honor the AWS_REGION env var and otherwise
# falls back to the profile's default region (~/.aws/config).
: "${AWS_REGION:?set MISE_ENV=staging|prod (AWS_REGION missing)}"
: "${AWS_PROFILE:?set MISE_ENV=staging|prod (AWS_PROFILE missing)}"
: "${STACK_NAME:?set MISE_ENV=staging|prod (STACK_NAME missing)}"
: "${TEMPORAL_ADDRESS:?TEMPORAL_ADDRESS missing}"
: "${TEMPORAL_NAMESPACE:?TEMPORAL_NAMESPACE missing}"
: "${TEMPORAL_TASK_QUEUE:?TEMPORAL_TASK_QUEUE missing}"
: "${TEMPORAL_API_KEY_PARAM:?TEMPORAL_API_KEY_PARAM missing}"
: "${ASSUME_ROLE_EXTERNAL_ID:?ASSUME_ROLE_EXTERNAL_ID missing}"

CURRENT=$(cat VERSION)

if [ -n "${1:-}" ]; then
    NEW_VERSION="$1"
else
    BASE="${CURRENT#v}"
    MAJOR=$(echo "$BASE" | cut -d. -f1)
    MINOR=$(echo "$BASE" | cut -d. -f2)
    NEW_VERSION="v${MAJOR}.$((MINOR + 1))"
fi

echo "→ Deploying ${STACK_NAME} BuildId=${NEW_VERSION} (was ${CURRENT}) to ${AWS_REGION}"

# One-time setup (run once before the first deploy): store the Temporal Cloud API key as an
# SSM SecureString that this worker fetches and decrypts at cold start:
#
#   aws ssm put-parameter --name "$TEMPORAL_API_KEY_PARAM" --type SecureString \
#       --value "<temporal-cloud-api-key>"
#
# NOTE: API key auth uses the regional gRPC endpoint, NOT the *.tmprl.cloud mTLS endpoint.
# Set TEMPORAL_ADDRESS (in mise.<env>.toml) to the API-key endpoint for your environment.
sam deploy \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --resolve-s3 \
    --s3-prefix "$STACK_NAME" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --confirm-changeset \
    --parameter-overrides \
        TemporalAddress="$TEMPORAL_ADDRESS" \
        TemporalNamespace="$TEMPORAL_NAMESPACE" \
        TemporalTaskQueue="$TEMPORAL_TASK_QUEUE" \
        TemporalApiKeyParam="$TEMPORAL_API_KEY_PARAM" \
        AssumeRoleExternalId="$ASSUME_ROLE_EXTERNAL_ID" \
        BuildId="${NEW_VERSION}" \
        FunctionTimeout="${FUNCTION_TIMEOUT:-180}" \
        WorkerGracefulShutdownSeconds="${WORKER_GRACEFUL_SHUTDOWN_SECONDS:-10}" \
        WorkerShutdownDeadlineBufferSeconds="${WORKER_SHUTDOWN_DEADLINE_BUFFER_SECONDS:-15}"

echo "${NEW_VERSION}" > VERSION
echo "✓ VERSION updated to ${NEW_VERSION}"
