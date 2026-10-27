#!/bin/sh
# DRAFT: this exact plan is intentionally blocked by status/null prerequisites.
set -u
cd evidence-workspace/moss-v39-B-qa/ordinary-prep || exit 125
[ ! -e wrapper.stdout ] && [ ! -e wrapper.stderr ] && [ ! -e wrapper.exit ] || exit 124
set -C
/usr/bin/python3 evidence-workspace/moss-v39-B-qa/ordinary-prep/run.py --plan-sha256 b0cc19beaf23a890e5b963a14e967d93b1fb6976b1ccedb7977b079d3897a2aa >wrapper.stdout 2>wrapper.stderr
rc=$?
printf '%s\n' "$rc" >wrapper.exit
exit "$rc"
