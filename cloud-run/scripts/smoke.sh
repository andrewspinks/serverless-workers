#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command gcloud
require_command jq
require_command node
require_command pnpm
require_main_state

build_id="${1:?Usage: smoke.sh BUILD_ID [NAME]}"
name="${2:-Cloud Run}"
pool_name="$(jq -er --arg build_id "$build_id" '.worker_versions[$build_id].pool_name' "$VERSIONS_FILE")"
project_id="$(tf_output project_id)"
region="$(tf_output region)"

load_temporal_api_key
TEMPORAL_ADDRESS="$(tf_output temporal_address)"
TEMPORAL_NAMESPACE="$(tf_output temporal_namespace)"
TEMPORAL_TASK_QUEUE="$(tf_output temporal_task_queue)"
export TEMPORAL_ADDRESS TEMPORAL_NAMESPACE TEMPORAL_TASK_QUEUE

pnpm --dir "$PROJECT_DIR" run start-workflow -- "$name"

gcloud run worker-pools describe "$pool_name" \
  --project="$project_id" \
  --region="$region" \
  --format='table(name,scaling.manualInstanceCount,latestCreatedRevision)'

query="temporal_worker_start{exported_namespace=\"$(tf_output temporal_namespace)\",build_id=\"$build_id\"}"
if ! MONITORING_ACCESS_TOKEN="$(gcloud auth print-access-token)" \
MONITORING_PROJECT_ID="$project_id" \
MONITORING_PROMQL="$query" \
  node "$SCRIPT_DIR/query-metric.mjs"; then
  echo "Workflow succeeded, but temporal_worker_start has not reached Cloud Monitoring yet." >&2
  echo "Metrics can take a few minutes to become visible; retry this smoke task." >&2
  exit 1
fi

echo "Workflow and Cloud Monitoring metric checks passed for $build_id."
