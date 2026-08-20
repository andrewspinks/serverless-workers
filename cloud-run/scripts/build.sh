#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command gcloud
require_command jq
require_command node
require_main_state

build_id="${1:?Usage: build.sh BUILD_ID}"
project_id="$(tf_output project_id)"
region="$(tf_output region)"
repository_id="$(tf_output artifact_repository_id)"
repository_host="$(tf_output artifact_repository_host)"
builder_email="$(tf_output build_service_account)"
source_bucket="$(tf_output build_source_bucket)"
name_prefix="$(tf_output name_prefix)"
pool_name="$(pool_name_for "$build_id" "$name_prefix")"
tag="$repository_host/$project_id/$repository_id/worker:$pool_name"

gcloud builds submit "$PROJECT_DIR" \
  --project="$project_id" \
  --region="$region" \
  --config="$PROJECT_DIR/cloudbuild.yaml" \
  --service-account="projects/$project_id/serviceAccounts/$builder_email" \
  --gcs-source-staging-dir="gs://$source_bucket/source" \
  --substitutions="_IMAGE=$tag"

digest="$(gcloud artifacts docker images describe "$tag" \
  --project="$project_id" \
  --format='value(image_summary.digest)')"

if [[ ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "Could not resolve an immutable digest for $tag" >&2
  exit 1
fi

release_file="$(release_file_for "$build_id")"
mkdir -p "$(dirname "$release_file")"
jq -n \
  --arg build_id "$build_id" \
  --arg pool_name "$pool_name" \
  --arg image "${tag%:*}@$digest" \
  '{build_id: $build_id, pool_name: $pool_name, image: $image}' >"$release_file"

echo "Built $(jq -r '.image' "$release_file")"
echo "Release metadata: $release_file"
