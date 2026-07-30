> Part 6 of 6 of the [EXP-067 pre-registration](exp067_coevolution_cycling.md). The root holds the framing, the status and the section index.

# EXP-067 PART 6. The DESIGN gate record, all three rounds, and the Result

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all nine changes applied above

The gate did not find the design circular and did not ask for a redesign. It recorded as clean, and
these are noted because a gate that only complains is not calibrated: the integer counter with its tie
rule in prose and the bands separable at 160 matches per cell; Null A decisiveness-gated, registered, and
argued against four named alternatives; scale comparisons made on shares of cyclable triples;
pseudoreplication handled with runs as the unit and the family-wise arithmetic shown; compute derived
rather than asserted, with the borrowed 0.625 match-length factor flagged and a superseding pilot
pre-registered; the under-convergence confound genuinely closed for the seeded arms; the seeding decision
argued with both biases declared and both labels pre-committed; the scope section forbidding the progress
and open-endedness overclaims; and H1 through H4 (PART 5) embarrassable with named falsifiers.

**What it did find was that the DECISION MACHINERY had holes that data already on disk could exploit.**
Two combinations of results landed in no verdict, the CYCLING rule dropped a conjunct its own outcome
definition asserted, the NO CYCLING branch contained an absolute-zero condition that the persisted matrix
already contradicted, and the IF-9 fallback rebuilt the three-nulls hole phase 0 paid for. None needed a
redesign and all nine changes are applied in place.

### The nine required changes and where each landed

1. **RC-1, the ladder is not a partition.** Applied in "Decision rule" (PART 4): per-run **GRADEABLE** is now
   defined (floor precondition, `n >= 15` distinct above-floor checkpoints after dedup, and no IF-9), and
   only a GRADEABLE run can be CYCLIC or enter NO CYCLING's zero-cyclic conjunct; an UNGRADEABLE run whose
   count exceeded its null is printed as an UNGRADEABLE EXCEEDANCE. The ladder is rewritten with **eight**
   outcomes, CYCLING and PARTIAL are explicitly **per-arm** and count a gradeable A4, the pooled count is
   printed and never promotes a verdict, FLOOR-LOST no longer reads A1 alone, and the totality claim is
   **discharged by an exhaustion argument under the ladder** (PART 4) instead of asserted. The outcome list at the
   head of the document (PART 1) says plainly that the earlier "no combination lands nowhere" sentence was false.
2. **RC-2, CYCLING must consume Instrument I1.** Applied in the ladder (branch 2, PART 4) and in "Instrument I1" (PART 2):
   the sub-labels **CYCLING (PANEL-VISIBLE)** and **CYCLING (SELF-RELATIVE)** are mandatory, the panel
   conjunct is `INV_20 - INV_0 >= 1` in at least 2 of the arm's cyclic runs [**SUPERSEDED IN ROUND 2 BY
   RC2-1: the raw delta is replaced by a Null C exceedance at each end. Left standing as the record of what
   round 1 landed; the live rule is in the round-2 section below.**], and SELF-RELATIVE is barred
   from pocket-exploitation and open-endedness language. The artifact mechanism is written up as **route
   B** in "The largest threat to validity" (PART 5), named as the answer to whether the headline can be produced by
   an instrument artifact: yes, by checkpoint-local specialisation drift under non-transferring aim.
3. **RC-3, the absolute `INV = 0` condition.** Applied in the ladder (branch 6, PART 4), in "What would falsify
   what", and in H1 (PART 5): the condition is now the **median over A1's runs of (`INV` at checkpoint 20 minus
   `INV` at checkpoint 0)** [**SUPERSEDED IN ROUND 2 BY RC2-1: that raw median is replaced by the median
   of the change in the CENTRED quantity `INV - E[INV]` over QUALIFYING runs. This row records what round
   1 landed and is left standing as that record; the live rule is in the round-2 section below.**], the
   checkpoint is named, and the 13 seeds' `INV_0` is **computed and printed**
   in section I1 (PART 2) from `exp066_crossplay.txt`. It is not zero: median 2 at band 0.10, nine of thirteen seeds
   non-zero, so the absolute form was unreachable before the first run. H1 is restated to match and the
   restatement is labelled as such.
4. **RC-4, the silent Null A to Null B swap.** Applied in "Null A" (fit gate, PART 2), "Null B" (role, PART 2), and the
   IF-9 row: IF-9 now makes the RUN ungradeable, records the mismatch **with its sign**, treats a DEFLATED
   null as positive-direction evidence that this instrument cannot convert into a verdict (with the
   NULL-UNFIT RESIDUE label) [**SUPERSEDED IN ROUND 2 BY RC2-4: the positive-direction reading of a
   DEFLATED null is WITHDRAWN as MEASURED AND FALSIFIED, and the DEFLATED branch keeps its behaviour and
   loses its interpretation. The NULL-UNFIT RESIDUE label survives with no positive-direction reading
   attached. This row records what round 1 landed and this bracket is added by DESIGN gate round 3,
   RC3-7b, which found it the only unmarked supersession in a section where RC-2 and RC-3 both carry
   one.**], and **Null B never decides CYCLIC in any circumstance**. A majority of IF-9
   firings in an arm is INSTRUMENT FAILED.
5. **RC-5, IF-3 under a non-stationary fitness.** Applied in the IF-3 row (PART 4) and in "The archive" (PART 3): collapse
   BELOW the floor stays instrument failure, collapse AT a floor-holding champion is **CONVERGED**, does
   not count toward the INSTRUMENT FAILED majority, and the run stays gradeable on its **deduplicated**
   above-floor submatrix when that leaves `n >= 15` or is CONVERGED-UNGRADEABLE when it does not. Dedup by
   content hash is stated in the archive section (PART 3).
6. **RC-6, common random numbers broken across arms.** Applied in "The opponent set" and "Seeds and every
   random quantity" (both PART 3): two streams per run, the optimiser sampling stream `{RunSeed, 7}` **shared** across
   A1, A2 and A3, the opponent-draw stream `{ArmCode, RunSeed, 11}` per arm, **SC11** checking that
   generation 1's offspring are bit-identical across those arms at the same run seed, and an explicit
   statement of what CRN buys here (generation 1 and the seed-level confound) and what it does not
   (anything after the trajectories diverge). A4 shares nothing, A3 consumes no opponent draws at all,
   and both facts are stated in that section rather than left to be inferred from the seed table.
