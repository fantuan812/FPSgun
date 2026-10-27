#!/bin/bash
cd <WORKSPACE>/moss-v39-prep/native-mechanics || exit 125
/usr/bin/python3 run.py > wrapper-r2.stdout 2> wrapper-r2.stderr
rc=$?
printf '%s\n' "$rc" > wrapper-r2.exit
exit "$rc"
