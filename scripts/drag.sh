#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

from_x="${1:?from_x is required}"
from_y="${2:?from_y is required}"
to_x="${3:?to_x is required}"
to_y="${4:?to_y is required}"
button="$(button_number "${5:-left}")"

xdotool mousemove --sync "${from_x}" "${from_y}"
xdotool mousedown "${button}"
xdotool mousemove --sync "${to_x}" "${to_y}"
xdotool mouseup "${button}"
