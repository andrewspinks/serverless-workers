#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command jq
require_command node
require_command terraform
require_main_state

build_id="${1:?Usage: deploy.sh BUILD_ID}"

"$SCRIPT_DIR/build.sh" "$build_id"
release_file="$(release_file_for "$build_id")"
image="$(jq -er '.image' "$release_file")"
pool_name="$(jq -er '.pool_name' "$release_file")"

temporary_versions="$(mktemp)"
jq \
  --arg build_id "$build_id" \
  --arg image "$image" \
  --arg pool_name "$pool_name" \
  '.worker_versions[$build_id] = {image: $image, pool_name: $pool_name}' \
  "$VERSIONS_FILE" >"$temporary_versions"
chmod 0644 "$temporary_versions"
mv "$temporary_versions" "$VERSIONS_FILE"

"$SCRIPT_DIR/infra-apply.sh"

terraform -chdir="$TF_MAIN_DIR" output -json temporal_connection | jq .
cat <<INSTRUCTIONS

Create the Temporal Worker Deployment Version and GCP Cloud Run compute
connection in Temporal Cloud using the values above:

  Deployment: $(tf_output temporal_deployment_name)
  Build ID:   $build_id
  Worker pool: $pool_name

The public Temporal CLI/Terraform provider does not yet expose the GCP
compute-connection fields, so this is the one interactive step.
INSTRUCTIONS

read -r -p "Type 'connected' after Temporal reports the compute connection ready: " confirmation
if [[ "$confirmation" != "connected" ]]; then
  echo "Pool is deployed but was not promoted. Run 'mise run release:promote -- $build_id' after linking it." >&2
  exit 1
fi

"$SCRIPT_DIR/promote.sh" "$build_id"
