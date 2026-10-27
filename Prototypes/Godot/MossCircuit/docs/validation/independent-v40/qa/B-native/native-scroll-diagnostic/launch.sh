#!/bin/sh
[ "$#" -eq 1 ] || exit 91
cd evidence-workspace/moss-v39-ui/B/native-scroll-diagnostic || exit 90
/usr/bin/python3 evidence-workspace/moss-v39-ui/B/native-scroll-diagnostic/run.py "$1" > wrapper.stdout 2> wrapper.stderr
rc=$?
printf "%s\n" "$rc" > wrapper.exit
exit "$rc"
