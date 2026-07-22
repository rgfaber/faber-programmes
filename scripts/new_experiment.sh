#!/usr/bin/env bash
#
# Scaffold a new experiment: a runner stub and its manifest.
#
#   scripts/new_experiment.sh 047 non_integrable_stressor
#
# Creates:
#   experiments/exp047_non_integrable_stressor_tests.erl
#   experiments/exp047_non_integrable_stressor.md   (the manifest, pre-registration)
#
# The manifest is filled in BEFORE the runner is written. That ordering is the
# point: a pre-registration written after seeing data is not a pre-registration.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 2 ]]; then
    echo "usage: $(basename "$0") <NNN> <slug>" >&2
    echo "   eg: $(basename "$0") 047 non_integrable_stressor" >&2
    exit 2
fi

NNN="$1"
SLUG="$2"

if [[ ! "$NNN" =~ ^[0-9]{3}$ ]]; then
    echo "error: NNN must be three digits, got '$NNN'" >&2
    exit 2
fi

if [[ ! "$SLUG" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "error: slug must be lowercase snake_case, got '$SLUG'" >&2
    exit 2
fi

BASE="exp${NNN}_${SLUG}"
RUNNER="${ROOT}/experiments/${BASE}_tests.erl"
MANIFEST="${ROOT}/experiments/${BASE}.md"

for f in "$RUNNER" "$MANIFEST"; do
    if [[ -e "$f" ]]; then
        echo "error: $f already exists, refusing to overwrite" >&2
        exit 1
    fi
done

# awk, not `grep | head`: a pipeline into head raises SIGPIPE under `set -o pipefail`.
ENGINE_REF="$(awk 'match($0, /[0-9a-f]{40}/) { print substr($0, RSTART, RLENGTH); exit }' "${ROOT}/rebar.config")"
TODAY="$(date -I)"

cat > "$MANIFEST" <<MANIFEST_EOF
# EXP-${NNN} — <one-line title>

Pre-registration. Fill this in BEFORE writing the runner. A decision rule written
after seeing data is not a decision rule.

- **Programme:** P<N>
- **Opened:** ${TODAY}
- **Engine pin at open:** \`${ENGINE_REF}\`
- **Runner:** \`experiments/${BASE}_tests.erl\`
- **Raw feed:** \`faber-ecosystem/insights/${NNN}-raw-<slug>.txt\`
- **Insight:** \`faber-ecosystem/insights/${NNN}-*.md\` (once signed)

## Hypothesis

<A falsifiable prediction, with a direction. State what would surprise us.>

## Arms

| Arm | Mechanism | Genome dims | Notes |
|---|---|---|---|
| null | <the arm that provably CANNOT do the thing being claimed> | | |
| | | | |

A missing null is the most common defect in this corpus. Without a floor, a good
static prior is indistinguishable from genuine within-lifetime adaptation.

## Controls

- **n:** <independent EVOLUTIONARY runs per arm, not instances scored from one genome>
- **Common random numbers:** <seed policy, and confirm it is shared ACROSS arms, not only within>
- **Matched budget:** <total lifetime steps / generations / population, identical across arms>
- **Matched capacity:** <genome dims per arm, or the sweep if they cannot be matched>
- **Metric:** <normalised against what? raw fitness is not comparable across instances
  with different achievable ceilings>

## Decision rule

<Numeric. What result accepts the hypothesis, what result rejects it. Both must be
reachable. If no outcome can embarrass the standing thesis, this is not a test.>

## Fallback interpretation

<What the most likely null outcome MEANS, committed in advance, so a null is not
silently reframed afterwards.>

## Kill criterion

<The condition under which we stop and call it.>

## Provenance

*Appended automatically by \`scripts/run_experiment.sh\`. Do not hand-edit.*

## Result

<One line, once the insight is signed. Link the insight.>
MANIFEST_EOF

cat > "$RUNNER" <<RUNNER_EOF
%%%-------------------------------------------------------------------
%%% @doc EXP-${NNN} — <one-line title>
%%%
%%% Pre-registration: experiments/${BASE}.md
%%% Run: scripts/run_experiment.sh ${BASE}_tests
%%%
%%% Archived after signing. This file is a permanent record of what was
%%% actually executed, not a maintained test.
%%% @end
%%%-------------------------------------------------------------------
-module(${BASE}_tests).

-include_lib("eunit/include/eunit.hrl").

%% eunit swallows io:format for PASSING tests. Write the feed to a file
%% (run_experiment.sh captures stdout too, but the file is the reliable copy).

${SLUG}_test_() ->
    {timeout, 3600, fun run/0}.

run() ->
    ?assert(false).
RUNNER_EOF

echo "created:"
echo "  $MANIFEST"
echo "  $RUNNER"
echo
echo "next: fill in the manifest, then have the adversary attack it before writing the runner:"
echo "  the faber-adversary agent, DESIGN gate"
