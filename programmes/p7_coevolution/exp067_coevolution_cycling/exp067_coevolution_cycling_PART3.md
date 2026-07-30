> Part 3 of 6 of the [EXP-067 pre-registration](exp067_coevolution_cycling.md). The root holds the framing, the status and the section index.

# EXP-067 PART 3. The reference panel, the coevolution design, the protocol and the frozen constants

## The reference panel: 25 members, measured once, frozen before any run

**Composition is complete rather than selected, so there is no cherry-picking to argue about:**

- **all 20 arm S champions**, seeds 2001 to 2020, from `exp066_champions_s.eterm`;
- **all 5 scripted rungs**: `sitting_duck`, `spinner`, `rammer`, `circle_strafer`, `predictive_gun`.

25 members, 300 pairs, 2,300 unordered triples, 300 x 160 = **48,000 matches, measured once**.

**Why arm S champions and the rungs, and why NOTHING else.** The panel must span the regimes the
population could move into, and arm S is the only arm with all four measured regimes present: brawl
at mean standoff range 113.7 to 129.3 whole units, tight orbit at 182.7 to 198.3, mid orbit at 205.6
to 214.6, and long standoff at 294.0 to 308.3 (`exp066_policy_probe.txt` section C, POST HOC). The
rungs anchor the bottom of the order and give the floor monitor for free. **Arm D is excluded from
the panel as well as from the seeds**: eight of its ten champions fail phase 0's own relevance line
on a rung BELOW the one they trained against, and its registered cyclic triples are curriculum
artifacts (arm D trained on the floor rung alone, so it never saw the rung that beats it). Scoring
inversions against an artifact would make them unattributable. Arm L is excluded for a simpler
reason: it is a different topology and adds no regime the arm S set does not already carry.

**What the panel measurement produces, and it is FROZEN before the first coevolution run:**

1. The full 300-pair integer win-count matrix.
2. Its decisive-edge count, cyclable-triple count and cyclic-triple count at all three bands, with
   and without the gunless-leg exclusion.
3. Its **dominance order**: descending Bradley-Terry strength fitted by the same MM iteration and
   the same declared prior as Null A. **The order's own violations are reported**: the number of
   band-decisive panel pairs whose direction disagrees with the fitted order, out of 300. That number
   is the panel's own intransitivity and it is the baseline every `INV` is read against. **AND THE SAME
   COUNT RESTRICTED TO THE 190 CHAMPION-VERSUS-CHAMPION PAIRS, WHICH IS IF-8's REAL HEADROOM AND IS NOT
   KNOWN BEFORE THIS POINT (DESIGN gate round 3, RC3-5).** The calibration's 26 of 150 is counted against
   the order fitted on the TWENTY-champion matrix; the panel refits over 25, SC3a fixes the 190 CELLS and
   not the fitted STRENGTHS, and five extra members can reorder the champions, so 26 neither is nor bounds
   the 25-member value. The 190-cell subcount and the 110-cell subcount are printed separately, and the
   distance from IF-8's trigger of more than 30 over all 300 is printed with them.
4. Per member: row mean over the other 24, Copeland count, and (for the 20 champions) held-out win
   rate against `predictive_gun` and tier.
5. `INV_0`, `E[INV]`, and the 200-permutation minimum, median and **MAXIMUM** for each of the 13 run
   seeds, so the seeds' pocket membership is known BEFORE the runs **and so the checkpoint-0 leg of the
   PANEL-VISIBLE conjunct is decided on measured numbers rather than on the prediction made from the
   champion-only lower bound**. Also printed: which seeds have a DEGENERATE Null C (`k_C = 0` or
   `k_C = n_C`, so the permutation distribution is a point mass at 0 and the seed's run can never
   contribute to PANEL-VISIBLE unless `k_C` moves), and whether `INV_0` exceeds its own maximum for any
   seed, which the champion-only table predicts it does not for any of the 13. **`INV_0` over the 25
   members must be at least the
   champion-only value printed in section I1 (PART 2), for every seed and every band**, because the 190
   champion cells are reproduced exactly (SC3a) and extra members can only add triples. That is
   **SC13**, an inequality that can fail: if it does, the panel does not contain the submatrix it is
   supposed to contain.
6. **A MONOTONICITY CHECK ON NULL C, so RC2-1's composition argument is measured and not asserted. ITS
   STATEMENT IS CORRECTED AND ITS SCOPE WIDENED BY DESIGN gate round 3 (RC3-3).** For **all 25** panel
   members, at fixed `n_C` and `D_C`, the 200-permutation maximum of `INV` is computed at every `k_C`
   from 0 to `n_C` and printed. **The check is that the reference RISES with `k_C` TOWARD `n_C / 2`**,
   which is what makes the exceedance test blind to composition drift, and it FAILS if the reference
   does not rise toward the middle at fixed `n_C` and `D_C`.
   **THE FIRST VERSION SAID THE CHECK FAILS "if the curve is flat or non-monotone" OVER `k_C` FROM 0 TO
   `n_C`, AND THAT VERSION FIRES UNCONDITIONALLY ON ARITHMETIC**: `E[INV] = D * k * (n - k) / (n(n-1))`
   is zero at both ends and maximal at the middle, so the curve over the full range is NECESSARILY
   unimodal and therefore necessarily non-monotone. A check whose verdict is fixed in advance is not a
   check. **The corrected form is the one PART 4's own falsifier already stated**, and the two now agree.
   The first version also commissioned it on ONE member while PART 4's falsifier promised all 25; it is
   all 25, which costs nothing because it is permutations of a frozen matrix's row.
7. **THE PANEL EXCEEDANCE LEG'S REACHABILITY ON REAL WIN PATTERNS, with both readings pre-committed
   (DESIGN gate round 3, RC3-6).** For each of the 25 panel members, at every band, whether its own `INV`
   EXCEEDS its own 200-permutation Null C maximum, printed member by member with the count. Every panel
   member is a coevolution-free win pattern, so this is the nearest thing to a coevolution-free reference
   the panel instrument admits, and it is free: the permutations are already drawn for item 5.
   - **If ANY of the 25 exceeds**, the "at most `1/201` per champion" Type I story for PANEL-VISIBLE dies
     exactly as Null A's `1/201` died on the phase 0 matrix, and every panel reading carries the label
     **PANEL LEG UNCALIBRATED**.
   - **If NONE of the 25 does**, the record states that the corpus contains zero examples of a real win
     pattern exceeding this reference and that the leg's reachability is UNEVIDENCED. Both the positive's
     PANEL-VISIBLE sub-label and the negative's branch 6 panel conjunct then carry **PANEL LEG UNREACHED
     ON REAL PATTERNS**, and the negative's scope section says its panel conjunct may be close to
     automatic.
   On the 190-cell champion-only lower bound the answer is already **0 of 20 at every band**
   (`exp067_panel_discriminator_redesign.txt` section D4), so the second reading is the expected one; the
   25-member measurement supersedes it and neither reading is a condition on running the arms.
