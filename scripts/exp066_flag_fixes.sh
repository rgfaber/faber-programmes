#!/usr/bin/env bash
#
# EXP-066: the two flag fixes the signed insight names as owed work (item 4 of
# "What this buys"). This does NOT re-run the experiment. The arms are done and
# their champions are archived; every number produced here comes from replaying
# archived champions through matches at the engine pin.
#
#   FIX A  IF-10 LADDER-INVERSION. The as-run predicate read two of the four
#          lower rungs and was draw-blind. inverted/1 is widened, the as-run
#          predicate is kept verbatim as inverted_as_run/1, and both are computed
#          over the same profiles so old and new print side by side. flags/3 also
#          gains the per-arm count under each predicate.
#
#   FIX B  PH-GEN, a NEW POST-HOC three-split generalisation diagnostic. It is
#          NOT a repair of IF-8: IF-8 was untestable with this instrument because
#          trainW sits at a ceiling forced by the fitness rule, and that fact
#          stands. PH-GEN reports the win rate and the FLOORED margin on train
#          (12 matches), calibration (60) and held out (160), plus the gaps.
#
# Writes:
#   programmes/p7_coevolution/exp066_competence_floor/exp066_flag_fixes.txt
#   an APPEND-ONLY note at the foot of BOTH copies of the feed:
#     programmes/p7_coevolution/exp066_competence_floor/exp066_floor_feed.txt
#     ../faber-ecosystem/insights/066-raw-competence-floor.txt
#
# WHICH STEP APPENDS. Only "fixes full" appends to the two feed copies, and the
# append is ONE-SHOT: running it twice would add a second copy of the same note to
# an append-only file. The record itself is overwritten rather than appended, so
# "record" regenerates it as often as you like and touches no feed.
#
# usage: scripts/exp066_flag_fixes.sh <fixes|record|verify> [smoke|dry]
#
#   smoke   a cut-down configuration that exercises every code path on a reduced
#           start set and writes to /tmp. ITS NUMBERS ARE NOT RESULTS: the splits
#           are truncated, so no win rate or margin in it is comparable with the
#           record. It exists to time the real run and to catch a format crash
#           before the real run touches an append-only file.
#
#   dry     the FULL configuration, real numbers, but every output redirected to
#           /tmp. The two feed copies are APPEND-ONLY, so the note is written to
#           throwaway copies first and read back before the real run appends to
#           the real ones. The computation is deterministic, so a dry run and the
#           real run produce identical numbers.
#
#   record  regenerates ONLY exp066_flag_fixes.txt, with addendum_feeds set to the
#           empty list so nothing is appended anywhere. Use this after any change
#           to the record's text; the feed note stays as it was written.
#
#   verify  re-derives the record's own IF-10 counts and checks every recomputed
#           held-out profile against the as-run profile in the feed, with code
#           that shares nothing with the runner. Takes the record path and the
#           feed path as optional arguments; defaults to the archived pair.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STEP="${1:-}"
MODE="${2:-full}"

case "$STEP" in
    fixes|record|verify) ;;
    *) echo "usage: $(basename "$0") <fixes|record|verify> [smoke|dry]" >&2
       exit 2 ;;
esac

case "$MODE" in
    full|smoke|dry) ;;
    *) echo "usage: $(basename "$0") <fixes|record|verify> [smoke|dry]" >&2
       exit 2 ;;
esac

MODULE=exp066_single_population_floor_tests
ARCH="programmes/p7_coevolution/exp066_competence_floor"

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

# The smoke configuration truncates the three splits, so it writes its record and
# its feed note to /tmp where they cannot be mistaken for the record.
SMOKE='#{heldout => 6, calibration => 4, train => 2,
         fx_out => "/tmp/exp066_flag_fixes_smoke.txt",
         addendum_feeds => ["/tmp/exp066_feed_smoke_a.txt",
                            "/tmp/exp066_feed_smoke_b.txt"]}'
DRY='#{fx_out => "/tmp/exp066_flag_fixes_dry.txt",
       addendum_feeds => ["/tmp/exp066_feed_dry_a.txt",
                          "/tmp/exp066_feed_dry_b.txt"]}'
# Record only: an empty feed list means add_append/2 is never called.
RECORD='#{addendum_feeds => []}'
FULL='#{}'

opts() {
    case "$STEP:$MODE" in
        record:*)    printf '%s' "$RECORD" ;;
        fixes:smoke) printf '%s' "$SMOKE" ;;
        fixes:dry)   printf '%s' "$DRY" ;;
        *)           printf '%s' "$FULL" ;;
    esac
}

cd "$ROOT"

# The dry run appends its note to THROWAWAY COPIES of the two append-only feeds,
# so what the real append will look like can be read back before it happens.
if [[ "$STEP" == "fixes" && "$MODE" == "dry" ]]; then
    cp "${ROOT}/${ARCH}/exp066_floor_feed.txt" /tmp/exp066_feed_dry_a.txt
    cp "${ROOT}/../faber-ecosystem/insights/066-raw-competence-floor.txt" \
       /tmp/exp066_feed_dry_b.txt
fi

if [[ "$STEP" == "verify" ]]; then
    echo "==> verify"
    exec "${ROOT}/scripts/exp066_verify_flag_fixes.escript"
fi

echo "==> ${STEP} (${MODE})"
EXPR="T0 = erlang:monotonic_time(second),
      R = ${MODULE}:flag_fixes($(opts)),
      io:format(\"~n~p~n\", [R]),
      io:format(\"~nwall clock: ~p s~n\", [erlang:monotonic_time(second) - T0]),
      halt()."
erl -noshell "${CODE_PATHS[@]}" -eval "$EXPR"

if [[ "$STEP" == "fixes" && "$MODE" == "full" ]]; then
    echo
    echo "==> the two feed copies must stay byte-identical"
    cmp "${ROOT}/${ARCH}/exp066_floor_feed.txt" \
        "${ROOT}/../faber-ecosystem/insights/066-raw-competence-floor.txt" \
        && echo "cmp: IDENTICAL"
fi

if [[ "$STEP" == "fixes" && "$MODE" == "dry" ]]; then
    echo
    echo "==> the two THROWAWAY feed copies must stay byte-identical"
    cmp /tmp/exp066_feed_dry_a.txt /tmp/exp066_feed_dry_b.txt && echo "cmp: IDENTICAL"
fi
