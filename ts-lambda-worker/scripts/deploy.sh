#!/usr/bin/env bash
set -euo pipefail

# Normalize to ts-lambda-worker/ regardless of where the script is called from
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

pnpm run build:lambda
pnpm exec cdk deploy TsLambdaWorker-sa-demo \
    --context buildId="${NEW_VERSION}" \
    --require-approval never

echo "${NEW_VERSION}" > VERSION
echo "✓ VERSION updated to ${NEW_VERSION}"