7. **RC-7, A4's arm-level gradeability undefined.** Applied in "Decision rule" (PART 4): **A4 is gradeable at arm
   level iff at least 10 of its 13 runs hold the per-run floor precondition**, the same fraction A1 is held
   to, and on a mixed A4 only the gradeable runs enter the conjuncts with both counts printed.
8. **RC-8, a verdict label resting on an unpersisted number.** Applied by computing it:
   `scripts/exp066_residue_and_inv0.escript` over `exp066_crossplay.txt`, persisted in
   `programmes/p7_coevolution/exp066_competence_floor/exp066_residue_and_inv0.txt` section B, cited in the
   seeding section (PART 3, with the full table) and in the IF-12 row (PART 4). The 11 kill-mode champions other than 2003
   and 2013 carry **0 cycles at all three bands** over 165 triples of which 130 / 115 / 96 are cyclable, so
   the zero is not a shortage of decisive material. Three gates against the persisted records run before
   any number is written, and the script uses no RNG.
9. **RC-9, three specification gaps.** (a) Applied in "The opponent set" (PART 3): one opponent set per generation,
   **shared by all `lambda` offspring**, so comma selection ranks on a common comparison. (b) Applied in the
   same section: A3's shuffle is now load-bearing as a **generation-indexed walk** through the once-shuffled
   frozen archive, with **SC12** checking that each member fills exactly 750 of the 15,000 opponent slots;
   the dead uniform-draw-from-a-shuffled-list form is gone. (c) Applied in "Instrument I2" (PART 2): the table has
   **six cells, not four**, with the band between the Null A median and maximum given its own pre-committed
   reading.

### The blind spots the gate named, and where each is answered

1. **The modal outcome may be INCONCLUSIVE and no run of `mu_lambda_es` has ever been executed on this
   task.** Answered in "How the search under-convergence confound stays CLOSED" (PART 5) as a **declared residual**,
   not a repaired one: `P(A4 gradeable)` is unestimated, no probe is invented, and outcome 5 already
   prescribes the next move.
2. **Checkpoint spacing is a sampling rate.** Answered in "The archive" (PART 3) and carried into "What a negative
   would NOT mean" (both PART 5): a NO CYCLING verdict is scoped to cycling slower than about two checkpoint intervals.
3. **The archive is one lineage, not a population.** Answered in the same two places: within-generation
   polymorphism is invisible to the primary instrument by construction, and A4 is the only arm whose
   representation could hold it.
4. **Mutual non-engagement had no named outcome.** Answered by adding outcome 8 **NON-ENGAGEMENT**, a
   carve-out at precedence 0 from INSTRUMENT FAILED, with the IF-2 row (PART 4) carrying the carve-out.
5. **The floor gate is coarse relative to the seeds, so `INV` rises are not the specialisation signature
   and nothing else.** Answered by softening the I1 claim (PART 2) to what Null C actually controls for and by adding
   **IF-14 FLOOR-SHED** (PART 4), whose firing bars a run's `INV` rise from counting toward the panel conjunct.

### What this pass added BEYOND the nine changes, labelled so the boundary is visible

