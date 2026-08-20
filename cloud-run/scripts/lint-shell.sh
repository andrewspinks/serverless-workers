#!/usr/bin/env bash

set -euo pipefail

find scripts -type f -name '*.sh' -print0 | sort -z | xargs -0 shellcheck -x -P scripts
find scripts -type f -name '*.sh' -print0 | sort -z | xargs -0 shfmt -d -i 2 -ci
