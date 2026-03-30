#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

text="${1:-}"
chunk_size=100

while [[ -n "${text}" ]]; do
  chunk="${text:0:${chunk_size}}"
  xdotool type --delay 6 --clearmodifiers -- "${chunk}"
  text="${text:${chunk_size}}"
done