Three things here are not gate-required and are marked as additions rather than smuggled in as repairs.
**SC13** (PART 3, the 25-member panel's `INV_0` must be at least the champion-only value now printed in PART 2) exists
because RC-3 turned a baseline into a printed number that the panel measurement must be consistent with.
**The per-arm blocking rule and the DECOUPLED-CONTROL CYCLED label** in the decision rule (PART 4) close two
ambiguities the exhaustion argument exposed while it was being written: "in a majority of an arm's runs"
did not say WHOSE failure blocks which verdict, and the ladder did not say whether A3 can carry a verdict
(it cannot). **Outcome 8 NON-ENGAGEMENT and IF-14 FLOOR-SHED** answer blind spots 4 and 5, which the gate
raised without requiring a change. Nothing else was altered: no threshold was moved, no band was swept,
no null was replaced and no definition was loosened.

**The gate's own critique is not immune to evidence either.** Its RC-3 argument is falsified if the
25-member panel measurement at step 2 returns a median seed `INV_0` of 0 at band 0.10, which would mean
the champion-only lower bound printed in section I1 (PART 2) is not what the full panel shows. That is checkable at
step 2 and the number goes in the record whichever way it lands. Its RC-1 combination (i) is falsified if
no run ever loses the floor while carrying a cyclic above-floor submatrix, in which case the repair costs
nothing and buys nothing. Neither falsification would restore the first version's rules, because both
holes were about what the rules PERMIT, not about what the runs happen to do.

---

## DESIGN gate verdict ROUND 2 (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all six changes applied

**The round-1 section above is unchanged and nothing in it is withdrawn.** Round 2 passed the design's
counting half and failed its PANEL half, on the prompt's own central test: construct a scenario where
"exploits cyclic pockets" and "climbs the transitive backbone" produce the SAME reading. The scenario
exists and the design half-built it itself. **Route B (checkpoint-local specialisation under
non-transferring aim) produces the count positive, and ordinary backbone climbing, which H3 predicts,
moves each champion's panel win count `k_C` toward `n_C / 2`, which mechanically inflates raw `INV`
because `E[INV] = D * k * (n - k) / (n * (n - 1))` peaks at `k = n / 2`.** The decision rules consumed
RAW `INV` deltas against a threshold of 1, the least nonzero integer, inside the permutation spread of
every seed, and never the registered Null C. **So the conjunction of two artifacts this document names
separately signed CYCLING (PANEL-VISIBLE). Null C was registered, specified in closed form, computed,
reported, and bypassed by every decision that mattered. That is phase 0's three-nulls hole one instrument
over: the count was never the problem, the reference was.**

### The six required changes and where each landed

1. **RC2-1, every panel-reading decision must consume Null C.** Applied in a new subsection of the nulls
   section (PART 2, "Every panel-reading decision now consumes Null C"), in the ladder's branch 2 sub-label (PART 4), in
   branches 6 and 7 (PART 4), in instrument I1's framing and its reported-per-run list (PART 2), in the constants table (PART 3), in
   the falsifier list (PART 4), in H1 and in route B (both PART 5). The CYCLING panel conjunct is now **`INV` at the final
   checkpoint exceeding that checkpoint's own 200-permutation Null C MAXIMUM while `INV` at checkpoint 0
   did not exceed its own** [**this half is LIVE and round 3 could construct no artifact route through
   it**]; the branch 6 / 7 discriminator is now the **median of the change in the
   CENTRED quantity `INV - E[INV]`, thresholded at 0** [**SUPERSEDED IN ROUND 3 BY RC3-1: subtracting
   `E[INV]` is not conditioning on `k_C`, so this median reads composition with a `k`-dependent sign and
   sends a pure transitive climb to branch 7 at a measured median of +15.6000 at band 0.10. It is
   replaced by the COUNT of A1's qualifying runs satisfying the PANEL-VISIBLE conjunct above, fewer than 2
   for branch 6 and 2 or more for branch 7, with a degenerate-checkpoint exclusion. This row records what
   round 2 landed; the live rule is in the round-3 section below.**]. The composition-drift argument is
   written out with
   the four drifts it absorbs (`k_C`, `n_C`, `D_C`, and the quasi-self-play drift of blind spot 2), and a
   monotonicity check on Null C is added to the panel measurement so the argument is measured rather than
   asserted [**round 3 corrected that check's statement, which as written fired unconditionally on
   arithmetic, and widened it from one panel member to all 25: RC3-3**]. **The threshold complement moved
   from `>= 1` to `> 0`** because the centred quantity is
   real-valued and `>= 1` would have left `(0, 1)` in no branch [**moot after round 3: the replacement is
   an integer count**].
2. **RC2-2, filter the branch 6 / 7 median symmetrically and name the thin-base reading.** Applied in
   branch 6, in the new ladder position **5b INCONCLUSIVE, PANEL BASE UNAVAILABLE** (both PART 4), in outcome 10 at the
   head of the document (PART 1), in the reading table (PART 4), in the exhaustion argument (PART 4), and in the constants table (PART 3). The
   median is computed only over A1 runs where IF-1 did not fire and IF-14 FLOOR-SHED did not fire, and at
   fewer than 7 of 13 qualifying runs the reading is **PANEL BASE ERODED**, which cannot default into
   branch 6 or branch 7. [**The symmetric filter is LIVE and round 3 extended it rather than replacing
   it: a run whose checkpoint 0 or whose final checkpoint has a DEGENERATE Null C is also disqualified,
   because the withdrawn median counted such a checkpoint's exact zero toward branch 6. RC3-1. The word
   "median" in this row is the withdrawn statistic's name; the base and its 7-of-13 gate carry over
   unchanged to the count that replaces it.**]
3. **RC2-3, a minimum evidence base for the universal negative.** Applied in the new ladder position **5a
   CONVERGED, BASE INSUFFICIENT** (PART 4), in outcome 9 (PART 1), in branch 6's conjunct list (PART 4), in the reading table (PART 4), in the
   exhaustion argument (PART 4), in the constants table (PART 3) and in H1's own failure mode (PART 5). NO CYCLING now requires at
   least 7 of 13 GRADEABLE runs in each of A1 and A2 and in A4 when it carries. **Author-added beyond the
   letter: the same gate also blocks branch 7**, because branch 7 asserts the same universal proposition
   over the archive and would otherwise be where a thin-based negative could still be signed.
4. **RC2-4, run Null A and the IF-9 gate on the persisted phase 0 matrix before the runner is written.**
   Done, and it changed the design. Records: `exp067_null_a_calibration.txt` (RNG `exsss` seeded
   `{3661, 0, 0}`, 200 draws, exported end state persisted) and an independent
   `exp067_null_a_verification.txt` (139 comparisons, 0 disagreements, plus a closed form with no RNG).
   **IF-9 does not fire (`+4.0` against a width of 20) and the width is re-derived and KEPT on its own
   measurement. The observed cycle count exceeds its own null MAXIMUM at all three bands, on a matrix with
   no coevolution in it, so RC2-4's second condition fired and the re-derivation is done in the
   document**: the 3-of-13 arithmetic is confirmed to five figures and its INPUT is contradicted, so the
   level `3.39e-5` is **WITHDRAWN with no level replacing it**, raising `k` is shown not to be the repair
   (`k = 6` at the 95 percent lower bound, no `k` at the point estimate), 3-of-13 is retained and
   **re-labelled a within-arm REPLICATION requirement**, and **CYCLIC gains leg (iii), the
   NO-COEVOLUTION REFERENCE SHARE**, as an exact integer test against phase 0's own persisted share
   (18/582 at band 0.10). The DEFLATED branch's "positive-direction evidence of non-scalar margin
   structure" reading is **withdrawn as falsified** (the null OVER-produced decisive edges on the one real
   matrix while that matrix carried 18 banded cycles against a closed-form expectation of 0.04797213 per
   synthetic matrix and a Markov bound of 0.00266512; **this row said "18 times the null maximum" until
   DESIGN gate round 3's RC3-4 replaced the sampled ratio with the seed-free closed form, because the
   sampled maximum is 1 at the calibration's seed and 2 at the verification's**). The two registered nulls are shown to
   BRACKET the observed count (Null A far above, Null B far below), so phase 0's three-nulls lesson is
   recorded as recurring between the nulls this design KEPT.
5. **RC2-5, the seed pool is CHOSEN and must be argued.** Applied in the seeding section and the constants
   table, both PART 3. The row reads CHOSEN, the named alternative "all floor-holding arm S champions" is argued
   against with its full 18-member membership table and each member's headroom above `B` in matches, the
   floor-headroom argument is given (it excludes exactly the four near-parity champions, three of which
   clear `B` by 1 to 5 matches of 160), and **the exclusion of seed 2016 at 0.8000 with 36 matches of
   headroom is recorded as an UNARGUED RESIDUAL** rather than defended by band membership. The
   lower-half-seeding bias is declared, a **LOWER-HALF-SEEDED** label is pre-committed on any
   PANEL-VISIBLE positive, and the scope line is added to "What a negative would NOT mean" (PART 5).
