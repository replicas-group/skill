#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

key="${1:?key is required}"
duration_ms="${2:-250}"

xdotool keydown "${key}"
sleep "$(awk "BEGIN { print ${duration_ms} / 1000 }")"
xdotool keyup "${key}"
