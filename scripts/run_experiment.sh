#!/usr/bin/env bash
#
# Run one experiment and record its provenance.
#
#   scripts/run_experiment.sh exp047_non_integrable_stressor_tests
#
# Captures stdout to the raw feed and appends a Provenance block to the manifest:
# engine commit actually built, OTP and rebar3 versions, date, and the command.
#
# The raw feed lands in the CORPUS (faber-ecosystem), which is where feeds live.
# Override the corpus location with FABER_CORPUS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="${FABER_CORPUS:-$(cd "${ROOT}/.." && pwd)/faber-ecosystem}"

if [[ $# -lt 1 ]]; then
    echo "usage: $(basename "$0") <runner_module> [extra rebar3 eunit args...]" >&2
    exit 2
fi

MODULE="$1"
shift

if [[ ! "$MODULE" =~ ^exp([0-9]{3})_(.+)_tests$ ]]; then
    echo "error: module must be exp<NNN>_<slug>_tests, got '$MODULE'" >&2
    exit 2
fi
NNN="${BASH_REMATCH[1]}"
SLUG="${BASH_REMATCH[2]}"

RUNNER="${ROOT}/experiments/${MODULE}.erl"
MANIFEST="${ROOT}/experiments/exp${NNN}_${SLUG}.md"

[[ -f "$RUNNER" ]] || { echo "error: no runner at $RUNNER" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo "error: no manifest at $MANIFEST" >&2; exit 1; }

if [[ -d "${CORPUS}/insights" ]]; then
    FEED="${CORPUS}/insights/${NNN}-raw-${SLUG}.txt"
else
    mkdir -p "${ROOT}/feeds"
    FEED="${ROOT}/feeds/${NNN}-raw-${SLUG}.txt"
    echo "warning: corpus not found at ${CORPUS}, feed staged at ${FEED}" >&2
fi

if [[ -e "$FEED" ]]; then
    echo "error: feed already exists at $FEED" >&2
    echo "       a rerun must not silently overwrite the record of the first run." >&2
    echo "       move the old feed aside, or use a distinct slug." >&2
    exit 1
fi

# Build first, so the engine commit recorded below is the one actually linked.
echo "==> building against the pinned engine"
(cd "$ROOT" && rebar3 as test compile)

ENGINE_DIR="${ROOT}/_build/test/lib/faber_tweann"
if [[ -d "${ENGINE_DIR}/.git" ]]; then
    ENGINE_SHA="$(git -C "$ENGINE_DIR" rev-parse HEAD)"
else
    ENGINE_SHA="unknown (dep not a git checkout)"
fi
ENGINE_PIN="$(awk 'match($0, /[0-9a-f]{40}/) { print substr($0, RSTART, RLENGTH); exit }' "${ROOT}/rebar.config")"

if [[ "$ENGINE_SHA" != "$ENGINE_PIN" ]]; then
    echo "error: built engine ($ENGINE_SHA) does not match the pin in rebar.config ($ENGINE_PIN)." >&2
    echo "       provenance would be wrong. run: rebar3 upgrade faber_tweann" >&2
    exit 1
fi

ENGINE_VSN="$(awk 'match($0, /\{vsn, *"[^"]+"/) { print substr($0, RSTART, RLENGTH); exit }' \
    "${ENGINE_DIR}/src/faber_tweann.app.src" 2>/dev/null || echo "unknown")"
OTP="$(erl -noshell -eval 'io:format("~s/~s", [erlang:system_info(otp_release), erlang:system_info(version)]), halt().')"
REBAR="$(cd "$ROOT" && rebar3 version)"
STARTED="$(date -Is)"

echo "==> running ${MODULE}, feed -> ${FEED}"
set +e
(cd "$ROOT" && rebar3 as test eunit --module="$MODULE" "$@") 2>&1 | tee "$FEED"
STATUS="${PIPESTATUS[0]}"
set -e
FINISHED="$(date -Is)"

cat >> "$MANIFEST" <<PROVENANCE_EOF

### Run ${STARTED}

| Field | Value |
|---|---|
| Runner | \`experiments/${MODULE}.erl\` |
| Engine commit | \`${ENGINE_SHA}\` |
| Engine version | ${ENGINE_VSN} |
| OTP / ERTS | ${OTP} |
| rebar3 | ${REBAR} |
| Command | \`rebar3 as test eunit --module=${MODULE} $*\` |
| Started | ${STARTED} |
| Finished | ${FINISHED} |
| Exit status | ${STATUS} |
| Raw feed | \`${FEED#"${CORPUS}/"}\` |
PROVENANCE_EOF

echo
echo "==> provenance appended to ${MANIFEST}"
echo "==> feed at ${FEED}"
echo
echo "next: the adversary attacks the CLAIM before you sign it. Give it the draft"
echo "      claim, the feed, AND this runner. Then archive:"
echo "      scripts/archive_experiment.sh ${NNN} <programme_dir>"

exit "$STATUS"
