> Part 4 of 6 of the [EXP-067 pre-registration](exp067_coevolution_cycling.md). The root holds the framing, the status and the section index.

# EXP-067 PART 4. The decision rule, instrument failure, and what would falsify what

## Decision rule, pre-committed, computed on held-out only, every outcome reachable

Per run, at band 0.10. **The gunless-leg exclusion is NOT named here, and its absence is the RC2-6
repair rather than an omission**: this rule reads archive matrices, whose members are 20 evolved
checkpoint champions, so no scripted rung can be in one and there is nothing for the exclusion to
remove. It applies to the PANEL-derived quantities this rule consumes (`INV` and, through IF-8, the
panel's own cyclic-triple count), and it is stated where those are defined.

```
the floor precondition iff >= 15 of the run's 20 checkpoints have W >= B = 0.5748 against
                           predictive_gun on the 80 held-out starts
ABOVE-FLOOR SUBMATRIX  the archive matrix restricted to the checkpoints whose W >= B, with
                       DUPLICATE PHENOTYPES REMOVED BY CONTENT HASH.
                       n varies per run (15 to 20 when the precondition holds and nothing
                       converged) and n is REPORTED with every count, because a count over
                       C(n,3) triples is not comparable across different n. The comparable
                       quantity is the SHARE of cyclable triples that are cyclic. The full
                       20-member count is ALSO reported.
a run is GRADEABLE     iff the floor precondition holds AND n >= 15 after dedup AND Null A's fit
  for cycling              gate does not fire on its submatrix (IF-9 in either direction).
                       A run that fails any of the three is UNGRADEABLE for cycling. It is NOT
                       CYCLIC, it is NOT a negative, and it does NOT enter any conjunct of the
                       NO CYCLING branch. Its label says which of the three it failed:
                       IF-1 FLOOR-LOST, CONVERGED-UNGRADEABLE, or NULL-UNFIT.
a run is CYCLIC        iff ALL THREE legs hold:
                       (i)   it is GRADEABLE, and
                       (ii)  its primary count on the ABOVE-FLOOR SUBMATRIX exceeds the MAXIMUM
                             of 200 Null A draws computed on THAT SAME SUBMATRIX, so the null is
                             self-matched to whatever n the restriction leaves, and
                       (iii) its share of cyclable triples that are cyclic exceeds the
                             NO-COEVOLUTION REFERENCE SHARE of a real matrix of the same shape,
                             as the exact integer test  cycles * 582 > 18 * cyclable  at band
                             0.10 (789/49 at 0.05, 487/12 at 0.15).
                       Leg (iii) is ADDED by DESIGN gate round 2 (RC2-4) because leg (ii) alone
                       fires on phase 0's 20-champion matrix, which contains no coevolution, at
                       all three bands. A run passing (ii) and failing (iii) is printed as a
                       SUB-REFERENCE EXCEEDANCE with both numbers and is NOT CYCLIC.
```

**THE GRADEABILITY CONDITION IS A REPAIR, AND WHAT IT REPAIRS IS CONCRETE (DESIGN gate RC-1a).** The
first version defined CYCLIC with no floor condition and put the floor condition only in the
arm-level rule, which left a run that LOSES the floor and is cyclic on a small above-floor submatrix
in no outcome at all: not CYCLING (the arm rule requires the floor in each cyclic run), not PARTIAL
(same), not FLOOR-LOST (that branch read A1's fraction only), and it blocked NO CYCLING's
zero-cyclic conjunct. It also left the test DEGENERATE at small `n`: at `n = 4` there are 4 triples and
one cycle can exceed the maximum of 200 draws. The `n >= 15` minimum closes the degeneracy and the
gradeability condition closes the hole. **An UNGRADEABLE run whose count exceeded its own null maximum
is still PRINTED, as an UNGRADEABLE EXCEEDANCE with its `n`, its label and its count**, because
suppressing an observation is not the same as declining to let it sign.

The restriction is PRIMARY and decides the verdict, because that is what the plan's precondition
licenses: cycling evidence counts only above the competence floor. The unrestricted 20-member count is
reported beside it, and if the two would give different verdicts that fact is printed as a label on
the verdict rather than used to pick the more convenient one.

**A4's ARM-LEVEL GRADEABILITY, WHICH WAS UNDEFINED (DESIGN gate RC-7).** Outcome 5 spoke of A4 being
UNGRADEABLE while the floor precondition is a PER-RUN quantity and no fraction of A4's 13 runs was
stated, so a mixed A4 (say 6 of 13 holding) was the analyst's free choice at read time, on the branch
that decides whether the universal negative may be signed. Fixed: **A4 is GRADEABLE AT ARM LEVEL iff at
least 10 of its 13 runs hold the per-run floor precondition**, the same 10-of-13 fraction A1 is held to,
which is phase 0's 15-of-20 applied to 13 runs and rounded up. When A4 is gradeable, only its GRADEABLE
runs enter the conjuncts, exactly as for A1 and A2, and the counts of gradeable and ungradeable runs are
printed. When it is not, the verdict is outcome 5.

Then, per arm of 13 runs, evaluated in this PRECEDENCE ORDER. **The claim that the verdicts partition
is DISCHARGED BY EXHAUSTION below the ladder, not asserted in this sentence, because the first
version's ladder asserted it and did not have it** (DESIGN gate RC-1). The numbers below are POSITIONS
IN THE LADDER and not the outcome numbers of the list in "The question" (PART 1); the outcome NAMES are what
carry between the two.

```
0. NON-ENGAGEMENT iff IF-2 AND IF-7 both fire in a majority of an arm's FLOOR-HOLDING runs.
   (a finding,        A population that converges on mutual non-engagement while holding the
   not a broken       certified floor, in draw-parked cells with too few decisive edges to
   instrument)        count, is a fact about this substrate's coevolutionary dynamic. No
                      cycling claim in either direction. Carve-out from precedence 1.
1. INSTRUMENT     iff IF-5 or IF-6 anywhere, or IF-2 or IF-3-BELOW-FLOOR in a majority of an
   FAILED             arm's runs, or IF-9 in a majority of an arm's floor-holding runs, or
                      Null B failing SC8.
                      CONVERGED runs (IF-3 at a champion HOLDING the floor) do NOT count
                      toward this majority.
2. CYCLING        iff SOME ONE ARM among A1, A2 and a GRADEABLE A4 has >= 3 of its 13 runs
                      CYCLIC. Per-arm, never pooled.
                      Sub-label, MANDATORY and pre-committed:
                        PANEL-VISIBLE  if in >= 2 of that arm's cyclic runs, at band 0.10
                                       against the frozen panel, INV at the FINAL checkpoint
                                       EXCEEDS the maximum of that checkpoint's own 200 Null C
                                       permutations AND INV at checkpoint 0 did NOT exceed
                                       checkpoint 0's own 200-permutation maximum.
                                       IF-14 FLOOR-SHED on a run bars that run's exceedance
                                       from counting toward the 2.
                                       Carries the label LOWER-HALF-SEEDED (RC2-5).
                                       UNAVAILABLE when IF-8 has voided instrument I1, in which
                                       case the sub-label is necessarily SELF-RELATIVE.
                        SELF-RELATIVE  otherwise. Signs intransitivity only. BARRED from
                                       pocket-exploitation and open-endedness language.
                      Labelled SECOND-OPTIMISER-ONLY when the arm is A4.
                      (The first version's panel conjunct was the RAW INV_final - INV_0 >= 1.
                      Replaced by DESIGN gate round 2, RC2-1: the raw delta is inflated by
                      composition drift that H3 itself predicts, and the threshold of 1 sat
                      inside the permutation spread of every seed. Round 3 left this conjunct
                      UNCHANGED, could construct no artifact route through it, and adopted
                      the same normalisation for branches 6 and 7, which had kept a
                      mean-centred median that composition could still steer (RC3-1).)
3. PARTIAL        iff >= 1 run of A1, A2 or a gradeable A4 is CYCLIC and no single one of
                      those arms reaches 3. Per-arm.
                      The POOLED count across arms is printed as a label and NEVER promotes
                      the verdict, because the REPLICATION requirement below is a within-arm
                      one and 2-in-A1-plus-2-in-A2 is replication across two different
                      opponent-set regimes rather than within one.
4. FLOOR-LOST     iff no run of A1, A2 or A4 is CYCLIC, AND (the floor precondition held in
                      FEWER than 10 of 13 of A1's runs, OR A2 trips IF-1 in a majority, 7 or
                      more, of its 13). Labelled THE ANCHOR SQUEEZE when A1 held and A2 did not.
5. INCONCLUSIVE,  iff no run of A1, A2 or A4 is CYCLIC, A1 held the floor in >= 10 of 13, A2 did not
   SECOND CLASS       majority-lose it, and A4 is UNGRADEABLE AT ARM LEVEL (fewer than 10 of
   UNTESTABLE         its 13 runs hold the per-run floor precondition), so the negative rests
                      on one optimiser class only.
5a. CONVERGED,     iff no run of A1, A2 or A4 is CYCLIC, the floor conditions of branch 4 do not
    BASE               fire, A4 is gradeable at arm level, AND fewer than 7 of 13 runs are
    INSUFFICIENT       GRADEABLE in ANY arm the negative needs (A1, A2, and A4 when it carries).
                       The universal negative would otherwise rest on an evidence base thinner
                       than the positive's own 3-of-13 requirement, and "0 CYCLIC runs among ALL
                       the GRADEABLE runs" is vacuously satisfiable over 2 gradeable runs of 39.
                       Prints the gradeable count per arm and, per ungradeable run, which of the
                       three conditions it failed. NOT NO CYCLING and NOT an instrument failure.
                       ADDED by DESIGN gate round 2, RC2-3.
5b. INCONCLUSIVE,  iff 5a does not fire and the panel base for the branch 6 / 7 conjunct is not
    PANEL BASE         readable. Two pre-committed sub-labels:
    UNAVAILABLE          PANEL BASE ERODED  fewer than 7 of 13 A1 runs QUALIFY, where a run
                                            qualifies iff IF-1 did not fire on it, IF-14
                                            FLOOR-SHED did not fire on it, AND neither its
                                            checkpoint-0 nor its final-checkpoint Null C is
                                            DEGENERATE (k_C = 0 or k_C = n_C).
                                            ADDED by DESIGN gate round 2, RC2-2; the
                                            degeneracy clause ADDED by round 3, RC3-1.
                         PANEL VOID         IF-8 PANEL-DEGENERATE fired, so instrument I1 has no
                                            readable order and no INV is defined at all.
                                            AUTHOR-ADDED, not gate-required: without it a firing
                                            IF-8 left branches 6 and 7 both unevaluable.
                       Neither sub-label may default into branch 6 or branch 7.
6. NO CYCLING     iff 0 CYCLIC runs among ALL the GRADEABLE runs of A1, A2 and A4,
                  AND the floor precondition held in >= 10 of 13 runs of A1,
                  AND A2 did not trip IF-1 in a majority of its 13,
                  AND A4 is GRADEABLE at arm level,
                  AND >= 7 of 13 runs are GRADEABLE in each arm the negative needs (5a),
                  AND >= 7 of 13 A1 runs QUALIFY for the panel conjunct (5b),
                  AND FEWER THAN 2 of A1's QUALIFYING runs have INV at checkpoint 20
                      EXCEEDING the MAXIMUM of that checkpoint's own 200 Null C
                      permutations while INV at checkpoint 0 did NOT exceed
                      checkpoint 0's own 200-permutation maximum, strictly greater,
                      both legs, at band 0.10 against the frozen panel.
7. PANEL-INVERTED iff branch 6 fails ON ITS LAST CONJUNCT ONLY: no run is CYCLIC, the floor
   ARCHIVE            held in A1 and was not majority-lost in A2, A4 is gradeable, both 7-of-13
   TRANSITIVE         bases hold, and 2 OR MORE of A1's QUALIFYING runs satisfy that same
                      two-legged Null C exceedance at band 0.10.

   QUALIFYING, for 5b, branch 6 and branch 7 alike: IF-1 did not fire on the run,
   IF-14 FLOOR-SHED did not fire on it, AND neither its checkpoint-0 nor its
   final-checkpoint Null C is DEGENERATE (k_C = 0 or k_C = n_C, permutation
   distribution a point mass at 0). A DEGENERATE checkpoint votes for NEITHER branch.
```

**THE BRANCH 6 AND 7 RULE IS THE POSITIVE'S OWN CONJUNCT, READ OVER THE NEGATIVE'S OWN BASE, AND THAT IS
A ROUND-3 REDESIGN OF THE STATISTIC RATHER THAN A THIRD PATCH TO IT (DESIGN gate round 3, RC3-1).** The
history is kept in full because it is the whole argument for the shape the rule now has.

**Round 1's form: the RAW `INV_20 - INV_0` over A1's 13 runs**, thresholded at `=< 0` for branch 6 and
`>= 1` for branch 7. **RC2-1** found it: the raw delta rises mechanically when a champion's panel win
count moves toward `n_C / 2`, which H3 predicts, so the negative this document declares its modal
expectation was reachable only if coevolution failed to climb the panel at all.

**Round 2's form: the median of the CENTRED quantity `INV - E[INV]`**, thresholded at 0, over the runs
surviving a filter symmetric with the positive's. **RC2-2** was right and stands: IF-14 FLOOR-SHED
barred a shed-driven `INV` rise from the CYCLING panel conjunct while the negative's discriminator was
UNFILTERED, so the same shed that could not help a positive could still block the negative. The filter
is symmetric from round 2 onward and round 3 only extends it. **RC2-1's centring did NOT hold.**

**Round 3's finding, and it is the round-2 defect with a `k`-dependent sign.** Subtracting `E[INV]` is
not conditioning on `k_C`. For a win pattern pinned near `INV = 0`, which is exactly the transitive
climber, the centred difference collapses to `E_0 - E_20`, a pure composition quantity whose sign is set
by where `k_C` moved relative to `n_C / 2`. Measured on the limit case, from data already on disk: a
lineage that ends beating every band-decisive panel member scores exactly `E_0 - INV_0`, which is
**+6.4375 to +26.5625 for 11 of the 13 seeds, 0 for the two degenerate ones, median +15.6000 at band
0.10**, so the pure transitive climber lands in branch 7
(`exp067_panel_discriminator_redesign.txt` section D1). **Branch 7's own pre-committed reading is false
for that champion, and a genuine specialist lands in the same branch. Two opposite mechanisms, one
reading.**

**What replaces it, and why this shape and not a fourth threshold.** The negative's panel conjunct is
now the PANEL-VISIBLE conjunct itself: the same 200 Null C permutations, the same strict exceedance at
each end, the same band, the same count of 2, read over A1's QUALIFYING runs instead of over the
carrying arm's CYCLIC runs. **One normalisation is used everywhere in this document for every panel
decision**, which is what round 2's RC2-1 asked for and what its own median then failed to deliver.
Three consequences follow and each is checkable:

- **Composition cannot set the sign.** The exceedance conditions on the realised `n_C`, `k_C` and `D_C`
  at the checkpoint being read, so a champion whose win set moves takes its own reference with it.
- **A degenerate checkpoint votes for nothing.** The withdrawn median fed a degenerate checkpoint's
  exact 0 into `=< 0`, which is branch 6, so a checkpoint the instrument could not read voted for the
  design's modal expectation. Degenerate checkpoints are now excluded from the qualifying base, which
  routes the case to 5b PANEL BASE ERODED when too many are excluded.
- **The partition question does not arise.** The discriminator is an integer count against 2, so
  "fewer than 2" and "2 or more" partition it with no interval left over. Round 2's careful `> 0` /
  `=< 0` complement was a correct repair to a real-valued statistic that is no longer used.

**AND IT IS TESTED BEFORE THE PANEL EXISTS, WHICH IS SC15.** For every champion, every band and every
`k_C` from 0 to `n_C`, the ORDER-CONSISTENT win set of that size was built against the panel's own
fitted order and `INV` counted exactly: **the largest `INV_prefix(k) - E[INV](k)` anywhere over 20
champions, 3 bands and every non-degenerate `k` is -2.5556**, and a value at or below the mean cannot be
above the maximum, so the exceedance leg cannot fire at any point of any backbone climb
(`exp067_panel_discriminator_redesign.txt` section D3). **And the contrast is computed in the same pass,
so that result is not an artifact of a statistic that cannot move: the ANTI-CONSISTENT win set, the `k`
STRONGEST members rather than the `k` weakest, exceeds its own exact mean in 60 of 60
champion-and-band cases and peaks at +37.1046.** SC15 re-runs both constructions on the real
25-member panel at step 2 and can go red.

**WHAT THE REPLACEMENT COSTS THE NEGATIVE, AND IT IS NOT HIDDEN.** The exceedance leg has never been
observed to fire on a real coevolution-free win pattern: **0 of 20 phase 0 champions have `INV` above
even their own exact mean, at any band** (`exp067_panel_discriminator_redesign.txt` section D4). If the
25-member measurement at step 2 reproduces that, branch 6's panel conjunct is close to automatic and
carries little information, the negative carries the label **PANEL LEG UNREACHED ON REAL PATTERNS**, and
that is a declared limitation on the negative rather than a reason to loosen the reference (RC3-6).

**WHICH ARM'S FAILURE BLOCKS WHICH VERDICT, because "in a majority of an arm's runs" does not say
whose.** IF-5 and IF-6 are GLOBAL and void everything. The arm-level triggers at precedences 0 and 1 are
PER-ARM, and they block a verdict exactly when that verdict NEEDS the affected arm's data. The negative
branches (5, 6, 7) name A1, A2 and A4, so any one of the three non-engaging or failing its instrument
blocks them and the verdict is 0 or 1. The positive branches (2, 3) rest on the CARRYING arm alone, so
they are blocked only when the carrying arm is the affected one: a positive in A1 is not voided because
A2 stopped engaging. A per-arm failure that blocks nothing is still printed as that arm's label.

**A3 NEVER CARRIES THE VERDICT.** It is the decoupled control, so its cyclic runs are counted, reported
and used for the coupling attribution, and they never enter branches 2 or 3. If A3 cycles and no coupled
arm does, the verdict is read from the coupled arms and carries the label **DECOUPLED-CONTROL CYCLED**,
which is itself a finding: cycling without reciprocal coupling, the curriculum-diversity route the grid
programme found rather than a Red Queen.

**EXHAUSTION, in one pass, so this is checkable rather than claimed. RE-RUN FOR THE TWO POSITIONS ROUND
2 ADDED.** Take any result. If IF-5 or IF-6 fired, it lands 1. If an arm-level trigger fired on an arm the
candidate verdict needs, it lands 0 or 1 (0 when IF-2 and IF-7 co-fire above the floor, 1 otherwise).
Otherwise, either some run of A1, A2 or a gradeable A4 is CYCLIC or none is. If some run is: either some
single one of those arms has 3 or more, giving 2, or the maximum over them is 1 or 2, giving 3. If none
is: either the floor conditions of branch 4 fire, giving 4, or they do not, in which case A4 has been run
(protocol step 8 triggers it whenever no arm reaches the CYCLING count) and is either ungradeable at arm
level, giving 5, or gradeable, **in which case the gradeable base is either below 7 of 13 in some arm the
negative needs, giving 5a, or at or above 7 of 13 in every one of them, in which case the panel base is
either unreadable, giving 5b (PANEL VOID when IF-8 fired, PANEL BASE ERODED when fewer than 7 of 13 A1
runs qualify), or readable, in which case the COUNT of A1's QUALIFYING runs satisfying the two-legged
Null C exceedance at band 0.10 is either fewer than 2, giving 6, or 2 or more, giving 7.** **That last
step is a round-3 replacement of a real-valued median by an integer count (RC3-1), and it partitions for
a simpler reason than the median did: 0 and 1 against 2 and above leaves no interval anywhere, and a
DEGENERATE checkpoint is excluded from the base rather than contributing an ambiguous zero to it.**
Every path terminates in exactly one outcome. The
two combinations the round-1 DESIGN gate produced still land: a floor-losing cyclic A2 run is UNGRADEABLE,
so it is not CYCLIC, it does not block branch 6, and it is printed as an UNGRADEABLE EXCEEDANCE; an
A4-only positive with 2 cyclic runs lands PARTIAL and with 3 lands CYCLING (SECOND-OPTIMISER-ONLY). **And
the three combinations round 2 produced now land too**: a matrix that exceeds Null A while carrying a
cyclic share at or below the coevolution-free reference is a SUB-REFERENCE EXCEEDANCE and not CYCLIC; a
39-run experiment with 2 gradeable runs lands 5a instead of signing the strongest claim the front can
make; and a firing IF-8 lands 5b PANEL VOID instead of falling off the end of the ladder. **And the
combination round 3 produced now lands too**: a lineage that climbs the panel to total dominance
(`k_C = n_C`) has a DEGENERATE final checkpoint, so it is excluded from the branch 6 / 7 base rather
than voting; if enough runs do that the verdict is 5b PANEL BASE ERODED, and if they do not, the runs
that remain are scored on arrangement rather than on composition. Under the withdrawn median that same
lineage scored a median of +15.6000 and landed 7.

**WHY 5a AND 5b BLOCK BRANCH 7 AS WELL AS BRANCH 6, WHICH IS AUTHOR-ADDED AND NOT IN RC2-3's LETTER.**
RC2-3 names branch 6. Branch 7 asserts the same universal proposition over the archive, "no run is
CYCLIC", and differs from branch 6 only in what the panel did, so it rests on exactly the same evidence
base and would otherwise become the place a thin-based negative could still be signed from. Both are
therefore gated. **The two new positions sit ABOVE 6 and 7 and BELOW 5**, so nothing that could previously
reach 4 or 5 is diverted: an arm that lost the floor still lands 4, and an ungradeable A4 still lands 5.

`10 of 13` is phase 0's own 15-of-20 fraction (0.75) applied to 13 runs and rounded up, not a new
constant. `7 of 13` is a majority, the same majority notion the INSTRUMENT FAILED branch already uses.
Precedence 2 above 4 is deliberate: CYCLING is an EXISTENCE claim, so GRADEABLE cyclic runs establish it
even when other runs of the same arm lost the floor, and FLOOR-LOST is then reported as a co-occurring
LABEL rather than as the verdict. Precedence 5 above 6 is what stops a single-optimiser negative from
being signed as NO CYCLING. Precedence 7 below 6 is not a fallback: it is the branch where the archive is
transitive and the panel instrument nevertheless moved, which is neither of the two stories this
experiment was built to separate and must not be collapsed into either.

**Why 3 of 13, and why WITHIN ONE ARM. THE ARITHMETIC THIS PARAGRAPH USED TO REST ON IS WITHDRAWN, AND
THE PARAGRAPH IS REWRITTEN RATHER THAN QUIETLY KEPT.** It read: the per-run test has probability at most
1/201 = 0.0049751 under Null A, so over 13 runs `P(>=1) = 0.0628`, `P(>=2) = 0.00186`,
`P(>=3) = 3.3e-5`, across the two coupled arms about 6.7e-5, and with a gradeable A4 about 1.0e-4, so
three of thirteen is a family-wise safe positive. **Every one of those five numbers is arithmetically
correct and has been reproduced twice** (`exp067_null_a_calibration.txt` section E2,
`exp067_null_a_verification.txt` item 6). **The INPUT is what fails.** 1/201 is the rate at which a
matrix DRAWN FROM Null A exceeds 200 further draws from Null A, not the rate at which a real matrix of
this substrate does, and the one real matrix available exceeds it at all three bands with no coevolution
in it. **So the level is withdrawn and no level replaces it**, raising `k` does not buy it back (no `k`
of 13 holds it at the point estimate, 6 of 13 at the 95 percent lower bound, and 6 of 13 is a bar this
substrate clears without coevolving), and the full re-derivation with its arithmetic is in "Null A has
now been run on a real matrix".

**WHAT 3 OF 13 IS NOW.** A within-arm REPLICATION requirement: three independent runs of one arm, each
exceeding both a self-matched scalar-strength null AND a coevolution-free reference share of the same
shape. One of thirteen is not that, which is why it still lands PARTIAL and not CYCLING. **The reason
the threshold is per-arm and pooling is refused is unchanged and does not depend on the withdrawn
level** (DESIGN gate RC-1c): the requirement is replication of a per-run test WITHIN one arm's fixed
configuration, and 2 cyclic runs in A1 plus 2 in A2 is replication across two different opponent-set
regimes rather than within one, so it lands PARTIAL with the pooled count printed and is not promoted by
an argument constructed after seeing it.

**Why the negative needs A4.** CYCLING is an EXISTENCE claim so one optimiser class suffices. NO
CYCLING is a UNIVERSAL claim, so it needs two, because a negative from a single optimiser reproduces
verbatim the search under-convergence confound this front exists to remove. This is phase 0's
asymmetric stopping rule carried over unchanged, and it is fixed in advance so it cannot be used to
shop for a result.

**Reading the arms together, pre-committed**

| pattern | reading |
|---|---|
| A1 cycles, A2 cycles, A3 does not | **CYCLING, COUPLING-ATTRIBUTED.** Reciprocal coupling produces it and a frozen shuffled archive of the same champions, walked on a schedule, does not. |
| A1 or A2 cycles, A3 cycles at the same rate | **CYCLING, NOT COUPLING-ATTRIBUTED.** The effect is curriculum diversity, which is exactly what the grid programme found. Reported with a Fisher exact one-tailed p on the cyclic-run counts, coupled against decoupled, as a reported number and not a gate, **computed only on the A1-A3 pairs surviving the degeneracy exclusion of "A3 inherits its paired A1 run's defects", with both `n` values printed; UNAVAILABLE if fewer than 7 of the 13 pairs survive** (gate blind spot 4). |
| A2 cycles, A1 does not, A2 held the floor | The HALL OF FAME suppresses it. The anchor is the mechanism. |
| A2 loses the floor, A1 holds it and does not cycle | **THE ANCHOR SQUEEZE.** In this substrate the only configuration that keeps the population above the certified competence floor is the one that removes the cycling opportunity, and the one that leaves the opportunity open cannot be read. This is `SYNTHESIS_P7.md`'s "too decoupled to escalate or too coupled to survive" appearing one level up, and it is signable as such, NOT as a clean no-cycling result. |
| A1 and A2 do not cycle, A4 does in >= 3 of its 13 while gradeable | **CYCLING (SECOND-OPTIMISER-ONLY)**, with its panel sub-label. The single-mean optimiser could not hold two coexisting strategies; the distinct-parent population could. A positive, and a statement about what a coevolutionary substrate needs. At 1 or 2 cyclic A4 runs this is PARTIAL, not a positive. |
| A1, A2 and A4 do not cycle, floor held, both 7-of-13 bases hold, FEWER THAN 2 qualifying A1 runs exceed their own Null C maximum at the final checkpoint while not exceeding it at checkpoint 0 | **NO CYCLING**, the two-optimiser-class negative, the only form of negative this front is entitled to sign. **Carries the label PANEL LEG UNREACHED ON REAL PATTERNS if the step-2 measurement found no panel member exceeding its own maximum either** (RC3-6), because then this conjunct is close to automatic and carries little information. |
| A1, A2 and A4 do not cycle, floor held, both 7-of-13 bases hold, 2 OR MORE qualifying A1 runs exceed their own Null C maximum at the final checkpoint while not exceeding it at checkpoint 0 | **PANEL-INVERTED, ARCHIVE TRANSITIVE.** The archive is explained by a scalar strength and the population still moved to a win pattern MORE cycle-forming than the most cycle-forming of 200 composition-matched random patterns of its own win-set size, in runs whose seeds were not already there. Read jointly with IF-14: with a large floor-`W` drop it is competence shed on an axis the panel order does not describe; without one it is specialisation the archive matrix cannot see. The IF-14 runs are already filtered out of the base (RC2-2), so this row is read on runs where the shed did not fire. **The row's first version read "by MORE than the change in its own win-set size accounts for", which was the reading of a rule that a pure transitive climb satisfied; that rule and that reading are both withdrawn (DESIGN gate round 3, RC3-1 and RC3-2).** |
| no run is CYCLIC and fewer than 7 of 13 runs are GRADEABLE in an arm the negative needs | **CONVERGED, BASE INSUFFICIENT.** The coevolutionary dynamic converged before the instrument had a population to measure. Not a negative and not an instrument failure. The gradeable count per arm and the failing condition per run are printed. |
| no run is CYCLIC, bases gradeable, but IF-8 fired or fewer than 7 of 13 A1 runs qualify for the panel conjunct | **INCONCLUSIVE, PANEL BASE UNAVAILABLE**, sub-labelled PANEL VOID or PANEL BASE ERODED. The archive is transitive and the panel instrument cannot be read, so neither NO CYCLING nor PANEL-INVERTED is available. **A run is disqualified by IF-1, by IF-14 FLOOR-SHED, or by a DEGENERATE Null C at checkpoint 0 or at the final checkpoint** (RC3-1). |
| a run exceeds its own Null A maximum but its cyclic share is at or below the no-coevolution reference | **SUB-REFERENCE EXCEEDANCE**, printed with both numbers, NOT CYCLIC. The scalar-strength model is rejected for that matrix and the matrix is no more cyclic than 20 independently evolved champions of the same substrate are. |
| any arm reaches 3 cyclic runs with `INV` not exceeding its own Null C maximum at the final checkpoint in a majority of them | **CYCLING (SELF-RELATIVE).** The intransitivity is real and the pocket claim is not available. Reported with the checkpoint-local-specialisation mechanism named as the live alternative, not dismissed. |
| decisive edges collapse and the draw share exceeds 0.20 in a majority of floor-holding runs | **NON-ENGAGEMENT.** Two coevolved orbiters that stop closing. A finding about the dynamic, not a broken instrument, and not a cycling result in either direction. |
| A3 cycles and neither A1 nor A2 nor a gradeable A4 does | The verdict is read from the coupled arms and carries **DECOUPLED-CONTROL CYCLED**. A3 never carries the verdict, so this is not a positive for the cycling question; it says the frozen shuffled curriculum produced intransitivity that reciprocal coupling did not, which is the grid programme's curriculum-diversity route and a pointer for the next rung. |
| 2 cyclic runs in A1 and 2 in A2, none in A4 | **PARTIAL**, with the pooled count of 4 printed as a label. The family-wise arithmetic is within-arm, so 2 plus 2 is not a safe positive and is not promoted to one. |
| all archives strongly time-ordered, backward-edge share below 0.10, counts at or below the Null A median | insight 057's dominance pattern reproduced in a materially different substrate, which is the sharpest available statement of the negative. |

**ONLY CYCLING or NO CYCLING signs the cycling question, and CYCLING (SELF-RELATIVE) signs only its
intransitivity half.** PARTIAL, FLOOR-LOST, INCONCLUSIVE (SECOND CLASS UNTESTABLE), CONVERGED (BASE
INSUFFICIENT), INCONCLUSIVE (PANEL BASE UNAVAILABLE), PANEL-INVERTED, NON-ENGAGEMENT and INSTRUMENT
FAILED each prescribe a different next move and MUST NOT be collapsed: PARTIAL sends the question to
more seeds at the same design, FLOOR-LOST to the anchoring mechanism, INCONCLUSIVE (SECOND CLASS) to a
seedable second optimiser class, **CONVERGED (BASE INSUFFICIENT) to the convergence itself, meaning a
smaller step size, a longer budget or a diversity-maintenance mechanism, since the dynamic reached a
fixed point before the instrument had 7 gradeable runs to read**, **INCONCLUSIVE (PANEL BASE
UNAVAILABLE) to the panel: a new measuring stick under PANEL VOID, and the floor-shed mechanism under
PANEL BASE ERODED**, PANEL-INVERTED to the panel-relative question and the floor trajectory,
NON-ENGAGEMENT to the fitness's treatment of draws, INSTRUMENT FAILED to the named instrument. **Nothing in phase 1 unlocks mesh, ReckonDB or evoq work.** Re-raise triggers 1, 2 and 3
of `PLAN_ROBO_RUMBLE.md` stand regardless of the verdict.

### Secondary endpoints, reported with the verdict, never gating

- **Panel trajectory per run**: row mean against the 25 panel members, Copeland count, and Bradley-Terry
  rank against the frozen panel order, per checkpoint.
- **Floor trajectory per run**: held-out W against `predictive_gun` per checkpoint, and the median
  damage margin.
- **The divergence between the two**: Spearman rho, per run, between checkpoint index and each of
  (panel row mean, floor-bot W). Under the phase 0 probe's picture these should have opposite signs.
- **Backward-edge share and RETURN triple count** per run, at all three bands.
- **Draw share** of every matrix, so a reader can judge whether the cells are contests.
- **Distinct quantised phenotypes** per generation and clamp fraction per checkpoint.
- **`INV` with the gunless legs INCLUDED**, alongside the primary excluded count.
- **The train-to-held-out FLOORED MARGIN gap** per checkpoint (IF-11's observable).
- **GRADEABILITY ACCOUNTING per arm**: how many of the 13 runs are GRADEABLE, and for each ungradeable
  run which of the three conditions it failed (IF-1 FLOOR-LOST, CONVERGED-UNGRADEABLE, NULL-UNFIT with its
  direction). A negative signed over 10 gradeable runs is a different object from one signed over 13, and
  the reader is told which.
- **UNGRADEABLE EXCEEDANCES**: every ungradeable run whose primary count exceeded its own Null A maximum,
  with its `n`, its count and its label. These do not sign anything and they are not hidden.
- **`n` after dedup** per run, beside the full 20-member count, so the shares are readable.
- **SUB-REFERENCE EXCEEDANCES**: every run that passed CYCLIC leg (ii) and failed leg (iii), with its
  cycle count, its cyclable count, its share, and the reference share it failed against. These are the
  runs the round-2 repair stops from signing and they are printed in full.
- **PER-CYCLE BEHAVIOURAL REPORT**, for every cyclic triple counted in any archive matrix or panel
  matrix: the three edges' DAMAGE PROVENANCE (winner's mean bullet damage dealt per decided match and
  loser's mean self-inflicted share of damage taken), the EDGE-FAMILY partition by shared edge with the
  cycle count per shared edge largest first, the MINIMUM ABSOLUTE MARGIN SLACK in matches above the band
  with the knife-edge label at a slack of 1, and the BEHAVIOURAL REGIME of each member. Required, never
  gating (RC2-6 and gate blind spot 3).
- **NULL C DIAGNOSTICS per champion per checkpoint**: `n_C`, `k_C`, `D_C`, `E[INV]`, the 200-permutation
  min, median and maximum, whether `INV` exceeds the maximum, the centred value `INV - E[INV]`, and the
  count of DEGENERATE checkpoints where `k_C = 0` or `k_C = n_C`.
- **THE RAW `INV` DELTA AND THE CENTRED `INV - E[INV]` DELTA, BOTH BESIDE THE EXCEEDANCE COUNT THAT NOW
  DECIDES**, per run and as arm medians, so both quantities earlier versions of this rule would have
  decided on stay visible next to the one that does. Round 2 kept the raw delta visible when it adopted
  the centred one; round 3 keeps both visible when it adopts the count (RC3-1). **Neither gates
  anything.**
- **THE PER-RUN QUALIFYING DECISION FOR THE BRANCH 6 / 7 BASE**, with the reason a disqualified run was
  disqualified: IF-1, IF-14 FLOOR-SHED, DEGENERATE checkpoint 0, or DEGENERATE final checkpoint.
- **THE PANEL LEG's CALIBRATION READ FROM STEP 2**: for each of the 25 panel members, whether its own
  `INV` exceeded its own 200-permutation Null C maximum, at every band, and the resulting label (PANEL
  LEG UNCALIBRATED if any did, PANEL LEG UNREACHED ON REAL PATTERNS if none did). Required with the
  verdict because it is what tells a reader how much the panel conjunct could ever have said (RC3-6).
- **A1-A3 PAIR ACCOUNTING**: which pairs survive the degeneracy exclusion, which do not and why, and the
  Fisher comparison's `n` on both sides.

---

## Instrument failure, distinguished from a real negative

IF-1 to IF-6 void or replace a verdict, with one exception: IF-3 does so only when it fires BELOW the
floor, and above the floor it records CONVERGED instead (RC-5). IF-7 to IF-9 are gates on the instruments
themselves. IF-10 to IF-14 are MODIFIERS or observables that label a verdict.

| code | trip | reading |
|---|---|---|
| **IF-1 FLOOR-LOST** | fewer than 15 of a run's 20 checkpoints have held-out `W >= B` against `predictive_gun` | The run left the certified competence regime. Its matrix is UNGRADEABLE for cycling, not a negative. Above the arm level this becomes the FLOOR-LOST verdict, which is a finding about coevolutionary dynamics and not an answer to the cycling question. |
| **IF-2 SEARCH-INERT** | a run's archive matrix has fewer than 30 of 190 band-decisive edges at 0.10, or fewer than 10 of its 20 checkpoints hold distinct quantised phenotypes | The population did not move. There is nothing to count and no cycling claim is available in either direction. **Carve-out:** when IF-7 fires on the same run and the floor precondition holds, the cells are draw-parked rather than structureless and the arm-level reading is NON-ENGAGEMENT (outcome 8), not instrument failure. |
| **IF-3 LATTICE-COLLAPSE, SPLIT BY FLOOR STATE** | a run ends with 1 distinct quantised phenotype per generation | `quantize/1` puts the search on a finite integer lattice at scale 256, so once per-coordinate sigma falls below about 1/256 every offspring collapses to the same phenotype. **BELOW the floor** that is the phase 0 search artifact this flag was written for and it is instrument failure. **AT a champion HOLDING `W >= B`** it is not: a population that converges onto one competent phenotype is a FIXED POINT of the coevolutionary dynamic, which is what H1 predicts, so it is recorded as **CONVERGED**, it does NOT count toward the INSTRUMENT FAILED majority, and the run stays gradeable on its deduplicated above-floor submatrix if that leaves `n >= 15`, or is CONVERGED-UNGRADEABLE if it does not. **The split is a DESIGN gate repair (RC-5)**: the flag was carried from phase 0, where the fitness was stationary, and under coevolution the un-split version let the design's own predicted result (runs converge and sit still) return INSTRUMENT FAILED and destroy its own negative. |
| **IF-4 SEARCH-DIVERGED** | more than half of a checkpoint champion's coordinates at the plus or minus 2048 clamp | `sep_cma_es` can emit 1.0e308-scale values from a diverging covariance, which `quantize/1` clamps silently. Read as a CHANGE from the seed's own fraction (min 0.1530, median 0.2989, max 0.3594), which is recorded above precisely so this flag is not reading an inherited state. |
| **IF-5 NON-DETERMINISTIC** | SC2, SC3, SC7, SC10 or SC13 fails | Everything void. |
| **IF-6 SEAT-ASYMMETRY** | SC4 fails | The half-matrix licence is void. Matrices are re-measured in full (double cost, affordable) and the verdict is recomputed. If it fails after full measurement, everything void. |
| **IF-7 DRAW-DOMINATED** | more than 20 percent of a matrix's matches are draws | The cells are mostly non-contests and the counter is reading a draw structure rather than a dominance structure. Phase 0's matrix ran 472 of 30,400 = 0.01553, so this trigger is 13x the measured rate. The verdict is labelled draw-dominated. `0.20` is a chosen constant, named as chosen. |
| **IF-8 PANEL-DEGENERATE** | the frozen panel has fewer than 150 of 300 band-decisive edges at 0.10, or its Bradley-Terry fit hits the iteration cap, or more than 30 of 300 band-decisive pairs disagree with its fitted order | The measuring stick has no order for inversions to be read against. Instrument I1 is VOID and the design falls back to the archive matrix and I2 alone, with the fallback recorded. **THIS FLAG IS KNOWN TO BE TIGHT AND ITS HEADROOM IS UNKNOWN UNTIL PANEL STEP 2 (DESIGN gate round 3, RC3-5, correcting round 2's "measured at 4").** At band 0.10, 26 of the 150 band-decisive pairs of the 190-cell champion submatrix disagree with the order fitted on the TWENTY-champion matrix (`exp067_null_a_calibration.txt` section D4), and the trigger is more than 30 over all 300 pairs. Round 2 subtracted and wrote "so 4 violations of headroom remain for the 110 rung-involving pairs". **That subtraction is not valid**: the panel refits over 25 members, SC3a fixes the 190 CELLS and not the fitted STRENGTHS, and five extra rungs can reorder the 20 champions relative to each other, so the count of those same 190 pairs disagreeing with the PANEL's order is neither 26 nor bounded by 26 in either direction. The 26 is printed as an INDICATOR from a different fit; the real headroom is recomputed and printed at panel step 2, before any arm runs. **The 30 is NOT moved.** The consequence is pre-committed instead: if IF-8 fires, a CYCLING verdict can only be SELF-RELATIVE, and a negative lands at ladder position 5b with the sub-label PANEL VOID rather than falling through the ladder. Separately, if the panel has fewer than 5 band-decisive cyclic triples at 0.10 after the gunless exclusion, the POCKET language is void (there are no pockets to be inside), `INV` is still computed and reported as an inversion count, and the pocket-retained / pocket-created labels are unavailable. |
| **IF-9 NULL-UNFIT** | Null A's median synthetic decisive-edge count at 0.10 differs from the observed by more than 20 of 190, or the fit hits the cap | The null is not matched to the observed decisiveness structure and cannot bound the count in either direction. This is exactly the defect that made phase 0's coin null unusable. **The RUN becomes UNGRADEABLE for the primary test; NULL B DOES NOT BECOME PRIMARY** (DESIGN gate RC-4). DEFLATED (median below observed): count and null position printed, and the verdict carries NULL-UNFIT RESIDUE if the count exceeded the deflated maximum. **The first version also read a DEFLATED shortfall as "positive-direction evidence of non-scalar margin structure"; that reading is WITHDRAWN by measurement (DESIGN gate round 2, RC2-4), because on the one real matrix of this shape the gate does not fire at all, the null slightly OVER-produces decisive edges at `+4.0`, and the same matrix carries 18 banded cycles against a closed-form expectation of 0.04797213 per synthetic matrix and a Markov bound of 0.00266512 (`exp067_null_a_verification.txt`; **the seed-free closed form replaces the sampled ratio "18 times the null maximum" here by DESIGN gate round 3, RC3-4, because that maximum is 1 at calibration seed `{3661, 0, 0}` and 2 at verification seed `{9091, 0, 0}`**). A matrix can pass this gate in the INFLATED direction and be nowhere near scalar, so the gate measures MATCHEDNESS and nothing else.** INFLATED (median above observed): nothing else is read. If IF-9 fires in a majority of an arm's floor-holding runs, INSTRUMENT FAILED. If Null B fails SC8, INSTRUMENT FAILED. **The gate's WIDTH of 20 of 190 is re-derived and KEPT: it accepts the phase 0 matrix with `|median - observed| = 4`, the smallest accepting width is 4, and the null's own sampling spread of the same count is 10, so 20 sits above the null's own spread.** |
| **IF-10 BUDGET-LIMITED** | on a NO CYCLING verdict, the median run's cyclic count over checkpoints 11..20 exceeds its count over checkpoints 1..10 by at least 2 (each a 10-member submatrix, 120 triples, so the two halves are scale-matched to each other) | The negative is budget-limited and says nothing about the substrate. |
| **IF-11 OVERFIT-TO-TRAIN-STARTS** | median checkpoint champion's train-minus-held-out FLOORED MARGIN gap exceeds the phase 0 kill-mode range of 5.28 to 18.41 whole units (`exp066_flag_fixes.txt` section B) | MODIFIER. The coevolved champions are more start-overfitted than the seeds were, and the verdict carries the label. **This is a NEW post-hoc-informed instrument, not IF-8 repaired.** It reads the floored margin because phase 0 measured that the win-rate train leg saturates at 1.0000 for 40 of 40 champions while the margin leg saturates nowhere. It is a comparison against a previously measured range, not an invented threshold. |
| **IF-12 POCKET-INHERITED** | every cyclic triple found across an arm appears in runs seeded from 2003 or 2013 | MODIFIER on a positive. Reported as POCKET RETAINED rather than POCKET ENTERED OR CREATED, and it is the weaker claim. **Its premise is now persisted** in `exp066_residue_and_inv0.txt` section B: the 11 kill-mode champions other than 2003 and 2013 carry 0 cycles at all three bands over 165 triples of which 130 / 115 / 96 are cyclable (DESIGN gate RC-8). |
| **IF-13 SEED-ERASED** | the `init_sigma` pilot's largest qualifying sigma does not exist, or a seeded run's checkpoint-1 champion is below `B` against the floor bot | The seed was destroyed by the initial step size, so the run did not start above the certified floor and its early checkpoints are outside the regime the plan licenses. |
| **IF-14 FLOOR-SHED** | a run's final checkpoint holds `W >= B` against `predictive_gun` but is more than 0.25 (40 matches of 160) BELOW its own checkpoint-0 `W` | MODIFIER, and it is what the floor gate's coarseness costs (gate blind spot 5). `B = 0.5748` against seed `W` of 0.9375 to 1.0000 means a champion can shed most of its floor competence and still "hold the floor". Because the panel order is roughly orthogonal to floor competence (H3), a shed like that can invert panel cells on its own. **A run with IF-14 firing is reported as FLOOR-SHED, and its Null C EXCEEDANCE, if it has one, counts toward NEITHER the CYCLING branch's panel conjunct NOR the branch 6 / 7 count.** (**This row said "an `INV` rise" until DESIGN gate round 3, RC3-7e**: the live rule reads an exceedance of the run's own 200-permutation maximum, not a rise in a raw count, so barring "the rise" barred an object no rule reads. No decision diverged, because barring the exceedance of a run that has none is vacuous, but the same conjunct was stated three ways and one of them was the dead one.) `0.25` is a chosen constant, named as chosen. |

**Note on what IF-10's non-firing does and does not carry.** Phase 0 recorded in advance that its
FAILED branch was near-unreachable and that its non-firing carried no information. The analogue here:
IF-2 SEARCH-INERT is unlikely on a seeded arm, because the seed is already a competent controller, so
its non-firing is weak evidence. It is kept because it is the only thing that catches a run whose
matrix has no structure to count.

**AND THE FLAG NUMBERS DO NOT CARRY ACROSS PHASES, WHICH IS WORTH ONE LINE BEFORE IT MISLEADS SOMEONE.**
Phase 1's **IF-10 is BUDGET-LIMITED**. Phase 0's **IF-10 was LADDER-INVERSION**, the flag whose predicate
`exp066_flag_fixes.txt` section A widened to four lower rungs with the draw-parked clause. **The same
collision exists at 8**: phase 0's IF-8 was the memorisation instrument that the "NOT carried" section (PART 1)
above declares untestable and permanently so, while phase 1's IF-8 is PANEL-DEGENERATE, and phase 1's
replacement for phase 0's IF-8 is IF-11. They are different flags with the same numbers in two different
documents, because each pre-registration numbers its own flags from 1. Where this document discusses phase
0's flag work it names the record rather than the number, and the paragraph above is about phase 1's IF-10
and phase 0's FAILED branch, which are not the same object either.

---

## What would falsify what

**For the experiment:**

- **CYCLING is falsified** by no single arm reaching 3 GRADEABLE runs that satisfy BOTH count legs at band
  0.10 (exceeding their own Null A maximum AND exceeding the no-coevolution reference share), or by IF-5
  or IF-6. **The second leg is added by DESIGN gate round 2 (RC2-4) and it makes CYCLING strictly harder
  to sign than the first version made it.**
- **CYCLING (PANEL-VISIBLE) is falsified**, with CYCLING (SELF-RELATIVE) surviving, by fewer than 2 of
  the arm's cyclic runs having `INV` at their final checkpoint above that checkpoint's own 200-permutation
  Null C maximum at band 0.10, or by those runs' checkpoint-0 `INV` already exceeding its own
  200-permutation maximum, or by those EXCEEDANCES co-occurring with IF-14 FLOOR-SHED, or by IF-8 voiding
  instrument I1. (**The word was "rises" until DESIGN gate round 3, RC3-7e; the live rule reads an
  exceedance and not a rise.**)
- **NO CYCLING is falsified** by any single GRADEABLE run of A1, A2 or A4 satisfying both count legs at
  band 0.10, or by **2 OR MORE of A1's QUALIFYING runs having `INV` at checkpoint 20 above that
  checkpoint's own 200-permutation Null C maximum while checkpoint 0 was not above its own, at band
  0.10**, or by the floor precondition holding in fewer
  than 10 of 13 of A1's runs, or by A2 tripping IF-1 in a majority of its 13, or by IF-10, or by A4 being
  UNGRADEABLE at arm level, **or by fewer than 7 of 13 runs being GRADEABLE in an arm the negative needs
  (RC2-3), or by fewer than 7 of 13 A1 runs qualifying for the panel conjunct (RC2-2 and RC3-1), or by
  IF-8 voiding
  the panel.** The last three do not falsify NO CYCLING into its opposite; they land 5a or 5b, which sign
  nothing about cycling in either direction.
  **The `INV` conjunct is RELATIVE and that is a DESIGN gate repair (RC-3): the first version made it
  absolute (`INV = 0`), and the 13 seeds' measured `INV_0` has a median of 2 at band 0.10, so the
  absolute form could not have fired no matter what coevolution did. Round 2 (RC2-1) made it relative to
  NULL C rather than to its own earlier raw value, because a raw delta is inflated by the composition
  drift H3 predicts. Round 3 (RC3-1) found that the negative's half of that repair, a median of
  `INV - E[INV]`, subtracts a mean without conditioning on `k_C` and therefore reads composition with a
  `k`-dependent sign, sending a pure transitive climb to branch 7 at a measured median of +15.6000. The
  negative's conjunct is now the POSITIVE's exceedance conjunct, one normalisation everywhere.**
- **The coupling attribution is falsified** by A3 producing cyclic runs at the same rate as A1 or A2.
- **The anchor mechanism reading is falsified** by A1 and A2 behaving alike on both the floor
  precondition and the cyclic count.
- **The single-mean limitation reading is falsified** by A4 producing no cyclic run while holding the
  floor, or by A4 failing to clear the floor at all (in which case it is UNGRADEABLE and falsifies
  nothing).
- **Instrument I1 (PART 2) is falsified as an instrument** by IF-8: a panel with no readable order, or with more
  than 30 of 300 decisive pairs disagreeing with its own fitted order.

**For the instruments themselves, so they are not immune to evidence either:**

- **The integer band test's justification is falsified** if no pair-and-band case in any phase 1 matrix
  has a margin exactly equal to its band, in which case the float and integer counters agree
  everywhere and the change is bookkeeping rather than a correction. Both counters are computed on every
  matrix and any disagreement is printed per pair.
- **Null A's suitability is falsified** by IF-9, which is computed and reported whatever it returns.
- **Null C's closed form is falsified** if the 200-permutation mean differs from
  `D_C * k_C * (n_C - k_C) / (n_C * (n_C - 1))` by more than one count on any champion, which would mean
  the sampler and the formula do not describe the same model. **After round 3 the closed form no longer
  enters any decision** (the branch 6 / 7 median that subtracted it is withdrawn), **but the check
  matters MORE and not less, because both branch decisions now read the MAXIMUM of the same 200
  permutations that produce that mean: a sampler that does not implement the model the closed form
  describes puts the error inside both the positive's conjunct and the negative's. It is SC14.**
- **The claim that Null C absorbs composition drift is falsified** if the 200-permutation maximum at a
  checkpoint does NOT rise with `k_C` toward `n_C / 2` at fixed `n_C` and `D_C`, which is checkable on
  **all 25** of the panel's own members at step 2 of the protocol (PART 3), before any run, and is
  printed there. **The check is over the RISE toward `n_C / 2` and not over monotonicity across the whole
  range `0..n_C`, because that curve is necessarily unimodal (zero at both ends, peak at the middle) and
  a monotonicity test over the full range would fire unconditionally on arithmetic. The protocol's own
  wording said "flat or non-monotone" and therefore stated a check whose verdict was fixed in advance;
  that is corrected in PART 3 by DESIGN gate round 3, RC3-3, and this falsifier's form is the one
  adopted.** After round 3 this is a falsifier of the EXCEEDANCE discriminator on both branches, since
  the exceedance is the only panel statistic either branch reads.
- **The round-3 replacement discriminator is falsified as a discriminator** if the synthetic
  backbone-climber construction at panel step 2 (**SC15**) produces, for any panel member at any band at
  any `k_C`, an order-consistent win set whose `INV` exceeds that `k_C`'s own 200-permutation maximum. On
  the 190-cell lower bound the worst case anywhere is `INV_prefix - E[INV] = -2.5556` over 20 champions,
  3 bands and every non-degenerate `k` (`exp067_panel_discriminator_redesign.txt` section D3), so the
  construction is expected to pass; if it does not, the replacement reads composition too and the panel
  half of this design has failed three times rather than twice.
- **The panel exceedance leg's REACHABILITY is measured rather than falsified, and both readings are
  pre-committed** (RC3-6): if any of the 25 panel members exceeds its own 200-permutation maximum the
  `1/201`-per-champion Type I story dies exactly as Null A's did, and if none does then the corpus
  contains no example of a real win pattern reaching this reference and the negative's panel conjunct is
  labelled as carrying little information. On the 190-cell lower bound the answer is 0 of 20 at every
  band (section D4 of the same record).
- **The no-coevolution reference share's own premise is falsified** if the phase 1 archive matrices turn
  out to span the same four behavioural regimes phase 0's 20-champion matrix spans, in which case the
  reference is shape-matched after all and the conservative-direction warning attached to leg (iii) does
  not apply. The regime of every checkpoint is a required report, so this is decidable.
- **The scale-matching claim is falsified** if the archive matrix does not have exactly 190 pairs, 1,140
  unordered triples and 3,420 ordered candidates, which is asserted arithmetic and is checked.
- **The panel's role as a spanning measuring stick is falsified** if its 25 members occupy fewer than 3
  of the 4 measured regimes once re-measured, which would mean the panel does not span the space it is
  meant to.

---

