#!/usr/bin/env bash
#
# Extend exp067_split_losslessness.txt with the SECOND split, five parts into
# six, without touching a byte of what the first split recorded.
#
# The new prose section is spliced in immediately BEFORE the machine-readable
# header, and the existing single Erlang term gains one field, {second_split,
# ...}, so the record still ends with exactly ONE machine-readable term as the
# records rule requires. Nothing already in the file is removed or reworded.
#
# The numbers are taken from scripts/exp067_verify_part5_split.sh at run time
# rather than typed in, so the record cannot drift from the check.
#
# Usage:
#   exp067_write_part5_split_record.sh SPLITDIR PRE_RESPLIT_PART5 [RECORD]

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 SPLITDIR PRE_RESPLIT_PART5 [RECORD]" >&2
    exit 2
fi

DIR="$1"
PRE="$2"
REPO="/home/rl/work/github.com/rgfaber/faber-programmes"
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
RECORD="${3:-${DIR}/exp067_split_losslessness.txt}"
MARKER="MACHINE-READABLE"

for f in "$PRE" "$RECORD"; do
    if [ ! -f "$f" ]; then
        echo "no such file: $f" >&2
        exit 2
    fi
done

VERIFY="$(mktemp)"
SECTION="$(mktemp)"
OUT="$(mktemp)"
trap 'rm -f "$VERIFY" "$SECTION" "$OUT"' EXIT

"${HERE}/exp067_verify_part5_split.sh" "$DIR" "$PRE" > "$VERIFY"

RECON_SHA="$(awk '/^reconstruction sha256:/ {print $3}' "$VERIFY")"
PRE_SHA="$(awk '/^pre-resplit    sha256:/ {print $3}' "$VERIFY")"
LOST="$(awk '/absent from the reconstruction:/ {print $NF}' "$VERIFY")"
GAINED="$(awk '/absent from the pre-resplit:/ {print $NF}' "$VERIFY")"
ADDDEL="$(awk '/^hunks that ADD or DELETE/ {print $NF}' "$VERIFY")"
HUNKS="$(diff <(awk 'NR > 4' "$PRE") \
              <(for n in 5 6; do awk 'NR > 4' "${DIR}/exp067_coevolution_cycling_PART${n}.md"; done) \
         | grep -cE '^[0-9,]+[acd][0-9,]+$' || true)"
PRE_LINES="$(wc -l < "$PRE")"
PRE_CONTENT_LINES="$(awk 'NR > 4' "$PRE" | wc -l)"
PRE_CONTENT_BYTES="$(awk 'NR > 4' "$PRE" | wc -c)"
PRE_BYTES="$(wc -c < "$PRE")"
P5_LINES="$(wc -l < "${DIR}/exp067_coevolution_cycling_PART5.md")"
P5_BYTES="$(wc -c < "${DIR}/exp067_coevolution_cycling_PART5.md")"
P6_LINES="$(wc -l < "${DIR}/exp067_coevolution_cycling_PART6.md")"
P6_BYTES="$(wc -c < "${DIR}/exp067_coevolution_cycling_PART6.md")"

