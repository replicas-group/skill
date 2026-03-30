#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

x="${1:?x is required}"
y="${2:?y is required}"
kind="${3:-left}"

xdotool mousemove --sync "${x}" "${y}"

case "${kind}" in
  double)
    xdotool click --repeat 2 1
    ;;
  triple)
    xdotool click --repeat 3 1
    ;;
  *)
    xdotool click "$(button_number "${kind}")"
    ;;
esac
