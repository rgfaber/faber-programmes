#!/usr/bin/env bash
#
# EXP-066 post-hoc POLICY PROBE, read-only.
#
# WHAT THE CHAMPIONS ACTUALLY DO against robo_gauntlet's predictive_gun.
#
# This script touches NO file in experiments/ and NO file in src/. It builds a
# throwaway view module out of the ALREADY-COMPILED runner beam's own
# debug_info abstract code, renamed and with export_all bolted on, so the pilot
# encoder and the match loop that produced the archived feed are called
# verbatim rather than reimplemented. Everything lands outside the repo, in
# WORK, so a concurrent rebar3 in the repo cannot contend with it.
#
# Usage: exp066_policy_probe.sh <function> [args...]
set -euo pipefail

REPO=/home/rl/work/github.com/rgfaber/faber-programmes
BUILD="${REPO}/_build/test/lib"
WORK="${HOME}/.cache/exp066_policy_probe"
SRC="${REPO}/scripts/exp066_policy_probe.erl"
BEAM="${BUILD}/faber_programmes/experiments/exp066_single_population_floor_tests.beam"

mkdir -p "${WORK}/ebin"

# 1. The view module: the runner's own abstract code, renamed, export_all.
cat > "${WORK}/mkview.erl" <<'ERL'
-module(mkview).
-export([main/1]).

main([Beam, Out]) ->
    {ok, {_M, [{abstract_code, {raw_abstract_v1, Forms}}]}} =
        beam_lib:chunks(Beam, [abstract_code]),
    Renamed = [rename(F) || F <- Forms],
    Injected = inject(Renamed),
    {ok, exp066_view, Bin} =
        compile:forms(Injected, [return_errors, nowarn_export_all, debug_info,
                                 {i, Out}]),
    ok = file:write_file(filename:join(Out, "exp066_view.beam"), Bin),
    io:format("view ok~n").

rename({attribute, L, module, _}) -> {attribute, L, module, exp066_view};
rename(F) -> F.

%% export_all immediately after the module attribute.
inject([{attribute, L, module, M} | Rest]) ->
    [{attribute, L, module, M},
     {attribute, L, compile, [export_all, nowarn_export_all]} | Rest];
inject([F | Rest]) -> [F | inject(Rest)];
inject([]) -> [].
ERL

erlc -o "${WORK}" "${WORK}/mkview.erl"
erl -noshell -pa "${WORK}" -eval \
  "mkview:main([\"${BEAM}\", \"${WORK}/ebin\"]), halt(0)."

# 2. The probe itself.
erlc -o "${WORK}/ebin" \
     -I "${BUILD}/faber_tweann/include" \
     -pa "${BUILD}/faber_tweann/ebin" \
     "${SRC}"

# 3. Run.
exec erl -noshell \
  -pa "${WORK}/ebin" \
  -pa "${BUILD}/faber_tweann/ebin" \
  -pa "${BUILD}/faber_programmes/ebin" \
  -eval "exp066_policy_probe:cli([$(printf '"%s",' "$@" | sed 's/,$//')]), halt(0)."
