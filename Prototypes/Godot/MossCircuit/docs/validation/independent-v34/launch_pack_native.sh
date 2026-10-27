#!/bin/bash
set -u
pack="$1"
qa="$2"
mkdir -p "$qa/pack-native/empty-reader" "$qa/pack-native/profile/home" "$qa/pack-native/profile/config" "$qa/pack-native/profile/cache" "$qa/pack-native/profile/data"
export HOME="$qa/pack-native/profile/home" XDG_CONFIG_HOME="$qa/pack-native/profile/config" XDG_CACHE_HOME="$qa/pack-native/profile/cache" XDG_DATA_HOME="$qa/pack-native/profile/data"
cd "$qa/pack-native/empty-reader"
godot --main-pack "$pack" --position 92,120 --script "$qa/checks/focus_pack_native_fixture.gd" -- 6 > "$qa/pack-native/controlled.log" 2>&1
code=$?
printf '%s\n' "$code" > "$qa/pack-native/controlled.exit"
exit "$code"
