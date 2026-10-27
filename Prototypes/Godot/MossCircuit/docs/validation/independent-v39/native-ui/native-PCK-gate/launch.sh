#!/bin/sh
cd <WORKSPACE>/moss-v39-ui/native-PCK-gate || exit 90
/usr/bin/python3 <WORKSPACE>/moss-v39-ui/native-PCK-gate/run.py > wrapper.stdout 2> wrapper.stderr
rc=$?
printf "%s\n" "$rc" > wrapper.exit
exit "$rc"