6. **RC2-6, fix the gunless-leg exclusion's scope and add the behavioural analogue.** Applied in the
   primary-endpoint sentence (PART 1; the clause is deleted from it, with the reason: no scripted rung can be a
   member of an archive matrix, so it did zero work there), in the gunless-leg paragraph (PART 1; rescoped to the
   PANEL-derived counts, where it does bite), and in a new required report (PART 1): **DAMAGE PROVENANCE per edge**
   for every counted cyclic triple, so an edge won by the opponent grinding itself to death is visible
   where there is no member identity to exclude on.

### The four blind spots the gate named, and where each is answered

1. **Signed insight 066 asserted a candidate triple that two persisted records refute.** The dated
   correction has been appended and pushed (`faber-ecosystem` commit 224247f), so this document now cites
   **the correction and never the refuted claim**, in the Upstream line (the root) and in the gunless-leg paragraph (PART 1),
   and imports the two facts it carries that bear on this design: **9 of phase 0's 13 recovered cycles run
   through an opponent that cannot deal damage** (all nine listed by member), and **the two surviving
   pre-registered cycles both run through the rammer while all thirteen pass through the single-rung-trained
   arm D**, so the residue is a statement about the CURRICULUM rather than the ARENA.
2. **Each run's panel contains its own seed, so `n_C` trends with checkpoint index.** SUBSUMED by RC2-1,
   and now **said explicitly** as the fourth of the four drifts Null C's conditioning absorbs, rather than
   left as a subsumption a reader has to reconstruct.
3. **No behavioural probe of counted cycles was planned.** RC2-6 covers the damage-provenance half. The
   other half is added as a required report (PART 1): **EDGE-FAMILY STRUCTURE** (the cycle set partitioned by shared
   pivot edge, counts largest first, because phase 0's residue was pivot-edge families and not independent
   cycles) and **MINIMUM ABSOLUTE MARGIN SLACK** in matches above the band, with a knife-edge label at a
   slack of 1, plus the behavioural REGIME of every member of every counted cycle.
4. **A degenerate paired A1 run is inherited by A3 and the Fisher comparison had no exclusion rule.** NOT
   covered by any of the six, and answered with one pre-committed sentence in the opponent-set section (PART 3): an
   A3 run whose paired A1 run is UNGRADEABLE, or whose frozen curriculum holds fewer than 15 distinct
   phenotypes after dedup, is excluded from the coupled-against-decoupled Fisher comparison and from the
   DECOUPLED-CONTROL CYCLED label, with the pair accounting printed; below 7 surviving pairs of 13 the
   coupling attribution is UNAVAILABLE rather than a null result. The exclusion predicate reads only A1
   quantities, so it cannot be steered by A3's result.

### What this pass added BEYOND the six changes, labelled so the boundary is visible

Five things, none gate-required.

1. **THE BEATS RELATION IS RECONCILED, in its own subsection.** Two different relations were in force
   across the phase 0 records, `W > 0.5` (the recovered-rates cycle census) and `L > W orelse D > 0.5` (the
   widened ladder-inversion predicate). Phase 1 inherits **ONE**: the BAND-DECISIVE MARGIN relation, which
   is what the primary endpoint counts under and what every pairwise reading in phase 1 uses. Both phase 0
   relations are named with the scope each keeps, and the one implication that actually holds is stated
   (`W > 0.5` implies BEATEN under the unbeaten predicate, and **BAND-DECISIVE implies NEITHER**, since a
   draw-heavy cell can be band-decisive with the winner below a majority, which is what IF-7 bounds).
2. **LADDER POSITION 5b's SECOND SUB-LABEL, PANEL VOID.** (PART 4.) RC2-2 covers the eroded base; a firing IF-8 left
   branches 6 and 7 both unevaluable and the ladder fell off its end. That hole is concrete rather than
   theoretical, because IF-8's order-violation trigger is known to be TIGHT: 26 of 150 band-decisive pairs
   of the 190-cell champion submatrix already disagree with a fitted order against a trigger of more than
   30 over all 300 pairs. [**Round 2 wrote "the measured IF-8 order-violation headroom is 4 on the 110
   panel pairs not yet measured". That subtraction is WITHDRAWN by DESIGN gate round 3, RC3-5: the 26 is
   counted against a TWENTY-member fit and the panel refits over 25, so the headroom is unknown until
   panel step 2. The sub-label's justification does not depend on the number, only on the trigger being
   tight, and it stands.**]
3. **THE IF-8 HEADROOM ITSELF, printed and not acted on.** 26 of 150 band-decisive pairs already disagree
   with the fitted order on the 190 cells SC3a (PART 3) forces the panel to reproduce, against a trigger of more
   than 30 over all 300. **The 30 is not moved**; the consequence is pre-committed instead. [**And the 26
   is now printed as an INDICATOR FROM A DIFFERENT MODEL FIT rather than as this panel's headroom, which
   is DESIGN gate round 3's RC3-5: SC3a fixes the 190 CELLS and not the fitted STRENGTHS, so five extra
   panel members can reorder the champions and the 190-pair disagreement count under the 25-member fit is
   neither 26 nor bounded by 26. It is recomputed at panel step 2 and printed there.**]
4. **THE NULL A PRIOR IS DISAMBIGUATED.** The verification found that the prior reading which reproduces
   the calibration is per UNORDERED pair, while both the calibration's prose and this document's Null A
   specification said "every ordered pair" (the two differ by 0.1006682371500549 at worst over the 20
   strengths). The specification block is corrected and the registered prior is stated once. No verdict
   turns on it, and a prior specified two ways is not specified.
5. **THE REGIME-BOUNDARY READING RULE.** Phase 0's within-tier recount had its own conclusion refuted, and
   this document now cites that refutation where it previously cited only the recount's per-cycle listing.
   The consequence is pre-committed: any phase 1 cyclic residue is read first as a candidate REGIME
   BOUNDARY, and the regime of every member of every counted cycle is a required report. **COUNT INTEGERS**
   is recorded with the correction it came from.

**Nothing else was altered. No threshold was moved, no band was swept, no null was replaced, no definition
was loosened, and the one width the gate asked to be re-derived was re-derived and kept because its own
measurement supports it.** The three constants that changed status did so in the direction of admitting
more choice, not less: the seed pool went FORCED to CHOSEN, the 3-of-13 threshold went "family-wise safe at
3.39e-5" to "replication requirement at no stated level", and CYCLIC gained a leg rather than losing one.

