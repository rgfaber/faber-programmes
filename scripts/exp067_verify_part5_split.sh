#!/usr/bin/env bash
#
# Prove that the SECOND split of the EXP-067 pre-registration, five parts into
# six, lost nothing.
#
# Method. Strip the four navigation lines each part carries (breadcrumb, blank,
# part title, blank), concatenate PART 5 then PART 6 in reading order, and
# compare the result with the pre-resplit PART 5.
#
# STAGE A is the split alone and must be BYTE-IDENTICAL.
# STAGE B is after the cross-reference repointing, where the only permitted
# difference is a line replaced by exactly one other line; the diff is printed
# in full so every difference is enumerated rather than counted.
#
# Usage:
#   exp067_verify_part5_split.sh SPLITDIR [PRE_RESPLIT_PART5]
#
# With one argument the reconstruction is compared against the recorded sha256
# below. With two, it is compared against the file as well, and the line
# accounting and the diff are printed. PRE_RESPLIT_PART5 is the whole file; its
# own four navigation lines are stripped here, because those are navigation and
# not pre-registration content and the new PART 5 and PART 6 carry their own.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "usage: $0 SPLITDIR [PRE_RESPLIT_PART5]" >&2
    exit 2
fi

DIR="$1"
BASE="exp067_coevolution_cycling"
NAV=4

# The pre-resplit PART 5's CONTENT, meaning the file as it stood immediately
# before the cut with its own four navigation lines stripped, which is what the
# two new parts have to reproduce between them: 1031 lines, 86689 bytes. The
# whole file was 1035 lines and 86954 bytes and its sha256 was
# ab855b49d537c8b3eac5022f25c3f9395da81da0e55ef9b52abc5ee529807601.
PRE_SHA="f655c226788b53aeae9db2ee8b931cc4de4908163c93ac0b789a3d33ea48c085"

RECON="$(mktemp)"
trap 'rm -f "$RECON"' EXIT

for n in 5 6; do
    f="${DIR}/${BASE}_PART${n}.md"
    if [ ! -f "$f" ]; then
        echo "missing part: $f" >&2
        exit 2
    fi
    awk -v skip="$NAV" 'NR > skip' "$f" >> "$RECON"
done

RECON_SHA="$(sha256sum "$RECON" | awk '{print $1}')"
RECON_LINES="$(wc -l < "$RECON")"
RECON_BYTES="$(wc -c < "$RECON")"

printf 'reconstruction: %s lines, %s bytes\n' "$RECON_LINES" "$RECON_BYTES"
printf 'reconstruction sha256: %s\n' "$RECON_SHA"
printf 'pre-resplit    sha256: %s\n' "$PRE_SHA"

if [ "$RECON_SHA" = "$PRE_SHA" ]; then
    printf 'VERDICT: BYTE-IDENTICAL. The split lost nothing and changed nothing.\n'
else
    printf 'VERDICT: NOT byte-identical. Every difference must be an enumerated repoint.\n'
fi

if [ "$#" -eq 2 ]; then
    WHOLE="$2"
    SRC="$(mktemp)"
    trap 'rm -f "$RECON" "$SRC"' EXIT
    awk -v skip="$NAV" 'NR > skip' "$WHOLE" > "$SRC"
    printf '\nline accounting against %s, navigation stripped:\n' "$WHOLE"
    printf '  whole file     : %s lines, %s bytes\n' \
        "$(wc -l < "$WHOLE")" "$(wc -c < "$WHOLE")"
    printf '  its content    : %s lines, %s bytes\n' \
        "$(wc -l < "$SRC")" "$(wc -c < "$SRC")"
    LOST="$(comm -23 <(sort "$SRC") <(sort "$RECON") | wc -l)"
    GAINED="$(comm -13 <(sort "$SRC") <(sort "$RECON") | wc -l)"
    printf '  lines present in the pre-resplit and absent from the reconstruction: %s\n' "$LOST"
    printf '  lines present in the reconstruction and absent from the pre-resplit: %s\n' "$GAINED"
    printf '\nthe diff, which is the complete list of lines the repointing touched:\n'
    printf -- '----------------------------------------------------------------------\n'
    diff "$SRC" "$RECON" || true
    printf -- '----------------------------------------------------------------------\n'
    ADDDEL="$(diff "$SRC" "$RECON" | grep -cE '^[0-9,]+[ad][0-9,]+$' || true)"
    printf 'hunks that ADD or DELETE a line rather than replace one: %s\n' "$ADDDEL"
fi
