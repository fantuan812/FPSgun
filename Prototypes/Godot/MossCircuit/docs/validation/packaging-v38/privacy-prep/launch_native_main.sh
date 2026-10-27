#!/bin/sh
p=<WORKSPACE>/moss-v38-packaging-privacy-prep
[ ! -e "$p/native-main-wrapper.stdout" ] || exit 93
/usr/bin/python3 "$p/run_native_main.py" > "$p/native-main-wrapper.stdout" 2> "$p/native-main-wrapper.stderr"
c=$?
printf '%s\n' "$c" > "$p/native-main-wrapper.exit"
exit "$c"
