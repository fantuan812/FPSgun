#!/bin/sh
q=<QA_ROOT>/ordinary
mkdir -p "$q/empty-reader" "$q/profile/home" "$q/profile/config" "$q/profile/cache" "$q/profile/data"
export HOME="$q/profile/home" XDG_CONFIG_HOME="$q/profile/config" XDG_CACHE_HOME="$q/profile/cache" XDG_DATA_HOME="$q/profile/data"
cd "$q/empty-reader"
<WORKSPACE>/moss-v35-pack/linux/MossCircuit.x86_64 --audio-driver Dummy --main-pack <WORKSPACE>/moss-v35-pack/linux/MossCircuit.pck --resolution 960x540 --position 92,120 > "$q/runtime.log" 2>&1
code=$?
printf '%s\n' "$code" > "$q/runtime.exit"
exit "$code"
