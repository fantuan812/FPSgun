#!/bin/sh
[ "$#" -eq 1 ] || exit 91
cd <WORKSPACE>/moss-v39-ui/equipment16-native-r2 || exit 90
/usr/bin/python3 <WORKSPACE>/moss-v39-ui/equipment16-native-r2/run.py "$1" > wrapper.stdout 2> wrapper.stderr
rc=$?
printf "%s\n" "$rc" > wrapper.exit
exit "$rc"
