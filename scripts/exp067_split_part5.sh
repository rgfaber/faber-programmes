#!/usr/bin/env bash
#
# SECOND SPLIT of the EXP-067 pre-registration: five parts become six.
#
# PART 5 reached 1035 lines and 86954 bytes once the round-3 DESIGN gate section
# was written into it, past the documentation rule that caps a plan file at
# roughly 1500 lines and 75KB on the byte limit. The DESIGN gate record and the
# Result move to a new PART 6.
#
# The cut is on a TOP-LEVEL SECTION BOUNDARY and no section is divided. The
# split is by LINE RANGE only: no line of the pre-registration is retyped,
# reordered or reflowed here. The only new text is navigation, being the
# four-line prefix on the new part (breadcrumb, blank, part title, blank) and
# the "of 5" to "of 6" correction in every part's breadcrumb.
#
# Usage:
#   exp067_split_part5.sh PART5 OUTDIR
#
# PART5 is the pre-resplit PART 5 file, taken from a snapshot rather than from
# the tree, so the script cannot silently re-split an already split tree and
# destroy the cross-reference repointing applied afterwards. OUTDIR is where
# the new PART 5 and PART 6 land.
#
# Verify with scripts/exp067_verify_part5_split.sh.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: $0 PART5 OUTDIR" >&2
    exit 2
fi

SRC="$1"
OUTDIR="$2"
BASE="exp067_coevolution_cycling"

if [ ! -f "$SRC" ]; then
    echo "no such part 5 snapshot: $SRC" >&2
    exit 2
fi
if [ ! -d "$OUTDIR" ]; then
    echo "no such output directory: $OUTDIR" >&2
    exit 2
fi

# The navigation prefix the first split added to every part: breadcrumb, blank,
# part title, blank. Lines 5 onward are pre-registration content.
NAV=4

# Top-level section boundaries, re-derived from the snapshot with
#   grep -n '^## ' exp067_coevolution_cycling_PART5.md
# The cut is immediately before the round-1 DESIGN gate section.
CUT=455
LAST="$(wc -l < "$SRC")"

P5_TITLE='Threats to validity, what a negative would mean, the budget and the hypothesis'
P6_TITLE='The DESIGN gate record, all three rounds, and the Result'

emit() {
    local n="$1" first="$2" last="$3" title="$4" out
    out="${OUTDIR}/${BASE}_PART${n}.md"
    {
        printf '> Part %s of 6 of the [EXP-067 pre-registration](%s.md). The root holds the framing, the status and the section index.\n' "$n" "$BASE"
        printf '\n'
        printf '# EXP-067 PART %s. %s\n' "$n" "$title"
        printf '\n'
        awk -v a="$first" -v b="$last" 'NR >= a && NR <= b' "$SRC"
    } > "$out"
    printf '%s  lines %s-%s of the pre-resplit PART 5\n' "$out" "$first" "$last"
}

# PART 5 keeps its content up to the line before the cut. The trailing "---"
# and blank line at 453-454 stay with PART 5, exactly as the first split left
# every other part ending on its own separator.
emit 5 "$((NAV + 1))" "$((CUT - 1))" "$P5_TITLE"
emit 6 "$CUT" "$LAST" "$P6_TITLE"

# Every other part's breadcrumb still says "of 5". That line is navigation, not
# pre-registration text, and it is excluded from the losslessness
# reconstruction, so correcting it cannot lose a line of the document.
for n in 1 2 3 4; do
    f="${OUTDIR}/${BASE}_PART${n}.md"
    if [ -f "$f" ]; then
        sed -i "1s/^> Part ${n} of 5 of the/> Part ${n} of 6 of the/" "$f"
        printf '%s  breadcrumb now reads "of 6"\n' "$f"
    fi
done
