#!/bin/sh
[ "$#" -eq 1 ] || exit 91
cd evidence-workspace/moss-v39-ui/combined-native-cards || exit 90
/usr/bin/python3 evidence-workspace/moss-v39-ui/combined-native-cards/run.py "$1" > wrapper.stdout 2> wrapper.stderr
rc=$?
printf "%s\n" "$rc" > wrapper.exit
exit "$rc"
