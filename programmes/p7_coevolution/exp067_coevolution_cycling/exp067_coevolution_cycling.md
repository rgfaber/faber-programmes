# EXP-067. Robo Rumble phase 1, the CYCLING question: does coevolution FIND AND EXPLOIT the cyclic pockets, or CLIMB THE TRANSITIVE BACKBONE past them?

Pre-registration. Phase 1 of the Robo Rumble front, unlocked by phase 0's cleared competence
floor (insight 066, verdict CLEARED at a median held-out win rate of 0.9750 against a
pre-registered bar of 0.5748). `PLAN_ROBO_RUMBLE.md` section 6 states phase 1's question as
"does this substrate produce intransitivity where the bare grid did not", and both answers are
signable.

**That question as the plan states it is not the question this document asks, because phase 0
made it too coarse.** Phase 0's cross-play probe (EXPLORATORY, POST HOC, unregistered, signs
nothing) suggests a landscape that is very nearly a single transitive competence ladder carrying a
small residue of cyclic pockets. **That suggestion is not a precondition and it does not decide
whether phase 1 runs; the cleared floor does that, and it is cleared.** What the suggestion does is
make the plan's binary question inadequate, because in such a landscape coevolution can do two
things that produce nearly identical champion trajectories and completely opposite conclusions:

- **(a) FIND AND EXPLOIT the cyclic pockets.** Non-transitive dynamics, a Red Queen with a return.
- **(b) CLIMB THE TRANSITIVE BACKBONE** while the pockets sit there unvisited. Not that.

**Distinguishing (a) from (b) IS the experiment.** A count of cyclic triples in a coevolutionary
archive does not distinguish them, because (b) also produces a non-zero count from binomial noise
around a total order, and (a) at a low rate is indistinguishable from (b) at a high one unless the
reference is a strength model rather than a coin. Everything below is built around that
separation.

- **Programme:** P7 (Coevolution) x the Robo Rumble front, phase 1
- **Opened:** 2026-07-30
- **Engine pin:** `a5e8bcfc5646827e9be49a9629f8a6a9678c814b`, the same pin phase 0 ran at. The
  engine is NOT modified: `robo_sim`, `robo_net`, `robo_gauntlet` and `robo_match` are untouched
  and gate 1 recomputes `robo_match_tests`' golden match vector `DFCD8106…B3895E88` to prove it
  rather than assert it. One pin, and it is the provenance.
- **Builds:** one runner in `experiments/`, and nothing else. `experiments/` is not built by
  `rebar3 compile`; `rebar3 as test compile`, beams under
  `_build/test/lib/faber_programmes/experiments`. Erlang only, elvis `faber_min` clean
  (`no_deep_nesting` level 2, `no_if_expression`, `no_nested_try_catch`), `warnings_as_errors`.
- **Raw feed / insight:** `faber-ecosystem/insights/067-*`
- **Upstream:** `PLAN_ROBO_RUMBLE.md` sections 2, 4, 6; insight 066 (the cleared floor and its four
  design notes); `066-note-crossplay-intransitivity-UNSIGNED.md` (its section "What phase 1 should
  take from this"); `SYNTHESIS_P7.md` (the closed programme's limitations, which this design is
  built to avoid reproducing).

---

## What phase 0 hands over, and what may NOT be carried

### Carried unchanged, and named so that nothing is silently re-derived

| Object | Where it comes from |
|---|---|
| The engine at the pin, and the golden match vector | `robo_match_tests` |
| The 17 integer sensor channels, the tracker, the three redundant frames, the 5 outputs | `exp066_single_population_floor.md`, sections "The controller" and "The 5 outputs" |
| Topology `[17,12,5]`, 281 parameters, `robo_net:weight_count/1` verified | same |
| The quantise lattice: scale 256, hard clamp at plus or minus 2048 | `robo_net:quantize/1` |
| The deterministic start generator and the 120-index split TRAIN 1..6 / HELD-OUT 7..86 / CALIBRATION 87..116 / unused 117..120 | `exp066_single_population_floor.md`, "The start split" |
| BOTH SEATS ALWAYS at every start | same |
| `margin/1`: `dealt - taken` alive, `dealt - max(taken, 25600)` dead, in arena fixed point | same, "The fitness" |
| The win definition: opponent tank DEAD and subject tank ALIVE at match end; draws count as NOT beating for both sides | same, "The primary endpoint" |
| `B = 0.5748`, `R_line = 0.4968`, `D_min = 0.0780`, `P = 0.4188`, binomial `SE = 0.0390`, bootstrap SE 0.0207, `N <= 0.0125`, `R = 0.0125` | `exp066_floor_feed.txt` |
| The 40 archived champions | `exp066_champions_s.eterm`, `_l.eterm`, `_d.eterm` |

### NOT carried, and each refusal is load-bearing

- **The ladder fitness is discarded**, by phase 0's own explicit DISCARD section: "The staircase is
  phase-0 scaffolding with no meaning once the opponent is another evolved net and there is no
  ladder." The per-match MARGIN is the durable object and is what carries forward.
- **Arm C is gone.** Expressibility is settled a fortiori by evolved champions that beat the floor
  bot. There is no hand construction in phase 1 and no precondition depending on one.
- **Nothing from the unsigned cross-play probe is a precondition established.** Phase 1 is unlocked
  by the FLOOR, not by the matrix. `PLAN_ROBO_RUMBLE.md` makes phase 1 conditional on the competence
  floor and the floor is cleared. **No number in that note is used here to argue that phase 1 is
  more likely to find cycling**, and the note's own counts, bands, nulls and conclusions are quoted
  below only in two roles: as a WARNING about a selection rule, and as the reason a quantity is
  re-measured under pre-registration before any coevolution run. Where a phase 0 probe number is
  quoted it is labelled POST HOC and it is superseded by the pre-registered panel measurement
  (section "The reference panel").
- **IF-8 as a memorisation instrument is not carried.** Phase 0's `trainW` reads 1.0000 for 40 of
  40 champions on a 12-match train split, so the flag was untestable with that instrument. That
  fact stands in phase 0's record permanently and is not repaired here. Phase 1 registers a
  DIFFERENT instrument (IF-11 below) that reads the FLOORED MARGIN, because phase 0's post-hoc
  diagnostic measured that the margin leg saturates nowhere (train 39.97 to 97.58, calibration
  -27.84 to 80.71, held out -27.63 to 79.78, `exp066_flag_fixes.txt` section B) while the win-rate
  leg is at ceiling. IF-11 is NEW and is labelled new, never as IF-8 fixed.
- **Any claim that a controller "learned to track" or "learned to handle intermittent observation"
  is unavailable** to this front by phase 0's pre-registration, because channels 9 to 14 report the
  contact's estimated position NOW and prediction is withheld. That is still true in phase 1.

---

## The question, asked so that every answer is signable

**Under coevolution on one island, above the certified competence floor, does the population enter
and exploit the intransitive pockets of this strategy space, or does it climb a transitive
dominance backbone while the pockets stay unvisited, and by what pre-registered measurement would
we tell those two apart from an instrument that never asked?**

**EIGHT outcomes, all pre-committed. The first version of this section said "six outcomes, all
reachable, with a precedence order fixed in the decision rule below so that no combination of
results lands nowhere". THAT CLAIM WAS FALSE**, and the DESIGN gate of 2026-07-30 produced two
concrete combinations the six-outcome ladder could not emit (a floor-losing run that is cyclic on
its own above-floor submatrix, and an A4-only positive). The ladder below is repaired, two outcomes
are added, and its totality is **discharged by an exhaustion argument at the foot of the decision
rule instead of asserted in a sentence.**

1. **CYCLING.** The archive carries more intransitivity than a fitted scalar-strength model can
   produce, and the population's win pattern against a pre-measured fixed panel is cycle-forming
   rather than prefix-shaped. **The split into two sub-labels is MANDATORY and pre-committed, and
   only the first is the headline:**
   - **CYCLING (PANEL-VISIBLE).** Both halves hold: the count test and the frozen-panel inversion
     test. First positive open-endedness-adjacent signal in this corpus.
   - **CYCLING (SELF-RELATIVE).** The count test holds and the panel inversion count does not move.
     This signs the intransitivity half only. It is **barred** from being reported as pocket
     exploitation, as open-endedness-adjacent, or as evidence that the population entered any
     pocket of the panel's space, because a matrix of checkpoints that each beat their temporal
     neighbours produces it with no pocket anywhere (see "The largest threat", route B).
2. **NO CYCLING.** The archive is transitive to within a strength-model bootstrap and the
   population's panel win pattern does not become more cycle-forming than the seed's own. A much
   stronger version of insight 057's negative, because the floor confound is closed AND the pockets
   are known to exist in the space being searched, which insight 057 could not say.
3. **PARTIAL.** One or two runs of thirteen cycle **within a single arm**, which is not a
   family-wise safe positive.
4. **FLOOR-LOST.** The population leaves the certified competence regime, so the matrix cannot be
   read against the certification the plan requires. Signable as a finding about coevolutionary
   dynamics, and it does NOT answer the cycling question.