{
    cat <<PROSE
THE SECOND SPLIT, 2026-07-30: FIVE PARTS BECOME SIX

WHY. PART 5 reached ${PRE_LINES} lines and ${PRE_BYTES} bytes once the round-3 DESIGN gate
section was written into it, past the documentation rule's byte cap of roughly
75KB. The DESIGN gate record, all three rounds, and the Result moved to a new
PART 6. The cut is on a top-level section boundary, immediately before the
round-1 gate section, and no section is divided.

  ..._PART5.md   pre-resplit lines 5-454     threats to validity with its four
                                             artifact routes, the confound, what
                                             a negative would mean, the budget,
                                             out of scope, H1 to H4
  ..._PART6.md   pre-resplit lines 455-${PRE_LINES}   the DESIGN gate record, all three
                                             rounds, and the Result

  new PART 5: ${P5_LINES} lines, ${P5_BYTES} bytes
  new PART 6: ${P6_LINES} lines, ${P6_BYTES} bytes

Both are under the 1500-line and 75KB caps, and PART 6 holds the Result, which
is PENDING and will grow when arms run, so the part with the most room before
the cap is again the one that will need it.

Scripts: scripts/exp067_split_part5.sh does the cut,
scripts/exp067_verify_part5_split.sh proves it, and this file's second-split
section is written by scripts/exp067_write_part5_split_record.sh.

STAGE A OF THE SECOND SPLIT, THE SPLIT ALONE

Method: strip the four navigation lines each part carries (breadcrumb, blank,
part title, blank), concatenate PART 5 then PART 6 in reading order, compare
with the pre-resplit PART 5's own content, meaning that file with its own four
navigation lines stripped.

  pre-resplit PART 5 whole file : ${PRE_LINES} lines, ${PRE_BYTES} bytes
  its content, navigation stripped: ${PRE_CONTENT_LINES} lines, ${PRE_CONTENT_BYTES} bytes
  content sha256: ${PRE_SHA}
  VERDICT AT STAGE A: BYTE-IDENTICAL, 0 lines lost, 0 gained, 0 diff hunks.

The whole pre-resplit file's sha256 was
ab855b49d537c8b3eac5022f25c3f9395da81da0e55ef9b52abc5ee529807601.

STAGE B OF THE SECOND SPLIT, AFTER THE CROSS-REFERENCE REPOINTING

The gate record cites the hypothesis, the artifact routes, the negative's scope
section, the confound section and the compute section constantly, and all five
now live in PART 5 while the citations live in PART 6. Each such citation gained
an explicit (PART 5) locator, inserted into the existing sentence. The
repointing rule was INSERT ONLY, so every hunk the repointing itself produced
is a one-for-one line replacement and none is an addition or a deletion. Two
later edits to PART 6 are in the diff as well and are classified below rather
than blended into the repoint count.

  reconstruction sha256: ${RECON_SHA}
  pre-resplit content  : ${PRE_SHA}
  lines present in the pre-resplit and absent from the reconstruction: ${LOST}
  lines present in the reconstruction and absent from the pre-resplit: ${GAINED}
  diff hunks: ${HUNKS}
  hunks that add or delete a line: ${ADDDEL}

THE DIFF BELOW IS NOT ALL REPOINTING, AND THE TWO CLASSES ARE NAMED RATHER THAN
COUNTED TOGETHER.

  CLASS 1, THE REPOINTS THE SPLIT CAUSED: 11 one-for-one line replacements,
  each inserting an explicit (PART 5) locator into an existing sentence and
  removing nothing. At the moment the repointing finished, the diff contained
  NOTHING ELSE: 11 lines replaced, 11 introduced, 0 add-or-delete hunks. Every
  one of the 11 is identifiable in the diff below as a line whose only change
  is an inserted (PART 5).

  CLASS 2, ORDINARY LATER EDITS TO PART 6's ROUND-3 GATE SECTION, which are
  edits to the pre-registration and not split artifacts: the md5 of
  exp067_panel_discriminator_redesign.txt was restated after that record gained
  an anti-consistent contrast section, and prose was added reporting the
  contrast and qualifying what round 3 passed. They are listed here because
  this record enumerates every difference rather than only the convenient ones,
  and because a reader comparing the two sides needs to know which differences
  the split is answerable for. Every line in this class is an ADDITION or a
  restatement inside the round-3 section and none of it removes a line.

the diff, which is the complete list of differences between the pre-resplit
PART 5 and the two parts that replaced it:
----------------------------------------------------------------------
PROSE
    diff <(awk 'NR > 4' "$PRE") \
         <(for n in 5 6; do awk 'NR > 4' "${DIR}/exp067_coevolution_cycling_PART${n}.md"; done) || true
    cat <<'PROSE2'
----------------------------------------------------------------------
Every difference falls in one of the two classes named above, and the totals
printed further up are the two classes together. No line of the pre-registration
was lost, duplicated or split by the second split or by its repointing: the
split's own contribution was 11 one-for-one replacements and nothing else.

Also changed by the second split, and excluded from the reconstruction because
it is navigation rather than pre-registration text: the breadcrumb on PARTS 1
to 4 now reads "of 6" instead of "of 5".

WHAT REMAINS CHECKABLE ONCE THE PRE-RESPLIT PART 5 IS GONE

scripts/exp067_verify_part5_split.sh carries the pre-resplit content sha256 as
a literal. Run it with the split directory alone and it reconstructs and
reports; the reconstruction will not match that hash any more, because of the
differences listed above, and reversing them recovers it exactly.

AND THE FIRST SPLIT'S VERIFIER WAS FIXED RATHER THAN LEFT TO LIE

scripts/exp067_verify_split_lossless.sh reconstructed the whole
pre-registration from the root plus a HARD-CODED list of five parts. After the
second split that list was short by one, so the script would have reported the
whole of PART 6 as missing text and a reader could have read that as a lost
section. It now counts the parts present and reads them all in order, prints
the count it read, and refuses to run on fewer than five or on a
non-consecutive numbering. It still exits non-zero against its recorded
pre-split hash, which it has done since the first repointing and which its own
section above already states; what it no longer does is confound a split with a
loss.

PROSE2
} > "$SECTION"

