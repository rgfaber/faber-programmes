#!/usr/bin/env bash
#
# Close EXP-066's CLAIM-gate findings. This does NOT re-run the experiment: the
# arms are done and their champions are archived. It produces the two records the
# gate found missing, both from the archive, both persisted:
#
#   crossplay  the exploratory cross-play probe, rewritten so it writes a file
#              instead of printing to a shell that no longer exists. Reports the
#              ordered (exp057) count AND the true unordered cycle count at three
#              bands, three random nulls, an n-matched subsample distribution, the
#              whole-matrix draw share, the margin granularity, and the full matrix.
#              -> programmes/p7_coevolution/exp066_competence_floor/exp066_crossplay.txt
#
#   addendum   the won_opp_shots column the per-seed emit dropped (IF-12's raw
#              material), recomputed per seed from the archived champions, plus arm
#              C's attempt accounting. APPENDED to the feed, marked post hoc.
#              -> faber-ecosystem/insights/066-raw-competence-floor.txt
#                 and the archived copy of the same feed
#
# usage: scripts/exp066_close_findings.sh <crossplay|addendum|gates|recover> [smoke]
#
#   smoke    runs a cut-down configuration to check the code paths and time the
#            real run. Its numbers are NOT results and it writes to /tmp.
#
#   recover  the draft insight quoted 100 intransitive triples at band 0.10 and
#            said the probe ran 6 held-out starts, while the runner's default was
#            12, and nothing was persisted either way, so the configuration behind
#            that number was unrecoverable FROM THE RECORD. It is recoverable BY
#            REPRODUCTION: this replays the probe at 6 and at 12 starts and prints
#            the band-0.10 counts, which identifies the configuration that produced
#            the quoted number. Writes to /tmp; the record is the 80-start run.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STEP="${1:-}"
MODE="${2:-full}"

case "$STEP" in
    crossplay|addendum|gates|recover) ;;
    *) echo "usage: $(basename "$0") <crossplay|addendum|gates|recover> [smoke]" >&2
       exit 2 ;;
esac

MODULE=exp066_single_population_floor_tests

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

# The cut-down configuration exists to time the real one and to exercise every code
# path cheaply. It writes to /tmp so it cannot be mistaken for the record.
SMOKE_XP='#{xp_starts => 4, xp_null_draws => 5, xp_sub_draws => 5,
            xp_out => "/tmp/exp066_crossplay_smoke.txt"}'
SMOKE_ADD='#{heldout => 8, calibration => 4,
             addendum_feeds => ["/tmp/exp066_feed_smoke.txt"]}'
FULL='#{}'

opts() {
    case "$1:$MODE" in
        crossplay:smoke) printf '%s' "$SMOKE_XP" ;;
        addendum:smoke)  printf '%s' "$SMOKE_ADD" ;;
        *)               printf '%s' "$FULL" ;;
    esac
}

case "$STEP" in
    gates)
        EXPR="io:format(\"~p~n\", [${MODULE}:gates()]), halt()."
        ;;
    crossplay)
        EXPR="T0 = erlang:monotonic_time(second),
              R = ${MODULE}:crossplay($(opts crossplay)),
              io:format(\"~n~p~n\", [R]),
              io:format(\"~nwall clock: ~p s~n\", [erlang:monotonic_time(second) - T0]),
              halt()."
        ;;
    recover)
        EXPR="Show = fun(S) ->
                        R = ${MODULE}:crossplay(#{xp_starts => S, xp_null_draws => 1,
                                                  xp_sub_draws => 1,
                                                  xp_out => \"/tmp/exp066_crossplay_asrun\"
                                                            ++ integer_to_list(S) ++ \".txt\"}),
                        {crossplay, F} = R,
                        C = element(2, lists:keyfind(counts, 1, F)),
                        G = element(2, lists:keyfind(granularity, 1, F)),
                        io:format(\"~n~p starts: ~p~n           ~p~n\", [S, C, G])
                    end,
              [Show(S) || S <- [6, 12]],
              halt()."
        ;;
    addendum)
        EXPR="T0 = erlang:monotonic_time(second),
              R = ${MODULE}:addendum($(opts addendum)),
              io:format(\"~n~p~n\", [R]),
              io:format(\"~nwall clock: ~p s~n\", [erlang:monotonic_time(second) - T0]),
              halt()."
        ;;
esac

echo "==> ${STEP} (${MODE})"
cd "$ROOT"
exec erl -noshell "${CODE_PATHS[@]}" -eval "$EXPR"