5. **INCONCLUSIVE, SECOND CLASS UNTESTABLE.** The negative holds for the seedable optimiser and the
   second optimiser class never reached the floor, so a universal claim is not available.
6. **INSTRUMENT FAILED.** Enumerated as IF-1 to IF-14 and each distinguished from a real negative
   in advance.
7. **PANEL-INVERTED, ARCHIVE TRANSITIVE. (ADDED by the DESIGN gate's RC-3.)** No run's archive
   beats its own strength-model bootstrap, so there is no intransitivity claim, but the median run's
   inversion count against the frozen panel RISES. The second conjunct of outcome 2 fails, so the
   negative is not signable as NO CYCLING, and the next move is the panel-relative question rather
   than more seeds.
8. **NON-ENGAGEMENT. (ADDED in answer to the gate's blind spot 4.)** The population converges on
   mutual non-engagement while holding the floor: draw-parked cells and few decisive edges. Two
   coevolved long-range orbiters that never close produce this, and it is a finding about what this
   substrate's coevolutionary dynamic converges to, **not** an instrument failure. No cycling claim
   is available in either direction.

---

## The primary endpoint, counted once and named

**Primary statistic: the number of UNORDERED BAND-DECISIVE CYCLIC TRIPLES in a run's archive
cross-play matrix, at band 0.10, with GUNLESS-LEG triples excluded.**

Definitions, complete, because phase 0's record left the tie rule in a script and in neither
record's prose.

```
Cell:      W(I,J) = K(I,J) / 160, K(I,J) = I's WINS over 80 held-out starts in BOTH seats.
           A win requires the opponent tank DEAD and I's tank ALIVE at match end.
           Draws (turn cap with both alive, or mutual death) count as NOT beating for either side,
           so K(I,J) + K(J,I) =< 160 and the shortfall is the cell's draw count.
Diagonal:  0.0, never read.
Margin:    margin(I,J) = W(I,J) - W(J,I) = (K(I,J) - K(J,I)) / 160.
Decisive:  |K(I,J) - K(J,I)| > band * 160,  STRICTLY GREATER, computed ON THE INTEGERS.
           band * 160 is exactly 8 at band 0.05, 16 at 0.10, 24 at 0.15.
           A margin exactly equal to the band is NOT decisive.
Edge:      when decisive, I -> J if K(I,J) > K(J,I), else J -> I.
Cyclic triple: an unordered {A,B,C} whose three pairwise edges are all decisive and form a cycle
           (each member has out-degree exactly 1 within the triple).
```

**THE BAND TEST IS AN INTEGER TEST AND THAT IS PRE-REGISTERED, NOT AN OPTIMISATION.** At 160
matches per cell every margin is an exact multiple of 1/160 and every band times 160 is an integer,
so `|margin| > band` is exactly computable with no rounding. Phase 0's counter did it in IEEE
doubles, and an independent verification found **seven pair-and-band cases whose margin is
mathematically exactly equal to its band, three of which double subtraction calls decisive and four
of which it does not** (`exp066_within_tier_verify.txt` section K: pair {2002,2014} at band 0.05
computes 0.05000000000000004441 and counts, {2011,2020} computes 0.04999999999999998890 and does
not, both being exactly 8/160 against a band of 8/160). Mathematically identical inputs receiving
opposite verdicts is not a convention anyone can defend, and it is closed here before a matrix
exists rather than corrected afterwards.

**GUNLESS-LEG EXCLUSION, and it makes the primary count SMALLER.** `sitting_duck` "does nothing at
all" and `spinner` has "NO GUN" (`robo_gauntlet.erl` line 14 for the duck, line 234 for the
spinner), so neither can deal damage and a loss to either is the subject killing itself on a wall, on
a ram or by spending its own bar. Phase 0's own record establishes the mechanism
(`exp066_two_attractors_probe.txt` section H: "duck_L and spin_L are losses to an opponent that NEVER
FIRES, so each one is the champion killing itself"). Of the 13 cyclic triples phase
0's recovered scripted-null work found, 9 run through the duck or the spinner. Any triple in any phase 1 matrix that contains `sitting_duck` or `spinner` is therefore
**counted separately and excluded from the primary statistic**, and reported with the exclusion
named. This biases toward the negative, which is the conservative direction, and the excluded count
is always printed.

**ONE COUNT, AND THE OTHER IS REPORTED FOR COMPARABILITY.** Insight 057's counter is over ORDERED
tuples `(A,X,C)` with `A < X`, which is not a cycle count: one cyclic triangle contributes twice in
one rotation direction and once in the other, so ordered lies between one and two times unordered.
The ordered count is computed and reported so phase 1 is comparable with the closed programme, and
**the bridging identity `ordered = 2 * forward + backward` is CHECKED at every band on every matrix,
never asserted** (SC6).

**SCALE MATCHING IS DESIGNED IN, NOT ARGUED AFTERWARDS.** The FULL archive matrix has 20 members, 190
pairs, 1,140 unordered triples and 3,420 ordered candidates, which is exactly phase 0's cross-play
matrix size, so those counts are directly comparable to phase 0's persisted 49 / 18 / 12. **Every other
comparison is made on the share of cyclable triples that are cyclic** (cyclable = all three edges
decisive), never on raw counts, because "comparing a raw count over 360 candidates with a raw count over
3,420 is not a comparison". That covers the above-floor submatrix (whose `n` varies per run), the
25-member panel, and any comparison with insight 057.

### Granularity, fixed in advance and shown separable

| quantity | phase 1 | phase 0's failed 6-start pass |
|---|---|---|
| starts per cell | 80 (the held-out split) | 6 |
| matches per cell, both seats | **160** | 12 |
| win-rate step | 0.00625 | 0.0833 |
| one flipped match moves a margin by | 0.0125 | 0.167 |
| flipped matches to cross band 0.05 | **5** (need `> 8` of 160) | 1 |
| flipped matches to cross band 0.10 | **9** (need `> 16`) | 1 |
| flipped matches to cross band 0.15 | **13** (need `> 24`) | 1 |
| representable margins strictly between 0.05 and 0.10 | 7 (9/160 to 15/160) | 1 (1/12 = 0.0833) |
| representable margins strictly between 0.10 and 0.15 | 7 (17/160 to 23/160) | **none** |

At 6 starts bands 0.10 and 0.15 were literally the same test, which the persisted record confirms
directly (band 0.05 gave 120 ordered / 84 cycles / 174 decisive while 0.10 and 0.15 both gave
100 / 73 / 170), and one flipped match jumped clean across the 0.10 band. At 160 matches per cell the three bands are three different tests and a
band-0.10 edge carries at least 17 matches of separation, so no single-match artifact can produce
one. **The cell size is fixed at 160 and the bands are 0.05, 0.10 and 0.15, with 0.10 PRIMARY.**
0.10 is primary because it is the band phase 0's records carry their headline counts at, so phase 1
is comparable to them, and because 17 matches of separation on each of three edges is beyond any
noise argument. 0.05 and 0.15 are reported as a pre-committed robustness table with one
pre-committed label: a positive at 0.10 that does not survive at 0.15 is reported as
**band-marginal**. **The bands are not swept.** A band chosen after seeing a count is a search, not
a robustness check.

---

## THE NULLS, REGISTERED BEFORE THE MATRIX EXISTS

This is the largest lesson available from phase 0 and it is discharged first. Reading the same 20
champions against three different nulls gave "a fifth of the coin-flip rate", "below the lowest of
200 draws" and "above the highest of 200 draws". **The count was never the problem.** Three nulls
are registered here, each attached to a specific statistic, and the alternatives are named and
rejected in advance.

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
           with ONE virtual win and ONE virtual loss added to every ordered pair. That prior is
           the standard fix for a win graph that is not strongly connected and it is DECLARED NOW,
           not chosen after a divergence. Stop at relative change below 1e-10 in every s_I,
           iteration cap 10,000, normalised so sum(s) = T. Hitting the cap fires IF-9.
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

The per-run test is one-sided: **a run is CYCLIC iff its primary count exceeds the MAXIMUM of its
own 200 draws**, and iff the run is gradeable (the floor precondition of the decision rule, and a
matched fit). Under the null the count test has probability at most 1/201 = 0.00498 per run.

**WHAT HAPPENS WHEN THE FIT GATE FIRES, pre-committed in both directions and with the reason the
directions differ (DESIGN gate RC-4).**

- **NULL-UNFIT (DEFLATED): the median synthetic decisive-edge count is BELOW the observed by more
  than 20.** This is the alternative hypothesis' own fingerprint: a matrix whose margins no scalar
  strength can reproduce makes the fit compress those pairs toward 0.5, which under-produces
  decisive edges and therefore also under-produces cyclable triples and cycles. So the null is
  DEFLATED and an exceedance of it is ANTI-CONSERVATIVE and **cannot sign a positive.** The run is
  UNGRADEABLE for the CYCLIC test, its count and its null position are printed anyway, and the
  shortfall in decisive edges is **recorded as positive-direction evidence of non-scalar margin
  structure** that this instrument cannot convert into a verdict. If any such run's count exceeded
  its deflated null maximum, the verdict carries the label **NULL-UNFIT RESIDUE** with the count of
  such runs.
- **NULL-UNFIT (INFLATED): the median is ABOVE the observed by more than 20.** The null over-produces
  the ingredient a cycle consumes, so it bounds nothing. The run is UNGRADEABLE for the primary test
  and nothing else is read from it.
- **In BOTH directions Null B is a CHECK ONLY** (its transitivity reading and SC8) and never decides
  CYCLIC. **If IF-9 fires in a majority of an arm's floor-holding runs the verdict is INSTRUMENT
  FAILED**, because the primary null was unmatched in most of the arm; a minority is carried as the
  NULL-UNFIT label above. "Majority" here is the same majority the INSTRUMENT FAILED branch already
  uses, not a new constant.

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

### Alternatives named and REJECTED in advance

- **A fair-coin-per-match null.** Rejected. It describes T equally strong players, so it
  under-supplies exactly the ingredient a cyclic triple consumes: at band 0.10 it leaves roughly 44
  decisive edges of 190 against 152 observed in phase 0's matrix, so it cannot bound the observed
  count in EITHER direction. It is also the null whose scaling defect produced two opposite readings
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
most runs before a single evaluation is spent. The instrument's question is therefore always a
DIFFERENCE, `INV` at the final checkpoint against `INV` at checkpoint 0, and no phase 1 write-up may
report pocket occupancy as a result.

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
outcome 1 with two conjuncts and then implemented only the first in the decision rule, so a positive
could be signed with `INV = 0` at every checkpoint, meaning with zero evidence that the population
entered any pocket. The panel conjunct is now in the CYCLING branch and the split label
PANEL-VISIBLE / SELF-RELATIVE is mandatory.

Reported per run: `INV` at checkpoint 0 (the seed, known in advance and printed below), the trajectory
over the 20 checkpoints, the median, the final value, `E[INV]` and the 200-permutation range at each
point, and `final minus checkpoint-0` with a sign test over the 13 runs.

### The 13 seeds' `INV` at checkpoint 0, COMPUTED BEFORE ANY RUN, from data already on disk

The DESIGN gate's RC-3 pointed out that this table was computable at authoring time and had not been
computed, while the decision rule contained an ABSOLUTE condition (`INV = 0`) that it might already
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
decision rule, and H1 is restated to match.

**Two scope facts about this table, both stated rather than buried.** First, it is a **LOWER BOUND**:
only the 190 champion-versus-champion cells of the 25-member panel exist on disk, SC3a forces the
phase 1 panel to reproduce them cell for cell, the 5 scripted rungs can only ADD triples, and the
gunless-leg exclusion removes nothing here because neither `sitting_duck` nor `spinner` is in this
matrix. The panel measurement at step 2 supersedes it with the full 25-member value, and the sign of
the difference is known in advance: up or equal, never down. Second, **every seed's `INV_0` is far
below its own `E[INV]`** (5 against 24.85, 6 against 27.79, and so on), so these win patterns are much
closer to prefix-shaped than to random. That is H1's direction. What it is not is zero.

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
   is the panel's own intransitivity and it is the baseline every `INV` is read against.
4. Per member: row mean over the other 24, Copeland count, and (for the 20 champions) held-out win
   rate against `predictive_gun` and tier.
5. `INV_0`, `E[INV]` and the 200-permutation range for each of the 13 run seeds, so the seeds' pocket
   membership is known BEFORE the runs. **`INV_0` over the 25 members must be at least the
   champion-only value printed in section I1, for every seed and every band**, because the 190
   champion cells are reproduced exactly (SC3a) and extra members can only add triples. That is
   **SC13**, an inequality that can fail: if it does, the panel does not contain the submatrix it is
   supposed to contain.

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
   report the order's own violations, compute E[INV], the permutation range and INV_0 for each
   of the 13 seeds, and print INV_0 beside the champion-only lower bound this document already
   carries, which is SC13. Nothing after this point may change the panel.
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
7. Compute Null A, Null B and Null C on every matrix. Decide every IF flag.
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
RUN SEED that both the reading table and H2 lean on, so an unnamed derogation would have confounded the
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
| **SC13** | the 25-member panel's `INV_0` for each of the 13 seeds is at least the champion-only value printed in section I1, at every band | IF-5, void; the panel does not contain the 190-cell submatrix SC3a says it reproduces |

SC11 and SC12 are ADDED by the DESIGN gate (RC-6 and RC-9b), and SC13 exists because RC-3's baseline is
now a printed number that the panel measurement must be consistent with. A check that cannot fail is not
a check, so each of SC2, SC3, SC6, SC8, SC11, SC12 and SC13 is exercised once against a deliberately
corrupted copy of its input, and the runner's exit code recorded, before the arms run.

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
| seeds per arm | 13, one per kill-mode arm S champion | FORCED by the seeding rule |
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
| CYCLING threshold | 3 of 13 runs, WITHIN ONE ARM | derived from Null A's 1/201 per-run rate |
| CYCLING panel conjunct | `INV_final - INV_0 >= 1` in at least 2 of the arm's cyclic runs | the delta is derived (the least nonzero integer); the count of 2 runs is CHOSEN, named as chosen |
| panel `INV` baselines | **step 2 supersedes them**, and the champion-only LOWER BOUND is now printed in this document | rule fixed; the 190-cell lower bound is measured and persisted, the 25-member value is not |

**Every chosen constant is in that table and is named as chosen at the point it is used as well.**
There are TWELVE of them: the primary band, `K`, the train-start indices, the null-draw count, the
backward-edge line, five gate widths (Null A's fit gate, IF-7, IF-8, IF-2, IF-10), IF-14's drop, and the
CYCLING panel conjunct's 2-run count. IF-14's drop and the 2-run count are ADDED by the DESIGN gate (RC-2
and its blind spot 5). **The first version said "nine of them" and that was wrong twice over**: it omitted
the 200 null draws, which its own table marks CHOSEN, and it predates the two additions. The count is
corrected here rather than left standing.
Everything else is either inherited from phase 0 (`B`, `R_line`, `P`, `M`, the evaluation budget, the
floor fraction, `init_sigma` for A4), fixed by arithmetic (the integer band values, the scale matching,
the CYCLING threshold, the minimum `n`, the `INV` delta), forced by a rule (13 seeds), or measured under
a pre-committed rule before the arms run (`init_sigma` for A1 to A3, the panel and its `INV`
baselines). **No constant in this document is derived from any phase 1 measurement, because none exists
yet.** The `INV` baseline table in section I1 is derived from PHASE 0's persisted matrix, which is an
input to phase 1 and not a phase 1 measurement.

---

## Decision rule, pre-committed, computed on held-out only, every outcome reachable

Per run, at band 0.10, with the gunless-leg exclusion applied:

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
a run is CYCLIC        iff it is GRADEABLE and its primary count on the ABOVE-FLOOR SUBMATRIX
                       exceeds the MAXIMUM of 200 Null A draws computed on THAT SAME SUBMATRIX,
                       so the null is self-matched to whatever n the restriction leaves.
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
IN THE LADDER and not the outcome numbers of the list in "The question"; the outcome NAMES are what
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
                        PANEL-VISIBLE  if in >= 2 of that arm's cyclic runs
                                       INV_final - INV_0 >= 1 at band 0.10 against the panel
                        SELF-RELATIVE  otherwise. Signs intransitivity only. BARRED from
                                       pocket-exploitation and open-endedness language.
                      Labelled SECOND-OPTIMISER-ONLY when the arm is A4.
3. PARTIAL        iff >= 1 run of A1, A2 or a gradeable A4 is CYCLIC and no single one of
                      those arms reaches 3. Per-arm.
                      The POOLED count across arms is printed as a label and NEVER promotes
                      the verdict, because the family-wise arithmetic below is a within-arm
                      calculation and 2-in-A1-plus-2-in-A2 is not covered by it.
4. FLOOR-LOST     iff no run of A1, A2 or A4 is CYCLIC, AND (the floor precondition held in
                      FEWER than 10 of 13 of A1's runs, OR A2 trips IF-1 in a majority, 7 or
                      more, of its 13). Labelled THE ANCHOR SQUEEZE when A1 held and A2 did not.
5. INCONCLUSIVE,  iff no run of A1, A2 or A4 is CYCLIC, A1 held the floor in >= 10 of 13, A2 did not
   SECOND CLASS       majority-lose it, and A4 is UNGRADEABLE AT ARM LEVEL (fewer than 10 of
   UNTESTABLE         its 13 runs hold the per-run floor precondition), so the negative rests
                      on one optimiser class only.
6. NO CYCLING     iff 0 CYCLIC runs among ALL the GRADEABLE runs of A1, A2 and A4,
                  AND the floor precondition held in >= 10 of 13 runs of A1,
                  AND A2 did not trip IF-1 in a majority of its 13,
                  AND A4 is GRADEABLE at arm level,
                  AND the MEDIAN over A1's 13 runs of (INV at checkpoint 20 minus INV at
                      checkpoint 0), at band 0.10 against the frozen panel, is =< 0.
7. PANEL-INVERTED iff branch 6 fails ON ITS LAST CONJUNCT ONLY: no run is CYCLIC, the floor
   ARCHIVE            held in A1 and was not majority-lost in A2, A4 is gradeable, and the
   TRANSITIVE         median (INV_20 - INV_0) at band 0.10 is >= 1.
```

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

**EXHAUSTION, in one pass, so this is checkable rather than claimed.** Take any result. If IF-5 or IF-6
fired, it lands 1. If an arm-level trigger fired on an arm the candidate verdict needs, it lands 0 or 1
(0 when IF-2 and IF-7 co-fire above the floor, 1 otherwise). Otherwise, either some run of A1, A2 or a
gradeable A4 is CYCLIC or none is. If some run is: either some single one of those arms has 3 or more,
giving 2, or the maximum over them is 1 or 2, giving 3. If none is: either the floor conditions of branch
4 fire, giving 4, or they do not, in which case A4 has been run (protocol step 8 triggers it whenever no
arm reaches the CYCLING count) and is either ungradeable at arm level, giving 5, or gradeable, in which
case the median `INV` delta over A1's 13 runs is either at or below 0, giving 6, or 1 or more, giving 7.
Every path terminates in exactly one outcome, and the two combinations the DESIGN gate produced now land:
a floor-losing cyclic A2 run is UNGRADEABLE, so it is not CYCLIC, it does not block branch 6, and it is
printed as an UNGRADEABLE EXCEEDANCE; an A4-only positive with 2 cyclic runs lands PARTIAL and with 3
lands CYCLING (SECOND-OPTIMISER-ONLY).

`10 of 13` is phase 0's own 15-of-20 fraction (0.75) applied to 13 runs and rounded up, not a new
constant. `7 of 13` is a majority, the same majority notion the INSTRUMENT FAILED branch already uses.
Precedence 2 above 4 is deliberate: CYCLING is an EXISTENCE claim, so GRADEABLE cyclic runs establish it
even when other runs of the same arm lost the floor, and FLOOR-LOST is then reported as a co-occurring
LABEL rather than as the verdict. Precedence 5 above 6 is what stops a single-optimiser negative from
being signed as NO CYCLING. Precedence 7 below 6 is not a fallback: it is the branch where the archive is
transitive and the panel instrument nevertheless moved, which is neither of the two stories this
experiment was built to separate and must not be collapsed into either.

**Why 3 of 13, and why WITHIN ONE ARM.** The per-run test has probability at most 1/201 = 0.0049751
under Null A, so over 13 runs P(at least 1) = 0.0628, P(at least 2) = 0.00186, P(at least 3) = 3.3e-5,
across the two coupled arms P(at least 3 in either) is about 6.7e-5, and with a gradeable A4 as a third
verdict-carrying arm it is about 1.0e-4. Three of thirteen is a family-wise safe positive; one of
thirteen is not, which is why it lands PARTIAL and not CYCLING. **This arithmetic is a WITHIN-ARM
calculation, which is the reason the CYCLING threshold is per-arm and pooling is refused** (DESIGN gate
RC-1c): 2 cyclic runs in A1 plus 2 in A2 is not covered by any line above, so it lands PARTIAL with the
pooled count printed, and it is not promoted by an argument constructed after seeing it.

**Why the negative needs A4.** CYCLING is an EXISTENCE claim so one optimiser class suffices. NO
CYCLING is a UNIVERSAL claim, so it needs two, because a negative from a single optimiser reproduces
verbatim the search under-convergence confound this front exists to remove. This is phase 0's
asymmetric stopping rule carried over unchanged, and it is fixed in advance so it cannot be used to
shop for a result.

**Reading the arms together, pre-committed**

| pattern | reading |
|---|---|
| A1 cycles, A2 cycles, A3 does not | **CYCLING, COUPLING-ATTRIBUTED.** Reciprocal coupling produces it and a frozen shuffled archive of the same champions, walked on a schedule, does not. |
| A1 or A2 cycles, A3 cycles at the same rate | **CYCLING, NOT COUPLING-ATTRIBUTED.** The effect is curriculum diversity, which is exactly what the grid programme found. Reported with a Fisher exact one-tailed p on the cyclic-run counts, coupled against decoupled, as a reported number and not a gate. |
| A2 cycles, A1 does not, A2 held the floor | The HALL OF FAME suppresses it. The anchor is the mechanism. |
| A2 loses the floor, A1 holds it and does not cycle | **THE ANCHOR SQUEEZE.** In this substrate the only configuration that keeps the population above the certified competence floor is the one that removes the cycling opportunity, and the one that leaves the opportunity open cannot be read. This is `SYNTHESIS_P7.md`'s "too decoupled to escalate or too coupled to survive" appearing one level up, and it is signable as such, NOT as a clean no-cycling result. |
| A1 and A2 do not cycle, A4 does in >= 3 of its 13 while gradeable | **CYCLING (SECOND-OPTIMISER-ONLY)**, with its panel sub-label. The single-mean optimiser could not hold two coexisting strategies; the distinct-parent population could. A positive, and a statement about what a coevolutionary substrate needs. At 1 or 2 cyclic A4 runs this is PARTIAL, not a positive. |
| A1, A2 and A4 do not cycle, floor held, median `INV` delta at or below 0 | **NO CYCLING**, the two-optimiser-class negative, the only form of negative this front is entitled to sign. |
| A1, A2 and A4 do not cycle, floor held, median `INV` delta 1 or more | **PANEL-INVERTED, ARCHIVE TRANSITIVE.** The archive is explained by a scalar strength and the population still moved to a place where it beats strong panel members and loses to weak ones. Read jointly with IF-14: with a large floor-`W` drop it is competence shed on an axis the panel order does not describe; without one it is specialisation the archive matrix cannot see. |
| any arm reaches 3 cyclic runs with `INV` unmoved in a majority of them | **CYCLING (SELF-RELATIVE).** The intransitivity is real and the pocket claim is not available. Reported with the checkpoint-local-specialisation mechanism named as the live alternative, not dismissed. |
| decisive edges collapse and the draw share exceeds 0.20 in a majority of floor-holding runs | **NON-ENGAGEMENT.** Two coevolved orbiters that stop closing. A finding about the dynamic, not a broken instrument, and not a cycling result in either direction. |
| A3 cycles and neither A1 nor A2 nor a gradeable A4 does | The verdict is read from the coupled arms and carries **DECOUPLED-CONTROL CYCLED**. A3 never carries the verdict, so this is not a positive for the cycling question; it says the frozen shuffled curriculum produced intransitivity that reciprocal coupling did not, which is the grid programme's curriculum-diversity route and a pointer for the next rung. |
| 2 cyclic runs in A1 and 2 in A2, none in A4 | **PARTIAL**, with the pooled count of 4 printed as a label. The family-wise arithmetic is within-arm, so 2 plus 2 is not a safe positive and is not promoted to one. |
| all archives strongly time-ordered, backward-edge share below 0.10, counts at or below the Null A median | insight 057's dominance pattern reproduced in a materially different substrate, which is the sharpest available statement of the negative. |

**ONLY CYCLING or NO CYCLING signs the cycling question, and CYCLING (SELF-RELATIVE) signs only its
intransitivity half.** PARTIAL, FLOOR-LOST, INCONCLUSIVE, PANEL-INVERTED, NON-ENGAGEMENT and INSTRUMENT
FAILED each prescribe a different next move and MUST NOT be collapsed: PARTIAL sends the question to
more seeds at the same design, FLOOR-LOST to the anchoring mechanism, INCONCLUSIVE to a seedable second
optimiser class, PANEL-INVERTED to the panel-relative question and the floor trajectory, NON-ENGAGEMENT
to the fitness's treatment of draws, INSTRUMENT FAILED to the named instrument. **Nothing in phase 1 unlocks mesh, ReckonDB or evoq work.** Re-raise triggers 1, 2 and 3
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
| **IF-8 PANEL-DEGENERATE** | the frozen panel has fewer than 150 of 300 band-decisive edges at 0.10, or its Bradley-Terry fit hits the iteration cap, or more than 30 of 300 band-decisive pairs disagree with its fitted order | The measuring stick has no order for inversions to be read against. Instrument I1 is VOID and the design falls back to the archive matrix and I2 alone, with the fallback recorded. Separately, if the panel has fewer than 5 band-decisive cyclic triples at 0.10 after the gunless exclusion, the POCKET language is void (there are no pockets to be inside), `INV` is still computed and reported as an inversion count, and the pocket-retained / pocket-created labels are unavailable. |
| **IF-9 NULL-UNFIT** | Null A's median synthetic decisive-edge count at 0.10 differs from the observed by more than 20 of 190, or the fit hits the cap | The null is not matched to the observed decisiveness structure and cannot bound the count in either direction. This is exactly the defect that made phase 0's coin null unusable. **The RUN becomes UNGRADEABLE for the primary test; NULL B DOES NOT BECOME PRIMARY** (DESIGN gate RC-4). DEFLATED (median below observed): recorded as positive-direction evidence of non-scalar margin structure, count and null position printed, and the verdict carries NULL-UNFIT RESIDUE if the count exceeded the deflated maximum. INFLATED (median above observed): nothing else is read. If IF-9 fires in a majority of an arm's floor-holding runs, INSTRUMENT FAILED. If Null B fails SC8, INSTRUMENT FAILED. |
| **IF-10 BUDGET-LIMITED** | on a NO CYCLING verdict, the median run's cyclic count over checkpoints 11..20 exceeds its count over checkpoints 1..10 by at least 2 (each a 10-member submatrix, 120 triples, so the two halves are scale-matched to each other) | The negative is budget-limited and says nothing about the substrate. |
| **IF-11 OVERFIT-TO-TRAIN-STARTS** | median checkpoint champion's train-minus-held-out FLOORED MARGIN gap exceeds the phase 0 kill-mode range of 5.28 to 18.41 whole units (`exp066_flag_fixes.txt` section B) | MODIFIER. The coevolved champions are more start-overfitted than the seeds were, and the verdict carries the label. **This is a NEW post-hoc-informed instrument, not IF-8 repaired.** It reads the floored margin because phase 0 measured that the win-rate train leg saturates at 1.0000 for 40 of 40 champions while the margin leg saturates nowhere. It is a comparison against a previously measured range, not an invented threshold. |
| **IF-12 POCKET-INHERITED** | every cyclic triple found across an arm appears in runs seeded from 2003 or 2013 | MODIFIER on a positive. Reported as POCKET RETAINED rather than POCKET ENTERED OR CREATED, and it is the weaker claim. **Its premise is now persisted** in `exp066_residue_and_inv0.txt` section B: the 11 kill-mode champions other than 2003 and 2013 carry 0 cycles at all three bands over 165 triples of which 130 / 115 / 96 are cyclable (DESIGN gate RC-8). |
| **IF-13 SEED-ERASED** | the `init_sigma` pilot's largest qualifying sigma does not exist, or a seeded run's checkpoint-1 champion is below `B` against the floor bot | The seed was destroyed by the initial step size, so the run did not start above the certified floor and its early checkpoints are outside the regime the plan licenses. |
| **IF-14 FLOOR-SHED** | a run's final checkpoint holds `W >= B` against `predictive_gun` but is more than 0.25 (40 matches of 160) BELOW its own checkpoint-0 `W` | MODIFIER, and it is what the floor gate's coarseness costs (gate blind spot 5). `B = 0.5748` against seed `W` of 0.9375 to 1.0000 means a champion can shed most of its floor competence and still "hold the floor". Because the panel order is roughly orthogonal to floor competence (H3), a shed like that can invert panel cells on its own. **A run with IF-14 firing AND an `INV` rise is reported as FLOOR-SHED, and its `INV` rise does not count toward the CYCLING branch's panel conjunct.** `0.25` is a chosen constant, named as chosen. |

**Note on what IF-10's non-firing does and does not carry.** Phase 0 recorded in advance that its
FAILED branch was near-unreachable and that its non-firing carried no information. The analogue here:
IF-2 SEARCH-INERT is unlikely on a seeded arm, because the seed is already a competent controller, so
its non-firing is weak evidence. It is kept because it is the only thing that catches a run whose
matrix has no structure to count.

---

## What would falsify what

**For the experiment:**

- **CYCLING is falsified** by no single arm reaching 3 GRADEABLE runs that exceed their own Null A
  maximum at band 0.10, or by IF-5 or IF-6.
- **CYCLING (PANEL-VISIBLE) is falsified**, with CYCLING (SELF-RELATIVE) surviving, by fewer than 2 of
  the arm's cyclic runs showing `INV` at checkpoint 20 at least 1 above `INV` at checkpoint 0 at band
  0.10, or by those rises co-occurring with IF-14 FLOOR-SHED.
- **NO CYCLING is falsified** by any single GRADEABLE run of A1, A2 or A4 exceeding its Null A maximum at
  band 0.10, or by the median over A1's runs of (`INV` at checkpoint 20 minus `INV` at checkpoint 0)
  being 1 or more at band 0.10, or by the floor precondition holding in fewer than 10 of 13 of A1's runs,
  or by A2 tripping IF-1 in a majority of its 13, or by IF-10, or by A4 being UNGRADEABLE at arm level.
  **The `INV` conjunct is RELATIVE and that is a DESIGN gate repair (RC-3): the first version made it
  absolute (`INV = 0`), and the 13 seeds' measured `INV_0` has a median of 2 at band 0.10, so the
  absolute form could not have fired no matter what coevolution did.**
- **The coupling attribution is falsified** by A3 producing cyclic runs at the same rate as A1 or A2.
- **The anchor mechanism reading is falsified** by A1 and A2 behaving alike on both the floor
  precondition and the cyclic count.
- **The single-mean limitation reading is falsified** by A4 producing no cyclic run while holding the
  floor, or by A4 failing to clear the floor at all (in which case it is UNGRADEABLE and falsifies
  nothing).
- **Instrument I1 is falsified as an instrument** by IF-8: a panel with no readable order, or with more
  than 30 of 300 decisive pairs disagreeing with its own fitted order.

**For the instruments themselves, so they are not immune to evidence either:**

- **The integer band test's justification is falsified** if no pair-and-band case in any phase 1 matrix
  has a margin exactly equal to its band, in which case the float and integer counters agree
  everywhere and the change is bookkeeping rather than a correction. Both counters are computed on every
  matrix and any disagreement is printed per pair.
- **Null A's suitability is falsified** by IF-9, which is computed and reported whatever it returns.
- **Null C's closed form is falsified** if the 200-permutation mean differs from
  `D_C * k_C * (n_C - k_C) / (n_C * (n_C - 1))` by more than one count on any champion, which would mean
  the sampler and the formula do not describe the same model.
- **The scale-matching claim is falsified** if the archive matrix does not have exactly 190 pairs, 1,140
  unordered triples and 3,420 ordered candidates, which is asserted arithmetic and is checked.
- **The panel's role as a spanning measuring stick is falsified** if its 25 members occupy fewer than 3
  of the 4 measured regimes once re-measured, which would mean the panel does not span the space it is
  meant to.

---

## The largest threat to validity, and what this design does about it

**Champion aim is fitted to one trajectory family.** A 0.574 hit rate with no lead solver, against an
opponent whose movement is identical in every start, has no support against an opponent that moves
differently. That is the largest risk to reading any phase 1 matrix as a fact about the substrate, and
it is stated as design note 3 of the signed insight.

**ROUTE B: THE SAME THREAT IS ALSO THE ARTIFACT ROUTE TO THE HEADLINE POSITIVE, AND THE DESIGN GATE
NAMED IT (RC-2).** The mechanism, spelled out so it cannot be waved away: each checkpoint champion is
selected against opponents drawn from its own temporal neighbourhood, and the aim does not transfer.
Checkpoint `u` therefore beats its temporal neighbours because it trained on them, while long-range
cells are off-distribution near-coin-flips whose orientation is close to random. A locally ordered spine
with randomly oriented long-range edges is **genuinely non-scalar**: Null A rejects it, backward edges
are plentiful, and the run lands in the strongest cell of the I2 table, returns AND intransitivity,
**while `INV` never moves at any checkpoint, meaning the population demonstrably never entered any
pocket of the frozen panel's space.** Under the first version's decision rule that combination signed
"the first positive open-endedness-adjacent signal in this corpus". So the answer to "can the headline
claim be produced by an instrument artifact" is YES, by checkpoint-local specialisation drift under
non-transferring aim. **Instrument I1 exists precisely to discriminate this, and the CYCLING branch now
consumes it**: that combination is CYCLING (SELF-RELATIVE), which signs intransitivity and is barred
from the pocket and open-endedness language. Route B is reported as the live alternative explanation
whenever the SELF-RELATIVE label applies, not dismissed.

**This design does not fix the aim-transfer threat. It measures it, and it accepts the scope that
measurement imposes.**

- **The threat is already visible in a pre-measured quantity, before phase 1 runs.** In phase 0's
  cross-play probe (POST HOC) the kill-mode champions average 0.4454 against their peers while scoring
  0.9375 to 1.0000 against the floor bot, and the weakest of all twenty in cross-play is a kill-mode
  champion at 0.9938 against the floor bot. So the non-transfer is not a hypothetical; the panel
  measurement at step 2 re-measures it under pre-registration and the number goes in the record before
  any coevolution run.
- **In coevolution the opponent's movement changes every generation, so the aim must generalise or the
  population's competence falls.** That is exactly what the floor monitor reads, at every checkpoint,
  against a frozen scripted opponent that is not in the training loop. IF-1 is the flag.
- **What is therefore NOT available, and it is stated now:** if the panel measurement shows the seeds'
  median panel win rate over the 19 non-scripted panel members well below their floor-bot rate, then
  every phase 1 matrix is a matrix of controllers whose aim does not transfer between opponents, and the
  cycling verdict is scoped to that population rather than to the substrate at large. That scope label
  is attached to the verdict unconditionally, not decided afterwards. **A cycle among controllers whose
  aim does not transfer is still a cycle, and a scalar strength that fails to explain such a matrix has
  still failed.** What is unavailable is any extrapolation to competent play.
- **`predictive_gun` NEVER enters a training opponent set, in any arm.** Training on the monitor would
  destroy the monitor. This is why the floor column of the panel scoring is a valid read at every
  checkpoint.

---

## How the search under-convergence confound stays CLOSED

This is the confound that spoiled every negative in the closed Flatland arc: "it never learned X"
always carried "at this budget", and `SYNTHESIS_P7.md` records it as the live unresolved limitation,
with Programme 2 having attempted to settle it and signed zero insights. Phase 0 closed it for this
front. Phase 1 keeps it closed by four pre-committed devices, not by assumption:

1. **The population STARTS above the floor.** A1, A2 and A3 are seeded from champions certified at
   0.9375 to 1.0000 held-out against `predictive_gun`, with SC1 proving the seed is the champion that
   was measured and SC2 proving its behaviour reproduces the panel's own row for it.
2. **The population is MONITORED against the floor at every checkpoint**, against the same frozen
   scripted opponent and the same 80 held-out starts and the same inherited bar `B = 0.5748`. That
   threshold is not chosen here; it is phase 0's. A run that leaves the regime is UNGRADEABLE by IF-1
   rather than counted as a negative.
3. **The budget is phase 0's**: 50,000 unique evaluations, both optimisers evaluating offspring only
   with no parent re-scoring, so evaluations equal lambda times generations exactly. At Dim 281 that is
   178 evaluations per dimension, and the objection "the covariance had not moved" is unavailable, as it
   was in phase 0. **IF-10 tests the budget from the inside**, by comparing the first and second halves
   of the archive on scale-matched submatrices.
4. **A negative requires two optimiser classes**, one of which (`mu_lambda_es`, mu = 10 distinct
   parents) can hold coexisting counter-strategies that the primary's single Gaussian mean cannot.

**The one thing phase 0 did NOT certify and phase 1 cannot inherit** is that either optimiser converges
under a NON-STATIONARY fitness. Phase 0's certification is for a fixed deterministic fitness against
scripted bots. This is named as the residual and it is what IF-2, IF-3, IF-4 and IF-10 exist to catch.
A negative that survives all four is a statement about the substrate at this budget with these two
optimiser classes, and no stronger.

**AND DEVICE 4 IS HOSTAGE TO A MACHINE THAT HAS NEVER BEEN TURNED ON (gate blind spot 1).** The
two-class negative requires an UNSEEDED `mu_lambda_es` population to climb from the random-genome null
`R = 0.0125` across `B = 0.5748` by checkpoint 6 while the fitness is moving under it. **No run of
`mu_lambda_es` has ever been executed on this task**, not even under phase 0's stationary fitness: phase
0's arm M was skipped when arm S cleared the floor. Nothing in the corpus estimates `P(A4 gradeable)`,
so the modal real outcome of this experiment may well be INCONCLUSIVE, SECOND CLASS UNTESTABLE, and the
signable form of H1 is hostage to that. **The design cannot close this without running an arm the plan
does not license**, so it stands as a declared residual rather than as a repaired one: no probe is
invented here, and if A4 turns out ungradeable the verdict is outcome 5 and the next move is a seedable
second optimiser class, which is already what outcome 5 prescribes.

---

## What a negative would mean, and what it would NOT mean

Insight 066 is strict about its own scope and this is held to the same standard.

**A NO CYCLING verdict would mean:** with the competence floor certified and held at every checkpoint,
on one island, at engine pin `a5e8bcfc`, with this 17-channel encoder and this `[17,12,5]` topology, at
50,000 unique evaluations per run, under `sep_cma_es` seeded from certified champions and
`mu_lambda_es` from random ones, with a coevolutionary fitness of mean floored damage margin over a
6-opponent sample, the archive of a coevolutionary run is transitive to within a fitted scalar-strength
bootstrap, and the population's win pattern against a pre-measured 25-member panel does not become more
cycle-forming than the seed's own already-measured pattern was. **That is a materially stronger negative
than the bare grid's**, for two
reasons the grid's could not claim: the optimiser confound is closed rather than caveated, and the
pockets are known to EXIST in the space being searched, so the negative is "coevolution did not go
there" and not "there was nothing there".

**It would NOT mean:**

- **Not that this substrate lacks intransitivity.** The panel measurement settles that separately and
  independently, before any run.
- **Not that coevolution cannot cycle here under other methods.** Competitive fitness sharing, explicit
  novelty pressure, larger or structured populations, longer budgets and a different opponent-sampling
  rule are all untested. Fitness sharing in particular is a known device for maintaining
  counter-strategy niches and is deliberately OUT OF SCOPE here (see below), so its absence is a limit
  on the negative and is named as one.
- **Not that a scalar strength describes this space globally.** The panel's own order violations bound
  that, and they are reported whatever they are.
- **Not anything about open-endedness, escalation or arms races.** A cycle count is not an
  open-endedness measure, and phase 1 does not run the graded fixed-benchmark progress instrument that
  the P7 toolkit requires for a progress claim. The four rules of insights 053 to 056 apply, and the
  first of them is that co-fitness is blind to progress. **No progress claim of any kind is available
  from phase 1.**
- **Not that phase 2 is unwarranted.** Whether distribution and migration change the outcome is a P5
  question and is untouched here.
- **Not transferable** to a different engine, a different encoder, a different turn cap, melee, or
  controllers whose aim transfers between opponents.
- **Not a replication or a refutation of the human RoboRumble metagame's reputation.** That reputation
  belongs to authors deliberately writing counters, which is a memetic ecosystem, and
  `PLAN_ROBO_RUMBLE.md` section 1 already refuses the inference in both directions.
- **NOT ANYTHING ABOUT CYCLING FASTER THAN THE SAMPLING RATE (gate blind spot 2).** The archive samples
  one genome per 2,500 evaluations, so a Red Queen cycle with a period shorter than about two checkpoint
  intervals aliases into noise or vanishes, and no instrument here reads within-interval dynamics. The
  negative is scoped to cycling slower than that sampling rate and says nothing at all about faster
  cycling.
- **NOT ANYTHING ABOUT COEXISTING COUNTER-STRATEGIES WITHIN A GENERATION (gate blind spot 3).** The
  primary arms' archive is one lineage's generation-bests under a single Gaussian mean, so the textbook
  coevolutionary form, two counter-strategies coexisting in one population, is invisible to the primary
  instrument by construction. A4 is the only arm whose representation can hold it, and A4's own
  gradeability is the declared residual above.

**A CYCLING verdict would mean** that the archive of a coevolutionary run above the certified floor
carries more intransitivity than any single scalar strength can produce, and, **under the PANEL-VISIBLE
sub-label only**, that the population's win pattern became more cycle-forming against a panel measured
and frozen in advance. **Only CYCLING (PANEL-VISIBLE) would be the first positive
open-endedness-adjacent signal in this corpus.** CYCLING (SELF-RELATIVE) would mean the archive is
non-scalar and nothing about pockets, because route B above produces exactly that pattern with no pocket
anywhere. Either would still be scoped to this engine, encoder, topology, budget and opponent-sampling
rule, and if IF-12 fires it is POCKET RETAINED and not POCKET CREATED.

---

## Compute budget

**Measured basis, from phase 0's pilot on this box, and the derivation is shown so the estimate can be
checked and superseded.** Phase 0's authoring estimate was 3x pessimistic and its own compute section
was superseded by a measurement; the same is expected here and the same treatment is pre-registered.

```
scripted match, both sides scripted                        0.94 ms   (phase 0 pilot)
full-length (2000-turn) net match, one net vs scripted     3.0 ms    (phase 0 pilot)
   so one net's own cost at full length                    3.0 - 0.94 = 2.06 ms
held-out endpoint, 160 matches net vs scripted             0.3 s = 1.875 ms per match average
   so the average-length factor                            1.875 / 3.0 = 0.625

net vs net, FULL length     0.94 + 2 x 2.06 = 5.06 ms       PESSIMISTIC figure
net vs net, average length  5.06 x 0.625   = 3.16 ms        CENTRAL figure, 3.2 ms used below
```

**The 0.625 factor is borrowed from champion-versus-floor-bot matches, which end in kills quickly, and
champion-versus-champion matches may run longer. A PILOT MEASUREMENT of the net-versus-net average match
cost is therefore pre-registered as part of step 1, and this section is superseded by it whatever it
returns.**

Per-run arithmetic:

```
matches per fitness evaluation   K x train starts x seats = 6 x 4 x 2 = 48
per run, 50,000 evaluations      50,000 x 48 = 2,400,000 matches
                                 x 3.2 ms = 7,680 s = 2.13 CPU-h  central
                                 x 5.1 ms = 12,240 s = 3.40 CPU-h pessimistic
archive matrix per run           190 pairs x 160 = 30,400 matches = 97 s central
panel scoring per run            21 archive entries x 25 panel = 525 cells x 160 = 84,000 matches
                                 (67,200 net vs net + 16,800 net vs scripted) = 247 s central
```

| item | matches | central | pessimistic |
|---|---|---|---|
| A1 + A2 + A3, 39 runs of 50,000 evaluations | 93.6 M | **83.2 CPU-h** | 132.6 |
| archive matrices, 39 | 1.19 M | 1.05 | 1.68 |
| panel scoring, 39 runs | 3.28 M | 2.68 | 4.26 |
| the panel's own 300-pair matrix, measured ONCE | 48 k | 0.04 | 0.06 |
| `init_sigma` pilot, instrument checks, all nulls (arithmetic over stored matrices) | small | 0.03 | 0.05 |
| **UNCONDITIONAL TOTAL** | **98.1 M** | **87.0 CPU-h** | **138.7 CPU-h** |
| A4 if triggered (13 runs plus its matrices and panel scoring) | 32.7 M | +29.0 | +46.2 |
| **WORST CASE, all four arms** | **130.8 M** | **116.0 CPU-h** | **184.9 CPU-h** |

Phase 0 spent 94 CPU-h central and 162 pessimistic unconditional, 150 and 259 worst case. Phase 1 is
slightly cheaper than phase 0 on the same box.

**THE MATRIX IS QUADRATIC AND SEAT SYMMETRY HALVES IT.** The archive matrix costs `T(T-1)/2` cells; at
T = 20 that is 190 pairs, and doubling T to 40 would cost 780 pairs, 4.1x. Because the engine is
deterministic and both seats are played at every start, the two games behind cell `{J,I}` are identical
to the two behind `{I,J}` and differ only in which side reports, so `W(J,I) = L(I,J)` exactly and 60,800
matches become 30,400. **That licence is CHECKED (SC4) on 10 pre-committed pairs of every matrix and not
assumed**, and IF-6 doubles the matrix cost rather than silently reporting a wrong number.

**BOX:** 32 cores, 125 GB. Runs are independent and pure and `rand` state is per process, so
parallelism is free and deterministic. A3 depends on A1's archives, so the wall clock is two stages:
stage 1 is A1 plus A2 (26 runs, one wave on 32 cores, about 2.2 h central), stage 2 is A3 (13 runs,
about 2.2 h). Plus about 30 minutes of measurement. **About 5 h wall clock central and 7.5 h
pessimistic unconditional, about 7 h and 11 h with A4.**

**Compute is NOT a reason to cut seeds, evaluations, or matches per cell.** If spare compute appears,
spend it in this pre-committed order: (1) more SEEDS per arm, because the decision rule counts runs and
13 is the binding number in every branch; (2) more archive checkpoints, because T is the matrix's
resolution; (3) more evaluations per run, which is last because IF-10 tests the budget from the inside.
**Cutting matches per cell below 160 is forbidden outright**, because that is the granularity failure
phase 0 already paid for.

---

## Out of scope, stated so it is not drifted into

- **Islands, migration and any mesh transport.** That is phase 2 and a P5 question.
  `PLAN_ROBO_RUMBLE.md` is explicit that introducing islands at the same moment as the cycling question
  makes neither result attributable, and calls it the front's main self-inflicted-confound risk. One
  island, one box.
- **ReckonDB, evoq, signed visit ledgers, spectators, leaderboards.** Re-raise triggers 1, 2 and 3.
- **Competitive fitness sharing, novelty pressure, and any diversity-maintenance mechanism.** These are
  the obvious next rung if phase 1 returns NO CYCLING with the floor held, and they are excluded here
  because each is a second experimental variable and phase 1 already carries two (coupling, anchoring).
  Their absence is a named limit on the negative, not a silent one.
- **Any engine change.** MAX_TURNS, the physics, the gauntlet bots and the activation path are all
  untouched, and SC7 proves it.
- **Melee.** The nearest-contact rule becomes a target-selection strategy the moment a third tank
  exists, and it would be the experimenter's strategy rather than evolution's.
- **Any progress or arms-race claim.** No graded fixed benchmark is run, so by the P7 toolkit's own
  first rule no progress statement is available.
- **Elo or any scalar rating adopted as an instrument.** The Bradley-Terry fit is a null model and the
  panel order is an axis for counting inversions. Neither is a rating and neither orders a champion for
  any decision.
- **Re-running any phase 0 arm, or modifying any archived genome.** Phase 1 reads the archive and
  replays archived champions through matches, which is not an arm re-run, and it says so wherever it
  does it.
- **Opponent-family generalisation as a claim.** The panel is fixed, so nothing here tests robustness
  to families outside it.

---

## Hypothesis

Stated in advance so the write-up cannot claim to have expected whatever happened. Each part can be
wrong and each has a named falsifier above.

**H1: NO CYCLING, and the mechanism is a graded monotone one.** 0 of 13 GRADEABLE runs in A1 and 0 of 13
in A2 exceed their own Null A maximum at band 0.10; **the median over A1's runs of (`INV` at checkpoint
20 minus `INV` at checkpoint 0) against the frozen panel is at or below 0 at band 0.10**; and the archive
matrices are strongly time-ordered with a backward-edge share below 0.10, reproducing insight 057's
"later dominates earlier 24-29 to 0-1" pattern in a materially different substrate. **The `INV` half of
H1 is RESTATED from its first version, which said the median `INV` is 0 at every checkpoint including
the last.** That form was already refuted by data on disk before any run: the 13 seeds' measured `INV_0`
at band 0.10 has a median of 2 and nine of thirteen seeds start non-zero (section I1's table, from
`exp066_residue_and_inv0.txt`). The prediction is that coevolution does not INCREASE the inversion count,
not that the count is zero, and the amendment is made here, before any arm runs, rather than after
seeing a phase 1 number. **Why:** phase 0 measured the winning mechanism as a
range-locked orbit that wins a damage exchange at a range where `robo_gauntlet:range_power/1` drops the
opponent from power 30 to power 20, held for a third to two thirds of every match, with weaving ruled
out directly (0.82 lateral sign reversals per 100 turns against a bullet flight of 8.2 to 21.8 turns)
and a constant-velocity ghost hit at essentially the same rate as the champion. **A better orbiter at a
better range beats a worse one. That is a scalar, and scalars do not cycle.**

**H2: the floor holds in A1 and is LOST in A2.** A1 satisfies the floor precondition in at least 10 of
13 runs; A2 trips IF-1 in a majority of its 13. **Why:** the hall of fame is the only thing in A1 that keeps a
floor-competent ancestor in the opponent set, and coevolution against contemporaries alone has no term
that preserves absolute competence. If both halves hold, phase 1's honest verdict is THE ANCHOR
SQUEEZE and not a clean negative, which is the `SYNTHESIS_P7.md` pattern appearing again.

**H3: the panel's dominance order will not align with floor competence.** The pre-registered panel
measurement reproduces a Spearman rho between held-out floor-bot `W` and panel row mean that is near
zero or negative (phase 0's post-hoc probe read -0.1451), the near-parity brawlers rank above the
kill-mode orbiters on average, and seed 2016 (in neither tier) ranks at or near the top. Consequently
the coevolved champions climb the panel order while their floor-bot win rate falls, and the two
trajectories have opposite Spearman signs against checkpoint index.

**H4: the specific residue phase 0 found is a regime boundary and phase 1 will not enlarge it.** Any
cyclic triple that does appear will involve a run seeded from 2003 or 2013 (long standoff), because that
is where phase 0's entire within-tier residue sits (now persisted: 0 cycles at all three bands over the
other 11 champions and 165 triples, of which 115 are cyclable at band 0.10,
`exp066_residue_and_inv0.txt` section B), so IF-12 fires and the positive is POCKET RETAINED.
**H4 is VACUOUS if H1 holds**, because a verdict with no cyclic triple in it has nothing for H4 to be
about. H4 is therefore testable only on the branch where H1 fails, and it is stated so that the branch
where H1 fails is not free to be read as maximally strong.

**Explicit falsifiers, restated as one list:**

- H1 falsified by any single GRADEABLE run of A1, A2 or A4 exceeding its Null A maximum at band 0.10, or
  by a median (`INV` at checkpoint 20 minus `INV` at checkpoint 0) of 1 or more over A1's runs.
- H1's mechanism half falsified by a backward-edge share of 0.10 or more with the archive still at or
  below the Null A median, which is the SECOND cell of the I2 table and is neither story.
- H2 falsified by A2 holding the floor, or by A1 losing it.
- H3 falsified by a panel Spearman rho above +0.5, or by the kill-mode group outranking the near-parity
  group on panel row mean.
- H4 falsified by a cyclic triple appearing in a run seeded from a tight or mid orbit champion.

---

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all nine changes applied above

The gate did not find the design circular and did not ask for a redesign. It recorded as clean, and
these are noted because a gate that only complains is not calibrated: the integer counter with its tie
rule in prose and the bands separable at 160 matches per cell; Null A decisiveness-gated, registered, and
argued against four named alternatives; scale comparisons made on shares of cyclable triples;
pseudoreplication handled with runs as the unit and the family-wise arithmetic shown; compute derived
rather than asserted, with the borrowed 0.625 match-length factor flagged and a superseding pilot
pre-registered; the under-convergence confound genuinely closed for the seeded arms; the seeding decision
argued with both biases declared and both labels pre-committed; the scope section forbidding the progress
and open-endedness overclaims; and H1 through H4 embarrassable with named falsifiers.

**What it did find was that the DECISION MACHINERY had holes that data already on disk could exploit.**
Two combinations of results landed in no verdict, the CYCLING rule dropped a conjunct its own outcome
definition asserted, the NO CYCLING branch contained an absolute-zero condition that the persisted matrix
already contradicted, and the IF-9 fallback rebuilt the three-nulls hole phase 0 paid for. None needed a
redesign and all nine changes are applied in place.

### The nine required changes and where each landed

1. **RC-1, the ladder is not a partition.** Applied in "Decision rule": per-run **GRADEABLE** is now
   defined (floor precondition, `n >= 15` distinct above-floor checkpoints after dedup, and no IF-9), and
   only a GRADEABLE run can be CYCLIC or enter NO CYCLING's zero-cyclic conjunct; an UNGRADEABLE run whose
   count exceeded its null is printed as an UNGRADEABLE EXCEEDANCE. The ladder is rewritten with **eight**
   outcomes, CYCLING and PARTIAL are explicitly **per-arm** and count a gradeable A4, the pooled count is
   printed and never promotes a verdict, FLOOR-LOST no longer reads A1 alone, and the totality claim is
   **discharged by an exhaustion argument under the ladder** instead of asserted. The outcome list at the
   head of the document says plainly that the earlier "no combination lands nowhere" sentence was false.
2. **RC-2, CYCLING must consume Instrument I1.** Applied in the ladder (branch 2) and in "Instrument I1":
   the sub-labels **CYCLING (PANEL-VISIBLE)** and **CYCLING (SELF-RELATIVE)** are mandatory, the panel
   conjunct is `INV_20 - INV_0 >= 1` in at least 2 of the arm's cyclic runs, and SELF-RELATIVE is barred
   from pocket-exploitation and open-endedness language. The artifact mechanism is written up as **route
   B** in "The largest threat to validity", named as the answer to whether the headline can be produced by
   an instrument artifact: yes, by checkpoint-local specialisation drift under non-transferring aim.
3. **RC-3, the absolute `INV = 0` condition.** Applied in the ladder (branch 6), in "What would falsify
   what", and in H1: the condition is now the **median over A1's runs of (`INV` at checkpoint 20 minus
   `INV` at checkpoint 0)**, the checkpoint is named, and the 13 seeds' `INV_0` is **computed and printed**
   in section I1 from `exp066_crossplay.txt`. It is not zero: median 2 at band 0.10, nine of thirteen seeds
   non-zero, so the absolute form was unreachable before the first run. H1 is restated to match and the
   restatement is labelled as such.
4. **RC-4, the silent Null A to Null B swap.** Applied in "Null A" (fit gate), "Null B" (role), and the
   IF-9 row: IF-9 now makes the RUN ungradeable, records the mismatch **with its sign**, treats a DEFLATED
   null as positive-direction evidence that this instrument cannot convert into a verdict (with the
   NULL-UNFIT RESIDUE label), and **Null B never decides CYCLIC in any circumstance**. A majority of IF-9
   firings in an arm is INSTRUMENT FAILED.
5. **RC-5, IF-3 under a non-stationary fitness.** Applied in the IF-3 row and in "The archive": collapse
   BELOW the floor stays instrument failure, collapse AT a floor-holding champion is **CONVERGED**, does
   not count toward the INSTRUMENT FAILED majority, and the run stays gradeable on its **deduplicated**
   above-floor submatrix when that leaves `n >= 15` or is CONVERGED-UNGRADEABLE when it does not. Dedup by
   content hash is stated in the archive section.
6. **RC-6, common random numbers broken across arms.** Applied in "The opponent set" and "Seeds and every
   random quantity": two streams per run, the optimiser sampling stream `{RunSeed, 7}` **shared** across
   A1, A2 and A3, the opponent-draw stream `{ArmCode, RunSeed, 11}` per arm, **SC11** checking that
   generation 1's offspring are bit-identical across those arms at the same run seed, and an explicit
   statement of what CRN buys here (generation 1 and the seed-level confound) and what it does not
   (anything after the trajectories diverge). A4 shares nothing, A3 consumes no opponent draws at all,
   and both facts are stated in that section rather than left to be inferred from the seed table.
7. **RC-7, A4's arm-level gradeability undefined.** Applied in "Decision rule": **A4 is gradeable at arm
   level iff at least 10 of its 13 runs hold the per-run floor precondition**, the same fraction A1 is held
   to, and on a mixed A4 only the gradeable runs enter the conjuncts with both counts printed.
8. **RC-8, a verdict label resting on an unpersisted number.** Applied by computing it:
   `scripts/exp066_residue_and_inv0.escript` over `exp066_crossplay.txt`, persisted in
   `programmes/p7_coevolution/exp066_competence_floor/exp066_residue_and_inv0.txt` section B, cited in the
   seeding section (with the full table) and in the IF-12 row. The 11 kill-mode champions other than 2003
   and 2013 carry **0 cycles at all three bands** over 165 triples of which 130 / 115 / 96 are cyclable, so
   the zero is not a shortage of decisive material. Three gates against the persisted records run before
   any number is written, and the script uses no RNG.
9. **RC-9, three specification gaps.** (a) Applied in "The opponent set": one opponent set per generation,
   **shared by all `lambda` offspring**, so comma selection ranks on a common comparison. (b) Applied in the
   same section: A3's shuffle is now load-bearing as a **generation-indexed walk** through the once-shuffled
   frozen archive, with **SC12** checking that each member fills exactly 750 of the 15,000 opponent slots;
   the dead uniform-draw-from-a-shuffled-list form is gone. (c) Applied in "Instrument I2": the table has
   **six cells, not four**, with the band between the Null A median and maximum given its own pre-committed
   reading.

### The blind spots the gate named, and where each is answered

1. **The modal outcome may be INCONCLUSIVE and no run of `mu_lambda_es` has ever been executed on this
   task.** Answered in "How the search under-convergence confound stays CLOSED" as a **declared residual**,
   not a repaired one: `P(A4 gradeable)` is unestimated, no probe is invented, and outcome 5 already
   prescribes the next move.
2. **Checkpoint spacing is a sampling rate.** Answered in "The archive" and carried into "What a negative
   would NOT mean": a NO CYCLING verdict is scoped to cycling slower than about two checkpoint intervals.
3. **The archive is one lineage, not a population.** Answered in the same two places: within-generation
   polymorphism is invisible to the primary instrument by construction, and A4 is the only arm whose
   representation could hold it.
4. **Mutual non-engagement had no named outcome.** Answered by adding outcome 8 **NON-ENGAGEMENT**, a
   carve-out at precedence 0 from INSTRUMENT FAILED, with the IF-2 row carrying the carve-out.
5. **The floor gate is coarse relative to the seeds, so `INV` rises are not the specialisation signature
   and nothing else.** Answered by softening the I1 claim to what Null C actually controls for and by adding
   **IF-14 FLOOR-SHED**, whose firing bars a run's `INV` rise from counting toward the panel conjunct.

### What this pass added BEYOND the nine changes, labelled so the boundary is visible

Three things here are not gate-required and are marked as additions rather than smuggled in as repairs.
**SC13** (the 25-member panel's `INV_0` must be at least the champion-only value now printed) exists
because RC-3 turned a baseline into a printed number that the panel measurement must be consistent with.
**The per-arm blocking rule and the DECOUPLED-CONTROL CYCLED label** in the decision rule close two
ambiguities the exhaustion argument exposed while it was being written: "in a majority of an arm's runs"
did not say WHOSE failure blocks which verdict, and the ladder did not say whether A3 can carry a verdict
(it cannot). **Outcome 8 NON-ENGAGEMENT and IF-14 FLOOR-SHED** answer blind spots 4 and 5, which the gate
raised without requiring a change. Nothing else was altered: no threshold was moved, no band was swept,
no null was replaced and no definition was loosened.

**The gate's own critique is not immune to evidence either.** Its RC-3 argument is falsified if the
25-member panel measurement at step 2 returns a median seed `INV_0` of 0 at band 0.10, which would mean
the champion-only lower bound printed in section I1 is not what the full panel shows. That is checkable at
step 2 and the number goes in the record whichever way it lands. Its RC-1 combination (i) is falsified if
no run ever loses the floor while carrying a cyclic above-floor submatrix, in which case the repair costs
nothing and buys nothing. Neither falsification would restore the first version's rules, because both
holes were about what the rules PERMIT, not about what the runs happen to do.

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
