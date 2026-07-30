#!/usr/bin/env bash
#
# EXP-066: the rates scripted_null/1 threw away, recovered and used; and the
# match-level null's scale, fixed at the source. This does NOT re-run the
# experiment. The arms are done and their champions are archived; every rate
# produced here comes from replaying archived champions and scripted bots through
# matches at the engine pin.
#
#   FIX C  scripted_null/1 kept element 1 of rates/1 and discarded the LOSS and
#          DRAW rates. A win rate of 0.0 is consistent with all losses and with
#          all draws, and those are different facts: the first is an EDGE from
#          the floor bot to that rung, the second is no edge at all. The full
#          W/L/D triple is recovered for every scripted opponent against every
#          one of the 40 champions, BOTH DIRECTIONS MEASURED, plus the full 5x5
#          scripted round robin, and then used to ask whether a genuine
#          intransitive triple exists inside the pre-registered arms under ONE
#          stated relation (draws count as NOT beating).
#
#   FIX D  the synthetic nulls stored a MARGIN where the counter differences WIN
#          RATES, so every synthetic margin was doubled and every band
#          effectively halved. Fixed at the source in xp_from_wins/2; the as-run
#          construction is kept verbatim as xp_from_pairs_as_run/2 so both
#          columns come off the same draws.
#
# Writes:
#   programmes/p7_coevolution/exp066_competence_floor/exp066_recovered_rates_and_null_fix.txt
#   an APPEND-ONLY note at the foot of BOTH copies of the feed:
#     programmes/p7_coevolution/exp066_competence_floor/exp066_floor_feed.txt
#     ../faber-ecosystem/insights/066-raw-competence-floor.txt
#
# WHICH STEP APPENDS. Only "recovered full" appends to the two feed copies, and
# the append is ONE-SHOT: running it twice would add a second copy of the same
# note to an append-only file. The record itself is overwritten rather than
# appended, so "record" regenerates it as often as you like and touches no feed.
#
# usage: scripts/exp066_recovered.sh <recovered|record|verify|scaling> [smoke|dry]
#
#   smoke   a cut-down configuration that exercises every code path on a reduced
#           start set and writes to /tmp. ITS NUMBERS ARE NOT RESULTS: the
#           held-out split is truncated, so no rate in it is comparable with the
#           record. It exists to time the real run and to catch a format crash
#           before the real run touches an append-only file.
#
#   dry     the FULL configuration, real numbers, but every output redirected to
#           /tmp. The two feed copies are APPEND-ONLY, so the note is written to
#           throwaway copies first and read back before the real run appends to
#           the real ones. The computation is deterministic, so a dry run and the
#           real run produce identical numbers.
#
#   record  regenerates ONLY the record, with addendum_feeds set to the empty
#           list so nothing is appended anywhere.
#
#   verify  re-derives the record's numbers with code that shares nothing with
#           the runner: the champion-versus-rung rates against the feed's own
#           as-run rung profiles, the triple search from the record's edge list,
#           and all three null encodings against one another.
#
#   scaling runs scripts/exp066_verify_null_scaling.escript, the independent
#           as-built-versus-corrected script the record's section F1b discusses.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STEP="${1:-}"
MODE="${2:-full}"

case "$STEP" in
    recovered|record|verify|scaling) ;;
    *) echo "usage: $(basename "$0") <recovered|record|verify|scaling> [smoke|dry]" >&2
       exit 2 ;;
esac

case "$MODE" in
    full|smoke|dry) ;;
    *) echo "usage: $(basename "$0") <recovered|record|verify|scaling> [smoke|dry]" >&2
       exit 2 ;;
esac

MODULE=exp066_single_population_floor_tests
ARCH="programmes/p7_coevolution/exp066_competence_floor"
RECORD="${ARCH}/exp066_recovered_rates_and_null_fix.txt"

echo "==> building against the pinned engine"
(cd "$ROOT" && rebar3 as test compile)

