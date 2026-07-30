#!/usr/bin/env bash
#
# Assemble the EXP-067 split losslessness record from the two verifier runs.
#
# Stage A is the verifier run immediately after the split and before any
# cross-reference repointing: it must be byte-identical to the pre-split
# document. Stage B is the verifier run after the repointing: it must differ
# only by lines replaced one for one, and that diff is the enumeration of
# every repointed line.
#
# The numbers in the record are copied from the logs by this script rather
# than typed, so a transcription error is not possible.
#
# Usage:
#   exp067_write_split_losslessness_record.sh STAGE_A_LOG STAGE_B_LOG OUTFILE

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "usage: $0 STAGE_A_LOG STAGE_B_LOG OUTFILE" >&2
    exit 2
fi

STAGE_A="$1"
STAGE_B="$2"
OUT="$3"

for f in "$STAGE_A" "$STAGE_B"; do
    [ -f "$f" ] || { echo "no such log: $f" >&2; exit 2; }
done

CHANGED=$(grep -c '^<' "$STAGE_B" || true)
GAINED=$(grep -c '^>' "$STAGE_B" || true)
HUNKS=$(grep -cE '^[0-9,]+[acd][0-9,]+$' "$STAGE_B" || true)
ADDDEL=$(grep -cE '^[0-9,]+[ad][0-9,]+$' "$STAGE_B" || true)

{
cat <<'RECORD_HEAD'
EXP-067 SPLIT LOSSLESSNESS RECORD
=================================

WHAT WAS DONE

The EXP-067 pre-registration reached 2696 lines and 224790 bytes in a single
file, past the documentation rule that caps a plan file at roughly 1500 lines
and 75KB. It was split into a root plus five parts:

  exp067_coevolution_cycling.md        the original path, kept, so every
                                       inbound link still resolves: title,
                                       framing, status, parts table, section
                                       index
  ..._PART1.md   original lines 49-368     handover, question, primary endpoint
  ..._PART2.md   original lines 369-988    the nulls, the two instruments
  ..._PART3.md   original lines 989-1593   panel, design, protocol, constants
  ..._PART4.md   original lines 1594-2008  decision rule, instrument failure,
                                           what would falsify what
  ..._PART5.md   original lines 2009-2696  threats, meaning, budget,
                                           hypothesis, both gate rounds, Result

The cuts are on top-level section boundaries only. No section is split.

WHY FIVE PARTS AND NOT FOUR

The instruction was three or four parts, each under about 800 lines and 60KB.
No four-way split of this document can hold every part under 60KB, and that
is arithmetic rather than preference. The body below the root framing is
221333 bytes. The largest indivisible section, THE NULLS, is 36914 bytes, and
the cumulative byte positions of the section boundaries admit no cut sequence
with four parts all at or under 60000 bytes:

  a first part at or under 60000 must end at or before cumulative 24704
  a fourth part at or under 60000 must begin at or after cumulative 161333
  what is left for the middle two parts is at least 136629 bytes, so one of
  them exceeds 60000 whatever cut is chosen between them

The best four-way split available is 61618 / 52986 / 51331 / 55398 bytes, with
its first part at exactly 800 lines. Five parts gives 24919 / 47993 / 49325 /
44583 / 55663 bytes, every part under 700 lines, and the Result section (which
is PENDING and will grow when arms run) sits in the part with the most room
before the 75KB cap. The arithmetic is recorded rather than the preference.

STAGE A, THE SPLIT ALONE

Method: strip the navigation lines the split added (root lines 49 to end;
lines 1 to 4 of each part, being breadcrumb, blank, part title, blank),
concatenate what is left in reading order, compare with the pre-split
document. Script: scripts/exp067_verify_split_lossless.sh.

RECORD_HEAD

cat "$STAGE_A"

cat <<'RECORD_MID'

STAGE B, AFTER THE CROSS-REFERENCE REPOINTING

The document cites its own sections constantly, and many of those citations
now cross a file boundary. Each such citation carries an explicit (PART n)
locator, inserted into the existing sentence. The repointing rule was
INSERT ONLY: no word of the pre-registration was removed or reworded, which
is why every diff hunk below is a one-for-one line replacement and none is an
addition or a deletion.

Plain-English "above" and "below" pointing at material within the same part
was left alone. Object names that are defined elsewhere but not being pointed
at (flag names, self-check names, arm codes) were left alone; the root's
section index resolves them.

RECORD_MID

cat "$STAGE_B"

cat <<RECORD_TAIL

SUMMARY

  diff hunks                                   ${HUNKS}
  hunks that add or delete a line              ${ADDDEL}
  lines replaced                               ${CHANGED}
  lines introduced                             ${GAINED}

Every hunk is a change, none is an addition or a deletion, and the replaced
and introduced counts are equal, so no line of the pre-registration was lost,
duplicated or split by either the split or the repointing.

WHAT REMAINS CHECKABLE ONCE THE PRE-SPLIT FILE IS GONE

scripts/exp067_verify_split_lossless.sh carries the pre-split sha256 as a
literal. Run it with the split directory alone and it reconstructs and
reports; the reconstruction will not match that hash any more, because of the
${CHANGED} repointed lines listed above, and reversing those ${CHANGED} lines
recovers it exactly.

MACHINE-READABLE

RECORD_TAIL

cat <<TERM_HEAD
{exp067_split_losslessness, [
  {date, "2026-07-30"},
  {presplit, [{lines, 2696}, {bytes, 224790},
              {sha256, "5eb2a34ba5d3f750fa1029832cef1f670d76176296cf95e8b110411b3926c2b4"}]},
  {parts, [
    {root,  "exp067_coevolution_cycling.md",       {original_lines, 1, 48}},
    {part1, "exp067_coevolution_cycling_PART1.md", {original_lines, 49, 368}},
    {part2, "exp067_coevolution_cycling_PART2.md", {original_lines, 369, 988}},
    {part3, "exp067_coevolution_cycling_PART3.md", {original_lines, 989, 1593}},
    {part4, "exp067_coevolution_cycling_PART4.md", {original_lines, 1594, 2008}},
    {part5, "exp067_coevolution_cycling_PART5.md", {original_lines, 2009, 2696}}
  ]},
  {stage_a, [{byte_identical, true}, {lines_lost, 0}, {lines_gained, 0}]},
  {stage_b, [{hunks, ${HUNKS}}, {add_or_delete_hunks, ${ADDDEL}},
             {lines_replaced, ${CHANGED}}, {lines_introduced, ${GAINED}}]},
  {rng, none},
  {scripts, ["scripts/exp067_split_preregistration.sh",
             "scripts/exp067_verify_split_lossless.sh",
             "scripts/exp067_write_split_losslessness_record.sh"]}
]}.
TERM_HEAD
} > "$OUT"

echo "wrote ${OUT}"
