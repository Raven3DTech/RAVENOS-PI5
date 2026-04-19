#!/usr/bin/env bash
# Fail if any tracked text file contains CR. Run from repo root (Git Bash / WSL / Linux):
#   bash scripts/check-no-crlf.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
bad=$(git grep -l -I $'\r' -- . || true)
if [[ -n "${bad}" ]]; then
  echo "CRLF detected — normalize to LF (see .gitattributes). Files:" >&2
  echo "${bad}" >&2
  exit 1
fi
echo "OK: no carriage returns in tracked text (git grep -I)."
