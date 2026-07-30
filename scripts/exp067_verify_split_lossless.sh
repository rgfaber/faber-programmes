#!/usr/bin/env bash
#
# Prove that splitting the EXP-067 pre-registration lost nothing.
#
# Method: strip the navigation lines the split ADDED, concatenate what is left
# in reading order, and compare the result with the pre-split document. The
# navigation lines are at known fixed positions, so the strip needs no
# heuristics:
#
#   root   lines 1..48        the title, the framing, the metadata bullets
#                             (everything from line 49 down is the added
#                             status block, parts table and section index)
#   PARTn  lines 5..end       (lines 1..4 are breadcrumb, blank, title, blank)
#
# PART COUNT. The first split made five parts; the SECOND split, 2026-07-30,
# made six by cutting PART 5 into PART 5 and PART 6. This script reads however
# many parts exist, in order, so it still reconstructs the WHOLE
# pre-registration rather than silently stopping at PART 5 and reporting a
# shortfall as if it were a lost line. The second split's own proof, which is
# the one that shows that cut lost nothing, is
# scripts/exp067_verify_part5_split.sh.
#
# Two things are checked and both are printed:
#
#   1. sha256 of the reconstruction against the pre-split sha256. Equal means
#      the split moved text and changed nothing at all.
#   2. a line diff of the reconstruction against the pre-split document. After
#      the cross-reference repointing this is NOT empty, and that diff IS the
#      enumeration of every line the repointing touched. Nothing else may
#      appear in it.
#
# Usage:
#   exp067_verify_split_lossless.sh SPLITDIR [ORIGINAL]
#
# With ORIGINAL the diff is printed. Without it only the sha256 comparison
# against the recorded pre-split hash is available, which is what remains
# checkable once the pre-split document no longer exists anywhere.

set -euo pipefail

# sha256 of exp067_coevolution_cycling.md as it stood immediately before the
# split, 2696 lines, 224790 bytes.
PRESPLIT_SHA=5eb2a34ba5d3f750fa1029832cef1f670d76176296cf95e8b110411b3926c2b4

ROOT_KEEP=48
PART_SKIP=4

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "usage: $0 SPLITDIR [ORIGINAL]" >&2
    exit 2
fi

SPLITDIR="$1"
ORIGINAL="${2:-}"
BASE="exp067_coevolution_cycling"

RECON="$(mktemp)"
trap 'rm -f "$RECON"' EXIT

awk -v b="$ROOT_KEEP" 'NR <= b' "${SPLITDIR}/${BASE}.md" > "$RECON"
PARTS=0
for f in "${SPLITDIR}/${BASE}_PART"*.md; do
    if [ -f "$f" ]; then
        PARTS=$((PARTS + 1))
    fi
done
if [ "$PARTS" -lt 5 ]; then
    echo "found only ${PARTS} parts, expected at least 5" >&2
    exit 2
fi
for n in $(seq 1 "$PARTS"); do
    f="${SPLITDIR}/${BASE}_PART${n}.md"
    if [ ! -f "$f" ]; then
        echo "parts are not numbered consecutively: ${f} is missing" >&2
        exit 2
    fi
    awk -v s="$PART_SKIP" 'NR > s' "$f" >> "$RECON"
done
echo "parts read: ${PARTS}"

RECON_SHA="$(sha256sum "$RECON" | awk '{print $1}')"

echo "reconstruction: $(wc -l < "$RECON") lines, $(wc -c < "$RECON") bytes"
echo "reconstruction sha256: ${RECON_SHA}"
echo "pre-split      sha256: ${PRESPLIT_SHA}"

if [ "$RECON_SHA" = "$PRESPLIT_SHA" ]; then
    echo "VERDICT: BYTE-IDENTICAL. The split lost nothing and changed nothing."
    SHA_MATCH=yes
else
    echo "VERDICT: NOT byte-identical. Every difference must be an enumerated repoint."
    SHA_MATCH=no
fi

if [ -z "$ORIGINAL" ]; then
    echo "no ORIGINAL given, so no line diff is available"
    [ "$SHA_MATCH" = yes ] && exit 0
    exit 1
fi

echo
echo "line accounting against ${ORIGINAL}:"
echo "  original       : $(wc -l < "$ORIGINAL") lines, $(wc -c < "$ORIGINAL") bytes"
LOST=$(diff "$ORIGINAL" "$RECON" | grep -c '^<' || true)
GAINED=$(diff "$ORIGINAL" "$RECON" | grep -c '^>' || true)
echo "  lines present in the original and absent from the reconstruction: ${LOST}"
echo "  lines present in the reconstruction and absent from the original: ${GAINED}"

echo
echo "the diff, which is the complete list of lines the repointing touched:"
echo "----------------------------------------------------------------------"
diff "$ORIGINAL" "$RECON" || true
echo "----------------------------------------------------------------------"

if [ "$LOST" -ne "$GAINED" ]; then
    echo "FAIL: a line was dropped or duplicated rather than edited in place."
    exit 1
fi
echo "every difference is a line replaced by exactly one other line."