**The round-2 critique is not immune to evidence either.** Its RC2-1 argument fails if the Null C
monotonicity check at panel step 2 shows the permutation maximum does NOT rise with `k_C`, in which case the
raw delta was not composition-inflated after all and the normalised rule is unnecessary rather than wrong.
**And half of RC2-1 has already failed to a later measurement rather than to that check: its exceedance
leg stands, and the mean-centred median it prescribed for branches 6 and 7 is withdrawn by round 3, which
measured it sending a pure transitive climb to branch 7. RC2-1 was right that the reference was the
problem and wrong about what a reference is.**
Its RC2-4 consequence is scoped by a fact the calibration itself states: the phase 0 matrix is 20
independently evolved champions and a phase 1 archive matrix is 20 checkpoints of one lineage, so if archive
matrices sit inside Null A after all, then leg (iii) is doing no work and the withdrawn level was
conservative rather than wrong. **Neither falsification would restore the first version's rules**, because
both holes were about what the rules PERMIT: a rule that can be satisfied by an artifact is defective
whether or not the artifact occurs.

---

## DESIGN gate verdict ROUND 3 (faber-adversary / Fable, 2026-07-30): REDESIGN, scoped to the negative's panel discriminator; all seven changes applied

**The round-1 and round-2 sections above are unchanged and nothing in them is withdrawn by this section
that is not marked withdrawn inside them.** Round 3 passed the counting half of this design without
breaking it: the Null A calibration is honest and independently verified, the withdrawn level is withdrawn
correctly, leg (iii) closes route C, the headline PANEL-VISIBLE conjunct is properly conditioned, and the
five-way split is lossless. **Passed is not the same as unqualified**: RC3-4 below records that the count
positive's verdict-deciding bar moved to leg (iii), a single unreplicated reference share, and RC3-6
records that the panel leg's reachability on real patterns is unevidenced. Neither is a defect in a rule;
both are operating points the document was not stating. **What round 3 FAILED is the PANEL half, on the
same central test round 2 used: construct
a scenario where "exploits cyclic pockets" and "climbs the transitive backbone" produce the SAME reading.
The scenario exists, one rule over from where round 2 found it, and the gate had pre-committed the
consequence: REDESIGN regardless of how much else improved.**

**WHY THE VERDICT IS REDESIGN AND NOT BUILD_WITH_CHANGES, in the gate's own terms.** Three point-patches
to the same scalar had failed the same test three times: round 1 the panel conjunct was bypassed, round 2
the raw delta read composition as signal, round 3 the mean-centred delta reads composition as signal with
a `k`-dependent sign. The gate declined to prescribe a fourth patch on the ground that its own round-2
prescription was what broke it, and required the panel discriminator to be **derived once from the
requirement and proven on a pre-registered synthetic test** instead. **What changed shape: the negative's
panel discriminator is no longer a statistic of its own.** It is the positive's conjunct, read over the
negative's base, so this document now uses ONE normalisation of `INV` for every panel decision it makes.
No outcome was added or removed, no band was swept, no threshold was moved, and no new constant was
introduced.

### The seven required changes and where each landed

