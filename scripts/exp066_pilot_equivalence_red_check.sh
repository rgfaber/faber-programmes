#!/usr/bin/env bash
#
# THE RED CHECK. A green equivalence suite is worth nothing until it is shown it
# can go red, and this front has already been bitten by exactly that: the
# extraction's own test file records a first red check that was worthless,
# because moving a constant by one unit left the suite green when integer
# division absorbed the change.
#
# NOTHING IS EDITED. robo_pilot itself is never touched. Each perturbation is a
# COPY of the pinned engine's robo_pilot.erl, renamed and corrupted in one named
# place, compiled into a scratch directory and pointed at by the harness's
# pilot_mod option. The real module and both repositories are left alone.
#
# THE THREE PERTURBATIONS, chosen to bite in different places:
#
#   p1_fire_clamp    to_range(E, 30) -> to_range(E, 29) in the OUTPUT decode.
#                    Catches a corrupted intent with the sensor vector intact.
#
#   p2_swap_16_17    target_lateral and target_range_rate exchanged in the
#                    SENSOR vector. Catches a channel-order defect, which is
#                    invisible to any cross-machine replay diff because it
#                    changes every match identically on every machine.
#
#   p3_tank_r        TANK_R 4608 -> 4068, a mistyped arena radius. CORRECTED
#                    2026-07-30: an earlier version of this comment called 4068
#                    the transposition robo_pilot_tests records as having PASSED
#                    EVERYTHING. That transposition is 4608 -> 4680, in the note
#                    above wall_danger_is_observable_near_a_wall_test/0, and the
#                    two are different typos (4680 raises the radius by 72, 4068
#                    lowers it by 540). What p3 tests is the same CLASS: a
#                    constant that is silent in open ground, where wall_danger
#                    saturates. If a full-match replay catches what an
#                    open-ground unit fixture missed, the replay is doing work
#                    the unit tests cannot. It says nothing about 4680, which
#                    this script does not build.
#
# Each perturbation must produce intent divergences. A perturbation that comes
# back GREEN is reported as such and is a finding about this harness, not a pass.

# MODES:
#   build   generate and compile the perturbed copies only, do not run them.
#           The record driver calls this so the python below lives in ONE place.
#   (none)  build, then run Part A against each.

set -euo pipefail

MODE="${1:-all}"
REPO="/home/rl/work/github.com/rgfaber/faber-programmes"
LOG_DIR="${REPO}/_build/equivalence_logs"
RED_DIR="${LOG_DIR}/red"
DEP_SRC="${REPO}/_build/default/lib/faber_tweann/src/robo_pilot.erl"
DEP_INC="${REPO}/_build/default/lib/faber_tweann/include"

rm -rf "${RED_DIR}"
mkdir -p "${RED_DIR}"
cd "${REPO}"

python3 - "${DEP_SRC}" "${RED_DIR}" <<'PYEOF'
import sys, pathlib

src_path, out_dir = sys.argv[1], pathlib.Path(sys.argv[2])
src = pathlib.Path(src_path).read_text()

LAT = "     clamp((WC * VY - WS * VX) div 2048, 256),\n"
RNG = "     clamp((WC * VX + WS * VY) div 2048, 256)].\n"

def fire_clamp(s):
    old = "fire = robo_net:to_range(E, 30)}"
    assert old in s, "fire clamp anchor missing"
    return s.replace(old, "fire = robo_net:to_range(E, 29)}")

def swap_16_17(s):
    assert LAT + RNG in s, "contact tail anchor missing"
    new = ("     clamp((WC * VX + WS * VY) div 2048, 256),\n"
           "     clamp((WC * VY - WS * VX) div 2048, 256)].\n")
    return s.replace(LAT + RNG, new)

def tank_r(s):
    old = "-define(TANK_R, 4608)."
    assert old in s, "TANK_R anchor missing"
    return s.replace(old, "-define(TANK_R, 4068).")

for name, fn in [("p1_fire_clamp", fire_clamp),
                 ("p2_swap_16_17", swap_16_17),
                 ("p3_tank_r", tank_r)]:
    mod = "robo_pilot_red_" + name
    body = fn(src).replace("-module(robo_pilot).", "-module(%s)." % mod, 1)
    assert body != src, name + " changed nothing"
    (out_dir / (mod + ".erl")).write_text(body)
    print("wrote %s.erl" % mod)
PYEOF

echo
echo "== compiling the perturbed copies =="
for f in "${RED_DIR}"/*.erl; do
  erlc -I "${DEP_INC}" -o "${RED_DIR}" "${f}" > "${RED_DIR}/$(basename "${f}").compile.log" 2>&1
  echo "  $(basename "${f}") compile exit: $?"
done

if [ "${MODE}" = "build" ]; then
  echo
  echo "built only, as asked; not run."
  exit 0
fi

echo
echo "== running Part A against each perturbation (a divergence is the PASS) =="
for MOD in robo_pilot_red_p1_fire_clamp robo_pilot_red_p2_swap_16_17 robo_pilot_red_p3_tank_r; do
  LOG="${LOG_DIR}/red_${MOD}.log"
  set +e
  erl -noshell -pa _build/test/lib/*/ebin \
      -pa _build/test/lib/faber_programmes/experiments \
      -pa "${RED_DIR}" \
      -eval "R = exp066_pilot_extraction_equivalence_tests:part_a(#{a_starts => 6, pilot_mod => ${MOD}}),
             io:format(\"~nRED CHECK ~p: divergences ~p~nfirst: ~p~n\",
                       [${MOD}, length(maps:get(divergences, R)),
                        maps:get(first_divergence, R)]),
             halt(case maps:get(equivalent, R) of true -> 1; false -> 0 end)." \
      > "${LOG}" 2>&1
  CODE=$?
  set -e
  echo "  ${MOD}: exit ${CODE} ($([ "${CODE}" -eq 0 ] && echo 'went RED, good' || echo 'STAYED GREEN, the harness is blind here'))"
  echo "    log: ${LOG}"
done
