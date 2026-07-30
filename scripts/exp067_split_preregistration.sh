#!/usr/bin/env bash
#
# Split the EXP-067 pre-registration into a root plus five parts.
#
# The single document reached 2696 lines and 224790 bytes, well past the
# documentation rule that caps a plan file at roughly 1500 lines and 75KB.
# The root keeps its original path so every inbound link still resolves.
#
# The split is by LINE RANGE only. No line is retyped, reordered or reflowed.
# The only new text is navigation: the root's status block, parts table and
# section index, and a four-line prefix on each part (breadcrumb, blank,
# part title, blank).
#
# Usage:
#   exp067_split_preregistration.sh ORIGINAL OUTDIR
#
# ORIGINAL is the pre-split document. OUTDIR is where root and parts land.
# Both are required, so the script cannot silently re-split an already split
# tree and destroy the cross-reference repointing applied after the split.
#
# Verify with scripts/exp067_verify_split_lossless.sh.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: $0 ORIGINAL OUTDIR" >&2
    exit 2
fi

ORIGINAL="$1"
OUTDIR="$2"
BASE="exp067_coevolution_cycling"

if [ ! -f "$ORIGINAL" ]; then
    echo "no such original: $ORIGINAL" >&2
    exit 2
fi
if [ ! -d "$OUTDIR" ]; then
    echo "no such output directory: $OUTDIR" >&2
    exit 2
fi

# Top-level section boundaries, re-derived from the document with
#   grep -n '^## ' exp067_coevolution_cycling.md
# and never cutting inside a section.
ROOT_LAST=48
P1_FIRST=49;   P1_LAST=368
P2_FIRST=369;  P2_LAST=988
P3_FIRST=989;  P3_LAST=1593
P4_FIRST=1594; P4_LAST=2008
P5_FIRST=2009
P5_LAST=$(wc -l < "$ORIGINAL")

emit_part() {
    local n="$1" first="$2" last="$3" title="$4" out
    out="${OUTDIR}/${BASE}_PART${n}.md"
    {
        printf '> Part %s of 5 of the [EXP-067 pre-registration](%s.md). The root holds the framing, the status and the section index.\n' "$n" "$BASE"
        printf '\n'
        printf '# EXP-067 PART %s. %s\n' "$n" "$title"
        printf '\n'
        awk -v a="$first" -v b="$last" 'NR >= a && NR <= b' "$ORIGINAL"
    } > "$out"
    printf '%s  lines %s-%s of the original\n' "$out" "$first" "$last"
}

emit_part 1 "$P1_FIRST" "$P1_LAST" \
    'The handover, the question, and the primary endpoint'
emit_part 2 "$P2_FIRST" "$P2_LAST" \
    'The nulls and the two instruments'
emit_part 3 "$P3_FIRST" "$P3_LAST" \
    'The reference panel, the coevolution design, the protocol and the frozen constants'
emit_part 4 "$P4_FIRST" "$P4_LAST" \
    'The decision rule, instrument failure, and what would falsify what'
emit_part 5 "$P5_FIRST" "$P5_LAST" \
    'Threats to validity, what a negative would mean, the budget, the hypothesis and the DESIGN gate record'

ROOT_TMP="$(mktemp)"
trap 'rm -f "$ROOT_TMP"' EXIT

awk -v b="$ROOT_LAST" 'NR <= b' "$ORIGINAL" > "$ROOT_TMP"

cat >> "$ROOT_TMP" <<'ROOT_NAV'
## Status

**Pre-registration. Nothing has been executed.** No arm has been run, no runner has been written,
no panel has been measured and no verdict exists. The DESIGN gate returned BUILD_WITH_CHANGES
twice: round 1 with nine required changes, round 2 with six, and all fifteen are applied. The two
Null A calibration records are INPUTS to this pre-registration rather than results of it. The full
account of what has and has not been done is the Result section, PART 5.

**Split 2026-07-30 at 2696 lines and 224790 bytes**, past the documentation rule that caps a plan
file at roughly 1500 lines and 75KB. The split is by top-level section boundary only. No line of
the pre-registration was rewritten by the split itself, proven byte-exactly by
`scripts/exp067_verify_split_lossless.sh` and recorded in `exp067_split_losslessness.txt`; the
cross-references that now cross a file boundary were repointed afterwards and carry an explicit
`(PART n)` locator, each one listed in that same record.

## The parts

| Part | One line |
|---|---|
| [PART 1](exp067_coevolution_cycling_PART1.md) | What phase 0 hands over and what may not be carried, the cycling question with its ten pre-committed outcomes, and the primary endpoint with the BEATS relation reconciled once. |
| [PART 2](exp067_coevolution_cycling_PART2.md) | The three registered nulls (A the Bradley-Terry bootstrap, B orientation, C row-permutation), what running Null A on a real matrix falsified, and the two instruments I1 and I2. |
| [PART 3](exp067_coevolution_cycling_PART3.md) | The 25-member reference panel, the coevolution design (fitness, the opponent set that is the experimental variable, seeding, optimisers), the protocol with its self-checks, and the frozen constants. |
| [PART 4](exp067_coevolution_cycling_PART4.md) | The decision rule: the precedence ladder, the reading table, the exhaustion argument, the secondary endpoints, the IF-1 to IF-14 instrument-failure table, and what would falsify what. |
| [PART 5](exp067_coevolution_cycling_PART5.md) | The largest threat to validity, how the under-convergence confound stays closed, what a negative would and would not mean, the compute budget, what is out of scope, H1 to H4, both DESIGN gate rounds, and the Result. |

