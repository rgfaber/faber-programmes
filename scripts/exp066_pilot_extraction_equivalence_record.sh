#!/usr/bin/env bash
#
# Produce programmes/p7_coevolution/exp066_competence_floor/exp066_pilot_extraction_equivalence.txt
#
# ONE COMMAND REPRODUCES THE WHOLE RECORD. The gates, Part A, Part B and the red
# check all run inside a single erl invocation and the file is written from those
# results, so no number in it was pasted in by hand from an earlier log.
#
# Preconditions, in order:
#   scripts/exp066_bump_pin_for_pilot_equivalence.sh   (pin -> 8556d7fd, lock moved)
#   scripts/exp066_gates_at_new_pin.sh                 (must PASS)
#
# NOTHING IS PIPED. A build or a run pushed through head or tail can SIGPIPE the
# producer and report a false success, so output is redirected to a log, the exit
# code is echoed, and the log is read afterwards.

set -euo pipefail

REPO="/home/rl/work/github.com/rgfaber/faber-programmes"
LOG_DIR="${REPO}/_build/equivalence_logs"
RED_DIR="${LOG_DIR}/red"
LOG="${LOG_DIR}/equivalence_record.log"

mkdir -p "${LOG_DIR}"
cd "${REPO}"

rebar3 as test compile > "${LOG_DIR}/record_compile.log" 2>&1
echo "compile exit: $?"

# The perturbed copies the red check points at. Built here, never committed, and
# robo_pilot itself is not touched by any of it.
./scripts/exp066_pilot_equivalence_red_check.sh build > "${LOG_DIR}/red_build.log" 2>&1
echo "red-check build exit: $?"

set +e
erl -noshell -pa _build/test/lib/*/ebin \
    -pa _build/test/lib/faber_programmes/experiments \
    -pa "${RED_DIR}" \
    -eval 'R = exp066_pilot_extraction_equivalence_tests:record(#{}),
           io:format("~nEQUIVALENT: ~p~n", [maps:get(equivalent, R)]),
           halt(case maps:get(equivalent, R) of true -> 0; false -> 1 end).' \
    > "${LOG}" 2>&1
CODE=$?
set -e

echo "record exit: ${CODE}"
echo "log: ${LOG}"
exit "${CODE}"
