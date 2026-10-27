#!/bin/bash
cd <WORKSPACE>/moss-v39-prep/native-mechanics || exit 125
python run.py > wrapper.stdout 2> wrapper.stderr
rc=$?
printf '%s\n' "$rc" > wrapper.exit
exit "$rc"
