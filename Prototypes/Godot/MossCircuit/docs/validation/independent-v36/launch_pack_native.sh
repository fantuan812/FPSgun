#!/bin/sh
q=<QA_ROOT>
pack=<WORKSPACE>/moss-v36-pack/linux/MossCircuit.pck
mkdir -p "$q/pack-native/empty-reader" "$q/pack-native/profile/home" "$q/pack-native/profile/config" "$q/pack-native/profile/cache" "$q/pack-native/profile/data"
export HOME="$q/pack-native/profile/home" XDG_CONFIG_HOME="$q/pack-native/profile/config" XDG_CACHE_HOME="$q/pack-native/profile/cache" XDG_DATA_HOME="$q/pack-native/profile/data"
cd "$q/pack-native/empty-reader"
godot --audio-driver Dummy --main-pack "$pack" --position 92,120 --script "$q/checks/scavenger_native_fixture.gd" > "$q/pack-native/controlled.log" 2>&1
code=$?
printf '%s\n' "$code" > "$q/pack-native/controlled.exit"
exit "$code"
