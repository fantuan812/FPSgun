#!/bin/sh
/usr/bin/python3 <WORKSPACE>/moss-v39-qa/run_ordinary.py arena > <WORKSPACE>/moss-v39-qa/ordinary-arena/wrapper.stdout 2> <WORKSPACE>/moss-v39-qa/ordinary-arena/wrapper.stderr
rc=$?
printf "%s\n" "$rc" > <WORKSPACE>/moss-v39-qa/ordinary-arena/wrapper.exit
exit "$rc"
