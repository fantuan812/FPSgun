#!/bin/sh
# Frozen actual raw prerequisites; launch only under explicit QA CUA lease.
set -u
cd evidence-workspace/moss-v39-B-qa/ordinary-prep || exit 125
[ ! -e wrapper.stdout ] && [ ! -e wrapper.stderr ] && [ ! -e wrapper.exit ] || exit 124
set -C
/usr/bin/python3 evidence-workspace/moss-v39-B-qa/ordinary-prep/run.py --plan-sha256 3df0b04819df47564559dd85118b1a331b4fcff91a0859e416d27c31dc03fee7 >wrapper.stdout 2>wrapper.stderr
rc=$?
printf '%s\n' "$rc" >wrapper.exit
exit "$rc"
