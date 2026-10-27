#!/bin/sh
set -u
q=<WORKSPACE>/moss-v39-ui/native-A-gate
[ ! -e "$q/wrapper.exit" ] || exit 93
/usr/bin/python3 "$q/run.py" > "$q/wrapper.stdout" 2> "$q/wrapper.stderr"
rc=$?
printf '%s\n' "$rc" > "$q/wrapper.exit"
exit "$rc"
