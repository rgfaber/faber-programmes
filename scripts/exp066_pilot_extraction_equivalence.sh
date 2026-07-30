#!/usr/bin/env bash
#
# THE OWED EQUIVALENCE REPLAY. Is robo_pilot the phase 0 controller, or only a
# careful-looking copy of it?
#
#   smoke  one champion, two starts. Shakes out the harness, proves nothing.
#   a      Part A, turn-by-turn intent equality, all 20 arm S champions.
#   b      Part B, the full held-out endpoint, three columns.
#   full   both, and the combined verdict.
#
# NOTHING IS PIPED. A build or a run pushed through head or tail can SIGPIPE the
# producer and report a false success, so every run is redirected to a log, the
# exit code is echoed, and the log is read afterwards.
#
# Requires faber_tweann at 8556d7fd (robo_pilot present). Run
# scripts/exp066_bump_pin_for_pilot_equivalence.sh first, then
# scripts/exp066_gates_at_new_pin.sh, which must PASS before any number below is
# interpretable.

set -euo pipefail

REPO="/home/rl/work/github.com/rgfaber/faber-programmes"
LOG_DIR="${REPO}/_build/equivalence_logs"
MODE="${1:-full}"

mkdir -p "${LOG_DIR}"
cd "${REPO}"

rebar3 as test compile > "${LOG_DIR}/equiv_compile.log" 2>&1
echo "compile exit: $?"

case "${MODE}" in
  smoke) CALL='io:format("~p~n", [exp066_pilot_extraction_equivalence_tests:part_a(#{a_starts => 2})])' ;;
  a)     CALL='R = exp066_pilot_extraction_equivalence_tests:part_a(#{}), io:format("~nfirst divergence: ~p~n", [maps:get(first_divergence, R)])' ;;
  b)     CALL='_ = exp066_pilot_extraction_equivalence_tests:part_b(#{})' ;;
  full)  CALL='R = exp066_pilot_extraction_equivalence_tests:run(#{}), io:format("~n== COMBINED ==~nequivalent: ~p~nfirst divergence: ~p~n", [maps:get(equivalent, R), maps:get(first_divergence, maps:get(part_a, R))])' ;;
  *)     echo "unknown mode: ${MODE}"; exit 2 ;;
esac

LOG="${LOG_DIR}/equivalence_${MODE}.log"

set +e
erl -noshell -pa _build/test/lib/*/ebin \
    -pa _build/test/lib/faber_programmes/experiments \
    -eval "${CALL}, halt(0)." > "${LOG}" 2>&1
CODE=$?
set -e

echo "run exit: ${CODE}"
echo "log: ${LOG}"
exit "${CODE}"