8. **THE SYNTHETIC BACKBONE-CLIMBER TEST, which is SC15 and which the branch 6 / 7 discriminator must
   pass (DESIGN gate round 3, RC3-1).** For every panel member, at every band, at every `k_C` from 0 to
   `n_C`, the ORDER-CONSISTENT win set of that size is constructed against the panel's own frozen
   dominance order (the member beats the `k_C` weakest members of its sub-panel), `INV` is counted
   exactly, and it is checked that this `INV` does NOT exceed that `k_C`'s own 200-permutation maximum. A
   pure transitive climb must contribute NOTHING toward branch 7 at any point of its trajectory, or the
   discriminator reads composition and not arrangement. The terminal point `k_C = n_C` is DEGENERATE and
   is excluded from the branch 6 / 7 base by rule, and the test covers it anyway.
   **The ANTI-CONSISTENT win set, the `k` STRONGEST members rather than the `k` weakest, is constructed
   and printed in the same pass as the CONTRAST that shows the test is not vacuous**: on the 190-cell
   lower bound it exceeds its own exact mean in 60 of 60 champion-and-band cases, peaking at
   `anti_INV - E[INV] = +37.1046`, so `INV` is not bounded above by its own mean and the prefix result is
   a fact about prefix arrangements rather than about the statistic. **Precedent from the
   190-cell lower bound: the worst `INV_prefix(k) - E[INV](k)` anywhere over 20 champions, 3 bands and
   every non-degenerate `k` is -2.5556**, so the construction is expected to pass by a wide margin; on
   failure, the panel half of this design reads composition for a third time and no panel-relative
   verdict is available. Also printed, for the same reason RC3-1 exists: the value the WITHDRAWN
   mean-centred median would have taken on the same trajectory, which on the 190-cell lower bound is a
   median of **+15.6000** at band 0.10, i.e. branch 7.

**THREE FREE SELF-CHECKS THE PANEL MUST PASS, because most of it has been measured before:**

- **SC3a:** the 190 champion-versus-champion cells must reproduce `exp066_crossplay.txt` cell for
  cell.
- **SC3b:** the 100 champion-versus-rung cells must reproduce the per-seed rung profiles in
  `exp066_floor_feed.txt` term for term.
- **SC3c:** the 10 rung-versus-rung cells must reproduce `exp066_recovered_rates_and_null_fix.txt`.
  Six of those pairs were measured post hoc there; measuring them here under pre-registration makes
  them pre-registered for phase 1.

Any disagreement fires **IF-5 NON-DETERMINISTIC** and voids everything. The engine is a deterministic
integer simulation on a deterministic start generator, so these are equalities, not agreements to
within tolerance.

**What phase 0's probes suggest the panel will show, quoted as the REASON FOR MEASURING and not as an
established fact.** `exp066_two_attractors_probe.txt` section I (POST HOC, unregistered) reports that
the champions' own ordering is roughly orthogonal to their floor-bot competence: Spearman rho
-0.1451; the strongest cross-play champion of all twenty is seed 2016 at row mean 0.8352, which is in
neither competence tier; the second strongest is 2015 at 0.6918, a near-parity champion; the weakest
of all twenty, 2005 at 0.2316, is a kill-mode champion at held-out 0.9938 against the floor bot; and
the near-parity group's mean row mean, 0.5366, EXCEEDS the kill group's 0.4454. If the pre-registered
panel measurement reproduces that, then the panel's dominance order is not a competence order, which
is the whole reason the seeding rule below does not use floor-gate ordering.

---

## The coevolution design

### The fitness

```
F(G) = mean over the opponent set O and over 4 train starts x 2 seats of margin(match)
margin  = phase 0's margin/1, unchanged, in arena fixed point, with the 25600 death floor
```

**No ladder, no shaping, no survival term, no energy term.** The ladder is discarded by phase 0's own
DISCARD note. Shaping is refused for the same reason phase 0 refused it: every cheap intermediate
signal available here (scans held, gun alignment, shots fired) is a proxy for a rung below the floor.
The death floor is kept because it is what makes dying weakly worse than surviving with the same
damage taken, at every turn, and its constant is the tank's own starting energy rather than a chosen
number.

**MARGIN, NOT WIN RATE, and the mismatch with the matrix is pre-committed rather than patched.** The
matrix cell is a win rate; the fitness is a margin. That is the same gate-versus-fitness mismatch
phase 0 decided rather than patched, and it gets the same treatment: no bonus constant is invented,
because a bullet kill already yields approximately one full bar of margin so margin ranks kills far
above draws by construction. The pre-committed secondary reading is that a champion can out-damage
without out-winning, and both are reported per checkpoint.

**Both optimisers select by RANK** (`mu_lambda_es` sorts and keeps the mu best offspring under comma
selection; `sep_cma_es` sorts and recombines the best mu), verified in both sources, so no magnitude
of `F` is read anywhere and the margin's scale carries no exchange rate.

### The opponent set, and this is the experimental variable

| Arm | Opponent set for generation `g` | `K` |
|---|---|---|
| **A1 ANCHORED** | 3 drawn from the previous generation's top-mu offspring, plus 3 drawn uniformly from the HALL OF FAME (the run's archived checkpoint champions so far, plus the seed at evaluation 0) | 6 |
| **A2 UNANCHORED** | 6 drawn from the previous generation's top-mu offspring only | 6 |
| **A3 DECOUPLED** | positions `((g-1)*6 .. (g-1)*6+5) mod 20` of a FROZEN, ONCE-SHUFFLED copy of the PAIRED A1 run's 20-checkpoint archive, a generation-indexed walk | 6 |
| **A4 SECOND OPTIMISER** | as A2 | 6 |

Generation 1 has no previous generation, so `O_1 = {the seed}` for the seeded arms and
`O_1 = {a uniform draw from the generation's own offspring}` for A4, `K = 1` for that generation only,
still one evaluation per offspring. A3 needs no special case: its generation 1 is positions 0 to 5 of
its frozen list. Stated so it is not decided at implementation time.

**ONE OPPONENT SET PER GENERATION, SHARED BY ALL `lambda` OFFSPRING (DESIGN gate RC-9a).** `O_g` is
drawn once per generation and every one of the generation's 20 (or 70) offspring is scored against
that same set, on the same 4 train starts in both seats. Comma selection then ranks offspring on a
COMMON comparison, which is the only way a rank is meaningful; per-offspring opponent draws would
rank them on different problems. The first version left this unstated.

**A3's SHUFFLE IS NOW LOAD-BEARING, WHICH IT WAS NOT (DESIGN gate RC-9b).** The first version drew A3's
opponents UNIFORMLY from a shuffled list, and a uniform draw from a shuffled list is exactly a uniform
draw from the list, so the shuffle and its seed `{3, RunSeed, 9}` were dead code and the record's seed
table would have implied a time structure that was never controlled. A3's purpose is to keep the same
champions and destroy the time order, so the shuffle must be the thing the schedule reads: the archive
is permuted ONCE by a Fisher-Yates shuffle off `{3, RunSeed, 9}` and generation `g` consumes the next 6
positions of that permutation, wrapping. Over 2,500 generations that is 15,000 opponent slots and each
of the 20 members appears in exactly 750 of them, which is **SC12** rather than an assertion. This is
also closer to insight 057's shape, a schedule over a frozen curriculum.

