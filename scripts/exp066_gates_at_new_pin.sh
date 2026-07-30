#!/usr/bin/env bash
#
# Re-run EXP-066's own seven kill gates at the BUMPED engine pin.
#
# THIS IS THE PRECONDITION FOR READING ANYTHING ELSE. Gate 1 recomputes
# robo_match_tests' golden match vector, which proves robo_sim, robo_net,
# robo_gauntlet and robo_match are byte-for-byte the same engine that produced
# every phase 0 number. Adding a module should not disturb them. If gate 1 fails,
# the pin bump changed the engine and no downstream comparison is interpretable.
#
# The output is REDIRECTED to a log and the exit code echoed. Piping a rebar or
# erl run through head or tail can SIGPIPE the producer and report a false
# success, so nothing here is piped.

set -euo pipefail

REPO="/home/rl/work/github.com/rgfaber/faber-programmes"
LOG_DIR="${REPO}/_build/equivalence_logs"
LOG="${LOG_DIR}/gates_at_new_pin.log"

mkdir -p "${LOG_DIR}"
cd "${REPO}"

rebar3 as test compile > "${LOG_DIR}/gates_compile.log" 2>&1
echo "compile exit: $?"

set +e
erl -noshell -pa _build/test/lib/*/ebin -pa _build/test/lib/faber_programmes/experiments \
    -eval 'G = exp066_single_population_floor_tests:gates(),
           Bad = [N || {N, false, _D} <- G],
           io:format("~n== gate roll-up ==~n"),
           [io:format("  ~s ~s~n", [case Ok of true -> "PASS"; false -> "FAIL" end, N])
            || {N, Ok, _} <- G],
           io:format("checks: ~p, failing: ~p~n", [length(G), Bad]),
           halt(case Bad of [] -> 0; _ -> 1 end).' \
    > "${LOG}" 2>&1
CODE=$?
set -e

echo "gates exit: ${CODE}"
echo "log: ${LOG}"
exit "${CODE}"
