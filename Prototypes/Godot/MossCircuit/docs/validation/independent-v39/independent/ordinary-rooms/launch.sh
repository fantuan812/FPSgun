#!/bin/sh
/usr/bin/python3 <WORKSPACE>/moss-v39-qa/run_ordinary.py rooms > <WORKSPACE>/moss-v39-qa/ordinary-rooms/wrapper.stdout 2> <WORKSPACE>/moss-v39-qa/ordinary-rooms/wrapper.stderr
rc=$?
printf "%s\n" "$rc" > <WORKSPACE>/moss-v39-qa/ordinary-rooms/wrapper.exit
exit "$rc"