**A3 INHERITS ITS PAIRED A1 RUN'S DEFECTS, AND THE COUPLED-AGAINST-DECOUPLED COMPARISON NOW HAS AN
EXCLUSION RULE FOR THAT (gate blind spot 4, which none of the six required changes covers).** A3's
curriculum IS the paired A1 run's 20-checkpoint archive, so if that A1 run is degenerate the control
inherits the degeneracy and the comparison is between a coupled arm and a decoupled arm walking a
curriculum that is not a curriculum. **Pre-committed, in one sentence: an A3 run whose paired A1 run at
the same run seed is UNGRADEABLE for cycling (IF-1 FLOOR-LOST, CONVERGED-UNGRADEABLE or NULL-UNFIT), or
whose frozen curriculum contains fewer than 15 DISTINCT phenotypes after dedup, is EXCLUDED from the
coupled-against-decoupled Fisher exact comparison and from the DECOUPLED-CONTROL CYCLED label, is
reported with its exclusion reason and its own counts, and the Fisher comparison is computed on the
surviving PAIRS with both `n` values printed; if fewer than 7 of the 13 pairs survive, the coupling
attribution is reported as UNAVAILABLE rather than as a null result.** The 7-of-13 here is the same
majority notion the ladder (PART 4) already uses, not a new constant. **The exclusion cannot be steered by A3's
result**, and the guarantee is structural rather than temporal: it is a function of the PAIRED A1 RUN's
floor trajectory, its distinct-phenotype count after dedup and its Null A fit gate, and not one of those
three reads any A3 number. Both arms' counts are computed at protocol step 7, so the protection is that
the exclusion predicate cannot see A3, not that it is evaluated earlier.

The top-mu list is reconstructed by the collector from the fitnesses it observes, which reproduces the
optimiser's own comma selection exactly (the top mu of that generation's lambda offspring) because the
collector sees the same values.

**EVERY DRAW COMES OFF A SEEDED `rand exsss` STREAM AND A RUN IS REPRODUCIBLE FROM ITS SEEDS, BUT
THERE ARE NOW TWO STREAMS PER RUN AND NOT ONE (DESIGN gate RC-6).** The split exists so that common
random numbers survive across arms; the seed table and the reason are in "Seeds and every random
quantity, persisted" below, and **SC11** checks that the shared stream is actually shared.

