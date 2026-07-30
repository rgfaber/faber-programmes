#!/usr/bin/env bash
# Sources ONE number used in exp068_cross_machine_replay.md: whether a full
# `rebar3 eunit` over faber-tweann is a usable CI instrument for the four golden
# vectors, or whether it is too slow and too timing-sensitive to be one.
#
# This is NOT exp068's runner. exp068's runner is a CI workflow that compares
# golden vectors, and it is not written: the DESIGN gate's standing rule is no
# experiment code before the gate returns BUILD. This probe only measures the
# runtime of the EXISTING suite, to justify narrowing the instrument to the four
# endpoint modules.
#
# Reports, to stdout and to a summary file beside the experiment:
#   - whether the suite finished inside the bound
#   - elapsed seconds
#   - the count of "Neuron ... input timeout" warnings, the timing-sensitivity signal
#
# Usage: exp068_suite_runtime_probe.sh [bound_seconds]   (default 300)

set -euo pipefail

BOUND="${1:-300}"
TWEANN="${TWEANN_DIR:-$HOME/work/github.com/rgfaber/faber-tweann}"
EXPDIR="$HOME/work/github.com/rgfaber/faber-programmes/programmes/p7_coevolution/exp068_cross_machine_replay"
SUMMARY="$EXPDIR/suite_runtime_probe.txt"
LOG="$(mktemp -t exp068_probe.XXXXXX.log)"

if [ ! -d "$TWEANN" ]; then
    echo "faber-tweann not found at $TWEANN" >&2
    exit 2
fi

echo "probing full-suite runtime, bound ${BOUND}s, in $TWEANN"

START=$(date +%s)
set +e
timeout "${BOUND}s" env -C "$TWEANN" rebar3 eunit > "$LOG" 2>&1
RC=$?
set -e
END=$(date +%s)
ELAPSED=$((END - START))

# 124 is timeout(1)'s "bound reached" code.
if [ "$RC" -eq 124 ]; then
    FINISHED="no, bound reached"
else
    FINISHED="yes, exit ${RC}"
fi

WARNINGS=$(grep -c "input timeout after" "$LOG" || true)
OTP=$(env -C "$TWEANN" erl -noshell \
      -eval 'io:format("~s/erts-~s~n",[erlang:system_info(otp_release),erlang:system_info(version)]),halt().')

{
    echo "exp068 full-suite runtime probe"
    echo "date        : $(date -Is)"
    echo "host_otp    : ${OTP}"
    echo "bound_s     : ${BOUND}"
    echo "finished    : ${FINISHED}"
    echo "elapsed_s   : ${ELAPSED}"
    echo "neuron_input_timeout_warnings : ${WARNINGS}"
    echo
    echo "%% machine-readable"
    echo "{exp068_suite_runtime_probe, ["
    echo "  {date, \"$(date -Is)\"},"
    echo "  {host_otp, \"${OTP}\"},"
    echo "  {bound_s, ${BOUND}},"
    echo "  {finished_within_bound, $([ "$RC" -eq 124 ] && echo false || echo true)},"
    echo "  {elapsed_s, ${ELAPSED}},"
    echo "  {neuron_input_timeout_warnings, ${WARNINGS}}"
    echo "]}."
} | tee "$SUMMARY"

echo
echo "summary written to $SUMMARY"
echo "raw log (scratch, not a record): $LOG"
