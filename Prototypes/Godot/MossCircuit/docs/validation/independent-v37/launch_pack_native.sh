#!/bin/sh
set -u
q=<QA_ROOT>
pack=<WORKSPACE>/moss-v37-pack/linux/MossCircuit.pck
[ ! -e "$q/pack-native/controlled.log" ] || exit 93
/usr/bin/python3 - <<'PY' || exit 94
import json,pathlib,hashlib
q=pathlib.Path('<QA_ROOT>');p=pathlib.Path('<WORKSPACE>/moss-v37-pack/linux/MossCircuit.pck');plan=json.loads((q/'PACKED_EXECUTION_PLAN.json').read_text());native=json.loads((q/'NATIVE_LAUNCH_FREEZE.json').read_text());assert json.loads((q/'packed-first/SUMMARY.json').read_text())['pass'];assert hashlib.sha256(p.read_bytes()).hexdigest()==plan['pck_sha256']==native['pck_sha256'];assert hashlib.sha256((q/'checks/forecast_native_fixture.gd').read_bytes()).hexdigest()==native['fixture_sha256'];assert hashlib.sha256((q/'native-support/audio_teardown.gd').read_bytes()).hexdigest()==native['helper_sha256']
PY
mkdir -p "$q/pack-native/empty-reader" "$q/pack-native/profile/home" "$q/pack-native/profile/config" "$q/pack-native/profile/cache" "$q/pack-native/profile/data"
export HOME="$q/pack-native/profile/home" XDG_CONFIG_HOME="$q/pack-native/profile/config" XDG_CACHE_HOME="$q/pack-native/profile/cache" XDG_DATA_HOME="$q/pack-native/profile/data"
cd "$q/pack-native/empty-reader" || exit 95
godot --audio-driver Dummy --main-pack "$pack" --position 92,120 --script "$q/checks/forecast_native_fixture.gd" > "$q/pack-native/controlled.log" 2>&1
code=$?
printf '%s\n' "$code" > "$q/pack-native/controlled.exit"
exit "$code"
