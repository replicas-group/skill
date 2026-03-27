#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

url="${1:-about:blank}"

for browser in google-chrome google-chrome-stable chromium-browser chromium; do
  if command -v "${browser}" >/dev/null 2>&1; then
    nohup "${browser}" \
      --no-sandbox \
      --disable-dev-shm-usage \
      --new-window \
      "${url}" >/dev/null 2>&1 &
    exit 0
  fi
done

echo "No supported browser found" >&2
exit 1
