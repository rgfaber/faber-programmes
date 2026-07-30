> Part 2 of 6 of the [EXP-067 pre-registration](exp067_coevolution_cycling.md). The root holds the framing, the status and the section index.

# EXP-067 PART 2. The nulls and the two instruments

## THE NULLS, REGISTERED BEFORE THE MATRIX EXISTS

This is the largest lesson available from phase 0 and it is discharged first. Reading the same 20
champions against three different nulls gave "a fifth of the coin-flip rate", "below the lowest of
200 draws" and "above the highest of 200 draws". **The count was never the problem.** Three nulls
are registered here, each attached to a specific statistic, and the alternatives are named and
rejected in advance.

**THREE NULLS AND, AFTER GATE ROUND 2, ONE MEASURED REFERENCE THAT IS NOT A NULL.** The
NO-COEVOLUTION REFERENCE SHARE registered below as CYCLIC leg (iii) is a single number measured on a
real coevolution-free matrix, not a distribution, so it yields no `p`-value and no range and it is never
called a null. It exists because Null A turned out to be rejected by a real matrix of the right shape
with no coevolution in it, which is the subject of the fourth subsection below. **And the lesson this
section opens with recurs INSIDE the set of nulls this design kept**: Null A puts the same phase 0
count far ABOVE its range while Null B puts it far BELOW. What discharges the lesson is not that the
references agree, because they do not; it is that each is bound to one named statistic before any
matrix exists, and that the primary is fixed in advance and cannot be swapped when it is inconvenient.

### Null A, PRIMARY for the archive cycle count: the BRADLEY-TERRY PARAMETRIC BOOTSTRAP

