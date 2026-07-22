#!/usr/bin/env bash
#
# Archive a finished experiment: move its runner and manifest out of the compiled
# working area into the permanent, never-compiled archive.
#
#   scripts/archive_experiment.sh 047 p3_meta_learning
#
# After this, `rebar3 as test compile` no longer touches the runner. That is
# deliberate. An archived runner is a record of what ran against a specific engine
# pin, not code we promise to keep green against a moving engine.
#
# To re-run an archived experiment: check out its recorded engine commit, set that
# ref in rebar.config, and copy the runner back into experiments/.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 2 ]]; then
    echo "usage: $(basename "$0") <NNN> <programme_dir>" >&2
    echo "   eg: $(basename "$0") 047 p3_meta_learning" >&2
    exit 2
fi

NNN="$1"
PROGRAMME="$2"

if [[ ! "$NNN" =~ ^[0-9]{3}$ ]]; then
    echo "error: NNN must be three digits, got '$NNN'" >&2
    exit 2
fi

shopt -s nullglob
RUNNERS=("${ROOT}/experiments/exp${NNN}_"*_tests.erl)
MANIFESTS=("${ROOT}/experiments/exp${NNN}_"*.md)
shopt -u nullglob

if [[ ${#RUNNERS[@]} -eq 0 ]]; then
    echo "error: no runner matching experiments/exp${NNN}_*_tests.erl" >&2
    exit 1
fi
if [[ ${#RUNNERS[@]} -gt 1 ]]; then
    echo "error: ${#RUNNERS[@]} runners match exp${NNN}_, refusing to guess:" >&2
    printf '  %s\n' "${RUNNERS[@]}" >&2
    exit 1
fi

RUNNER="${RUNNERS[0]}"
BASE="$(basename "$RUNNER" _tests.erl)"

if ! grep -q '^### Run ' "${ROOT}/experiments/${BASE}.md" 2>/dev/null; then
    echo "error: ${BASE}.md has no Provenance run block." >&2
    echo "       archiving an experiment that was never recorded as run defeats the point." >&2
    exit 1
fi

DEST="${ROOT}/programmes/${PROGRAMME}/${BASE}"
mkdir -p "$DEST"

for f in "$RUNNER" "${MANIFESTS[@]}"; do
    [[ -e "$f" ]] || continue
    if [[ -e "${DEST}/$(basename "$f")" ]]; then
        echo "error: ${DEST}/$(basename "$f") exists, refusing to overwrite" >&2
        exit 1
    fi
    git -C "$ROOT" mv "$f" "$DEST/" 2>/dev/null || mv "$f" "$DEST/"
    echo "archived: ${DEST}/$(basename "$f")"
done

echo
echo "done. experiments/ is clear for the next run; the record is permanent."
