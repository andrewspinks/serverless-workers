#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command jq
require_command temporal
require_main_state

build_id="${1:?Usage: promote.sh BUILD_ID}"
if ! jq -e --arg build_id "$build_id" '.worker_versions[$build_id]' "$VERSIONS_FILE" >/dev/null; then
  echo "Build ID is not retained in $VERSIONS_FILE: $build_id" >&2
  exit 1
fi

load_temporal_api_key
deployment_name="$(tf_output temporal_deployment_name)"

temporal worker deployment describe-version \
  --address "$(tf_output temporal_address)" \
  --namespace "$(tf_output temporal_namespace)" \
  --deployment-name "$deployment_name" \
  --build-id "$build_id"

temporal worker deployment set-current-version \
  --address "$(tf_output temporal_address)" \
  --namespace "$(tf_output temporal_namespace)" \
  --deployment-name "$deployment_name" \
  --build-id "$build_id" \
  --yes

echo "Promoted $deployment_name:$build_id."