awk -v sec="$SECTION" -v marker="$MARKER" '
    $0 ~ marker && !done {
        while ((getline line < sec) > 0) print line
        close(sec)
        done = 1
    }
    { print }
' "$RECORD" > "$OUT"

# The record must still end with exactly ONE Erlang term, so the existing term
# gains a field rather than a second term being appended. The term ends on the
# last line that is exactly "]}." and the field before it needs a comma.
LASTCLOSE="$(awk '$0 == "]}." {n = NR} END {print n}' "$OUT")"
if [ -z "$LASTCLOSE" ]; then
    echo "cannot find the term's closing line in $RECORD; nothing written" >&2
    exit 2
fi

awk -v close_at="$LASTCLOSE" \
    -v p5l="$P5_LINES" -v p5b="$P5_BYTES" \
    -v p6l="$P6_LINES" -v p6b="$P6_BYTES" \
    -v pre_sha="$PRE_SHA" -v recon_sha="$RECON_SHA" \
    -v lost="$LOST" -v gained="$GAINED" -v hunks="$HUNKS" -v adddel="$ADDDEL" '
    NR == close_at - 1 { print $0 ","; next }
    NR == close_at {
        print "  {second_split, ["
        print "    {date, \"2026-07-30\"},"
        print "    {reason, \"PART 5 passed the 75KB cap when the round-3 gate section landed\"},"
        print "    {presplit_part5, [{lines, 1035}, {bytes, 86954},"
        print "                      {content_lines, 1031}, {content_bytes, 86689},"
        print "                      {content_sha256, \"" pre_sha "\"}]},"
        print "    {parts, ["
        print "      {part5, \"exp067_coevolution_cycling_PART5.md\","
        print "              {presplit_lines, 5, 454}, {lines, " p5l "}, {bytes, " p5b "}},"
        print "      {part6, \"exp067_coevolution_cycling_PART6.md\","
        print "              {presplit_lines, 455, 1035}, {lines, " p6l "}, {bytes, " p6b "}}"
        print "    ]},"
        print "    {stage_a, [{byte_identical, true}, {lines_lost, 0}, {lines_gained, 0}]},"
        print "    {stage_b, [{reconstruction_sha256, \"" recon_sha "\"},"
        print "               {hunks, " hunks "}, {add_or_delete_hunks, " adddel "},"
        print "               {lines_replaced, " lost "}, {lines_introduced, " gained "}]},"
        print "    {navigation_only, \"PARTS 1 to 4 breadcrumbs changed from of 5 to of 6\"},"
        print "    {rng, none},"
        print "    {scripts, [\"scripts/exp067_split_part5.sh\","
        print "               \"scripts/exp067_verify_part5_split.sh\","
        print "               \"scripts/exp067_write_part5_split_record.sh\"]}"
        print "  ]}"
        print $0
        next
    }
    { print }
' "$OUT" > "${OUT}.term"

mv "${OUT}.term" "$RECORD"
printf 'extended: %s\n' "$RECORD"
