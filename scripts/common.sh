#!/usr/bin/env bash

set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"

button_number() {
  case "${1:-left}" in
    left) echo 1 ;;
    middle) echo 2 ;;
    right) echo 3 ;;
    wheel-up) echo 4 ;;
    wheel-down) echo 5 ;;
    *) echo "${1}" ;;
  esac
}
