#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command jq
require_command temporal
require_command terraform
require_main_state

build_id="${1:?Usage: prune.sh BUILD_ID}"
if ! jq -e --arg build_id "$build_id" '.worker_versions[$build_id]' "$VERSIONS_FILE" >/dev/null; then
  echo "Build ID is not retained in $VERSIONS_FILE: $build_id" >&2
  exit 1
fi

load_temporal_api_key
deployment_name="$(tf_output temporal_deployment_name)"
deployment_json="$(temporal worker deployment describe \
  --address "$(tf_output temporal_address)" \
  --namespace "$(tf_output temporal_namespace)" \
  --deployment-name "$deployment_name" \
  --output json)"

current_build="$(jq -r '
  .workerDeploymentInfo.routingConfig.currentDeploymentVersion.buildId //
  .routingConfig.currentDeploymentVersion.buildId // empty
' <<<"$deployment_json")"
ramping_build="$(jq -r '
  .workerDeploymentInfo.routingConfig.rampingDeploymentVersion.buildId //
  .routingConfig.rampingDeploymentVersion.buildId // empty
' <<<"$deployment_json")"
current_legacy="$(jq -r '.workerDeploymentInfo.routingConfig.currentVersion // .routingConfig.currentVersion // empty' <<<"$deployment_json")"
ramping_legacy="$(jq -r '.workerDeploymentInfo.routingConfig.rampingVersion // .routingConfig.rampingVersion // empty' <<<"$deployment_json")"

if [[ "$build_id" == "$current_build" || "$build_id" == "$ramping_build" ||
  "$current_legacy" == *"$build_id" || "$ramping_legacy" == *"$build_id" ]]; then
  echo "Refusing to prune current or ramping build: $build_id" >&2
  exit 1
fi

temporal worker deployment describe-version \
  --address "$(tf_output temporal_address)" \
  --namespace "$(tf_output temporal_namespace)" \
  --deployment-name "$deployment_name" \
  --build-id "$build_id" \
  --report-task-queue-stats

read -r -p "Confirm Temporal shows $build_id drained by typing its Build ID: " confirmation
if [[ "$confirmation" != "$build_id" ]]; then
  echo "Prune cancelled." >&2
  exit 1
fi

temporary_versions="$(mktemp)"
jq --arg build_id "$build_id" 'del(.worker_versions[$build_id])' \
  "$VERSIONS_FILE" >"$temporary_versions"
chmod 0644 "$temporary_versions"
mv "$temporary_versions" "$VERSIONS_FILE"

"$SCRIPT_DIR/infra-apply.sh"
echo "Pruned Cloud Run worker pool for $build_id. The container image remains in Artifact Registry."