# Provenance: the engine actually linked must be the pin, or every number below is
# attributed to the wrong engine.
ENGINE_DIR="${ROOT}/_build/test/lib/faber_tweann"
ENGINE_PIN="$(awk 'match($0, /[0-9a-f]{40}/) { print substr($0, RSTART, RLENGTH); exit }' \
    "${ROOT}/rebar.config")"
if [[ -d "${ENGINE_DIR}/.git" ]]; then
    ENGINE_SHA="$(git -C "$ENGINE_DIR" rev-parse HEAD)"
else
    ENGINE_SHA="unknown"
fi
if [[ "$ENGINE_SHA" != "$ENGINE_PIN" ]]; then
    echo "error: built engine ($ENGINE_SHA) is not the pin ($ENGINE_PIN)." >&2
    echo "       run: rebar3 upgrade faber_tweann" >&2
    exit 1
fi
echo "==> engine pin verified: ${ENGINE_SHA}"

CODE_PATHS=(-pa "${ROOT}"/_build/test/lib/*/ebin
            -pa "${ROOT}/_build/test/lib/faber_programmes/experiments")

cd "$ROOT"

if [[ "$STEP" == "scaling" ]]; then
    echo "==> the independent as-built versus corrected script"
    exec "${ROOT}/scripts/exp066_verify_null_scaling.escript"
fi

if [[ "$STEP" == "verify" ]]; then
    echo "==> verify"
    exec "${ROOT}/scripts/exp066_verify_recovered.escript"
fi

# The smoke configuration truncates the held-out split, so it writes its record
# and its feed note to /tmp where they cannot be mistaken for the record.
SMOKE='#{heldout => 6,
         rc_out => "/tmp/exp066_recovered_smoke.txt",
         addendum_feeds => ["/tmp/exp066_rc_feed_smoke_a.txt",
                            "/tmp/exp066_rc_feed_smoke_b.txt"]}'
DRY='#{rc_out => "/tmp/exp066_recovered_dry.txt",
       addendum_feeds => ["/tmp/exp066_rc_feed_dry_a.txt",
                          "/tmp/exp066_rc_feed_dry_b.txt"]}'
RECORD_ONLY='#{addendum_feeds => []}'
FULL='#{}'

opts() {
    case "$STEP:$MODE" in
        record:*)        printf '%s' "$RECORD_ONLY" ;;
        recovered:smoke) printf '%s' "$SMOKE" ;;
        recovered:dry)   printf '%s' "$DRY" ;;
        *)               printf '%s' "$FULL" ;;
    esac
}

# The dry run appends its note to THROWAWAY COPIES of the two append-only feeds,
# so what the real append will look like can be read back before it happens.
if [[ "$STEP" == "recovered" && "$MODE" == "dry" ]]; then
    cp "${ROOT}/${ARCH}/exp066_floor_feed.txt" /tmp/exp066_rc_feed_dry_a.txt
    cp "${ROOT}/../faber-ecosystem/insights/066-raw-competence-floor.txt" \
       /tmp/exp066_rc_feed_dry_b.txt
fi

echo "==> ${STEP} (${MODE})"
EXPR="T0 = erlang:monotonic_time(second),
      R = ${MODULE}:recovered($(opts)),
      io:format(\"~n~p~n\", [R]),
      io:format(\"~nwall clock: ~p s~n\", [erlang:monotonic_time(second) - T0]),
      halt()."
erl -noshell "${CODE_PATHS[@]}" -eval "$EXPR"

if [[ "$STEP" == "recovered" && "$MODE" == "full" ]]; then
    echo
    echo "==> the two feed copies must stay byte-identical"
    cmp "${ROOT}/${ARCH}/exp066_floor_feed.txt" \
        "${ROOT}/../faber-ecosystem/insights/066-raw-competence-floor.txt" \
        && echo "cmp: IDENTICAL"
    echo "==> record: ${RECORD}"
fi

if [[ "$STEP" == "recovered" && "$MODE" == "dry" ]]; then
    echo
    echo "==> the two THROWAWAY feed copies must stay byte-identical"
    cmp /tmp/exp066_rc_feed_dry_a.txt /tmp/exp066_rc_feed_dry_b.txt \
        && echo "cmp: IDENTICAL"
fi