1. **RC3-1, FATAL: discard the mean-centred branch 6 / 7 discriminator and rebuild it on a statistic that
   conditions on each checkpoint's realised composition.** Done, as a change of shape. Applied in a new
   subsection of the nulls section (PART 2, "AND THE MEAN-CENTRED HALF OF THAT REPAIR IS ITSELF
   WITHDRAWN"), in branches 6 and 7 and their explanatory block (PART 4), in ladder position 5b (PART 4),
   in the exhaustion argument (PART 4), in the reading table (PART 4), in the secondary endpoints
   (PART 4), in the falsifier list (PART 4), in the degenerate-case paragraph and the reported-per-run
   list (PART 2), in outcomes 2, 7 and 10 (PART 1), in the panel measurement and the constants table
   (PART 3), in H1 and in a new route D (PART 5).
   **The live rule:** the COUNT of A1's QUALIFYING runs whose `INV` at checkpoint 20 exceeds that
   checkpoint's own 200-permutation Null C maximum while checkpoint 0 did not exceed its own, strictly,
   at band 0.10. **Fewer than 2 gives branch 6, 2 or more gives branch 7.** That is the PANEL-VISIBLE
   conjunct character for character, with the same 200 draws, the same strictness, the same band and the
   same chosen count of 2, so no new constant enters and no second normalisation exists.
   **The pre-committed degenerate-checkpoint rule the gate required:** a run whose checkpoint 0 or whose
   final checkpoint has `k_C = 0` or `k_C = n_C` is excluded from the qualifying base and contributes to
   NEITHER branch, which routes the case to 5b PANEL BASE ERODED rather than letting an exact zero vote
   for the negative.
   **The pre-committed synthetic backbone-climber test the gate required is SC15** (PART 3, panel
   measurement item 8), run over all 25 panel members at every band at every `k_C` before any arm, and
   **it is also run TODAY on the 190-cell lower bound** so the replacement is adopted on a measurement
   rather than on an argument. Record:
   `programmes/p7_coevolution/exp067_coevolution_cycling/exp067_panel_discriminator_redesign.txt`,
   produced by `scripts/exp067_panel_discriminator_redesign.escript`, no RNG, md5
   `686d59647c96da380b54a5821e081b3c` twice, gated against `exp066_crossplay.txt`,
   `exp066_residue_and_inv0.txt` section C (60 of 60 per-champion rows AGREE) and
   `exp067_null_a_calibration.txt` (its fitted strengths and their own order-violation counts, 3 of 3
   bands AGREE) before any number is written.
   - **The withdrawn rule scored on a pure transitive climb (section D1):** +6.4375 to +26.5625 for 11 of
     the 13 seeds and 0 for the two degenerate ones, **median +15.6000 at band 0.10**, so the climber
     lands branch 7; +18.3750 and 13 of 13 at band 0.05, +13.1333 at band 0.15.
   - **The installed rule on the same climb (section D2):** 0 exceedances, for two independent reasons.
   - **The installed rule over the WHOLE prefix-climb family (section D3):** the largest
     `INV_prefix(k) - E[INV](k)` over 20 champions, 3 bands and every non-degenerate `k` is **-2.5556**,
     and at or below the mean cannot be above the maximum, so the exceedance leg cannot fire anywhere on
     any backbone climb, proved with no permutation drawn.
   - **The CONTRAST, in the same pass, so that result is not an artifact of a statistic that cannot
     move (section D3):** the ANTI-CONSISTENT win set, the `k` STRONGEST members rather than the `k`
     weakest, exceeds its own exact mean in **60 of 60** champion-and-band cases and peaks at
     **+37.1046**. `INV` is therefore not bounded above by its own mean as a matter of arithmetic, the
     exceedance leg is not identically unsatisfiable, and the prefix result is a fact about PREFIX
     arrangements rather than about the statistic.
2. **RC3-2, make the three descriptions of the negative's panel clause state the implemented rule, and
   delete or rewrite the asymmetry sentence.** Applied in outcome 2 and outcome 7 (PART 1), in "A NO
   CYCLING verdict would mean" (PART 5), in branch 7's ladder reading and the reading table (PART 4), and
   in the nulls section (PART 2), where **the asymmetry sentence is quoted in full and refuted**: "an
   over-firing panel leg cannot manufacture a positive from nothing, it can only mislabel one" is true of
   branch 2 and FALSE of branches 6 and 7, where the panel leg alone blocks the negative. What replaces
   it is three concrete things rather than an argument: one normalisation on both sides, the degeneracy
   exclusion, and the step-2 reachability measurement with both readings pre-committed. **What is still
   missing is stated as missing: there is no coevolution-free reference SHARE for the panel instrument
   and no `p`-value from it.**
3. **RC3-3, fix the Null C monotonicity check to one statement.** Applied in panel measurement item 6
   (PART 3) and in the falsifier list (PART 4). The protocol's "flat or non-monotone over `k_C` from 0 to
   `n_C`" **fired unconditionally on arithmetic**, since `E[INV]` is zero at both ends and maximal in the
   middle so the curve is necessarily unimodal. PART 4's form, "does NOT rise with `k_C` toward
   `n_C / 2`", is adopted in both places; the check is commissioned over **all 25** panel members as
   PART 4 already promised rather than over one as the protocol said; and it is a falsifier of the
   EXCEEDANCE discriminator on both branches, which is the only panel statistic either branch now reads.
4. **RC3-4, state the count test's operating point after calibration, and replace the seed-dependent
   headline.** Applied in the nulls section (PART 2) under leg (iii)'s definition, on the "Null A REMAINS
   PRIMARY" sentence, in the constants table's leg (iii) row (PART 3), in "A CYCLING verdict would mean" (PART 5)
   (PART 5) and in the IF-9 row (PART 4). **Leg (ii)'s bar on a matrix of this shape is about 2 cycles
   and leg (iii) needs about 18 at cyclable 582, so leg (iii) is the BINDING leg by a factor of six to
   nine and the count positive rests mostly on one unreplicated reference share with no `p`-value.**
   PRIMARY is now explicitly defined as "the null the statistic is bound to" and explicitly NOT as "the
   leg that decides". The headline is now the seed-free closed form (expected **0.04797213** banded
   3-cycles per synthetic matrix at band 0.10, Markov bound **0.00266512**), with the sampled ratio kept
   beside it and labelled seed-dependent: **1 at the calibration's `{3661, 0, 0}` and 2 at the
   verification's `{9091, 0, 0}`, a factor of 18 against a factor of 9.**
5. **RC3-5, restate IF-8's headroom as unknown until step 2.** Applied in the "TWO SMALLER FACTS" bullet
   (PART 2), in the IF-8 row (PART 4), in panel measurement item 3 and protocol step 2 (PART 3), in
   outcome 10's PANEL VOID sub-label (PART 1), and in the round-2 gate section's items 2 and 3 above.
   The 26 of 150 is counted against the order fitted on the TWENTY-champion matrix; **SC3a fixes the 190
   CELLS and not the fitted STRENGTHS**, and five extra panel members can reorder the champions, so the
   25-member disagreement count over those same 190 pairs is neither 26 nor bounded by 26. The 26 is
   printed as an indicator from a different fit and the real headroom is recomputed at step 2. **The 30
   is still not moved and the pre-committed consequence is unchanged.**