## Section index

Every section of the pre-registration, and the file it now lives in. Cross-references inside the
document resolve here.

| Section | File |
|---|---|
| What phase 0 hands over, and what may NOT be carried | PART 1 |
| Carried unchanged, and named so that nothing is silently re-derived | PART 1 |
| NOT carried, and each refusal is load-bearing | PART 1 |
| The question, asked so that every answer is signable | PART 1 |
| The primary endpoint, counted once and named | PART 1 |
| The BEATS relation, reconciled and stated ONCE | PART 1 |
| Granularity, fixed in advance and shown separable | PART 1 |
| THE NULLS, REGISTERED BEFORE THE MATRIX EXISTS | PART 2 |
| Null A, PRIMARY for the archive cycle count: the BRADLEY-TERRY PARAMETRIC BOOTSTRAP | PART 2 |
| NULL A HAS NOW BEEN RUN ON A REAL MATRIX, AND HALF OF WHAT WAS CLAIMED FOR IT IS FALSIFIED | PART 2 |
| Null B, SECONDARY and registered: the ORIENTATION NULL | PART 2 |
| Null C, PRIMARY for the panel-inversion instrument: the ROW-PERMUTATION NULL | PART 2 |
| EVERY PANEL-READING DECISION NOW CONSUMES NULL C, AND THE FIRST VERSION COMPUTED IT AND THEN BYPASSED IT (DESIGN gate round 2, RC2-1) | PART 2 |
| Alternatives named and REJECTED in advance | PART 2 |
| The two instruments, sharpened | PART 2 |
| Instrument I1: is the population INSIDE the cyclic pockets, or outside them? | PART 2 |
| The 13 seeds' `INV` at checkpoint 0, COMPUTED BEFORE ANY RUN, from data already on disk | PART 2 |
| Instrument I2: does a champion that lost the throne ever REGAIN it against a LATER opponent? | PART 2 |
| The reference panel: 25 members, measured once, frozen before any run | PART 3 |
| The coevolution design | PART 3 |
| The fitness | PART 3 |
| The opponent set, and this is the experimental variable | PART 3 |
| Seeding: WHICH champions, and it is a recorded pre-committed decision | PART 3 |
| The optimisers and the initial step size | PART 3 |
| Protocol, and the order is load-bearing | PART 3 |
| The archive | PART 3 |
| Seeds and every random quantity, persisted | PART 3 |
| The self-checks, and each one can go red | PART 3 |
| The frozen constants | PART 3 |
| Decision rule, pre-committed, computed on held-out only, every outcome reachable | PART 4 |
| Secondary endpoints, reported with the verdict, never gating | PART 4 |
| Instrument failure, distinguished from a real negative | PART 4 |
| What would falsify what | PART 4 |
| The largest threat to validity, and what this design does about it | PART 5 |
| How the search under-convergence confound stays CLOSED | PART 5 |
| What a negative would mean, and what it would NOT mean | PART 5 |
| Compute budget | PART 5 |
| Out of scope, stated so it is not drifted into | PART 5 |
| Hypothesis | PART 5 |
| DESIGN gate verdict (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all nine changes applied above | PART 5 |
| The nine required changes and where each landed | PART 5 |
| The blind spots the gate named, and where each is answered | PART 5 |
| What this pass added BEYOND the nine changes, labelled so the boundary is visible | PART 5 |
| DESIGN gate verdict ROUND 2 (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all six changes applied | PART 5 |
| The six required changes and where each landed | PART 5 |
| The four blind spots the gate named, and where each is answered | PART 5 |
| What this pass added BEYOND the six changes, labelled so the boundary is visible | PART 5 |
| Result | PART 5 |

## Records beside this pre-registration

| File | What it is |
|---|---|
| `exp067_null_a_calibration.txt` | Null A fitted, bootstrapped and gated on phase 0's persisted 20-champion matrix. RNG `exsss` seeded `{3661, 0, 0}`, 200 draws, end state persisted. |
| `exp067_null_a_verification.txt` | An independent check of that calibration sharing no code with it, plus a closed form with no RNG. 139 tested comparisons, 0 disagreements. |
| `exp067_split_losslessness.txt` | The proof that this split lost nothing, and the list of every cross-reference repointed after it. |
ROOT_NAV

mv "$ROOT_TMP" "${OUTDIR}/${BASE}.md"
trap - EXIT

printf '%s  lines 1-%s of the original, plus the navigation block\n' \
    "${OUTDIR}/${BASE}.md" "$ROOT_LAST"
