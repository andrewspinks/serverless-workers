#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command jq
require_main_state

build_id="${1:?Usage: rollback.sh BUILD_ID}"
if ! jq -e --arg build_id "$build_id" '.worker_versions[$build_id]' "$VERSIONS_FILE" >/dev/null; then
  echo "Build ID is not retained in $VERSIONS_FILE: $build_id" >&2
  exit 1
fi

"$SCRIPT_DIR/promote.sh" "$build_id"
echo "Rolled back to $build_id."
