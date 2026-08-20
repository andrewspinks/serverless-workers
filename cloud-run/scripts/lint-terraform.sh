#!/usr/bin/env bash

set -euo pipefail

terraform fmt -check -recursive terraform
jq empty terraform/main/versions.auto.tfvars.json

for directory in terraform/bootstrap terraform/main; do
  terraform -chdir="$directory" init -backend=false
  terraform -chdir="$directory" validate
  tflint --chdir="$directory"
done
