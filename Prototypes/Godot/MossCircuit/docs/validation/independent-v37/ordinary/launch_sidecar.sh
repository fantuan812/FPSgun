#!/bin/sh
set -u
q=<QA_ROOT>/ordinary
[ ! -e "$q/sidecar-runtime.log" ] || exit 93
/usr/bin/python3 - <<'PY' || exit 94
import pathlib,json,hashlib
q=pathlib.Path('<QA_ROOT>');pack=pathlib.Path('<WORKSPACE>/moss-v37-pack/linux');d=json.loads((q/'NATIVE_LAUNCH_FREEZE.json').read_text());assert json.loads((q/'packed-first/SUMMARY.json').read_text())['pass'];assert hashlib.sha256((pack/'MossCircuit.pck').read_bytes()).hexdigest()==d['pck_sha256'];assert hashlib.sha256((pack/'MossCircuit.x86_64').read_bytes()).hexdigest()==d['elf_sha256'];assert (q/'pack-native/controlled.exit').read_text().strip()=='0'
PY
mkdir -p "$q/empty-reader" "$q/profile/home" "$q/profile/config" "$q/profile/cache" "$q/profile/data"
export HOME="$q/profile/home" XDG_CONFIG_HOME="$q/profile/config" XDG_CACHE_HOME="$q/profile/cache" XDG_DATA_HOME="$q/profile/data"
cd "$q/empty-reader" || exit 95
<WORKSPACE>/moss-v37-pack/linux/MossCircuit.x86_64 --audio-driver Dummy --resolution 960x540 --position 92,120 > "$q/sidecar-runtime.log" 2>&1
code=$?
printf '%s\n' "$code" > "$q/sidecar-runtime.exit"
exit "$code"
