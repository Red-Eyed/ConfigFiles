#!/usr/bin/env bash
# Compatibility entry for installations using the former SSH resilience name.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
exec bash ./install_earlyoom.sh "$@"