**THE ANCHOR IS THE VARIABLE AND ITS BIAS DIRECTION IS DECLARED NOW.** A hall of fame is the standard
device for preventing coevolutionary forgetting, and preventing forgetting is precisely what
suppresses cycling. So A1 is biased AGAINST a positive and A2 is the maximal-chance arm. A2 in turn
risks losing absolute competence, which would make its matrix unreadable against the floor
certification (IF-1). **Those two failure directions are the squeeze `SYNTHESIS_P7.md` found twice**
("every configuration tested was either too decoupled to escalate or too coupled to survive, and no
lever was found that moves between those two failure modes"), and the possibility that phase 1
reproduces it one level up is pre-committed as a named outcome (THE ANCHOR SQUEEZE, in the reading
table below) rather than discovered afterwards.

**NO FITNESS CACHE.** Phase 0 could cache on the quantised integer weight list because its fitness
was deterministic AND stationary. A coevolutionary fitness is non-stationary, so a genome-keyed cache
returns a stale value computed against a previous opponent set. The cache is removed and the reason is
recorded, because reusing it is the kind of silent defect that produces a wrong signed result.

**THE OPTIMISER'S RETURNED `best` AND `fitness` FIELDS ARE MEANINGLESS HERE AND ARE NOT READ.** Both
optimisers track a global best-by-fitness across generations, and under a non-stationary fitness
values from different generations are not comparable. The archive is built by the collector, and the
only accounting check against the optimiser is SC5, that the collector's evaluation count equals the
optimiser's returned `evaluations`.

### Seeding: WHICH champions, and it is a recorded pre-committed decision

**Seeds: the 13 kill-mode arm S champions, one per run, all of them, no ordering applied.**

`[2001, 2002, 2003, 2004, 2005, 2006, 2008, 2010, 2012, 2013, 2017, 2019, 2020]`

- **Constraint discharged: no arm D.** Eight of ten arm D champions fail phase 0's own relevance line
  on a rung below the one they trained against, and eight of ten occupy a `circle_strafer` band
  (strictly between 0.875 and 0.98125) that is empty across all thirty full-ladder champions. Cycling
  in a mixed population would be unattributable between substrate and curriculum.
- **Constraint discharged: the floor gate's ordering is NOT a seeding filter.** The tier is a BAND
  MEMBERSHIP, not a rank, and all 13 members of the band are used. "Take the best floor performers" is
  refused, and phase 0's own reason is quoted: the gate certifies competence against ONE scripted
  opponent and its ordering of these champions is roughly orthogonal to the ordering they impose on
  each other. `sep_cma_es` takes ONE `x0` vector, so 13 champions map onto 13 runs, one each. That is
  why the arm has 13 seeds rather than a round number.
- **THE POOL ITSELF IS CHOSEN, NOT FORCED, AND THE ROUND-2 GATE WAS RIGHT THAT THE CHOICE WAS NEVER
  ARGUED (RC2-5).** The constants table used to mark the seed count **FORCED by the seeding rule**,
  which is circular: the rule is the choice. It now reads CHOSEN, and the choice is argued here against
  the named alternative.

**THE NAMED ALTERNATIVE, AND EXACTLY WHAT IT ADDS.** The alternative pool is "all floor-holding arm S
champions", meaning every arm S champion with held-out `W >= B = 0.5748` against `predictive_gun`. That
pool has **18 members, not 13**. Reproducible from `exp066_recovered_rates_and_null_fix.txt` section C
(the `predictive_gun`-versus-champion cells, 160 matches each):

| champion | held-out `W` vs floor bot | in the kill band? | headroom above `B`, in matches of 160 |
|---|---|---|---|
| the 13 kill-band seeds | 0.9375 to 1.0000 | yes | **58 to 68** |
| **2016** | **0.8000** | **no, singleton class at p10 115.8** | **36** |
| 2018 | 0.60625 | no, near parity | 5 |
| 2007 | 0.58125 | no, near parity | 1 |
| 2014 | 0.58125 | no, near parity | 1 |
| 2009 | 0.5750 | no, near parity | **1** (92 of 160; `B` is 91.968 of 160, so it clears by one match) |
| 2011 | 0.5375 | no, near parity | below `B`, excluded from the alternative too |
| 2015 | 0.41875 | no, near parity | below `B`, excluded from the alternative too |

**THE ARGUMENT FOR THE KILL BAND, AND IT IS A FLOOR-HEADROOM ARGUMENT RATHER THAN A COMPETENCE ONE.**
The floor precondition requires `W >= B` at 15 of a run's 20 checkpoints. A seed one match above `B`
fails that precondition the moment coevolution moves it at all, so 2007, 2009, 2014 and 2018 would enter
as runs that are UNGRADEABLE by construction from checkpoint 1, and IF-13 SEED-ERASED would be firing on
the pool rather than on the step size. The 13 kill-band champions carry 58 to 68 matches of headroom, so
the floor precondition is a real test on them instead of a foregone conclusion. **That argument is
quantitative, checkable, and it excludes exactly the four near-parity champions.**

**IT DOES NOT EXCLUDE 2016, AND THAT IS RECORDED AS THE WEAKEST LINK IN THIS DECISION RATHER THAN
PAPERED OVER.** Seed 2016 holds the floor at 0.8000 with 36 matches of headroom, and it is the strongest
cross-play champion of all twenty (row mean 0.8352) and the top of the fitted Bradley-Terry order at
strength 4.19469 (`exp067_null_a_calibration.txt` section B), so it is the panel's likely apex. The only
ground on which this design excludes it is that the p10 closing-range classifier puts it alone in a
singleton class at 115.8, in neither tier. **A singleton class is a classification fact, not a reason,
and the gate is right that "the tier is a BAND MEMBERSHIP" does not discharge the choice.** The pool is
kept at 13 anyway, and the reason is stated as what it is: 13 is the number every downstream arithmetic
in this document is built on (the within-arm replication requirement, the 10-of-13 and 7-of-13
fractions, the compute budget's 39 runs), and re-deriving all of it to add one seed is a change this
design is not entitled to make after a gate round while claiming nothing was moved. **The exclusion of
2016 is therefore an UNARGUED RESIDUAL of a CHOSEN pool, and it is written down as one.**

**THE ROUND-3 GATE ACCEPTED THIS AS THE WEAKER-BUT-HONEST FORM RC2-5 ASKED FOR, and its reason is
recorded so the concession is not read as more than it is.** The gate's finding: the floor-headroom
argument genuinely discharges the four near-parity exclusions and is quantitative and checkable, the row
reads CHOSEN, the LOWER-HALF-SEEDED label is pre-committed on any PANEL-VISIBLE positive, and the scope
line is in the negative's limits, so the load-bearing protections all landed; what did not land is the
argument for the pool's APEX exclusion, and this document says so rather than papering it. **The gate
also recorded that "13 is the number every downstream arithmetic is built on" is a BOOKKEEPING reason and
not a scientific one**, since the three fractions that consume it (3-of-13 replication, 10-of-13 floor,
7-of-13 majority) are defined as fractions and would simply be recomputed on 14. That is true and it is
left standing as the reason, labelled as bookkeeping.

**WHAT THE CHOICE COSTS ON THE PANEL INSTRUMENT, DECLARED IN THE POSITIVE DIRECTION.** The 13 seeds sit
in the panel's lower half: on the champion-only lower bound at band 0.10 their `k_C` runs from 0 to 11 of
`n_C` 14 to 18, so **seeding only from the lower half maximises panel-climb headroom**, and panel climbing
is precisely the composition drift that inflated the first version's raw `INV` delta. That interaction is
the reason RC2-1 and RC2-5 arrived together. RC2-1's conditioning on `k_C` removes the mechanical part of
it; what conditioning cannot remove is that a pool with more room to climb gives the instrument more
opportunity to move at all. **A PANEL-VISIBLE positive therefore carries the label LOWER-HALF-SEEDED**,
pre-committed here, naming that the seeds were drawn from the lower half of the panel they are scored
against.
- **Constraint discharged: the tier of each seeded champion is RECORDED, and by which classifier.**
  `trainW` reads 1.0000 for all 40 phase 0 champions and identifies nobody. The classifier is the
  **tenth percentile of perceived closing range** (`exp066_two_attractors_probe.txt` section F), which
  is held out and independent of both cross-play and the win rate, and whose three group ranges are
  disjoint and ordered so that no threshold has to be chosen: near parity {6.2, 13.3}, seed 2016 alone
  at 115.8, kill mode {143.7, 258.2}, gaps 102.5 and 27.9. Every threshold pair inside those two gaps
  reproduces the same partition.

**Per-seed record, frozen here, reproducible from `exp066_within_tier_recount.txt` section C and
`exp066_policy_probe.txt` section C, plus the clamp fraction computed from
`exp066_champions_s.eterm`:**

| run | seed | held-out W vs floor bot | p10 closing range | mean standoff range | regime | fraction of coordinates at the plus or minus 2048 clamp |
|---|---|---|---|---|---|---|
| 1 | 2001 | 0.9750 | 143.7 | 183.8 | tight orbit | 0.3488 |
| 2 | 2002 | 0.9375 | 145.7 | 184.8 | tight orbit | 0.3096 |
| 3 | 2003 | 1.0000 | 234.0 | 294.0 | **long standoff** | 0.2456 |
| 4 | 2004 | 0.9938 | 152.9 | 191.8 | tight orbit | 0.1744 |
| 5 | 2005 | 0.9938 | 150.6 | 185.9 | tight orbit | 0.3594 |
| 6 | 2006 | 0.9938 | 149.7 | 188.1 | tight orbit | 0.2989 |
| 7 | 2008 | 0.9750 | 148.0 | 182.7 | tight orbit | 0.2918 |
| 8 | 2010 | 0.9875 | 178.4 | 214.6 | mid orbit | 0.2562 |
| 9 | 2012 | 1.0000 | 153.2 | 198.3 | tight orbit | 0.3132 |
| 10 | 2013 | 0.9750 | 258.2 | 308.3 | **long standoff** | 0.3096 |
| 11 | 2017 | 1.0000 | 170.9 | 207.5 | mid orbit | 0.2562 |
| 12 | 2019 | 0.9812 | 149.4 | 190.8 | tight orbit | 0.3345 |
| 13 | 2020 | 0.9875 | 159.6 | 196.8 | tight orbit | 0.1530 |

Kill-mode clamp fractions: min 0.1530, median 0.2989, max 0.3594. Recorded because phase 0's IF-4
(SEARCH-DIVERGED) reads "more than half the coordinates at the clamp", and a seeded run INHERITS a
third of them, so the flag must read a CHANGE and not an inherited state.

**THE LONG-STANDOFF SEEDS ARE INCLUDED, AND WHAT THAT COSTS IS STATED NOW.** Within phase 0's
kill-mode tier every cyclic triple at every band contains seed 2003 or seed 2013. That is checkable
directly from the per-cycle member listing in `exp066_within_tier_recount.txt`: the four cycles at
bands 0.10 and 0.15 are {2001,2013,2003}, {2001,2013,2006}, {2003,2020,2012} and {2003,2020,2013}, and
band 0.05 adds {2003,2010,2012}, {2003,2010,2013}, {2003,2017,2012} and {2003,2017,2013}.

**THAT RESIDUE CLAIM IS NOW PERSISTED, WHICH IT WAS NOT (DESIGN gate RC-8).** The first version said
the zero-cycles recomputation "is from an adversarial review pass and is persisted in no record", and a
pre-registration may not hang a verdict label (IF-12's POCKET RETAINED against POCKET ENTERED OR
CREATED) or a hypothesis (H4) on a number that exists only in a reviewer's notes. Recomputed and
persisted in `programmes/p7_coevolution/exp066_competence_floor/exp066_residue_and_inv0.txt` section B,
by `scripts/exp066_residue_and_inv0.escript` over `exp066_crossplay.txt`, on the integer grid, with
three gates against the persisted records first:

| band | set | cycles | cyclable triples | triples | decisive edges | of pairs |
|---|---|---|---|---|---|---|
| 0.05 | kill tier, 13 members | 8 | 243 | 286 | 74 | 78 |
| 0.05 | **residue, 11 members** | **0** | 130 | 165 | 51 | 55 |
| 0.10 | kill tier, 13 members | 4 | 204 | 286 | 70 | 78 |
| 0.10 | **residue, 11 members** | **0** | 115 | 165 | 49 | 55 |
| 0.15 | kill tier, 13 members | 4 | 179 | 286 | 67 | 78 |
| 0.15 | **residue, 11 members** | **0** | 96 | 165 | 46 | 55 |

Every one of the 8, 4 and 4 kill-tier cycles contains 2003 or 2013; the record lists all of them by
member and cross-checks the residue count against the number containing neither, at every band. **The
zero is not a shortage of decisive material**: the 11-member residue still carries 115 cyclable triples
at band 0.10, any of which could have been cyclic.

The two seeds are the tier's behavioural outliers on both printed columns: mean standoff range 294.0 and
308.3 against 182.7 to 214.6 for the other eleven, p10 234.0 and 258.2 against 143.7 to 178.4. **So the
only within-tier pocket the landscape is known to have sits between the long-standoff regime and the
orbit regimes.**

**AND THAT IS A REFUTATION OF THE RECOUNT'S OWN CONCLUSION, NOT AN ELABORATION OF IT, WHICH THIS
DOCUMENT MUST CITE THE WAY THE RECORD DOES.** `exp066_within_tier_recount.txt` section D carried the
sentence "A cycle counted here is a cycle among peers of the same competence, so it cannot be an
artifact of mixing tiers", and that record now carries a boxed note marking the sentence **REFUTED**:
partitioning on COMPETENCE was not sufficient, because the residue is the same regime-boundary mechanism
one level down, on the BEHAVIOURAL axis. The same refutation is recorded in the signed insight's dated
correction (`faber-ecosystem/insights/066-evolution-clears-the-robo-rumble-competence-floor.md`, section
"APPENDED CORRECTION AND POINTER, 2026-07-30", commit 224247f): "the residue tracks **regime**
boundaries, not competence boundaries". **The consequence for phase 1 is a reading rule, and it is
pre-committed:** any cyclic residue in any phase 1 matrix is read first as a candidate REGIME BOUNDARY
and only then as anything else, and the behavioural regime of every member of every counted cycle is a
required report beside the damage provenance, the edge families and the margin slack. A cycle whose three
members all sit in one behavioural regime is a materially stronger object than one that straddles two,
and phase 0 has no example of the former: its 11-member one-regime-family residue carries **zero** cycles
at all three bands.

**AND THE REGIME-BOUNDARY READING NEEDS ITS OWN BASELINE, WHICH THE SAME CORRECTION BLOCK SUPPLIES AND
WHICH CUTS AGAINST OVERREADING IT.** `exp066_within_tier_recount.txt` correction 2: the observed spanning
shares of 41 of 49, 14 of 18 and 8 of 12, which are 84, 78 and 67 percent, look decisive until compared
with what UNIFORM allocation over cyclable triples already gives, **67.7, 63.1 and 61.6 percent** (543 of
802, 381 of 604, 300 of 487). "The boundary produced most of the cycles" is therefore **a near-null effect
at band 0.15 and modest at 0.05**, and the record files it under the same error it records against its
parent note, a raw share reported against no reference. **So the phase 1 reading rule is that a
boundary-spanning share is reported ONLY beside its uniform-allocation baseline over that matrix's own
cyclable triples**, never as a raw share, and the regime attribution of a cycle is a description of the
cycle rather than an explanation of it. Two behavioural outliers carrying every within-tier cycle is a
strong fact because the complement is exactly zero; a spanning share of 78 percent against a baseline of
63 percent is not.

**THE COUNTING RULE THAT FELL OUT OF THE SAME CORRECTION IS ALREADY BINDING ABOVE, AND THIS IS WHERE IT
CAME FROM.** The recount's band-0.10 decisive-edge and cyclable-triple counts are one edge high (71 and
213 against the exact 70 and 204) because a float band test admits an edge whose margin is exactly the
band, and 0.10 is exactly 16/160. **COUNT INTEGERS.** The cycle counts themselves are unaffected at every
band (8 / 4 / 4 either way), which is why the table above is safe to quote while the edge and cyclable
columns are quoted from `exp066_residue_and_inv0.txt` section B on the integer grid rather than from the
recount. The same rule is what makes the observed decisive count of record 150 rather than 152 in "Null A
has now been run on a real matrix".
Excluding those two seeds would remove it and bias the design toward a negative; including them
biases a positive toward "the pocket was already there". Both readings are pre-committed:

- A positive whose cycles all appear in runs seeded from 2003 or 2013 is reported as **POCKET
  RETAINED**, and is the weaker claim (IF-12).
- A positive whose cycles appear in runs seeded from the tight or mid orbit regimes is reported as
  **POCKET ENTERED OR CREATED**, and is the stronger claim.

### The optimisers and the initial step size

| Arm | Optimiser | `x0` | `init_sigma` | lambda | mu | generations | Role |
|---|---|---|---|---|---|---|---|
| **A1** | `sep_cma_es` | dequantised kill-mode champion | frozen by pilot | 20 | 10 | 2,500 | PRIMARY, anchored |
| **A2** | `sep_cma_es` | same | same as A1 | 20 | 10 | 2,500 | PRIMARY, unanchored, maximal chance |
| **A3** | `sep_cma_es` | same | same as A1 | 20 | 10 | 2,500 | DECOUPLED CONTROL, mandatory |
| **A4** | `mu_lambda_es` | none available | 1.0 | 70 | 10 | 714 | SECOND OPTIMISER CLASS, conditional |

`lambda` and `mu` are the verified library defaults at Dim 281 (`sep_cma_es`
`lambda = 4 + trunc(3*ln N)` gives 20, `mu = lambda div 2` gives 10; `mu_lambda_es` mu 10 lambda 70).
`max_generations = 50000 div lambda`, phase 0's formula, giving 50,000 evaluations for A1 to A3 and
49,980 for A4.

**`x0` IS THE DEQUANTISED CHAMPION.** The archive stores the quantised integer weight list at scale
256 with the plus or minus 2048 clamp, so `x0 = [I / 256.0 || I <- ArchivedInts]`. **SC1:**
`robo_net:quantize/1` of that float list must return the archived integer list exactly, for all 13
seeds, or the seed is not the champion that was measured.

**`init_sigma` IS MEASURED AND FROZEN BEFORE THE ARMS, NOT CHOSEN.** Phase 0 used 1.0 from a random
`x0`; 1.0 on a trained champion whose weights cap at 8.0 would erase the seed in one generation, and
the run would then start below the certified floor. The pilot, pre-committed:

```
For sigma in [1.0, 0.3, 0.1, 0.03], in that order, on 3 pilot seeds (2001, 2010, 2013 = one tight
orbit, one mid orbit, one long standoff), run ONE generation of A1 and score the generation best
against predictive_gun on the 30 CALIBRATION starts (indices 87..116, both seats, 60 matches).
FREEZE the LARGEST sigma whose MEDIAN calibration win rate over the 3 pilot seeds is >= B = 0.5748.
If none qualifies, freeze 0.03 and record that the pilot's own floor was not met, which fires
IF-13 in advance and makes every seeded arm's first checkpoints suspect.
```

The pilot runs on CALIBRATION starts, never on held-out, because held-out carries the matrix and the
floor monitor. This mirrors phase 0's rule that everything tunable is measured and frozen before the
first arm runs, on the split reserved for building.

**A4 CANNOT BE SEEDED and that is a fact about the library, not a choice.** `mu_lambda_es:evolve/3`
takes no `x0` and initialises mu parents from `random_vector(Dim)` (verified in source), so A4 starts
from random genomes, which sit at the random-genome null `R = 0.0125` against the floor bot. A4 must
therefore climb the floor while coevolving, and if it does not, its matrix is uninterpretable in
exactly the way the floor exists to prevent. **A4 is UNGRADEABLE for cycling unless it satisfies the
floor precondition, per run, and at arm level unless at least 10 of its 13 runs do (DESIGN gate RC-7,
where the fraction is fixed)**, and that is stated in advance so its negative branch cannot be read as a
substrate negative. A4 is nonetheless the right second class, for one reason: its mu = 10 parents are
DISTINCT vectors and can hold coexisting counter-strategies, which `sep_cma_es`'s single Gaussian mean
cannot. That limitation of the primary arm is named again below as the largest threat to a negative.

---

## Protocol, and the order is load-bearing

```
1. Instrument checks and self-checks SC1, SC3a, SC3b, SC3c, SC4, SC7. Any failure STOPS here,
   and the runner ENFORCES this rather than documenting it.
2. Measure the reference panel: 300 pairs, 48,000 matches. Fit and FREEZE its dominance order,
   report the order's own violations over all 300 pairs AND over the 190 champion pairs, which is
   IF-8's real headroom (RC3-5), compute E[INV], the permutation range, the permutation MAXIMUM
   and INV_0 for each of the 13 seeds, and print INV_0 beside the champion-only lower bound this
   document already carries, which is SC13. Then run the three checks that cost no matches and
   that the panel-half decision rules rest on: the Null C MONOTONICITY check over all 25 members
   (item 6, RC3-3), the EXCEEDANCE REACHABILITY read over all 25 members with both readings
   pre-committed (item 7, RC3-6), and the SYNTHETIC BACKBONE-CLIMBER test, which is SC15 (item 8,
   RC3-1). Nothing after this point may change the panel.
3. Run the init_sigma pilot on CALIBRATION starts. FREEZE sigma.
4. Run arms A1 and A2 (26 runs). Archive 20 checkpoints each plus checkpoint 0. SC11 is
   evaluated here, on A1 against A2 at every run seed.
5. Score every archived champion against the panel (525 cells per run) and build every archive
   matrix (190 pairs per run), deduplicating identical phenotypes by content hash before the
   primary count and reporting n. The predictive_gun column of the panel scoring IS the floor
   monitor, so it costs nothing extra.
6. Run arm A3, whose opponent sets walk A1's frozen shuffled archives (13 runs). SC11 is
   completed here (A3 against A1 and A2 at generation 1) and SC12 is evaluated. Score and
   matrix it identically.
7. Compute Null A, Null B and Null C on every matrix, and for Null C compute the 200-permutation
   MAXIMUM as well as the mean and range at every checkpoint, because the panel conjunct now reads
   the maximum. Evaluate CYCLIC legs (i), (ii) and (iii) per run. Decide every IF flag. Emit the
   per-cycle behavioural report (damage provenance, edge families, minimum margin slack, regime) for
   every counted cyclic triple. Apply the A1-A3 degeneracy exclusion and print the pair accounting.
   Compute the gradeable base and the qualifying base per arm BEFORE reading the branch 6 / 7 median.
8. Run arm A4 ONLY IF no single arm reached 3 CYCLIC runs, which is the CYCLING branch's COUNT
   condition and not its panel sub-label: existence of intransitivity is settled by one
   optimiser class, so a SELF-RELATIVE positive does not trigger A4 either.
```

Step 4 cannot precede step 2 or step 3, and step 6 cannot precede step 4, and no null may be
computed before step 2 has frozen the panel.

### The archive

- **Checkpoints at every 2,500 unique evaluations, k = 1..20**, at the first generation whose
  cumulative evaluation count reaches `k * (E / 20)` where `E` is the arm's total (50,000, or 49,980
  for A4). The checkpoint champion is that GENERATION's best, not the optimiser's global best.