6. **RC3-6, add the panel-half analogue of RC2-4, free at step 2.** Applied as panel measurement item 7
   (PART 3), as a new subsection of the nulls section (PART 2, "CAN A REAL WIN PATTERN EXCEED ITS OWN
   NULL C MAXIMUM"), as a required secondary endpoint and a registered falsifier (PART 4), in the
   negative's scope list and in "A NO CYCLING verdict would mean" (PART 5), and in the NO CYCLING row of
   the reading table (PART 4). Both readings are pre-committed: **PANEL LEG UNCALIBRATED** if any of the
   25 panel members exceeds its own 200-permutation maximum, **PANEL LEG UNREACHED ON REAL PATTERNS** if
   none does. **And the question is answered today on the data that exists: 0 of 20 phase 0 champions
   have `INV` above even their own exact `E[INV]`, at any band** (section D4 of the redesign record), so
   none of them could exceed its own maximum. The expected reading is therefore the second one, and the
   consequence, that a true positive may be systematically degraded to SELF-RELATIVE and that the
   negative's panel conjunct may be close to automatic, is written into the negative's limits rather than
   discovered in a write-up.
7. **RC3-7, consistency sweep, seven items.** (a) Outcome 1 (PART 1) gains leg (iii), which outcome 2
   already carried. (b) The round-1 gate record's RC-4 row gains its **[SUPERSEDED IN ROUND 2]** bracket,
   the only unmarked supersession in a section where RC-2 and RC-3 both carry one. (c) The fair-coin
   rejection paragraph (PART 2) now says **150** and not 152, with the reason. (d) The two "every one of
   the 13 seeds has `INV_0` far BELOW its own `E[INV]`" sentences (PART 2) are corrected to eleven of
   thirteen, with seeds 2002 and 2005 named as DEGENERATE at equality, and the conclusion re-derived from
   the degeneracy argument for those two. (e) The IF-14 row and the PANEL-VISIBLE falsifier (PART 4) now
   speak of an EXCEEDANCE and not of an "`INV` rise". (f) H1's (PART 5) "makes H1 HARDER to hold, not easier"
   asserted the opposite of what its own clause implied and is replaced by the honest statement that the
   direction was seed-dependent and never derived. (g) The compute section's (PART 5) spend priority no longer
   licenses more SEEDS, which the seeding section forbids; the seeding section governs, and adding seeds
   is named as a new pre-registration rather than a spend of spare compute.

### The gate's landing check and coherence read, and where each finding is answered

The gate reported two additional reads. Both are answered here, and the four findings it graded SERIOUS
or BLOCKING are all folded into the seven changes above.

1. **The branch 6 / 7 discriminator had no degenerate-checkpoint exclusion (SERIOUS).** Folded into
   RC3-1, which makes the exclusion part of the rule. It was already live: seeds 2002 and 2005 at band
   0.10, three of the 20 panel champions.
2. **Leg (iii) is an author-added third leg, installed after a measurement, whose error direction points
   at the design's own hypothesis (SERIOUS).** Answered in the nulls section (PART 2), where the
   provenance is now stated as plainly as the limits: what is offered for it (a measured mechanism, an
   error direction declared at the point of definition, a re-scoped negative) and **the residual that is
   not resolved: the reference object and the object it gates are not shape-matched and nothing in this
   corpus measures by how much.** That mismatch is a registered falsifier of leg (iii)'s own premise.
3. **The 2016 exclusion was conceded rather than argued (MINOR, accepted).** Recorded in the seeding
   section (PART 3), including the gate's own reason for accepting the weaker form and its finding that
   "13 is the number every downstream arithmetic is built on" is BOOKKEEPING and not science. Left
   standing, labelled as bookkeeping.
4. **The IF-14 row and one falsifier described the dead raw-rise rule (MINOR).** RC3-7e.
5. **The monotonicity check existed in two versions (MINOR).** RC3-3.
6. **The "18 times the null maximum" headline is seed-dependent (MINOR).** RC3-4.
7. **RC2-4 said "persist beside `exp066_residue_and_inv0.txt`" and both records went to the exp067
   directory instead (MINOR).** The deviation was recorded in the calibration's own header and not in
   this pre-registration; it is now stated in the nulls section (PART 2) where the records are first
   cited. Nothing is lost and every citation resolves.

The coherence read's two BLOCKING findings are RC3-1 and RC3-2; its four SERIOUS findings are RC3-3,
RC3-4, RC3-5 and RC3-7a plus RC3-7b; its four MINOR findings are RC3-7c, RC3-7d, RC3-7f and RC3-7g.
**Every one is applied. None was negotiated away and none is deferred.**

### What this pass added BEYOND the seven changes, labelled so the boundary is visible

Four things, none gate-required.

1. **ROUTE D, the fourth artifact route, written up beside routes B and C** (PART 5). Routes B and C are
   artifact routes to a false POSITIVE. Route D is an artifact route to a false BLOCK ON THE NEGATIVE, and
   naming it is what makes the round-3 failure the same kind of object as the round-1 and round-2 ones
   rather than a separate species. **A branch 7 verdict must now report whether the exceeding runs' `k_C`
   moved toward or away from `n_C / 2`**, so a reader can check that the replacement did not relocate the
   artifact a fourth time.
2. **SC15's CORRUPTED-INPUT DEMONSTRATION IS THE WITHDRAWN RULE** (PART 3). Every self-check in this
   document is exercised once against a deliberately corrupted input so that a check which cannot fail is
   not passed off as a check. SC15's corrupted input is specified to be the withdrawn mean-centred median
   evaluated on the same synthetic trajectory, which must go RED, so SC15 is demonstrated to DISTINGUISH
   the two rules rather than merely to pass.
3. **THE WITHDRAWN CENTRED MEDIAN IS RETAINED AS A REPORTED-ONLY QUANTITY** (PART 2 and PART 4), beside
   the raw delta round 2 already retained. Two superseded statistics are now printed next to the one that
   decides, for the same reason round 2 printed one: a reader can see what each earlier version of this
   rule would have concluded.
4. **THE REDESIGN RECORD ITSELF**, `exp067_panel_discriminator_redesign.txt`, and its script. RC3-1 asked
   for a pre-registered test; computing it today on the 190-cell lower bound was not required. It is done
   because this front's standard after RC2-4 is that a rule is not adopted on an argument when the
   arithmetic is available, and because the number that condemns the withdrawn rule should be reproducible
   from a file rather than quoted from a gate.

**Nothing else was altered. No threshold was moved, no band was swept, no null was replaced, no outcome
was added or removed, no definition was loosened and no new constant was introduced.** The one constant
the replacement consumes, the count of 2, is the CYCLING panel conjunct's own chosen count reused in a
second place, and the exceedance level it consumes is the null's own maximum over the already-registered
200 draws.

**The round-3 critique is not immune to evidence either.** Its RC3-1 argument fails if SC15 at panel step
2 shows a prefix-shaped win set EXCEEDING its own permutation maximum at some `k_C`, in which case the
replacement reads composition too and neither rule is usable; the 190-cell precedent (-2.5556 worst case)
says that is unlikely, and the check is registered precisely so the claim is not left as a precedent. Its
RC3-6 concern is falsified if any of the 25 panel members exceeds its own maximum at step 2, in which case
the exceedance leg is reachable on real patterns and the label PANEL LEG UNREACHED never applies. **Neither
falsification would restore the withdrawn median**, because its defect is about what the rule PERMITS: a
rule a pure transitive climb can satisfy is defective whether or not a transitive climb occurs.

---

## Result

PENDING. No arm has been run, no runner has been written, no panel has been measured and no verdict
exists. Nothing in this document has been executed.

What HAS been done, 2026-07-30, and none of it commits an arm:

- Phase 0's pre-registration, signed insight, unsigned cross-play note and `SYNTHESIS_P7.md` were read
  in full, together with the three fresh phase 0 follow-ups (the within-tier recount and its independent
  verification, the two flag fixes, and the recovered scripted-null and null-scaling fixes).
- The 13 seed identities, their tier classifier values, their regimes and their clamp fractions were
  read off persisted records and are tabulated above with the file each is reproducible from. The clamp
  fractions were computed from `exp066_champions_s.eterm`.
- `mu_lambda_es:evolve/3` and `sep_cma_es:evolve/3` were read in source to establish that `x0` exists in
  one and not the other, which is what forces A4 to be unseeded and conditional.
- The pre-registration went through the DESIGN gate (BUILD_WITH_CHANGES, nine required changes) and all
  nine are applied above, each recorded with where it landed in the gate verdict section.
- Two recomputations the gate required were run over phase 0's persisted matrix and persisted in
  `programmes/p7_coevolution/exp066_competence_floor/exp066_residue_and_inv0.txt` by
  `scripts/exp066_residue_and_inv0.escript`: the within-tier residue without seeds 2003 and 2013 (0 cycles
  at all three bands over 165 triples) and the 13 seeds' `INV` at checkpoint 0 (median 2 at band 0.10,
  nine of thirteen non-zero). Three gates against the persisted records pass before either number is
  written, and the script uses no RNG, so there is no seed to persist. **This is arithmetic over a
  persisted matrix. No genome was loaded, no match was replayed and no arm was re-run.**
