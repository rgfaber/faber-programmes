#!/usr/bin/env bash
#
# Bump the faber_tweann pin to the commit that carries robo_pilot, so the
# extracted controller is reachable for the owed equivalence replay.
#
# WHY A SCRIPT AND NOT A ONE-LINER. rebar.lock silently overrides a rebar.config
# ref bump. Editing the config and running a plain `rebar3 compile` leaves the OLD
# engine in _build, and every downstream check then reports a false green against
# the code it was meant to replace. `rebar3 upgrade` is the only call that moves
# the lock, so the two steps belong together where they cannot be separated.
#
# OLD ref a5e8bcfc5646827e9be49a9629f8a6a9678c814b  (provenance of every phase 0 number)
# NEW ref 8556d7fd9177acfaf21c21569628775f06625faa  (robo_pilot + robo_pilot_tests)
#
# The bump is REPLAY ONLY. No evolutionary arm is re-run.

set -euo pipefail

REPO="/home/rl/work/github.com/rgfaber/faber-programmes"
LOG_DIR="${REPO}/_build/equivalence_logs"
OLD_REF="a5e8bcfc5646827e9be49a9629f8a6a9678c814b"
NEW_REF="8556d7fd9177acfaf21c21569628775f06625faa"

mkdir -p "${LOG_DIR}"
cd "${REPO}"

echo "== pin before =="
grep -n "ref" rebar.config
grep -n "ref" rebar.lock

echo
echo "== rewriting rebar.config ref =="
sed -i "s/${OLD_REF}/${NEW_REF}/" rebar.config
grep -n "ref" rebar.config

echo
echo "== rebar3 upgrade faber_tweann (moves the LOCK, which the config alone does not) =="
rebar3 upgrade faber_tweann > "${LOG_DIR}/upgrade.log" 2>&1
echo "upgrade exit: $?"

echo
echo "== pin after =="
grep -n "ref" rebar.config
grep -n "ref" rebar.lock

echo
echo "== the checked-out dep HEAD, which is the only pin that actually ran =="
git -C _build/default/lib/faber_tweann rev-parse HEAD

echo
echo "== is robo_pilot present in the checkout =="
ls -l _build/default/lib/faber_tweann/src/robo_pilot.erl