- **Checkpoint 0** is the seed at evaluation 0. It is recorded, scored against the panel, and used for
  SC2 and as the `INV` baseline. **It is NOT a member of the archive matrix**, which is over the 20
  evaluation checkpoints so that it is scale-matched to phase 0's 20-champion matrix exactly.
- **Each archived entry records**: arm, run seed, checkpoint index, evaluation count, generation, the
  quantised integer weight list, the count of coordinates at the plus or minus 2048 clamp, the count of
  distinct quantised phenotypes among that generation's lambda offspring, and a content hash (first 16
  hex characters of the SHA-256 of the integer list) so a matrix cell is attributable to a genome
  without ambiguity.
- **Lineage beyond the run seed is OUT OF SCOPE.** Under `sep_cma_es` the state is a mean, so there is
  no individual lineage to record, and the whole archive of a run descends from one seed. Recording
  parent identifiers only for A4 would make the arms non-comparable.
- **DUPLICATE CHECKPOINTS ARE DEDUPLICATED BY CONTENT HASH BEFORE THE PRIMARY COUNT (DESIGN gate
  RC-5).** A run that converges emits the same quantised phenotype at several checkpoints, and identical
  members produce indecisive cells, which deflates decisive edges, cyclable triples and the cycle count.
  The full 20-member matrix is still built and reported, because that is what is scale-matched to phase
  0's matrix; the PRIMARY count runs on the above-floor submatrix with duplicates removed, and its `n`
  is reported with every count. The content hash the archive already records is what does the removing,
  so nothing new is measured.