- No genome was loaded into a match, no arm was re-run, no engine module was touched and nothing was
  committed.

Added 2026-07-30, in the same day, after the DESIGN gate's SECOND pass (BUILD_WITH_CHANGES, six required
changes), and none of it commits an arm either:

- **Null A was fitted, bootstrapped and gated on phase 0's persisted 20-champion matrix**, which RC2-4
  required before any runner exists. `scripts/exp067_null_a_calibration.escript`, record
  `programmes/p7_coevolution/exp067_coevolution_cycling/exp067_null_a_calibration.txt`, RNG `exsss` seeded
  `{3661, 0, 0}` (this document's own registered Null A scheme at `MatrixIndex 0`), 200 draws, exported end
  state and md5 persisted, six literal gates against the persisted phase 0 records passing before any number
  is written. **The fit gate survived and the per-run rate did not**, and both consequences are written into
  the nulls section (PART 2) rather than into a footnote.
- **An independent check of that calibration was written and run**, sharing no code, no helper and no parse
  path with it, and adding a closed form with no RNG anywhere in it:
  `scripts/exp067_verify_null_a_calibration.escript`, record `exp067_null_a_verification.txt`. **139 tested
  comparisons, 0 disagreements.** It found one defect the calibration's prose had and its arithmetic did not:
  the Bradley-Terry prior is per UNORDERED pair, not per ordered pair. **The check did not compile on first
  invocation** (a final `emit/2` call where only `emit/3` exists), which is recorded here because an
  independent check that cannot run is not a check; the missing argument list was added and nothing else in
  that file was touched.
- The six required changes and the four blind spots were applied to this document, each recorded with where
  it landed in the round-2 gate section, and the boundary between gate-required and author-added is marked
  there.
- **This is arithmetic over persisted matrices. No genome was loaded, no match was replayed, no arm was
  re-run, no engine module was read, and no runner code of any kind was written** (the standing rule on this
  front is that no experiment code exists before the gate returns BUILD, and it has returned
  BUILD_WITH_CHANGES twice).
- The two append-only records, `exp066_floor_feed.txt` and `insights/066-raw-competence-floor.txt`, were not
  touched and still share md5 `2aa36633da745b62be4db2971a6481b7`.

Added 2026-07-30, in the same day, after the DESIGN gate's THIRD pass (REDESIGN, scoped, seven required
changes), and none of it commits an arm either:

- **The negative's panel discriminator was rebuilt rather than patched.** The mean-centred median of
  `INV - E[INV]` is withdrawn and replaced by the positive's own two-legged Null C exceedance conjunct,
  counted over A1's qualifying runs, with a pre-committed degenerate-checkpoint exclusion. **This document
  now uses ONE normalisation of `INV` for every panel decision it makes.** Where each part of that landed
  is the round-3 gate section above.
- **The arithmetic that condemns the withdrawn rule, and the arithmetic the replacement survives, were
  computed and persisted**, because RC3-1's test is computable from data already on disk and this front's
  standard after RC2-4 is not to adopt a rule on an argument when the numbers are available.
  `scripts/exp067_panel_discriminator_redesign.escript`, record
  `programmes/p7_coevolution/exp067_coevolution_cycling/exp067_panel_discriminator_redesign.txt`. **No RNG
  anywhere in it**, so there is no seed to persist: the exceedance leg's 200-permutation maximum is bounded
  below by the exact closed-form mean instead of being sampled, which makes every conclusion in it hold
  whatever those 200 draws would return. md5 `686d59647c96da380b54a5821e081b3c` on two consecutive
  executions. Gates before any number is written: the integer counter against
  `exp067_null_a_calibration.txt`'s own `{decisive, cyclable, cycles}` at three bands, the fitted-order
  violation counts at three bands (which is what proves the order it sorts by is the calibration's own
  order), the 20 fitted strengths parsed rather than re-fitted, and **60 of 60 per-champion
  `{seed, n_C, k_C, D_C, INV, E_INV}` rows against `exp066_residue_and_inv0.txt` section C**. All AGREE.
  Findings: the withdrawn rule sends a pure transitive climb to branch 7 at a median of **+15.6000** at
  band 0.10 (11 of 13 seeds above 0); the replacement sends it to neither branch; the replacement cannot
  fire anywhere on the whole prefix-climb family (**worst case -2.5556**); and **0 of 20 real
  coevolution-free champions have `INV` above even their own exact mean at any band**, which is the
  reachability limitation now carried on both the positive's sub-label and the negative's conjunct.
- **The pre-registration was split again**, from five parts to six, because PART 5 was going to pass the
  75KB cap once the round-3 gate section was added. The DESIGN gate record and the Result moved to a new
  PART 6 on a top-level section boundary, byte-preserving, proven by
  `scripts/exp067_verify_split_lossless.sh` and recorded in `exp067_split_losslessness.txt`.
- **This is arithmetic over persisted matrices. No genome was loaded, no match was replayed, no arm was
  re-run, no engine module was read, and no runner code of any kind was written** (the standing rule on
  this front is that no experiment code exists before the gate returns BUILD, and it has now returned
  BUILD_WITH_CHANGES twice and REDESIGN once).
- The two append-only records were not touched again and still share md5
  `2aa36633da745b62be4db2971a6481b7`.
