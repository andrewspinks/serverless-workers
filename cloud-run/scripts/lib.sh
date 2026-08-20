#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_MAIN_DIR="$PROJECT_DIR/terraform/main"
# Referenced by scripts that source this file.
# shellcheck disable=SC2034
VERSIONS_FILE="$TF_MAIN_DIR/versions.auto.tfvars.json"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_main_state() {
  if [[ ! -f "$TF_MAIN_DIR/backend.hcl" ]]; then
    echo "Missing terraform/main/backend.hcl; run 'mise run infra:bootstrap -- PROJECT BUCKET [REGION]' first." >&2
    exit 1
  fi
}

tf_output() {
  terraform -chdir="$TF_MAIN_DIR" output -raw "$1"
}

load_temporal_api_key() {
  if [[ -n "${TEMPORAL_API_KEY:-}" ]]; then
    export TEMPORAL_API_KEY
    return
  fi

  local project_id secret_name
  project_id="$(tf_output project_id)"
  secret_name="$(tf_output temporal_api_key_secret)"
  secret_name="${secret_name##*/}"
  TEMPORAL_API_KEY="$(gcloud secrets versions access latest --project="$project_id" --secret="$secret_name")"
  export TEMPORAL_API_KEY
}

release_file_for() {
  local build_id="$1"
  local digest
  digest="$(node "$SCRIPT_DIR/hash.mjs" "$build_id" 12)"
  printf '%s/.releases/%s.json\n' "$PROJECT_DIR" "$digest"
}

pool_name_for() {
  local build_id="$1"
  local prefix="$2"
  local slug hash base
  slug="$(printf '%s' "$build_id" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  [[ -n "$slug" ]] || slug="build"
  hash="$(node "$SCRIPT_DIR/hash.mjs" "$build_id" 8)"
  base="${prefix}-${slug}"
  printf '%s-%s\n' "${base:0:40}" "$hash"
}
