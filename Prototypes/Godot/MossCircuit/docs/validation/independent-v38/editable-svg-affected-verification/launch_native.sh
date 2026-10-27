#!/bin/sh
set -u
q=<WORKSPACE>/moss-v38-svg-qa
pack=<WORKSPACE>/moss-v38-svg-pack/linux/MossCircuit.pck
[ ! -e "$q/pack-native/controlled.log" ] || exit 93
/usr/bin/python3 - <<'PY' || exit 94
import json,pathlib,hashlib
q=pathlib.Path('<WORKSPACE>/moss-v38-svg-qa');p=pathlib.Path('<WORKSPACE>/moss-v38-svg-pack/linux/MossCircuit.pck');n=json.load(open(q/'NATIVE_LAUNCH_FREEZE.json'));h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();assert json.load(open(q/'packed-first/RESULT.json'))['pass'];assert h(p)==n['pck_sha256'];assert h(q/'support_native_fixture.gd')==n['fixture_sha256'];assert h(q/'native-support/audio_teardown.gd')==n['helper_sha256']
PY
mkdir -p "$q/pack-native/empty-reader" "$q/pack-native/profile/home" "$q/pack-native/profile/config" "$q/pack-native/profile/cache" "$q/pack-native/profile/data"
export HOME="$q/pack-native/profile/home" XDG_CONFIG_HOME="$q/pack-native/profile/config" XDG_CACHE_HOME="$q/pack-native/profile/cache" XDG_DATA_HOME="$q/pack-native/profile/data"
cd "$q/pack-native/empty-reader" || exit 95
godot --audio-driver Dummy --main-pack "$pack" --position 92,120 --script "$q/support_native_fixture.gd" > "$q/pack-native/controlled.log" 2>&1
code=$?
printf '%s\n' "$code" > "$q/pack-native/controlled.exit"
exit "$code"