- **THE CHECKPOINT SPACING IS A SAMPLING RATE, AND IT SCOPES EVERY NEGATIVE (gate blind spot 2).** One
  genome per 2,500 evaluations means a Red Queen cycle whose period is shorter than about two checkpoint
  intervals aliases into noise or vanishes entirely, and no instrument in this design reads
  within-interval dynamics. **A NO CYCLING verdict is therefore scoped to cycling slower than this
  sampling rate**, and that sentence is carried into the negative's scope section rather than left to a
  reader to notice.
- **THE ARCHIVE IS ONE LINEAGE'S BEST, NOT A POPULATION SNAPSHOT (gate blind spot 3).** `sep_cma_es`
  carries a single Gaussian mean, so coexisting counter-strategies WITHIN a generation, which is the
  textbook form of coevolutionary cycling, are invisible to a matrix of generation-best champions **by
  construction**. The design half-said this as A4's rationale; it is said plainly here. The primary
  instrument can see cycling between successive states of one lineage and cannot see within-generation
  polymorphism at all.

### Seeds and every random quantity, persisted

Nothing in the match path comes off `rand`: the engine is a deterministic integer simulation on a
deterministic start generator. The random quantities are the optimiser's sampling, the opponent draws,
the time shuffle and the null draws, and all of them are named here.

| what | seed |
|---|---|
| **optimiser sampling stream, SHARED ACROSS ARMS at the same run seed** | `rand exsss` from `{RunSeed, 7}`, RunSeed 3001..3013, identical in A1, A2 and A3 |
| **opponent-draw stream, per arm** | `rand exsss` from `{ArmCode, RunSeed, 11}`, ArmCode 1..4 |
| A3's time-shuffle permutation of the paired A1 archive (Fisher-Yates, once per run, then walked) | `{3, RunSeed, 9}` |
| Null A, Bradley-Terry bootstrap | `{3661, MatrixIndex, 0}`, 200 draws, fresh per matrix |
| Null B, orientation | `{3660, MatrixIndex, 0}`, 200 draws |
| Null C, row permutation | `{3662, MatrixIndex, ChampionIndex}`, 200 draws |
| init_sigma pilot | pilot run seeds 3901, 3902, 3903 |

Phase 0 used 2001..2020 and 660 / 661 / 662; phase 1's ranges are disjoint from all of them.
`rand` state is per process, so 32-way parallelism is deterministic. **SC9:** two consecutive
executions of every null column must produce byte-identical output.

**COMMON RANDOM NUMBERS ARE RESTORED ACROSS ARMS, AND THE FIRST VERSION BROKE THEM (DESIGN gate
RC-6).** The first version seeded one stream per run from `{ArmCode, RunSeed, 7}`, which makes every
random quantity in the run arm-specific by construction. Phase 0 honoured the programme's standing
method (common random numbers by run index across arms), and A1 against A2 is a comparison PAIRED BY
RUN SEED that both the reading table (PART 4) and H2 (PART 5) lean on, so an unnamed derogation would have confounded the
arm difference with a stream difference. The optimiser's sampling stream is therefore shared and only
the opponent draws are arm-specific.