A single scalar strength per champion, fitted to the observed matrix, then synthetic matrices drawn
from the fit and counted with the same integer counter. **This is the null whose rejection means
something, because the front's own scientific hypothesis is precisely that no scalar strength
exists** (`PLAN_ROBO_RUMBLE.md` section 7: "Elo assumes a scalar skill, and this front's scientific
hypothesis is precisely that no scalar exists"). A count above this null's range is intransitivity
that no competence ladder can explain. A count inside it is a matrix a ladder explains.

Specification, complete, so no part of it can be chosen later:

```
Input      the archive matrix as integer win counts K(I,J), T = 20 members, M = 160 per cell.
Decisive matches per cell  N(I,J) = K(I,J) + K(J,I).   Draws are NOT modelled; they are HELD FIXED.
Model      P(I beats J | the match is decisive) = s_I / (s_I + s_J).
Fit        maximum likelihood over the decisive matches by the MM (Zermelo / Ford) iteration,
           with ONE virtual win and ONE virtual loss per UNORDERED pair, so the pair's augmented
           decisive count is N(I,J) + 2 and each member of the pair gains one virtual win.
           (The first version wrote "every ordered pair", which is a different prior; the
           per-unordered-pair reading is the one the calibration actually fitted and the
           verification identified, and the ambiguity is closed in "Null A has now been run on a
           real matrix". A prior specified two ways is not specified.)
           That prior is the standard fix for a win graph that is not strongly connected and it is
           DECLARED NOW, not chosen after a divergence. Stop at relative change below 1e-10 in
           every s_I, iteration cap 10,000, normalised so sum(s) = T. Hitting the cap fires IF-9.
Draw       for each pair hold N(I,J) at its observed value; draw K*(I,J) ~ Binomial(N(I,J), p);
           set K*(J,I) = N(I,J) - K*(I,J); the draw count of the cell is unchanged.
           So the synthetic matrix has the observed per-cell decisive count and the observed
           per-cell draw count, EXACTLY, edge for edge.
Draws      200, seeded from a persisted constant, fresh per matrix.
Report     median, min, max, and the observed count's position in the 200.
Fit gate   IF-9: the median synthetic decisive-edge count at band 0.10 must be within 20 of the
           observed value out of 190. Outside that the null is not matched to the observed
           decisiveness structure, it CANNOT bound the count in either direction, the RUN becomes
           UNGRADEABLE for the primary test, and the mismatch is recorded WITH ITS SIGN.
           NULL B DOES NOT BECOME PRIMARY. That is a repair made by the DESIGN gate (RC-4):
           the first version of this document promoted Null B here, which would have re-based
           precisely the most cyclic runs onto the one null that cannot see them.
```

The per-run test is one-sided: **the count leg of CYCLIC is that a run's primary count exceeds the
MAXIMUM of its own 200 draws**, and the run must be gradeable (the floor precondition of the decision
rule, and a matched fit). **That leg is NO LONGER SUFFICIENT, and a second leg is registered below,
because Null A has now been exercised on a real matrix of exactly this shape and it fires on one that
contains no coevolution at all.** The claim that "under the null the count test has probability at
most 1/201 = 0.00498 per run" is a correct TYPE I statement about a matrix DRAWN FROM Null A and is
**NOT** a statement about the rate at which a real matrix of this substrate trips the test; the first
version used the first as if it were the second. See "Null A has now been run on a real matrix".

**WHAT HAPPENS WHEN THE FIT GATE FIRES, pre-committed in both directions and with the reason the
directions differ (DESIGN gate RC-4).**

- **NULL-UNFIT (DEFLATED): the median synthetic decisive-edge count is BELOW the observed by more
  than 20.** The mechanism is that a matrix whose margins no scalar strength can reproduce makes the
  fit compress those pairs toward 0.5, which under-produces decisive edges and therefore also
  under-produces cyclable triples and cycles. So the null is DEFLATED and an exceedance of it is
  ANTI-CONSERVATIVE and **cannot sign a positive.** The run is UNGRADEABLE for the CYCLIC test and
  its count and its null position are printed anyway.
  **THE FIRST VERSION ALSO CALLED THE SHORTFALL "the alternative hypothesis' own fingerprint" AND
  "positive-direction evidence of non-scalar margin structure". THAT CLAIM IS WITHDRAWN, AND IT IS
  WITHDRAWN BECAUSE IT WAS MEASURED AND FALSIFIED (DESIGN gate round 2, RC2-4).** On the one real
  matrix of this shape available, the fit gate does not fire in the DEFLATED direction at all: the
  null slightly **OVER**-produces decisive edges (median synthetic 154.0 against observed 150 at band
  0.10, sign INFLATED) while that same matrix's cycle count is 18 against a null maximum of 1, a
  factor of 18. **A matrix can pass the fit gate comfortably, in the INFLATED direction, and be
  nowhere near scalar.** So a decisive-edge shortfall is not a fingerprint of non-scalar structure and
  its absence is not evidence of scalar adequacy; the fit gate measures whether the null is MATCHED,
  and nothing else. The DEFLATED branch keeps its behaviour (ungradeable, printed, cannot sign) and
  loses its interpretation. If any such run's count exceeded its deflated null maximum, the verdict
  still carries the label **NULL-UNFIT RESIDUE** with the count of such runs, now with no
  positive-direction reading attached to it. Numbers from
  `programmes/p7_coevolution/exp067_coevolution_cycling/exp067_null_a_calibration.txt` sections D1 and
  D2, independently reproduced in `exp067_null_a_verification.txt`.
- **NULL-UNFIT (INFLATED): the median is ABOVE the observed by more than 20.** The null over-produces
  the ingredient a cycle consumes, so it bounds nothing. The run is UNGRADEABLE for the primary test
  and nothing else is read from it.
- **In BOTH directions Null B is a CHECK ONLY** (its transitivity reading and SC8) and never decides
  CYCLIC. **If IF-9 fires in a majority of an arm's floor-holding runs the verdict is INSTRUMENT
  FAILED**, because the primary null was unmatched in most of the arm; a minority is carried as the
  NULL-UNFIT label above. "Majority" here is the same majority the INSTRUMENT FAILED branch already
  uses, not a new constant.

### NULL A HAS NOW BEEN RUN ON A REAL MATRIX, AND HALF OF WHAT WAS CLAIMED FOR IT IS FALSIFIED

**This subsection exists because the DESIGN gate's round-2 RC2-4 required Null A to meet real data
BEFORE the runner is written rather than mid-experiment on the branch that decides the verdict.** A
matrix of exactly the right shape was already on disk. It has been fitted, bootstrapped and gated, and
**one half of Null A survives its own measurement and the other half does not.** Nothing below is
moved to make it come out better; the number that embarrasses the design is the finding.

Record: `programmes/p7_coevolution/exp067_coevolution_cycling/exp067_null_a_calibration.txt`, produced
by `scripts/exp067_null_a_calibration.escript` over phase 0's persisted
`exp066_competence_floor/exp066_crossplay.txt`, gated against that record and against
`exp066_within_tier_verify.txt` section K before any number is written. RNG persisted: `exsss` seeded
`{3661, 0, 0}`, which is this document's own registered Null A scheme `{3661, MatrixIndex, 0}` at
`MatrixIndex 0`, 200 draws, exported state after the last draw
`{exsss,[217753459242762793|87565821519516937]}`. Two consecutive executions give md5
`ea463cc967a61c9257336667bcd1c01e` both times, which is SC9's form applied in advance.

**ONE DEVIATION FROM RC2-4's LETTER, RECORDED HERE RATHER THAN ONLY IN THE CALIBRATION'S OWN HEADER.**
RC2-4 said "persist the record beside `exp066_residue_and_inv0.txt`", which is the exp066 directory.
Both Null A records were written to the exp067 directory instead, on the ground that they are phase 1
machinery rather than phase 0 evidence. Nothing is lost and every citation in this document resolves,
but a reader comparing the gate's wording with the tree would find the records in neither of the places
named, so the deviation is stated here (DESIGN gate round 3, landing-check finding 7).

**INDEPENDENTLY VERIFIED, and the verification is a separate implementation.**
`scripts/exp067_verify_null_a_calibration.escript` re-fits the model, recomputes every observed count
on both counters, evaluates IF-9, recomputes the tail probabilities, and adds a **CLOSED FORM with no
RNG anywhere in it**, sharing no code and no parse path with the calibration. Result:
`exp067_null_a_verification.txt`, **139 tested comparisons, 0 disagreements**, its own 200-draw
bootstrap at a deliberately different seed `{9091, 0, 0}`.

**WHAT SURVIVES: THE FIT, ITS IDENTIFICATION, AND THE FIT GATE'S WIDTH.**

| quantity | value | source |
|---|---|---|
| MM iterations to relative change below 1.0e-10 in every `s_I` | 114 of a cap of 10,000, status converged, cap not hit | calibration section B |
| identification | 1 of 380 ordered pairs has zero wins for the row, namely `{5,16}` (2005 never beat 2016 in 160 matches); raw win digraph strongly connected TRUE, so Ford's condition holds even without the prior; augmented digraph complete; fit IDENTIFIED | calibration section B, verification item 5 |
| top and bottom fitted strengths, sum normalised to 20 | 2016 at 4.19469, 2015 at 1.89879, 2020 at 1.54580, down to 2008 at 0.37488 and 2005 at 0.24105 | calibration section B and footer |
| **IF-9 at band 0.10** | median synthetic decisive edges **154.0** of 190, range 146 to 164; observed **150** on the integer counter; `median - observed = +4.0`; **fires = FALSE**; sign INFLATED | calibration section D1 |
| smallest integer width that accepts this matrix | **4** | calibration section E4 |
| the null's OWN sampling spread of the same count, `max |draw - median|` over 200 draws | **10.0** | calibration section E4 |

**THE FIT GATE WIDTH IS RE-DERIVED AND KEPT AT 20, AND THE MEASUREMENT IS THE REASON.** A width below
the null's own sampling spread of 10 would reject matrices the null itself generates; a width of 4
would accept this matrix with no slack at all. The registered 20 sits above the null's own spread and
five times above what this matrix needs. **The width is not moved, because its own measurement
supports it**, and this is the first time it has been measured against anything.

**WHAT DOES NOT SURVIVE: THE PER-RUN RATE, AND THEREFORE THE 3-OF-13 THRESHOLD'S JUSTIFICATION.**

The per-run CYCLIC count test, applied to this matrix as though it were one run's above-floor
submatrix, **fires at every band, and not marginally**:

| band | observed cycles | null min | null median | null max | exceeds max | draws below / equal | bootstrap `p` |
|---|---|---|---|---|---|---|---|
| 0.05 | 49 | 0 | 1.0 | 5 | **TRUE** | 200 / 0 | 0.004975 |
| **0.10** | **18** | 0 | **0.0** | **1** | **TRUE** | 200 / 0 | 0.004975 |
| 0.15 | 12 | 0 | 0.0 | 0 | **TRUE** | 200 / 0 | 0.004975 |

**THE HEADLINE IS THE CLOSED FORM AND NOT THE SAMPLED RATIO, WHICH IS A ROUND-3 CORRECTION (RC3-4).**
The closed form settles the size of the effect with no RNG in it: summed exactly over all 1,140 triples
from the fitted per-edge orientation probabilities, the expected number of banded 3-cycles in ONE
synthetic matrix is **1.02822896** at 0.05, **0.04797213** at 0.10 and **0.00081969** at 0.15, so
Markov's inequality alone gives `P(a null draw reaches the observed count) =< 0.02098426`, **`0.00266512`**
and `0.00006831` (`exp067_null_a_verification.txt`, DETAIL B and its judgement section). Those three
numbers do not move with a seed and they are what this document quotes as the headline.

**THE SAMPLED RATIO IS PRINTED BESIDE THEM AND IS LABELLED SEED-DEPENDENT.** At the primary band the
observed count is 18 against a sampled null maximum of 1 at seed `{3661, 0, 0}`, a factor of 18. **The
independent verification's own 200-draw bootstrap at the deliberately different seed `{9091, 0, 0}` has
a band-0.10 maximum of 2**, a factor of 9 (`exp067_null_a_verification.txt`, its bootstrap footer term).
Neither is wrong; the maximum of 200 draws is a sampled quantity and it moved by a factor of two between
the two records this document cites. The first version repeated "18 times the null maximum" three times
as a headline and did not say so. Across all 200 synthetic matrices TOGETHER the calibration's bootstrap
produced 195 cycles at band 0.05, **7** at band 0.10 and **0** at band 0.15, and 85 / 193 / 200 of the
200 draws contain no banded cycle at all. The observed matrix carries 49 / 18 / 12 in ONE matrix.

**AND THIS MATRIX CONTAINS NO COEVOLUTION.** It is 20 champions from 20 separate phase 0 arm S runs
that never met each other during evolution. **So on this substrate the count test does not, on its
own, separate coevolutionary cycling from the substrate's ordinary non-scalar structure: the second
alone passes it at all three bands.**

**NULL A IS NOT AT FAULT AND CANNOT BE DISMISSED THE WAY THE FAIR-COIN NULL WAS.** This document
rejects the fair-coin null for under-supplying the ingredient a cycle consumes. Null A does the
opposite: at band 0.10 its median count of all-three-decisive CYCLABLE triples is **611.5** against the
observed **582**, so the null has MORE cycle opportunity than the observed matrix and still produces
0.035 cycles per draw. **The shortfall is ORIENTATION, not opportunity**, which is what makes the
exceedance a real rejection of the scalar-strength model rather than an artifact of a badly matched
null. The defect is in what the DESIGN concluded from a rejection, not in the null's construction.

**THE 3-OF-13 ARITHMETIC IS CORRECT AND ITS INPUT IS WRONG.** Every number this document states is
reproduced exactly, by two independent implementations:

| quantity | recomputed | this document stated |
|---|---|---|
| `P(>=1 of 13)` at `p = 1/201` | 0.06278075655132542 | 0.0628 |
| `P(>=2 of 13)` | 0.0018615057271615762 | 0.00186 |
| `P(>=3 of 13)` | 3.392820243666039e-5 | 3.3e-5 |
| two verdict-carrying arms | 6.78552537503041e-5 | 6.7e-5 |
| three arms with a gradeable A4 | 1.0178115398018495e-4 | 1.0e-4 |

`p = 1/201 = 0.004975124378109453` is the probability that a matrix **DRAWN FROM Null A** exceeds the
maximum of 200 further Null A draws. **The event the threshold counts is a real phase 1 archive matrix
exceeding it**, and the only real matrix available exceeds it at all three bands while containing no
coevolution at all. The input rate is contradicted, so **the level `3.39e-5` per arm and `1.02e-4`
family-wise is WITHDRAWN. No level is claimed in its place.**

**RAISING `k` IS NOT THE REPAIR, AND THE ARITHMETIC SAYS SO** (calibration section E6, verification
item 6). Holding the level `3.39e-5` that 3-of-13 was advertised to buy:

| per-run rate `q` | what `q` is | smallest `k` of 13 holding the level |
|---|---|---|
| 0.004975 | the registered rate, a matrix drawn FROM Null A | **3** |
| 0.05 | Clopper-Pearson one-sided 95% LOWER bound from 1 exceedance in 1 matrix, solving `1 - (1 - q) = 0.05` | **6** |
| 1.0 | the point estimate from 1 of 1 | **none**, because `P(>=13 of 13) = 1` |

Read the last row first. At the point estimate no `k` of 13 holds the level at all. At the most
favourable reading one exceedance in one matrix allows, the threshold would be 6 of 13, and even that
is not a repair: it would require 6 of 13 phase 1 runs to be non-scalar, which the phase 0 matrix says
this substrate reaches with no coevolution in it. **One matrix cannot estimate a rate**, which is why
both `q = 1.0` and `q >= 0.05` are printed and neither is adopted as an estimate. And the bootstrap `p`
is **saturated** at its floor `(0 + 1)/201` at all three bands, so it cannot distinguish one cycle
above the maximum from eighteen times the maximum; it is read beside the raw counts, never instead of
them.

**WHAT THE PRE-REGISTRATION DOES ABOUT IT, decided here and not left open.** The calibration record
states that which reference to adopt is a design decision and does not take it; it is taken here. **Null
A REMAINS PRIMARY for the archive cycle count and the exceedance form is unchanged**, because its
rejection is a real rejection of the scalar-strength model and that is the statistic it was bound to.
What changes is that the rejection is no longer SUFFICIENT for the verdict the design was reading off
it. **PRIMARY here means "the null the count statistic is bound to", and after the change below it does
NOT mean "the leg that decides the verdict": that is leg (iii), by a factor of six to nine, and the
arithmetic is under leg (iii)'s definition (DESIGN gate round 3, RC3-4).** Two changes, and a retention
that is re-labelled rather than re-argued.

1. **A SECOND LEG IS ADDED TO THE PER-RUN CYCLIC TEST: the NO-COEVOLUTION REFERENCE SHARE.** A run's
   share of cyclable triples that are cyclic must exceed the share a real matrix of the same shape
   carries with no coevolution anywhere in it, which is phase 0's own persisted 20-champion matrix on
   the integer counter. **Computed as an EXACT INTEGER cross-multiplication so no float comparison
   decides anything**, in the same spirit as the integer band test:

   ```
   band 0.05   CYCLIC leg (iii) iff  cycles * 789 > 49 * cyclable
   band 0.10   CYCLIC leg (iii) iff  cycles * 582 > 18 * cyclable      PRIMARY
   band 0.15   CYCLIC leg (iii) iff  cycles * 487 > 12 * cyclable
   ```

   where `cycles` and `cyclable` are the run's own counts on its above-floor deduplicated submatrix.
   The reference shares those integers encode are 49/789 = 0.06210, **18/582 = 0.03093** and
   12/487 = 0.02464 (calibration section D3, gated against `exp066_within_tier_verify.txt` section K).
   **A run that passes leg (ii) and fails leg (iii) is printed as a SUB-REFERENCE EXCEEDANCE with both
   numbers and is NOT CYCLIC.**

   **THE OPERATING POINT THAT FALLS OUT OF THIS, STATED HERE BECAUSE A READER CANNOT SEE IT OTHERWISE
   (DESIGN gate round 3, RC3-4).** On a matrix of this shape leg (ii)'s bar is now trivial: the
   calibration's band-0.10 null maximum is 1 over 200 draws, so **2 cycles clears leg (ii)**. Leg (iii)
   at a comparable cyclable count needs `cycles * 582 > 18 * cyclable`, which is about **18 cycles** at
   cyclable 582 and about 13 at cyclable 400. **Leg (iii) is therefore the BINDING leg by a factor of
   six to nine, and the whole count positive rests on one unreplicated reference share measured on a
   differently-structured object, with no `p`-value and with an error direction this document itself
   declares to be toward the negative.** Null A remains PRIMARY for the archive cycle count in the
   precise sense that its rejection is what makes the count non-scalar, and that sentence may not be
   carried without this one beside it: after RC2-4 the verdict-deciding bar moved from the null carrying
   the word PRIMARY to a single measured number.
2. **THE 3-OF-13 THRESHOLD IS RETAINED AND RE-LABELLED.** It is no longer a family-wise Type I control
   at a stated level, because no level is available. It is a **WITHIN-ARM REPLICATION requirement**:
   three independent runs of one arm, each exceeding both a self-matched scalar-strength null and a
   coevolution-free reference share of the same shape. The threshold is not raised, because the
   arithmetic above shows raising it does not buy the withdrawn level back; it is not lowered, because
   nothing in the measurement argues for a weaker positive.

**WHAT LEG (iii) COSTS, AND THE DIRECTION OF ITS ERROR IS DECLARED.** The reference object spans four
measured behavioural regimes and contains the two long-standoff outliers that carry **every one** of
its within-tier cycles: remove seeds 2003 and 2013 and the within-tier count is **0 at all three
bands** over 165 triples of which 115 are still cyclable at band 0.10
(`exp066_residue_and_inv0.txt` section B). A phase 1 archive matrix is one lineage's 20 checkpoints and
may span a single regime, in which case the honest coevolution-free expectation is **closer to the
residue's zero than to 0.03093**. So leg (iii) may sit far above the coevolution-free rate for a
one-regime object, and **the direction of that error is toward the negative**: it makes a positive
harder to sign and can suppress a real one. That is the conservative direction and it is declared here
rather than discovered in the write-up. Its second limit: the reference is a single number from a
differently-structured object (independent champions, not one lineage's checkpoints), so it is a
**REFERENCE and not a null distribution**, and no `p`-value is computed from it.

**AND ITS PROVENANCE IS STATED AS PLAINLY AS ITS LIMITS: LEG (iii) IS AN AUTHOR-ADDED THIRD LEG,
INSTALLED AFTER A MEASUREMENT, THAT MOVES THE PRIMARY TEST IN THE DIRECTION OF THIS DESIGN'S OWN
HYPOTHESIS (DESIGN gate round 3, landing-check finding 2).** RC2-4 asked only that Null A and the IF-9
gate be run on the persisted matrix and that the width and the 3-of-13 arithmetic be re-derived if the
matrix fired. Adding a leg went beyond that. Three things are offered for it and the residual is named:
the mechanism it closes is MEASURED and not hypothetical (leg (ii) alone fires on a coevolution-free
matrix at all three bands, so leg (ii) alone cannot separate coevolutionary cycling from substrate
structure); the error direction is declared at the point of definition rather than found in the
write-up; and the negative is explicitly re-scoped to match the bar in "What a negative would NOT mean"
(PART 5). **The residual, unresolved: the reference object is 20 independently evolved champions
spanning four measured behavioural regimes and the thing it gates is 20 checkpoints of ONE lineage that
may span one, so the two objects are not shape-matched and no measurement in this corpus tells us by how
much.** That mismatch is a falsifier of leg (iii)'s own premise and is registered as one (PART 4).

**THE TWO REGISTERED NULLS BRACKET THE OBSERVED COUNT, so the sign of the reading is set entirely by
which one is primary.** Null A: observed 18 against a maximum of 1, far ABOVE. Null B, the orientation
null, from phase 0's persisted `exp066_crossplay_null_audit.txt`: observed 18 against a median of 151,
far BELOW. **Phase 0's three-nulls lesson therefore recurs between the two nulls this design KEPT, not
only between the ones it rejected**, and that is said here rather than left implied by the sentence at
the head of this section that calls the lesson discharged. What discharges it is not that the nulls
agree; it is that each is attached to one named statistic in advance, that the primary is fixed before
any matrix exists, and that Null B never decides CYCLIC in any circumstance.

**TWO SMALLER FACTS THE CALIBRATION SETTLED, both of which this document had assumed.**

- **THE COUNTER CHANGES THE OBSERVED DECISIVE COUNT OF RECORD FROM 152 TO 150.** Two pairs at band
  0.10, `{5,8}` and `{11,18}`, sit exactly on the band on the 160 grid and the float counter admits
  both through binary rounding at 0.10000000000000003331. Phase 1 pre-registers the integer counter, so
  the value IF-9 applies to is **150**, and the gate verdict is unchanged either way (`+4.0` on the
  integer counter, `+2.0` on the float). That is now measured rather than assumed.
- **IF-8's ORDER-VIOLATION TRIGGER IS ALREADY TIGHT, AND ITS HEADROOM IS UNKNOWN UNTIL STEP 2 (DESIGN
  gate round 3, RC3-5, correcting this bullet's first version).** At band 0.10, **26 of the 150**
  band-decisive pairs of the 190-cell champion submatrix disagree with the fitted order, and IF-8's
  trigger is more than 30 over all 300 pairs of the eventual panel. **The first version said "so 4
  violations of headroom remain for the remaining 110 pairs" and presented the 4 as measured. It is
  not.** The 26 is counted against the Bradley-Terry order fitted on the TWENTY-champion matrix; the
  panel refits over 25 members with the same MM iteration; SC3a fixes the 190 CELLS and not the fitted
  STRENGTHS; and adding five rungs changes every strength and can reorder the champions relative to each
  other. So the number of those same 190 pairs that disagree with the PANEL's order is not 26 and is not
  bounded by 26 in either direction. **What the 26 is: an INDICATOR from a different model fit, printed
  as one.** The real headroom is recomputed at panel step 2 and printed there, before any arm runs.
  **The 30 is NOT moved.** The consequence is pre-committed regardless of what the recomputation
  returns: IF-8 may well fire, in which case instrument I1 is VOID, a CYCLING verdict can only be
  SELF-RELATIVE, and the negative lands at ladder position 5b with the sub-label PANEL VOID rather than
  falling through the ladder (PART 4).

**WHAT THIS DOES NOT ESTABLISH, stated as plainly as what it does.** The phase 0 matrix is **not** an
archive matrix. Its dependence structure is 20 independently evolved champions, not 20 checkpoints of
one coevolutionary lineage, so **it is not established that phase 1 archive matrices will exceed Null
A too.** This document's own "Alternatives named and REJECTED" section describes insight 057's objects
as ten checkpoints along one monotone trajectory already known to lie on a near-total order, with a
cycle count of zero, and a within-lineage archive matrix may well sit inside Null A. What is
established is narrower and still fatal to the withdrawn arithmetic: a real matrix of exactly the
shape the test consumes, with no coevolution in it, exceeds the null at every band, so **1/201 cannot
be ASSUMED to be the rate at which phase 1 matrices trip the test.**

**ONE DISCREPANCY IN THE CALIBRATION'S OWN PROSE, recorded rather than smoothed over.** The
calibration and this document both describe Null A's prior as "one virtual win and one virtual loss
added to every ORDERED pair". The verification fitted both readings and found that the one which
reproduces the calibration's strengths to 0.0 is the **per-UNORDERED-pair** reading (`w_ij = K_ij + 1`,
`n_ij = N_ij + 2`); the per-ordered-pair reading (`w_ij = K_ij + 2`, `n_ij = N_ij + 4`) differs by
0.1006682371500549 at worst over the 20 strengths (`exp067_null_a_verification.txt`, item 1, rows
"fit: prior reading that reproduces the record" and "fit: worst |mine - claimed| over 20 strengths,
prior 2"). **The prior that is registered for phase 1 is therefore stated exactly, once, here: ONE
virtual win and ONE virtual loss per UNORDERED pair, so the augmented decisive count of a pair is
`N(I,J) + 2` and each member of the pair gains one virtual win.** No verdict in the calibration turns
on the difference (identification holds under both, since the raw win digraph is already strongly
connected), but a prior specified two ways is not specified, and phase 1 fits this model on every
matrix.

### Null B, SECONDARY and registered: the ORIENTATION NULL

Keep every observed absolute margin edge for edge, so the decisive / indecisive structure at every
band is preserved bit for bit, and randomise only the signs: one fair coin per pair decides
keep-or-swap of that pair's two integer WIN COUNTS. Exact closed form for the expectation:
(all-three-decisive triples) / 4. 200 draws, seeded.

**It must be built by swapping WIN COUNTS, never by storing a margin and its negation.** Phase 0's
`xp_from_pairs/2` stored `V` at `{I,J}` and `-V` at `{J,I}` and was then differenced again by a
win-rate operator, so every synthetic margin was DOUBLE its intended size and every band effectively
HALVED: the persisted band-0.10 row is a band-0.05 row, and correcting it reverses the sign of the
comparison. That defect is closed here by construction, before a matrix exists.

**What Null B answers and what it does not.** It answers "given edges this separated, is the
ORDERING more or less cyclic than chance". It preserves no strength structure at all, so **any
matrix carrying a dominance ordering falls far below it**, and a count below its range is therefore
evidence about the global ordering rather than evidence that a particular triple is not cyclic. That
limit is stated now so no phase 1 write-up can convert "the archive is mostly transitive" into "the
residue is not real". **Its role is exactly one thing: a transitivity check. It NEVER decides whether
a run is CYCLIC, in any circumstance, including when IF-9 fires** (DESIGN gate RC-4; the first
version made it the fallback primary, and the reason that is wrong is written into the Null A fit
gate above). Its decisive-edge count must equal the observed exactly at every band, which is what
matched means here (SC8).

### Null C, PRIMARY for the panel-inversion instrument: the ROW-PERMUTATION NULL

For one archived champion `C` against the fixed panel, restrict to the sub-panel of panel members
whose edge to `C` is band-decisive (size `n_C`, of which `C` beats `k_C`). For each band-decisive
panel pair `(P,Q)` inside that sub-panel with `P -> Q`, the triple `{C,P,Q}` is cyclic iff `C` beats
`P` and `Q` beats `C`. Hold `k_C` fixed and permute which `k_C` of the `n_C` members `C` beats,
uniformly. Then

```
E[INV(C)] = D_C * k_C * (n_C - k_C) / (n_C * (n_C - 1))
```

where `D_C` is the number of band-decisive panel pairs inside the sub-panel. Exact, closed form,
plus 200 sampled permutations for the range, seeded.

**This null is win-count-matched AND decisiveness-matched AND holds the panel's own structure fixed
bit for bit**, which is what the orientation null cannot do. It is the reference that separates the
two hypotheses directly, and its three readings are all reachable:

| INV(C) | reading |
|---|---|
| **0** | `C`'s win set is a PREFIX of the panel order. The transitive-backbone story. |
| **near E[INV]** | `C`'s win pattern is no more ordered than a random pattern of the same size, so the panel order does not describe `C`. |
| **above E[INV]** | `C`'s wins are MORE cycle-forming than a random pattern of the same strength. The specialist / counter-strategy signature. |

**THE FIRST ROW IS AN IDEALISATION AND THE PANEL'S OWN ORDER VIOLATIONS MAKE IT ONE, WHICH MATTERS
BECAUSE THE ROUND-3 REDESIGN IS TESTED ON PREFIX-SHAPED WIN SETS.** `INV(C) = 0` requires that no
band-decisive sub-panel pair `P -> Q` has `C` beating `P` while `Q` beats `C`. A prefix of a
VIOLATION-FREE order gives that exactly, because a member below the cut cannot beat one above it. The
panel's fitted order is not violation-free: 26 of 150 band-decisive pairs of the 190-cell champion
submatrix already disagree with it at band 0.10. **So a genuinely prefix-shaped win set has `INV` equal
to the number of order-violating decisive pairs that straddle its cut, which is small but not always
zero: measured on the 190-cell lower bound at band 0.10 it peaks at 11 for seed 2001, against an exact
`E[INV]` of 29.44 at the same `k_C`** (`exp067_panel_discriminator_redesign.txt` section D3). **The
reading in the row above therefore stands as a direction and not as an identity**, the quantity that
carries the decisions is the position of `INV` inside its own permutation distribution, and this is
exactly why the round-3 replacement is tested on the prefix family at every `k_C` rather than argued
from the row.

#### EVERY PANEL-READING DECISION NOW CONSUMES NULL C, AND THE FIRST VERSION COMPUTED IT AND THEN BYPASSED IT (DESIGN gate round 2, RC2-1)

**This is the round-2 gate's load-bearing finding and it is phase 0's three-nulls hole one instrument
over.** Null C was registered, specified in closed form, computed, reported, and then **every decision
that mattered consumed a RAW inversion count instead**: the CYCLING panel conjunct was
`INV_final - INV_0 >= 1` in at least 2 of the arm's cyclic runs, and the branch 6 against branch 7
discriminator was the median raw delta thresholded at 0 and 1. **The count was never the problem. The
reference was.**

**WHY A RAW DELTA IS NOT A MEASUREMENT OF WHAT THE INSTRUMENT CLAIMS TO MEASURE.** The closed form is
`E[INV(C)] = D_C * k_C * (n_C - k_C) / (n_C * (n_C - 1))`, which is maximised at `k_C = n_C / 2`.
**H3 predicts exactly the drift that inflates it**: the coevolved champions climb the panel order while
their floor-bot win rate falls, so a champion's panel win count `k_C` moves off the low end toward the
middle, and `E[INV]` rises with it **whether or not the win pattern becomes any more cycle-forming**.
The gate's worked example is this document's own table: seed 2004 starts at `k_C = 3`, `n_C = 16`,
`D_C = 95`, `E[INV] = 15.44`, `INV_0 = 9`; at a final `k_C = 8` its `E[INV]` is 25.3, so a final pattern
**MORE** ordered than random at `INV = 12` still posts a raw delta of `+3` and cleared a threshold of 1.
The threshold of 1, the least nonzero integer, sits inside the permutation spread of `INV` for every
seed, so per run the raw conjunct was close to a coin. **Two artifacts this document names separately,
backbone climbing and composition drift, were together sufficient to sign CYCLING (PANEL-VISIBLE).**

**THE TWO ROUND-2 REPLACEMENTS, both using machinery already specified above. THE FIRST SURVIVED THE
ROUND-3 GATE AND THE SECOND DID NOT; the second is printed here as the record of what round 2 landed,
and the rule that replaces it is the subsection immediately below.**

```
PANEL-VISIBLE, per run    a cyclic run counts toward the PANEL-VISIBLE sub-label iff
                          INV at its FINAL checkpoint EXCEEDS the MAXIMUM of that
                          checkpoint's own 200 Null C permutations,
                          AND INV at checkpoint 0 did NOT exceed checkpoint 0's own
                          200 Null C permutation maximum.
                          Strictly greater, both legs, at band 0.10.
                          (The arm-level count of 2 such runs is unchanged and remains
                          CHOSEN. IF-14 FLOOR-SHED still bars a run's rise from
                          counting, unchanged.)
                          LIVE. Round 3 could construct no route by which an artifact
                          satisfies this conjunct, and it is the normalisation the
                          round-3 replacement below adopts for the negative too.

BRANCH 6 vs 7 median      WITHDRAWN BY THE ROUND-3 GATE (RC3-1). It read:
  [WITHDRAWN, round 3]    the median over A1's QUALIFYING runs of
                              (INV - E[INV]) at checkpoint 20
                            - (INV - E[INV]) at checkpoint 0
                          at band 0.10, thresholded at 0. Branch 6 needs =< 0,
                          branch 7 needs > 0. E[INV] is the exact closed form at that
                          checkpoint's own n_C, k_C and D_C.
                          It is MEASURED to send a pure transitive climb to branch 7:
                          see the subsection below and
                          exp067_panel_discriminator_redesign.txt section D1.
```

**THE THRESHOLD ON THE MEDIAN WAS `=< 0` AGAINST `> 0`, NOT `=< 0` AGAINST `>= 1`, AND THAT WAS FORCED
RATHER THAN CHOSEN.** The raw delta was an integer, so `=< 0` and `>= 1` partitioned it. The centred
quantity `(INV - E[INV])` is real-valued, so `>= 1` would leave the interval `(0, 1)` in no branch and
reintroduce exactly the kind of hole the round-1 gate's RC-1 was about. The complement was taken at 0,
which kept the two branches a partition. **No constant was introduced by that change**: 0 is where the
round-1 rule already sat. **This paragraph is retained as the record of a repair that was right about
the partition and wrong about the statistic being partitioned. The round-3 replacement is an integer
COUNT, so the partition question does not arise for it at all.**

#### AND THE MEAN-CENTRED HALF OF THAT REPAIR IS ITSELF WITHDRAWN, BECAUSE SUBTRACTING A MEAN IS NOT CONDITIONING ON A COMPOSITION (DESIGN gate round 3, RC3-1)

**This is the round-3 gate's fatal finding and it is the same failure a third time, one rule over.**
Round 1 the panel conjunct was bypassed; round 2 the raw delta read composition as signal; round 3 the
mean-centred delta reads composition as signal **with a `k`-dependent sign**. The gate pre-committed the
consequence before looking: if a scenario could still be built in which "exploits cyclic pockets" and
"climbs the transitive backbone" produce the same reading, the verdict is REDESIGN. It could, and here
it is.

**THE MECHANISM.** The centred rule subtracts `E[INV]` but does not CONDITION on the realised `k_C`. For
a win pattern that stays close to prefix-shaped, `INV` is pinned near 0 at both ends, so the difference
collapses to

```
(0 - E_20) - (0 - E_0)  =  E_0 - E_20
```

which carries no arrangement information at all. `E[INV] = D * k * (n - k) / (n * (n - 1))` is a
downward parabola in `k` with its peak at `k = n / 2`, so the SIGN of that difference is set entirely by
where `k_C` moved relative to `n_C / 2`. **H3 predicts the population climbs the panel**, which is
exactly the move that takes `k_C` away from the middle and drives the difference positive. The rule
therefore sends the transitive-backbone story to branch 7, whose pre-committed reading asserts the
opposite of what that champion did.

**MEASURED, NOT ARGUED, FROM DATA ALREADY ON DISK.** Take the climb in its limit form: the lineage ends
beating EVERY band-decisive panel member, `k_C = n_C`. Then no panel member beats it, so no inversion
triple can exist and `INV_20 = 0`; and the permutation distribution at `k = n` is a point mass at 0, so
`E_20 = 0` and the centred value at checkpoint 20 is exactly 0. The withdrawn rule's value is then
exactly `E_0 - INV_0`, which needs no assumption about the trajectory in between and is computable today
from the `INV_0` table below. Record:
`programmes/p7_coevolution/exp067_coevolution_cycling/exp067_panel_discriminator_redesign.txt` section
D1, produced by `scripts/exp067_panel_discriminator_redesign.escript`, no RNG anywhere in it, md5
`686d59647c96da380b54a5821e081b3c` on two consecutive executions, gated against `exp066_crossplay.txt`,
`exp066_residue_and_inv0.txt` section C (60 of 60 per-champion rows AGREE) and
`exp067_null_a_calibration.txt` (the fitted strengths and their own order-violation counts) before any
number is written.

| band | the withdrawn rule's value on the total climb, over the 13 seeds | median | seeds sent to branch 7 |
|---|---|---|---|
| 0.05 | +0.3529 to +29.2941 | **+18.3750** | **13 of 13** |
| **0.10** | **0 for the two degenerate seeds, +6.4375 to +26.5625 for the other eleven** | **+15.6000** | **11 of 13** |
| 0.15 | 0 for two, +5.0714 to +23.5000 for eleven | **+13.1333** | **11 of 13** |

**So under the design's own modal world, H1 archive-transitive and H3 panel-climbing, branch 6 NO
CYCLING is unreachable and the verdict is branch 7, whose reading is provably false for that champion.**
And a genuine specialist that inverts panel cells with no count positive lands in the same branch 7. Two
opposite mechanisms, one reading. That is the conflation this experiment exists to resolve, decidable in
the wrong direction, inside the rule that decides the negative.

**THE IF-14 FILTER DOES NOT RESCUE IT.** The panel order is roughly orthogonal to floor competence
(Spearman rho -0.1451, H3), so a run can climb the panel while holding its floor-bot win rate within
0.25 of its checkpoint-0 value, qualify under the RC2-2 filter, and post a positive value anyway.

**AND THE ABSORPTION ARGUMENT BELOW WAS TRUE OF THE EXCEEDANCE LEG AND WAS SILENTLY EXTENDED TO THE
MEDIAN, WHERE IT IS FALSE.** The paragraph now headed "WHY THE EXCEEDANCE RULE CANNOT BE SATISFIED BY
COMPOSITION DRIFT ALONE", which was headed "WHY THE NORMALISED RULE ..." until round 3 rescoped it,
says "the quantity `E[INV]` peaking at `k = n/2` is the artifact; conditioning on `k_C` is
what removes it". Conditioning is what the EXCEEDANCE leg does: it scores `INV` against the distribution
of `INV` over the `C(n_C, k_C)` win sets of exactly that size. Subtracting the mean is not that.
Subtracting a mean absorbs the mean's drift only if the statistic tracks the mean, and a prefix-shaped
pattern does not track it at all. **That argument keeps its full force for the exceedance leg, where it
was made, and it is withdrawn for the median, where it was never true. The paragraph below is therefore
read as a statement about the exceedance leg only, and it says so at its head.**

**THE REPLACEMENT, AND IT IS A CHANGE OF SHAPE RATHER THAN A THIRD PATCH TO THE SAME SCALAR.** The
negative's panel discriminator stops being a real-valued scalar of centred counts and becomes the
positive's own conjunct, evaluated over the negative's own base. One normalisation, used everywhere.

```
BRANCH 6 vs 7 COUNT       the number of A1's QUALIFYING runs whose INV at the
(LIVE, round 3, RC3-1)    FINAL checkpoint EXCEEDS the MAXIMUM of that checkpoint's
                          own 200 Null C permutations, AND whose INV at checkpoint 0
                          did NOT exceed checkpoint 0's own 200-permutation maximum.
                          Strictly greater, both legs, at band 0.10.
                          Branch 6 NO CYCLING needs FEWER THAN 2 such runs.
                          Branch 7 PANEL-INVERTED needs 2 OR MORE.

                          This is character for character the PANEL-VISIBLE conjunct
                          of the positive, with the same 200 draws, the same
                          strictness, the same band and the same count of 2, read
                          over A1's QUALIFYING runs instead of over the arm's CYCLIC
                          runs. NO NEW CONSTANT: the 2 is the one already registered
                          and named as CHOSEN in the constants table, and the
                          exceedance level is the null's own maximum over the
                          registered 200 draws.

QUALIFYING, extended      a run QUALIFIES for the branch 6 / 7 base iff IF-1 did not
(RC2-2 filter + RC3-1)    fire on it, IF-14 FLOOR-SHED did not fire on it, AND
                          NEITHER its checkpoint-0 NOR its final-checkpoint Null C is
                          DEGENERATE (k_C = 0 or k_C = n_C, so the permutation
                          distribution is a point mass at 0).
                          A DEGENERATE checkpoint contributes to NEITHER branch.
                          Below 7 of 13 qualifying runs the reading is 5b PANEL BASE
                          ERODED, unchanged.
```

**WHY THE DEGENERACY CLAUSE IS PART OF THE RULE AND NOT A FOOTNOTE.** Under the withdrawn median a
degenerate checkpoint fed an exact 0 into the median, and 0 satisfies `=< 0`, so a run the panel
instrument could not read in either direction counted toward the design's own modal expectation. That is
the RC2-2 defect one mechanism over, and it was already live: **two of the 13 seeds, 2002 and 2005, are
degenerate at checkpoint 0 at band 0.10 on the champion-only lower bound, and three of the 20 panel
champions are** (2002, 2005 and 2015; 1 of 20 at band 0.05 and 3 of 20 at band 0.15,
`exp067_panel_discriminator_redesign.txt` section D4). Excluding them from the base rather than counting
them toward branch 6 routes the case to 5b, which is where an unreadable panel already belongs.

**THE REPLACEMENT IS TESTED, NOT ASSERTED, AND THE TEST IS PRE-REGISTERED AS SC15.** Two dispositions on
the same total climb, either of which alone suffices:

1. **The terminal checkpoint is DEGENERATE** (`k_C = n_C`), so the run is excluded from the qualifying
   base and contributes to neither branch.
2. **Even with the degeneracy clause switched off**, `INV_20 = 0` and the permutation maximum at
   `k = n` is 0, and the test is STRICTLY greater, so the climb does not exceed and contributes 0 toward
   branch 7's count of 2.

**AND THE WHOLE CLIMB IS CHECKED, NOT ONLY ITS LIMIT** (`exp067_panel_discriminator_redesign.txt`
section D3). For every one of the 20 champions, at every band, at every `k_C` from 0 to `n_C`, the
ORDER-CONSISTENT win set of that size was constructed against the panel's own fitted Bradley-Terry order
and `INV` counted exactly, then compared with the exact `E[INV]` at the same `k`. **The largest value of
`INV_prefix(k) - E[INV](k)` anywhere over all 20 champions, all three bands and every non-degenerate `k`
is -2.5556**, so a backbone climber sits at least two and a half inversions BELOW its own exact mean even
at its best point, and a value at or below the mean cannot be above the maximum. The exceedance leg
therefore cannot fire at any point of any champion's backbone climb, and that is proved without drawing
a single permutation. At band 0.10 the climb's largest inversion count is 11, for seed 2001, against an
exact mean of 29.44 at the same `k`.

**AND THE CONTRAST IS COMPUTED IN THE SAME PASS, SO THE RESULT IS NOT AN ARTIFACT OF A STATISTIC THAT
CANNOT MOVE.** A test that no arrangement can satisfy would give the same table. The ANTI-CONSISTENT win
set of size `k`, the `k` STRONGEST members of the sub-panel rather than the `k` weakest, is the maximally
inverted arrangement the panel order admits, and it goes the other way hard: **the largest
`anti_INV(k) - E[INV](k)` is +37.1046, and the anti-consistent set exceeds its own exact mean in 60 of
60 champion-and-band cases** (`exp067_panel_discriminator_redesign.txt` section D3). At band 0.10 seed
2001's anti-consistent peak is `INV = 62` against the same mean of about 30, where its prefix peak is 11.
**So `INV` is not bounded above by its own mean as a matter of arithmetic, the exceedance leg is not
identically unsatisfiable, and the prefix result above is a fact about PREFIX ARRANGEMENTS rather than
about the statistic.** Exceeding the mean is necessary and not sufficient for exceeding the
200-permutation maximum, so this does not establish that the leg fires on the anti-consistent
arrangement; what it establishes is that the direction of the prefix construction is the load-bearing
one and that the test discriminates.

**WHAT THE REPLACEMENT COSTS, DECLARED IN THE SAME BREATH AS WHAT IT BUYS.** It ties the negative's panel
conjunct to a leg whose reachability on real win patterns is unevidenced, which is the round-3 gate's
RC3-6 and is answered in "CAN A REAL WIN PATTERN EXCEED ITS OWN NULL C MAXIMUM" below. Under the
withdrawn median branch 7 fired easily and wrongly; under the replacement it may fire rarely, and if it
fires rarely because no real pattern can reach the reference then branch 6's panel conjunct is close to
automatic and carries little information. **That is a limitation on the NEGATIVE and it is labelled on
the negative**, rather than repaired by loosening the reference. The measurement that decides it is free
at panel step 2 and both readings are pre-committed there.

**WHY THE EXCEEDANCE RULE CANNOT BE SATISFIED BY COMPOSITION DRIFT ALONE. THIS PARAGRAPH IS ABOUT THE
EXCEEDANCE LEG AND ABOUT NOTHING ELSE, WHICH IS THE ROUND-3 CORRECTION TO ITS SCOPE (RC3-1).** It was
written as an argument about "the normalised rule" and was then read as covering the mean-centred median
too, where it is false. Both branch decisions now consume the exceedance leg, so the paragraph covers
both, but it covers them BECAUSE they are the same leg and not because subtracting a mean was ever the
same operation. Null C **conditions on the composition** at the checkpoint being evaluated. It holds `k_C` fixed, holds `n_C` fixed by
construction (the sub-panel IS the set of panel members whose edge to `C` is band-decisive), holds the
frozen panel's own `D_C` decisive pairs fixed bit for bit, and permutes only **which** `k_C` of the
`n_C` members `C` beats. So:

- **`k_C` drift is absorbed.** The reference is the distribution of `INV` over the `C(n_C, k_C)` win
  sets of exactly that size. A champion whose win set moves toward the middle takes its null's maximum
  up with it, so a rise that is no more than a random pattern of the new size would give does not
  exceed the new maximum. The quantity `E[INV]` peaking at `k = n/2` is the artifact; conditioning on
  `k_C` is what removes it.
- **`n_C` drift is absorbed**, by the same conditioning. A champion that becomes decisive against more
  or fewer panel members is scored against the null for the sub-panel it actually has.
- **`D_C` drift is absorbed.** The panel is FROZEN before any run, so `D_C` moves only through
  sub-panel membership, which is `n_C`.
- **THE QUASI-SELF-PLAY DRIFT IS ABSORBED TOO, and the gate asked for this to be said explicitly rather
  than left as subsumed (blind spot 2).** Each run's panel contains its own seed, so at early
  checkpoints the champion's cell against that seed is a near-self-play cell, mostly indecisive, which
  keeps it OUT of the sub-panel and holds `n_C` down; as the lineage moves away from its seed that cell
  becomes decisive and `n_C` rises with checkpoint index. That is a third composition drift with
  checkpoint index, and a raw delta reads it as signal. Conditioning on the realised `n_C` at each
  checkpoint removes it in exactly the same way as the other two.

**What remains to exceed the maximum is the ARRANGEMENT of the win set against the panel's own
decisive-pair structure, which is the only thing `INV` was ever supposed to measure.** The checkpoint-0
leg is a second condition in the conservative direction: a run whose SEED already exceeded its own maximum
cannot contribute, so a pocket the population started in cannot be counted as a pocket it entered.

**AND THE RATE THIS BUYS IS STATED WITH THE SAME CAUTION RC2-4 FORCED ON NULL A, BECAUSE THE TEMPTATION
IS IDENTICAL.** Under Null C the final-checkpoint leg fires with probability at most 1/201 per champion,
and **that is a TYPE I statement about a win pattern DRAWN FROM Null C, not an estimate of the rate at
which a real coevolved champion's win pattern exceeds it.** Null A's 1/201 was used as the second when it
was only ever the first, and nothing in this document estimates the second for Null C either: no
coevolution-free reference exists for the panel instrument, because the only champions ever scored
against this panel are the panel's own members and the phase 1 checkpoints.

**THE ASYMMETRY THIS PARAGRAPH USED TO CLAIM IS FALSE ABOUT THIS DESIGN'S OWN LADDER, AND THE ROUND-3
GATE WAS RIGHT (RC3-2).** It read: "What limits the damage here is that the panel conjunct is not the
headline on its own: it only ever splits an already-established count positive into PANEL-VISIBLE and
SELF-RELATIVE, so an over-firing panel leg cannot manufacture a positive from nothing, it can only
mislabel one. That asymmetry is the reason no leg (iii) analogue is registered for Null C." **The first
sentence is true of branch 2 and false of branches 6 and 7**, where the panel leg alone decides whether
the negative may be signed at all: 2 or more exceedances among A1's qualifying runs blocks NO CYCLING
outright and lands PANEL-INVERTED. So an over-firing panel leg CAN do damage, and the damage it does is
to the negative.

**WHAT REPLACES THE ASYMMETRY, AND IT IS THREE MEASURED OR PRE-COMMITTED THINGS RATHER THAN AN
ARGUMENT.** First, one normalisation is used on both sides (RC3-1), so an over-firing or under-firing
leg fires the same way for the positive and for the negative and cannot be tuned to favour either.
Second, the degeneracy exclusion keeps unreadable checkpoints out of both branches rather than letting
them default into one. Third, **the reachability of the leg on real win patterns is MEASURED at panel
step 2 and both readings are pre-committed there**, which is the nearest thing to a leg (iii) analogue
the panel instrument admits: it is not a coevolution-free null distribution, it is 25 real
coevolution-free win patterns scored against the same reference the phase 1 checkpoints will be scored
against. **What is still missing, and is stated as missing rather than argued away: there is no
coevolution-free reference SHARE for the panel instrument and no `p`-value from it.**

#### CAN A REAL WIN PATTERN EXCEED ITS OWN NULL C MAXIMUM? THE DATA ON DISK SAYS NO, FOR ALL 20 (DESIGN gate round 3, RC3-6)

**RC2-4's lesson applied to the other instrument, before the arms run, because the measurement is free.**
Null A's `1/201` was a Type I statement about a matrix drawn FROM Null A and was used as though it were
the rate at which real matrices trip the test; measurement contradicted it. Null C's `1/201` is exactly
the same kind of statement, and the same question can be asked of it on the only real win patterns that
exist: phase 0's 20 arm S champions, which come from 20 separate runs that never met during evolution
and are therefore coevolution-free by construction.

**The answer available today is uncomfortable and it is recorded as such.**
`exp067_panel_discriminator_redesign.txt` section D4, on the 190-cell champion-only lower bound:

| band | champions whose `INV` is ABOVE their own exact `E[INV]` | so champions that could exceed their own permutation MAXIMUM | DEGENERATE champions |
|---|---|---|---|
| 0.05 | **0 of 20** | at most 0 of 20 | 1 of 20 |
| **0.10** | **0 of 20** | **at most 0 of 20** | 3 of 20 |
| 0.15 | **0 of 20** | at most 0 of 20 | 3 of 20 |

A value at or below the mean cannot be above the maximum, so this bounds the exceedance count without
drawing a permutation. **On the data that exists, the exceedance leg fires for ZERO of 20 real
coevolution-free champions at every band.**

**WHAT THAT DOES AND DOES NOT LICENSE.** It does NOT establish that the leg is unreachable: the 190-cell
matrix is a LOWER BOUND on the 25-member panel, the five scripted rungs add triples that move `INV` and
`E[INV]` both, and a coevolved champion is not one of these twenty. It DOES establish that the corpus
contains no example of any real win pattern reaching this reference, which is the opposite of the
situation Null A was in (where a real matrix cleared the reference at all three bands). **So the two
instruments' failure directions are opposite and both are now declared: Null A's per-run leg fires too
easily on this substrate, and Null C's exceedance leg may fire too rarely.**

**PRE-COMMITTED AT PANEL STEP 2, BOTH READINGS, BEFORE ANY ARM RUNS.** Each of the 25 panel members is
scored against its own 200 Null C permutations at every band and the result is printed.

- **If ANY of the 25 exceeds its own maximum**, the "at most `1/201` per champion" Type I story for
  PANEL-VISIBLE is dead in exactly the way Null A's `1/201` died on the phase 0 matrix, the fact is on
  the page before any arm runs, and every panel reading carries the label **PANEL LEG UNCALIBRATED**.
- **If NONE of the 25 does**, the record states plainly that the corpus contains zero examples of a real
  win pattern exceeding this reference and that PANEL-VISIBLE's reachability is UNEVIDENCED. Both the
  positive's PANEL-VISIBLE sub-label and the negative's branch 6 panel conjunct then carry the label
  **PANEL LEG UNREACHED ON REAL PATTERNS**, and the negative's scope section says that its panel
  conjunct may be close to automatic. **A true positive may in that case be systematically degraded to
  SELF-RELATIVE, which is the opposite failure to the one round 2's repair risks, and it is named here
  rather than discovered in the write-up.**

Neither reading moves a threshold, and neither is a condition on running the arms.

**THE PRE-MEASURED `INV_0` VALUES SAY THE SECOND LEG WILL HOLD FOR EVERY SEED, WHICH IS WORTH KNOWING
BEFORE THE RUN.** In the table below, at band 0.10, **eleven of the 13 seeds have `INV_0` strictly and
far BELOW their own `E[INV]`** (the closest case is seed 2004 at 9 against 15.44; seed 2001 is 5 against
24.85), **and the other two, seeds 2002 and 2005, are DEGENERATE at `k_C = 0` with `INV_0 = 0` and
`E[INV] = 0.00`, which is EQUAL and not below.** The first version of this sentence said "every one of
the 13 seeds", and that universal is false for those two (DESIGN gate round 3, RC3-7d). The conclusion
survives for them by the degeneracy argument two paragraphs down rather than by this one: at `k_C = 0`
the permutation maximum is 0 and `INV_0` is 0, and the test is strict, so the checkpoint-0 leg holds
there too. A value below the mean cannot be above the maximum, so **the checkpoint-0 leg is expected to
hold for all 13 seeds and the binding leg is the final checkpoint's**. That is a prediction from data on disk, not an
assumption: the 25-member panel measurement at step 2 of the protocol (PART 3) computes each seed's actual permutation maximum
and prints it, and if any seed's `INV_0` does exceed its own maximum that run cannot contribute to
PANEL-VISIBLE and the fact is printed.

**ONE DEGENERATE CASE IS NAMED RATHER THAN LEFT TO BE DISCOVERED.** When `k_C = 0` or `k_C = n_C` the
permutation distribution is a point mass at 0, `E[INV] = 0`, and the maximum is 0, so `INV` cannot
exceed it and the run cannot contribute to PANEL-VISIBLE at that checkpoint. **Two of the 13 seeds are
already in that state at band 0.10 on the champion-only lower bound**: seed 2002 and seed 2005 both have
`k_C = 0`, meaning each beats NO band-decisive panel member. Their `INV` can only become readable if the
lineage starts beating panel members. This is a real limit on the panel instrument's per-run coverage,
it is measured in advance, and the count of degenerate champion-checkpoints is a required report.

**AND THE DEGENERATE CASE IS NOW A RULE ON BOTH BRANCHES AND NOT ONLY ON THE POSITIVE (DESIGN gate round
3, RC3-1).** Naming it was not enough: the withdrawn branch 6 / 7 median took a degenerate checkpoint's
exact 0 and counted it toward `=< 0`, which is branch 6 NO CYCLING, so a checkpoint the instrument could
not read in either direction voted for the design's own modal expectation. **A DEGENERATE checkpoint now
contributes to NEITHER branch**, and a run whose checkpoint 0 or whose final checkpoint is degenerate is
excluded from the branch 6 / 7 qualifying base outright, which routes it to ladder position 5b PANEL
BASE ERODED when too many are excluded rather than into a verdict. Three of the 20 panel champions are
degenerate at band 0.10 (2002, 2005 and 2015), one at 0.05 and three at 0.15
(`exp067_panel_discriminator_redesign.txt` section D4); the 25-member panel measurement at step 2 of the
protocol (PART 3) supersedes those counts.

### Alternatives named and REJECTED in advance

- **A fair-coin-per-match null.** Rejected. It describes T equally strong players, so it
  under-supplies exactly the ingredient a cyclic triple consumes: at band 0.10 it leaves roughly 44
  decisive edges of 190 against **150** observed in phase 0's matrix, so it cannot bound the observed
  count in EITHER direction. (**The first version wrote 152 here**, which is the float counter's value;
  the counter of record is the integer one and its value is 150, as this section already states two
  paragraphs above. Corrected by DESIGN gate round 3, RC3-7c. The rejection is unchanged either way.) It is also the null whose scaling defect produced two opposite readings
  of the same data in phase 0.
- **The analytic all-decisive coin null, `C(T,3)/4` cycles and `3*C(T,3)/8` ordered.** Rejected as a
  reference for a BANDED count: every edge is decisive by construction, so it is not band-matched to
  anything and comparing a banded count against it is a category error. It is reported once as an
  arithmetic upper reference and never used as a test.
- **Comparison with insight 057's zero.** Rejected as a test. It is a count over 10 objects and 45
  pairs, its objects are ten checkpoints along ONE monotone trajectory and were already known to lie
  on a near-total order, it is a MEDIAN over runs rather than a single count, and its cells are
  cross-role. If a comparison is wanted it is made on the share of cyclable triples, and it is
  labelled as an object-set comparison, not a substrate comparison.
- **Elo or any scalar rating as an instrument.** Rejected per the plan. The Bradley-Terry fit here is
  a NULL MODEL used to generate synthetic matrices. It is not adopted as a rating, no champion is
  ordered by it for any decision, and the panel's dominance order (which IS derived from it) is used
  only as the axis inversions are counted against, with the order's own internal violations reported.

---

## The two instruments, sharpened

The unsigned note names two instruments. Both need sharpening before they are measurable.

### Instrument I1: is the population INSIDE the cyclic pockets, or outside them?

As the note states it, "whether the population's occupied region of the matrix lies inside the
all-three-decisive cyclic triangles or outside them" is **not measurable**, because if the matrix is
built from the population then the cycles counted in it ARE the occupied region by construction and
there is no outside.

**Sharpened: a FIXED REFERENCE PANEL whose cyclic structure is measured ONCE and FROZEN before any
coevolution run, and each archived champion is scored against it.** Membership in a cyclic triangle
then has meaning: `C` occupies a pocket when `{C,P,Q}` is cyclic for some band-decisive panel pair
`(P,Q)`. Counted as `INV(C)` against Null C above.

**AND OCCUPANCY AT CHECKPOINT 0 IS NOT NEWS, because the seeds are already in it.** Nine of the 13
seeds have `INV_0 >= 1` at band 0.10 (table below), so "the population is inside a pocket" is TRUE of
most runs before a single evaluation is spent. The instrument's question is therefore never an absolute
count, and no phase 1 write-up may report pocket occupancy as a result.

**BUT IT IS NOT A RAW DIFFERENCE EITHER, AND THE FIRST VERSION SAID IT WAS.** This paragraph used to
read "the instrument's question is therefore always a DIFFERENCE, `INV` at the final checkpoint against
`INV` at checkpoint 0". A raw difference of two counts drawn under two different compositions confounds
the arrangement of the win set with the SIZE of the win set, and the size is what H3 predicts will
move. **The question is a difference against NULL C at each end**: whether `INV` exceeds its own
composition-matched permutation maximum at the final checkpoint while it did not at checkpoint 0, and,
for the arm-level median, the change in the CENTRED quantity `INV - E[INV]`. Both forms and the reason
are in "Every panel-reading decision now consumes Null C" above (DESIGN gate round 2, RC2-1).

Two properties make this the load-bearing instrument rather than a decoration:

- **It has a pre-measured baseline per run.** Each of the 13 run seeds IS a panel member, so its own
  `INV` is known from the panel matrix before the run starts. The question "did the population move
  into a pocket" is then answered by a trajectory with a known origin, not by an absolute count.
- **It is robust to UNIFORM competence loss.** A champion that gets uniformly weaker beats fewer panel
  members but its win set stays a PREFIX, so `INV` stays where it was. `INV` rises when the champion
  beats a strong panel member while losing to a weak one. **That is the specialisation signature OR a
  competence loss along an axis the panel order does not describe**, and the two are not separated by
  `INV` alone: the panel's own order is roughly orthogonal to floor competence (H3), so shedding floor
  competence can itself invert panel cells. The first version of this section said `INV` rises are
  "the specialisation signature and nothing else", which overstates what Null C controls for; the
  DESIGN gate's blind spot 5 is answered by **IF-14 FLOOR-SHED**, which labels an `INV` rise that
  co-occurs with a large drop in floor-bot win rate.

**AND THE CYCLING VERDICT CONSUMES THIS INSTRUMENT (DESIGN gate RC-2).** The first version defined
outcome 1 with two conjuncts and then implemented only the first in the decision rule (PART 4), so a positive
could be signed with `INV = 0` at every checkpoint, meaning with zero evidence that the population
entered any pocket. The panel conjunct is now in the CYCLING branch and the split label
PANEL-VISIBLE / SELF-RELATIVE is mandatory. **Round 2 of the gate then found that the conjunct
consumed a raw count rather than the null registered for it, which is repaired by RC2-1 above.**

Reported per run: `INV` at checkpoint 0 (the seed, known in advance and printed below), the trajectory
over the 20 checkpoints, the median, the final value, and **at EVERY checkpoint** `n_C`, `k_C`, `D_C`,
the exact `E[INV]`, the 200-permutation minimum, median and **MAXIMUM**, whether `INV` exceeds that
maximum, and the centred value `INV - E[INV]`. Also reported: `final minus checkpoint-0` in BOTH the raw
and the centred form with a sign test over the 13 runs, so the two quantities earlier versions would
have decided on stay visible beside the one that now decides; the count of checkpoints whose Null C is
DEGENERATE (`k_C = 0` or `k_C = n_C`, permutation distribution a point mass at 0); and whether each run
QUALIFIES for the arm-level branch 6 / 7 base under the extended filter (IF-1 did not fire, IF-14 did not
fire, and neither checkpoint 0 nor the final checkpoint is DEGENERATE). **The withdrawn centred median
is itself now a reported-only quantity** (DESIGN gate round 3, RC3-1): it is printed per run and as an
arm median so that the quantity round 2 would have decided on stays visible beside the exceedance count
that now decides, exactly as round 2 kept the raw delta visible beside it.

### The 13 seeds' `INV` at checkpoint 0, COMPUTED BEFORE ANY RUN, from data already on disk

The DESIGN gate's RC-3 pointed out that this table was computable at authoring time and had not been
computed, while the decision rule (PART 4) contained an ABSOLUTE condition (`INV = 0`) that it might already
contradict. It does contradict it. Reproducible from
`programmes/p7_coevolution/exp066_competence_floor/exp066_residue_and_inv0.txt` section C, produced by
`scripts/exp066_residue_and_inv0.escript` over `exp066_crossplay.txt`, with no RNG (Null C's closed
form is evaluated exactly, so there is no seed to persist) and with three gates against the persisted
records before any number is written.

| run | seed | `INV_0` at 0.05 | **`INV_0` at 0.10** | `INV_0` at 0.15 | `n_C` | `k_C` | `D_C` | `E[INV]` at 0.10 |
|---|---|---|---|---|---|---|---|---|
| 1 | 2001 | 6 | **5** | 3 | 18 | 5 | 117 | 24.85 |
| 2 | 2002 | 7 | **0** | 0 | 15 | 0 | 93 | 0.00 |
| 3 | 2003 | 16 | **6** | 5 | 17 | 8 | 105 | 27.79 |
| 4 | 2004 | 13 | **9** | 3 | 16 | 3 | 95 | 15.44 |
| 5 | 2005 | 1 | **0** | 0 | 16 | 0 | 89 | 0.00 |
| 6 | 2006 | 5 | **1** | 1 | 16 | 6 | 105 | 26.25 |
| 7 | 2008 | 0 | **0** | 0 | 16 | 2 | 92 | 10.73 |
| 8 | 2010 | 9 | **3** | 3 | 14 | 10 | 78 | 17.14 |
| 9 | 2012 | 3 | **1** | 1 | 16 | 9 | 105 | 27.56 |
| 10 | 2013 | 9 | **5** | 5 | 15 | 8 | 84 | 22.40 |
| 11 | 2017 | 14 | **2** | 2 | 15 | 10 | 88 | 20.95 |
| 12 | 2019 | 2 | **0** | 0 | 15 | 3 | 91 | 15.60 |
| 13 | 2020 | 6 | **4** | 3 | 15 | 11 | 83 | 17.39 |

**Median `INV_0` over the 13 seeds: 6 at band 0.05, 2 at band 0.10, 2 at band 0.15. Nine of thirteen
seeds start with `INV_0 >= 1` at the primary band; four start at 0.** So the condition "the median A1
run's `INV = 0` at band 0.10", which the first version put inside NO CYCLING, was **unreachable
unless coevolution DROVE the median inversion count DOWN to zero**, which is a different and much
stronger claim than the one the negative was meant to make. It is replaced by the relative form in the
decision rule (PART 4), and H1 (PART 5) is restated to match.

**Two scope facts about this table, both stated rather than buried.** First, it is a **LOWER BOUND**:
only the 190 champion-versus-champion cells of the 25-member panel exist on disk, SC3a forces the
phase 1 panel to reproduce them cell for cell, the 5 scripted rungs can only ADD triples, and the
gunless-leg exclusion removes nothing here because neither `sitting_duck` nor `spinner` is in this
matrix. The panel measurement at step 2 of the protocol (PART 3) supersedes it with the full 25-member value, and the sign of
the difference is known in advance: up or equal, never down. Second, **eleven of the thirteen seeds'
`INV_0` is far below its own `E[INV]`** (5 against 24.85, 6 against 27.79, and so on), so these win
patterns are much closer to prefix-shaped than to random; **the remaining two, 2002 and 2005, are
DEGENERATE at `k_C = 0` with `INV_0 = 0` against `E[INV] = 0.00`, which is equal.** (The first version
said "every seed's", a universal its own table two rows up contradicts: DESIGN gate round 3, RC3-7d.)
That is H1's direction. What it is not is zero. **And it is also what makes the checkpoint-0 leg of the
PANEL-VISIBLE conjunct expected to hold for all 13 seeds**, for the eleven because a value below the
permutation mean cannot be above the permutation maximum, and for the two degenerate seeds because the
maximum is 0, `INV_0` is 0 and the test is strict. Both are set out in "Every panel-reading decision now
consumes Null C" and measured for real at panel step 2 of the protocol (PART 3).

### Instrument I2: does a champion that lost the throne ever REGAIN it against a LATER opponent?

Sharpened into two counts over the run's own time-ordered archive matrix.

```
BACKWARD EDGE   a band-decisive pair (t, u) with t < u that the EARLIER champion wins.
                Reported as a SHARE of band-decisive time-ordered pairs.
RETURN TRIPLE   a triple (t, u, v) with t < u < v, all three edges band-decisive,
                C_u beats C_t (the throne is lost) and C_t beats C_v (regained against a later
                opponent). Two edges constrained, so returns are a superset of cycles.
```

**The backward-edge share ALONE cannot distinguish the two stories and is not read alone.** A run
that simply got worse would show many backward edges and remain perfectly transitive. So I2 is read
jointly with the primary count, and the table is pre-committed. **It has SIX cells, not four: the
first version's two columns were "at or below the Null A median" and "above the Null A maximum",
which left the whole band between median and maximum, the most likely single outcome, in no cell of
a table labelled pre-committed** (DESIGN gate RC-9c).

| backward-edge share | cyclic count vs Null A | pre-committed reading |
|---|---|---|
| below 0.10 | at or below the Null A median | **Monotone climb on a transitive backbone.** Insight 057's dominance pattern (later beats earlier 24-29 to 0-1) reproduced in a materially different substrate. |
| 0.10 or above | at or below the Null A median | **Non-monotone progress, still transitive.** The run regressed or drifted along one axis. NOT cycling, and it must not be reported as cycling. |
| below 0.10 | above the median, not above the maximum | **Not separable from a fitted scalar strength.** The count is inside the range a scalar model produces, so no intransitivity claim is available in either direction; the low backward-edge share is read as a statement about the time axis alone. |
| 0.10 or above | above the median, not above the maximum | **Not separable from a fitted scalar strength, with returns along the time axis.** Same as the row above on intransitivity. The returns are reported, and they do not license a cycling claim. |
| below 0.10 | above the Null A maximum | **Cycles between contemporaries, not along the time axis.** Pockets exist in the occupied region but the Red Queen does not return. |
| 0.10 or above | above the Null A maximum | **The pocket-exploitation signature: returns AND intransitivity.** This cell licenses the phrase "pocket exploitation" ONLY when the CYCLING branch's panel conjunct also holds, i.e. under CYCLING (PANEL-VISIBLE). Under CYCLING (SELF-RELATIVE) the same cell is reported as returns and intransitivity among the run's own checkpoints, with no pocket claim. |

`0.10` is a chosen constant and is named as chosen. It is 19 of the 190 pairs, and at band 0.10 each
backward edge carries at least 17 matches of separation, so the constant is not carrying the weight
a threshold on a noisy quantity would.

---

