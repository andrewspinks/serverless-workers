#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command gcloud
require_main_state

project_id="$(tf_output project_id)"
secret_name="$(tf_output temporal_api_key_secret)"
secret_name="${secret_name##*/}"

if [[ -t 0 ]]; then
  read -r -s -p "Temporal Cloud API key: " api_key
  echo
  printf '%s' "$api_key" | gcloud secrets versions add "$secret_name" --project="$project_id" --data-file=-
else
  gcloud secrets versions add "$secret_name" --project="$project_id" --data-file=-
fi

echo "Added a new version to projects/$project_id/secrets/$secret_name."
