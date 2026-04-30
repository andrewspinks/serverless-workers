#!/usr/bin/env bash
set -euo pipefail

# Normalize to py-lambda-worker/ regardless of where the script is called from
cd "$(dirname "$0")/.."

CURRENT=$(cat VERSION)

if [ -n "${1:-}" ]; then
    NEW_VERSION="$1"
else
    BASE="${CURRENT#v}"
    MAJOR=$(echo "$BASE" | cut -d. -f1)
    MINOR=$(echo "$BASE" | cut -d. -f2)
    NEW_VERSION="v${MAJOR}.$((MINOR + 1))"
fi

echo "→ Deploying BuildId=${NEW_VERSION} (was ${CURRENT})"

sam deploy \
    --stack-name aspinks-py-lambda-worker \
    --resolve-s3 \
    --s3-prefix aspinks-py-lambda-worker \
    --profile SolutionsArchitecture/AWSAdministratorAccess \
    --region us-east-2 \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --confirm-changeset \
    --parameter-overrides \
        TemporalAddress="sa-demo-01.temporal-dev.tmprl-test.cloud:7233" \
        TemporalNamespace="sa-demo-01.temporal-dev" \
        TemporalTaskQueue="py-lambda-worker-queue-3" \
        TemporalTLSCertArn="arn:aws:secretsmanager:us-east-2:429214323166:secret:temporal/serverless/client-cert-SFwM47" \
        TemporalTLSKeyArn="arn:aws:secretsmanager:us-east-2:429214323166:secret:temporal/serverless/client-key-dTlDRy" \
        AssumeRoleExternalId="python-external-id" \
        BuildId="${NEW_VERSION}"

echo "${NEW_VERSION}" > VERSION
echo "✓ VERSION updated to ${NEW_VERSION}"
