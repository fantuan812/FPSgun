#!/bin/sh
cd evidence-workspace/moss-held8-integration-review/native-prep || exit 90
for f in wrapper.stdout wrapper.stderr wrapper.exit; do
 test ! -e "$f" || exit 91
done
/usr/bin/python3 run.py "$1" > wrapper.stdout 2> wrapper.stderr
rc=$?
printf "%s\n" "$rc" > wrapper.exit
exit "$rc"
