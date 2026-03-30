#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

direction="${1:-down}"
steps="${2:-1}"

case "${direction}" in
  up)
    button=4
    ;;
  down)
    button=5
    ;;
  left)
    button=6
    ;;
  right)
    button=7
    ;;
  *)
    echo "Unsupported scroll direction: ${direction}" >&2
    exit 1
    ;;
esac

xdotool click --repeat "${steps}" "${button}"
