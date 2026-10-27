#!/bin/bash
set -u
runtime="$1"
qa="$2"
mkdir -p "$qa/ordinary/profile/home" "$qa/ordinary/profile/config" "$qa/ordinary/profile/cache" "$qa/ordinary/profile/data"
export HOME="$qa/ordinary/profile/home" XDG_CONFIG_HOME="$qa/ordinary/profile/config" XDG_CACHE_HOME="$qa/ordinary/profile/cache" XDG_DATA_HOME="$qa/ordinary/profile/data"
"$runtime/MossCircuit.x86_64" --position 92,120 > "$qa/ordinary/runtime.log" 2>&1
code=$?
printf '%s\n' "$code" > "$qa/ordinary/runtime.exit"
exit "$code"
