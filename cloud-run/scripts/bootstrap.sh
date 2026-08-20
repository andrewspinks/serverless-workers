#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command terraform
require_command gcloud

project_id="${1:?Usage: bootstrap.sh PROJECT_ID STATE_BUCKET [REGION]}"
state_bucket="${2:?Usage: bootstrap.sh PROJECT_ID STATE_BUCKET [REGION]}"
region="${3:-us-central1}"
bootstrap_dir="$PROJECT_DIR/terraform/bootstrap"

terraform -chdir="$bootstrap_dir" init

if gcloud storage buckets describe "gs://$state_bucket" --project="$project_id" >/dev/null 2>&1 &&
  ! terraform -chdir="$bootstrap_dir" state show google_storage_bucket.terraform_state >/dev/null 2>&1; then
  terraform -chdir="$bootstrap_dir" import \
    -var="project_id=$project_id" \
    -var="state_bucket_name=$state_bucket" \
    -var="region=$region" \
    google_storage_bucket.terraform_state "$state_bucket"
fi

terraform -chdir="$bootstrap_dir" apply \
  -var="project_id=$project_id" \
  -var="state_bucket_name=$state_bucket" \
  -var="region=$region"

printf 'bucket = "%s"\n' "$state_bucket" >"$TF_MAIN_DIR/backend.hcl"
terraform -chdir="$TF_MAIN_DIR" init -reconfigure -backend-config=backend.hcl

echo "Main Terraform backend initialized in gs://$state_bucket."
