#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

curl --proto '=https' --tlsv1.2 -sSf https://astral.sh/uv/install.sh | sh
