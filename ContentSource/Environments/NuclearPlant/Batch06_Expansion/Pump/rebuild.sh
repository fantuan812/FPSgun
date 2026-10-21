#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
blender -b -t 2 --python "$ROOT/build_pumps.py"
blender -b -t 2 --python "$ROOT/export_modules.py"
blender -b -t 2 --python "$ROOT/check_render.py"
python "$ROOT/write_manifest.py"