**WHAT CRN BUYS HERE AND WHAT IT DOES NOT, stated so it is not oversold.** `sep_cma_es` samples
generation 1's offspring before any fitness is known, so at the same run seed A1, A2 and A3 evaluate
the SAME 20 offspring vectors in generation 1, which is **SC11**. From generation 2 the opponent sets
differ, the fitness ranking differs, the covariance update differs and the trajectories diverge, so CRN
does not hold the arms' later samples in common and no variance-reduction claim is made beyond
generation 1. What it does buy is that the seed-level and generation-1 confound is removed rather than
assumed away, and that the paired reading is exactly as paired as it says. **A4 shares nothing**: it is
a different optimiser at a different `lambda` from an unseeded start, so there is no correspondence to
share, and that is stated rather than left to be inferred from the table.

**A3 CONSUMES NO OPPONENT DRAWS.** Its schedule is deterministic given its shuffle, so its opponent-draw
stream `{3, RunSeed, 11}` is never advanced and the only randomness in A3's opponent sequence is the one
Fisher-Yates permutation off `{3, RunSeed, 9}`. The row is kept in the table so the arms are described
uniformly, and it is stated here that it is unused rather than left to imply draws that do not happen.
The stride-6 walk over 20 positions has period 10 generations and covers each position exactly 3 times
per period, which is where SC12's 750 comes from: 2,500 generations is 250 periods, 250 x 3 = 750.

### The self-checks, and each one can go red

| id | check | on failure |
|---|---|---|
| **SC1** | `quantize(dequantize(archived))` equals the archived integer list, all 13 seeds | stop |
| **SC2** | the archive's checkpoint-0 row against the panel equals the panel's own internal row for that seed, cell for cell | IF-5, void |
| **SC3a/b/c** | the panel reproduces `exp066_crossplay.txt`, the feed's rung profiles, and `exp066_recovered_rates_and_null_fix.txt` | IF-5, void |
| **SC4** | seat symmetry: `W(J,I) = L(I,J)` exactly, on 10 pre-committed pairs of the panel and of every archive matrix | the half-matrix licence is void, matrices are re-measured in full at double cost |
| **SC5** | collector evaluation count equals the optimiser's returned `evaluations` | stop |
| **SC6** | `ordered = 2 * forward + backward` at every band on every matrix | stop |
| **SC7** | `robo_match_tests`' golden match vector `DFCD8106…B3895E88` recomputed | IF-5, void |
| **SC8** | Null B's decisive-edge count equals the observed exactly at every band | the null is not matched, IF-9 |
| **SC9** | two consecutive executions of every null column are byte-identical | stop |
| **SC10** | re-running arm A1 seed 3001 reproduces its whole 21-entry archive bit-identically | IF-5, void |
| **SC11** | at every run seed, A1, A2 and A3 evaluate the SAME 20 generation-1 offspring vectors, bit-identically, which is what common random numbers across arms MEANS here | stop; CRN is not in force and the paired A1-against-A2 reading is void |
| **SC12** | each of the 20 members of A3's frozen shuffled archive appears in exactly 750 of that run's 15,000 opponent slots | stop; the decoupled control's schedule is not what the document says it is |
| **SC13** | the 25-member panel's `INV_0` for each of the 13 seeds is at least the champion-only value printed in section I1 (PART 2), at every band | IF-5, void; the panel does not contain the 190-cell submatrix SC3a says it reproduces |
| **SC14** | Null C's 200-permutation MEAN agrees with its exact closed form `D_C * k_C * (n_C - k_C) / (n_C * (n_C - 1))` to within one count, for every champion at every checkpoint at every band, and the permutation MAXIMUM is computed from the same 200 draws as the mean | stop. **ADDED by DESIGN gate round 2 (RC2-1). ITS JUSTIFICATION IS REWRITTEN BY ROUND 3 (RC3-1) AND THE CHECK IS UNCHANGED AND MORE LOAD-BEARING, NOT LESS.** Round 2's reason was that "the branch 6 / 7 discriminator now SUBTRACTS `E[INV]`", and that discriminator is withdrawn, so `E[INV]` no longer enters any decision. What replaces the reason: BOTH branch decisions and the positive's sub-label now read the MAXIMUM of the same 200 permutations whose mean this check tests, so a sampler that does not implement the model the closed form describes puts one error simultaneously inside the positive's conjunct and inside the negative's. The mean is the only cheap way to test that sampler against a known truth. |
| **SC15** | the SYNTHETIC BACKBONE-CLIMBER test of panel measurement item 8: for every panel member, every band and every `k_C` from 0 to `n_C`, the ORDER-CONSISTENT win set of that size has `INV` NOT exceeding that `k_C`'s own 200-permutation maximum | stop; the branch 6 / 7 discriminator reads COMPOSITION rather than ARRANGEMENT and no panel-relative verdict is available. **ADDED by DESIGN gate round 3 (RC3-1)**, because the rule it replaces failed exactly this test at a measured median of +15.6000 and the replacement may not be adopted on an argument when the test is computable before any arm runs. Precedent on the 190-cell lower bound: worst case -2.5556 over 20 champions, 3 bands and every non-degenerate `k` (`exp067_panel_discriminator_redesign.txt` section D3). |

SC11 and SC12 are ADDED by the round-1 DESIGN gate (RC-6 and RC-9b), SC13 exists because RC-3's baseline is
now a printed number that the panel measurement must be consistent with, **SC14 is ADDED by round 2
(RC2-1)** and **SC15 is ADDED by round 3 (RC3-1)**. A check that cannot fail is not a check, so each of
SC2, SC3, SC6, SC8, SC11, SC12, SC13, **SC14** and **SC15** is exercised once against a deliberately
corrupted copy of its input, and the runner's exit code recorded, before the arms run. **SC15's corrupted
input is the withdrawn mean-centred median evaluated on the same trajectory**, which must go RED, so the
check is demonstrated to distinguish the two rules rather than to pass everything.

---

## The frozen constants

