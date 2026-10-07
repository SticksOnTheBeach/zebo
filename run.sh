#!/bin/bash
# Compile Zebo, assemble le bundle Zebo.app et le lance.
set -euo pipefail
cd "$(dirname "$0")"

./bundle.sh debug
pkill -x Zebo || true
open build/Zebo.app
