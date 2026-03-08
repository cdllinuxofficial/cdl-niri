#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $(eval echo $CDL_NIRI_VENV)/bin/activate
"$SCRIPT_DIR/find_regions.py" "$@"
deactivate
