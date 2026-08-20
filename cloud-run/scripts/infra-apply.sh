#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command terraform
require_main_state

terraform -chdir="$TF_MAIN_DIR" init -backend-config=backend.hcl
terraform -chdir="$TF_MAIN_DIR" apply "$@"