| symbol | what it is | status |
|---|---|---|
| `B` | 0.5748, the floor bar | **INHERITED** from phase 0, frozen, not re-derived. The floor monitor's threshold. |
| `R_line` | 0.4968 | inherited, reported |
| `P` | 0.4188, `predictive_gun` against its own clone | inherited, reported |
| `M` | 160 matches per cell (80 held-out starts x 2 seats) | fixed by the split |
| primary band | **0.10** | CHOSEN, named as chosen. 0.05 and 0.15 reported, never swept. |
| band on the integer grid | 8 / 16 / 24 of 160, strict `>` | derived, exact |
| `T` | 20 archive checkpoints per run | fixed, scale-matched to phase 0 |
| panel size | 25 (20 arm S champions + 5 rungs) | fixed, complete rather than selected |
| `K` | 6 opponents per fitness evaluation | CHOSEN |
| train starts | indices 1..4, both seats | CHOSEN. Indices 5 and 6 are generated and deliberately unused. |
| evaluations per run | 50,000 unique (49,980 for A4) | inherited from phase 0 |
| seeds per arm | 13, one per kill-mode arm S champion | **CHOSEN**, named as chosen, and argued in the seeding section against the named alternative "all floor-holding arm S champions", which has 18 members. The first version marked this FORCED by the seeding rule, which is circular: the rule IS the choice (DESIGN gate round 2, RC2-5). |
| `init_sigma` (A1 to A3) | **MEASURE AT FREEZE** by the pilot | value unknown at authoring, rule fixed |
| `init_sigma` (A4) | 1.0, from random `x0`, as phase 0 | inherited |
| null draws | 200 per column | CHOSEN, matches phase 0's draw count |
| backward-edge line | 0.10 of band-decisive time-ordered pairs | CHOSEN, named as chosen |
| Null A fit-gate width | 20 decisive edges of 190 | CHOSEN, named as chosen |
| IF-7 draw-share trigger | 0.20, which is 13x phase 0's measured 0.01553 | CHOSEN, named as chosen |
| IF-8 panel gates | 150 of 300 decisive, 30 of 300 order violations, 5 cyclic triples | CHOSEN, named as chosen |
| IF-2 inertia gates | 30 of 190 decisive edges, 10 of 20 distinct phenotypes | CHOSEN, named as chosen |
| IF-10 half-archive delta | 2 cycles over scale-matched 10-member submatrices | CHOSEN, named as chosen |
| IF-14 floor-shed drop | 0.25 of held-out `W` below the run's own checkpoint 0, which is 40 matches of 160 | CHOSEN, named as chosen |
| floor precondition | 15 of 20 checkpoints per run; 10 of 13 runs per arm, A4 included | phase 0's 15-of-20 fraction, INHERITED |
| minimum `n` for the primary count | 15 DISTINCT above-floor checkpoints | the same 15 as the floor precondition, applied after dedup. It is not implied by the precondition: a floor-holding run whose distinct count falls below 15 is CONVERGED-UNGRADEABLE (RC-5), which is a finding and not an instrument failure. |
| CYCLING threshold | 3 of 13 runs, WITHIN ONE ARM | **RETAINED and RE-LABELLED as a within-arm REPLICATION requirement.** It was derived from Null A's 1/201 per-run rate; that input is contradicted by measurement and the level it bought is WITHDRAWN (RC2-4). Not raised, because the arithmetic shows raising it does not buy the level back; not lowered, because nothing argues for a weaker positive. |
| **no-coevolution reference share** | leg (iii) of CYCLIC: `cycles * 582 > 18 * cyclable` at band 0.10, exact integers; 789/49 and 487/12 at 0.05 and 0.15 | **MEASURED, not chosen.** Phase 0's persisted 20-champion matrix on the integer counter, `exp067_null_a_calibration.txt` section D3. ADDED by DESIGN gate round 2, RC2-4. Its error direction is toward the negative and is declared where it is defined. **AND IT IS THE BINDING LEG OF THE COUNT POSITIVE, by a factor of six to nine over leg (ii), whose bar on a matrix of this shape is about 2 cycles against leg (iii)'s about 18 at cyclable 582 (DESIGN gate round 3, RC3-4). The whole count positive therefore rests on one unreplicated reference share from a differently-structured object, with no `p`-value.** |
| CYCLING panel conjunct | `INV` exceeds its own 200-permutation Null C maximum at the final checkpoint and did NOT at checkpoint 0, in at least 2 of the arm's cyclic runs | the exceedance level is DERIVED (the null's own maximum over the registered 200 draws, so no new constant); the count of 2 runs is CHOSEN, named as chosen. **The first version's `INV_final - INV_0 >= 1` is replaced by RC2-1: the delta of 1 sat inside the permutation spread of every seed and the raw form was inflated by composition drift.** **Unchanged by round 3, which adopted this conjunct for branches 6 and 7 as well, so the count of 2 is now used in two places and is still ONE chosen constant (RC3-1).** |
| **branch 6 / 7 discriminator** | the COUNT of A1's QUALIFYING runs satisfying the CYCLING panel conjunct above, at band 0.10: fewer than 2 gives branch 6, 2 or more gives branch 7 | DERIVED, and it introduces NO new constant: the exceedance level is the null's own maximum over the registered 200 draws and the 2 is the CYCLING panel conjunct's own chosen count, reused. **REPLACES round 2's median of the change in `INV - E[INV]` thresholded at 0, which DESIGN gate round 3 (RC3-1) measured to send a pure transitive climb to branch 7 at a median of +15.6000 at band 0.10** (`exp067_panel_discriminator_redesign.txt` section D1). The withdrawn median is retained as a reported-only quantity. |
| **branch 6 / 7 qualifying filter** | IF-1 did not fire, IF-14 FLOOR-SHED did not fire, and NEITHER checkpoint 0 NOR the final checkpoint has a DEGENERATE Null C (`k_C = 0` or `k_C = n_C`) | DERIVED from flags and from Null C's own degeneracy, no new constant. The first two legs are RC2-2's symmetric filter; the third is ADDED by round 3 (RC3-1) because the withdrawn median counted a degenerate checkpoint's exact zero toward branch 6. |
| **minimum gradeable base for the negative** | 7 of 13 runs GRADEABLE in each arm the negative needs | DERIVED, not a new constant: 7 is the majority of 13, the same majority notion the INSTRUMENT FAILED and FLOOR-LOST branches already use. ADDED by RC2-3. |
| **minimum qualifying base for the panel conjunct** | 7 of 13 A1 runs surviving the IF-1, IF-14 and DEGENERACY filter | DERIVED, the same majority. ADDED by RC2-2; the degeneracy leg ADDED by RC3-1. The row said "panel median" until round 3 replaced the median with a count. |
| **minimum surviving pairs for the coupling attribution** | 7 of 13 A1-A3 pairs after the degeneracy exclusion | DERIVED, the same majority. ADDED in answer to gate blind spot 4. |
| panel `INV` baselines | **step 2 supersedes them**, and the champion-only LOWER BOUND is now printed in this document | rule fixed; the 190-cell lower bound is measured and persisted, the 25-member value is not |

**Every chosen constant is in that table and is named as chosen at the point it is used as well.**
There are **THIRTEEN** of them: the primary band, `K`, the train-start indices, the null-draw count, the
backward-edge line, five gate widths (Null A's fit gate, IF-7, IF-8, IF-2, IF-10), IF-14's drop, the
CYCLING panel conjunct's 2-run count, and **the 13-champion seed pool**. IF-14's drop and the 2-run count
are ADDED by the DESIGN gate (RC-2 and its blind spot 5). **The seed pool joins the list at gate round 2
(RC2-5): it was marked FORCED, and calling a choice forced by the rule that expresses it is circular.**
**The first version said "nine of them" and that was wrong twice over**: it omitted
the 200 null draws, which its own table marks CHOSEN, and it predates the two additions. The count is
corrected here rather than left standing, twice now.
Everything else is either inherited from phase 0 (`B`, `R_line`, `P`, `M`, the evaluation budget, the
floor fraction, `init_sigma` for A4), fixed by arithmetic (the integer band values, the scale matching,
the CYCLING replication threshold, the minimum `n`, the three 7-of-13 majorities, the Null C exceedance
level, and the branch 6 / 7 count of 2, which is the CYCLING panel conjunct's own chosen count reused
rather than a new one), or measured under a pre-committed rule before the arms run
(`init_sigma` for A1 to A3, the panel and its `INV` baselines, **and the no-coevolution reference share,
which is measured on PHASE 0's persisted matrix**). **No constant in this document is derived from any
phase 1 measurement, because none exists yet.** The `INV` baseline table in section I1 (PART 2), the no-coevolution
reference share, and the Null A calibration are all derived from PHASE 0's persisted matrix, which is an
input to phase 1 and not a phase 1 measurement.

---

