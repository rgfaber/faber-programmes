> Part 1 of 6 of the [EXP-067 pre-registration](exp067_coevolution_cycling.md). The root holds the framing, the status and the section index.

# EXP-067 PART 1. The handover, the question, and the primary endpoint

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
  (section "The reference panel", PART 3).
- **IF-8 as a memorisation instrument is not carried.** Phase 0's `trainW` reads 1.0000 for 40 of
  40 champions on a 12-match train split, so the flag was untestable with that instrument. That
  fact stands in phase 0's record permanently and is not repaired here. Phase 1 registers a
  DIFFERENT instrument (IF-11 below, PART 4) that reads the FLOORED MARGIN, because phase 0's post-hoc
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

**TEN outcomes, all pre-committed. The first version of this section said "six outcomes, all
reachable, with a precedence order fixed in the decision rule below (PART 4) so that no combination of
results lands nowhere". THAT CLAIM WAS FALSE**, and the DESIGN gate of 2026-07-30 produced two
concrete combinations the six-outcome ladder could not emit (a floor-losing run that is cyclic on
its own above-floor submatrix, and an A4-only positive). The ladder below is repaired, two outcomes
are added, and its totality is **discharged by an exhaustion argument at the foot of the decision
rule (PART 4) instead of asserted in a sentence.** **The gate's ROUND 2 then found the negative had no
minimum evidence base and the panel median no symmetric filter, so outcomes 9 and 10 are added by
RC2-3 and RC2-2 and the ladder (PART 4) gains two precedence positions, 5a and 5b.** **The gate's ROUND
3 returned REDESIGN, on one thing and one thing only: the rule separating outcome 2 from outcome 7 was
still decidable by COMPOSITION rather than by ARRANGEMENT, so a pure transitive climb landed in the
branch reserved for panel inversion. NO OUTCOME IS ADDED OR REMOVED BY ROUND 3 and the ladder keeps its
ten positions; what changes is the STATISTIC that separates the last two, and the descriptions of
outcomes 1, 2, 7 and 10 below are corrected to state the rule that is now implemented.**

1. **CYCLING.** The archive carries more intransitivity than a fitted scalar-strength model can
   produce, **AND more than a coevolution-free matrix of the same shape on this same substrate already
   carries (leg (iii), RC2-4; this leg was missing from THIS SENTENCE while outcome 2 below carried it,
   and it is added by DESIGN gate round 3, RC3-7a)**, and the population's win pattern against a
   pre-measured fixed panel is cycle-forming rather than prefix-shaped. **The split into two sub-labels
   is MANDATORY and pre-committed, and only the first is the headline:**
   - **CYCLING (PANEL-VISIBLE).** Both halves hold: the count test and the frozen-panel inversion
     test **read against Null C rather than against its own earlier raw value (RC2-1)**. First
     positive open-endedness-adjacent signal in this corpus.
   - **CYCLING (SELF-RELATIVE).** The count test holds and the panel inversion count does not rise
     above its own row-permutation null. This signs the intransitivity half only. It is **barred**
     from being reported as pocket exploitation, as open-endedness-adjacent, or as evidence that the
     population entered any pocket of the panel's space, because a matrix of checkpoints that each
     beat their temporal neighbours produces it with no pocket anywhere (see "The largest threat", PART 5,
     route B).
2. **NO CYCLING.** The archive is transitive to within a strength-model bootstrap, **or is no more cyclic
   than a coevolution-free matrix of the same shape on this same substrate (leg (iii), RC2-4)**, and
   **fewer than 2 of A1's qualifying runs end with a panel win pattern more cycle-forming than the MOST
   cycle-forming of 200 composition-matched random patterns of the same win-set size, in a run whose seed
   was not already above that reference (RC3-1)**. Requires a minimum evidence base of 7 gradeable runs
   of 13 in each arm the claim needs (RC2-3), otherwise outcome 9, and 7 of 13 qualifying runs for the
   panel conjunct, otherwise outcome 10. **The panel clause is stated here in the form the ladder
   implements, which is a round-3 correction (RC3-2): the first version read "than the seed's own",
   which compares two patterns of different sizes; round 2 replaced that with a mean-centred median that
   the ladder then implemented and round 3 withdrew; the live rule is the exceedance COUNT above, the
   same conjunct the positive uses, and this sentence, PART 5's "What a NO CYCLING verdict would mean"
   and PART 4's branch 6 now all say so.** A much
   stronger version of insight 057's negative, because the floor confound is closed AND the pockets
   are known to exist in the space being searched, which insight 057 could not say.
3. **PARTIAL.** One or two runs of thirteen cycle **within a single arm**, which does not meet the
   within-arm replication requirement. (The first version called it "not a family-wise safe positive",
   which rested on a per-run rate that measurement has since contradicted; see RC2-4.)
4. **FLOOR-LOST.** The population leaves the certified competence regime, so the matrix cannot be
   read against the certification the plan requires. Signable as a finding about coevolutionary
   dynamics, and it does NOT answer the cycling question.
5. **INCONCLUSIVE, SECOND CLASS UNTESTABLE.** The negative holds for the seedable optimiser and the
   second optimiser class never reached the floor, so a universal claim is not available.
6. **INSTRUMENT FAILED.** Enumerated as IF-1 to IF-14 and each distinguished from a real negative
   in advance.
7. **PANEL-INVERTED, ARCHIVE TRANSITIVE. (ADDED by the DESIGN gate's RC-3.)** No run's archive
   beats its own strength-model bootstrap, so there is no intransitivity claim, but **2 or more of A1's
   qualifying runs end with a panel win pattern that EXCEEDS the maximum of 200 composition-matched
   random patterns of its own win-set size, while their seeds did not.** The second conjunct of outcome
   2 fails, so the negative is not signable as NO CYCLING, and the next move is the panel-relative
   question rather than more seeds. **The description "the median run's inversion count against the
   frozen panel RISES" is withdrawn (DESIGN gate round 3, RC3-1 and RC3-2): a rise in an inversion count
   is what composition drift produces on its own, which is why the rule no longer reads one.**
8. **NON-ENGAGEMENT. (ADDED in answer to the gate's blind spot 4.)** The population converges on
   mutual non-engagement while holding the floor: draw-parked cells and few decisive edges. Two
   coevolved long-range orbiters that never close produce this, and it is a finding about what this
   substrate's coevolutionary dynamic converges to, **not** an instrument failure. No cycling claim
   is available in either direction.
9. **CONVERGED, BASE INSUFFICIENT. (ADDED by DESIGN gate round 2, RC2-3.)** No run is CYCLIC, but
   fewer than 7 of 13 runs are GRADEABLE in an arm the negative needs, so the universal claim would
   rest on an evidence base thinner than the positive's own 3-of-13 arithmetic requires. **This is
   the design's own H1-predicted endgame** (runs converge onto one competent phenotype, dedup takes
   `n` below 15, the run is CONVERGED-UNGRADEABLE), and as the first version was written "0 CYCLIC
   runs among ALL the GRADEABLE runs" was **vacuously satisfiable over 2 gradeable runs of 39**. It
   is NOT NO CYCLING and it is NOT an instrument failure: it is a statement that the coevolutionary
   dynamic converged before the instrument had a population to measure.
10. **INCONCLUSIVE, PANEL BASE UNAVAILABLE. (ADDED by DESIGN gate round 2, RC2-2, with its second
    sub-label author-added.)** No run is CYCLIC and the archive is transitive, but the panel conjunct
    that separates outcome 2 from outcome 7 cannot be evaluated on a base that means anything. (**The
    word was "median" until DESIGN gate round 3 replaced the median with an exceedance count, RC3-1.**)
    Two pre-committed sub-labels:
    - **PANEL BASE ERODED.** Fewer than 7 of 13 A1 runs qualify for the branch 6 / 7 conjunct after the
      symmetric filter (IF-1 did not fire, IF-14 FLOOR-SHED did not fire, **and neither checkpoint 0 nor
      the final checkpoint has a DEGENERATE Null C, `k_C = 0` or `k_C = n_C`, whose permutation
      distribution is a point mass at 0 and which can therefore vote for neither branch: added by DESIGN
      gate round 3, RC3-1, after the withdrawn median was found to count a degenerate checkpoint's exact
      zero toward the negative**).
    - **PANEL VOID.** IF-8 PANEL-DEGENERATE fired, so instrument I1 has no readable order and no
      `INV` is defined. **This sub-label is author-added, not gate-required**, because IF-8's
      order-violation trigger is known to be tight (26 of 150 band-decisive pairs of the 190-cell
      champion submatrix already disagree with a fitted order, against a trigger of more than 30 over
      all 300 pairs; **the headroom that leaves is UNKNOWN until the 25-member refit at panel step 2,
      which is DESIGN gate round 3's RC3-5 correcting a first version that called it 4**, see "Null A
      has now been run on a real matrix", PART 2) and without this sub-label a firing IF-8 left branches
      6 and 7 both unevaluable and the ladder fell through.
    Neither sub-label may default into branch 6 or branch 7.

---

## The primary endpoint, counted once and named

**Primary statistic: the number of UNORDERED BAND-DECISIVE CYCLIC TRIPLES in a run's archive
cross-play matrix, at band 0.10.**

**THE GUNLESS-LEG CLAUSE IS GONE FROM THIS SENTENCE AND THAT IS A CORRECTION, NOT A LOOSENING
(DESIGN gate round 2, RC2-6).** The first version read "at band 0.10, with GUNLESS-LEG triples
excluded". An archive matrix's members are 20 evolved checkpoint champions of one run; `sitting_duck`
and `spinner` are PANEL members and can never be members of an archive matrix, so the exclusion did
zero work in the primary count while implying a protection the primary count cannot have. The
exclusion is real and it is retained where it bites, on the PANEL-DERIVED counts (`INV`, the panel's
own cyclic-triple count, IF-8's pocket clause), and it is stated there. What replaces it in the
archive matrix is not an identity test, because there is no member identity to exclude on: it is the
**DAMAGE PROVENANCE REPORT** below, which makes the same mechanism visible behaviourally.

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

**GUNLESS-LEG EXCLUSION, SCOPED TO THE PANEL-DERIVED COUNTS, and it makes those counts SMALLER.**
`sitting_duck` "does nothing at all" and `spinner` has "NO GUN" (`robo_gauntlet.erl` line 14 for the
duck, line 234 for the spinner), so neither can deal damage and a loss to either is the subject
killing itself on a wall, on a ram or by spending its own bar. Phase 0's own record establishes the
mechanism (`exp066_two_attractors_probe.txt` section H: "duck_L and spin_L are losses to an opponent
that NEVER FIRES, so each one is the champion killing itself"). Any triple in any PANEL-derived count
that contains `sitting_duck` or `spinner` is therefore **counted separately and excluded from the
panel-derived statistic**, and reported with the exclusion named. This biases toward the negative,
which is the conservative direction, and the excluded count is always printed. **It does not apply
to an archive matrix, where no member can be a scripted rung.**

**HOW BIG THAT MECHANISM WAS IN PHASE 0, imported from the signed insight's dated correction rather
than from the claim it corrects.** Of the 13 cyclic triples phase 0's recovered scripted-null work
found under its own `W > 0.5` relation, **9 run through the duck or the spinner**
(`exp066_recovered_rates_and_null_fix.txt` section D and its footer term's `cyclic_triples` list:
the nine are `{rammer, sitting_duck, d2008}`, `{rammer, spinner, d2001}`, `{rammer, spinner, d2008}`,
`{circle_strafer, sitting_duck, d2008}`, `{circle_strafer, spinner, d2001}`,
`{circle_strafer, spinner, d2008}`, `{predictive_gun, sitting_duck, d2008}`,
`{predictive_gun, spinner, d2001}`, `{predictive_gun, spinner, d2008}`). **The two surviving
PRE-REGISTERED cycles both run through the `rammer`, which can deal damage**, and are
`{predictive_gun, rammer, d2003}` and `{predictive_gun, rammer, d2007}`. **All thirteen pass through
an arm D champion, and arms S and L contribute none.** Arm D trained on the floor rung alone and
therefore never saw the rung that beats it, so **phase 0's recovered residue is a statement about the
CURRICULUM and not about the ARENA**
(`faber-ecosystem/insights/066-evolution-clears-the-robo-rumble-competence-floor.md`, section
"APPENDED CORRECTION AND POINTER, 2026-07-30", commit 224247f). That correction also **REFUTES** the
candidate intransitive triple the signed insight's own final section asked for: against arm D seed
2004 the sitting duck wins 1 of 160 and draws 157, so under this experiment's convention the duck does
not beat 2004 and the leg fails. **Nothing in this document cites that candidate triple; the
correction is what is cited.**

**PER-CYCLE BEHAVIOURAL REPORTING IS REQUIRED, NOT OPTIONAL (RC2-6 and gate blind spot 3).** Phase 0
learned the gunless mechanism only from an adversarial pass afterwards, and that pass also found its
within-tier residue was **neither independent nor comfortably inside the band**. Both facts are persisted
in `exp066_within_tier_recount.txt`'s own correction block, and both are quoted here as the reason these
reports exist rather than as background:

- **KNIFE-EDGE (its correction 3).** "At band 0.15 the cycles {2001,2003,2013} and {2001,2006,2013} both
  have minimum absolute margin 0.15625, which is 0.00625 above the band, half of one flipped match out of
  30,400. **No margin-slack statistic was reported for any counted cycle; it should have been.**" That is
  2 of the 4 all-kill cycles at that band.
- **PIVOT EDGES (its correction 4).** "At bands 0.10 and 0.15 all four all-kill cycles hang on two pivot
  edges: (2001,2013) carries two and (2003,2020) carries two. Flipping either edge removes half of them."
  So a count of 4 was 2 independent structures.

For **every cyclic triple counted in any archive matrix or any panel matrix**, at every band, the runner
therefore prints:

1. **DAMAGE PROVENANCE, per edge.** For each of the triple's three edges, the winner's mean BULLET
   DAMAGE DEALT per decided match and the loser's mean SELF-INFLICTED share of the damage it took,
   so an edge won by the opponent grinding itself to death against a wall, a ram or its own bar is
   visible on the page. This costs no extra matches: the cells are already played, and the
   requirement is that the per-cell damage totals are RETAINED during matrix measurement rather than
   discarded once the win count is formed.
2. **EDGE-FAMILY STRUCTURE.** The set of cyclic triples is partitioned by SHARED EDGE, and for each
   edge carried by two or more counted cycles the count of cycles hanging on it is printed, largest
   first. Phase 0's cyclic residue was pivot-edge families around behavioural outliers, not
   independent cycles, and a count of 4 cycles resting on 1 pivot edge is a different object from 4
   independent cycles.
3. **MINIMUM ABSOLUTE MARGIN SLACK.** For each counted cycle, `min` over its three edges of
   `|K(I,J) - K(J,I)| - band * 160` on the integer grid. **The unit is the WIN-COUNT DIFFERENCE, and one
   flipped match moves that difference by 2**, so a slack of 1 is half a flipped match and is the
   smallest nonzero value the grid admits. That is exactly phase 0's knife-edge case: 25 against a band
   integer of 24 at band 0.15, which its record reports as 0.15625 against 0.15. **A cycle whose minimum
   slack is 1 is labelled KNIFE-EDGE**, and the distribution of minimum slack over all counted cycles is
   printed with the count, so a count of `n` cycles is never read without knowing how many flipped
   matches would remove them.

**None of the three gates any verdict.** They are required reports, so that the adversarial pass
phase 0 needed afterwards is available at the moment the count is read.

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

### The BEATS relation, reconciled and stated ONCE

**Phase 0 left TWO different beats relations in force across its records, and phase 1 may inherit only
one.** Neither phase 0 relation is wrong on its own ground; what is wrong is carrying both forward
without saying which counts.

| relation | exact form | where it comes from |
|---|---|---|
| **MAJORITY** | `A beats B iff W(A,B) > 0.5`, draws count as NOT beating | `exp066_recovered_rates_and_null_fix.txt` section D, the recovered-rates cycle census. That record states it once and says "NO SECOND RELATION IS DEFINED ANYWHERE IN THIS RECORD". |
| **UNBEATEN PREDICATE** | a rung is UNBEATEN iff `L > W orelse D > 0.5`; equivalently BEATEN iff `W >= L` and `D =< 0.5` | `exp066_flag_fixes.txt` section A, the WIDENED ladder-inversion predicate `inverted/1` over the four lower scripted rungs |
| **BAND-DECISIVE MARGIN** | `A beats B iff K(A,B) - K(B,A) > band * 160` on the integers, strict | THIS document's primary endpoint, defined in the block above |

**PHASE 1 USES THE BAND-DECISIVE MARGIN RELATION, AND IT USES NOTHING ELSE FOR ANY PAIRWISE CELL.**
That is the relation the primary endpoint counts cyclic triples under, and it is also the relation
`INV` and Null C read the panel under, the relation I2's backward edges and return triples are read
under, and the relation Null A's decisive-edge count and Null B's preserved structure are matched on.
One relation, every pairwise reading, no exceptions.

**The two phase 0 relations are named and each keeps exactly the scope it already had.** MAJORITY
governs the phase 0 recovered-rates census this document cites for the 13 recovered cycles and for the
gunless-leg mechanism, and it is quoted as that record's relation whenever those numbers appear. The
UNBEATEN PREDICATE governs phase 0's ladder-inversion observable over the scripted rungs, which phase
1 does not have: there is no ladder in phase 1, the ladder fitness is discarded, and no phase 1 flag
reads a rung as unbeaten. **Neither is used to read a phase 1 cell.**

**THE THREE ARE NOT NESTED THE WAY A READER WOULD ASSUME, AND THE ONE IMPLICATION THAT DOES HOLD IS
WORTH STATING.** `W(A,B) > 0.5` implies `W(A,B) > L(A,B)` and `D(A,B) < 0.5`, so MAJORITY implies
BEATEN under the unbeaten predicate; that is why the recovered-rates record calls itself "the STRICTER
of the two readings available". **But BAND-DECISIVE implies NEITHER of them.** A cell with
`W = 0.45`, `L = 0.30`, `D = 0.25` has margin `0.15 > 0.10` and is band-decisive at the primary band
while the winner does not hold a majority. So a phase 1 matrix can be full of band-decisive edges
whose winners win fewer than half their matches, and **that is precisely the state IF-7
DRAW-DOMINATED exists to flag**, at a draw share above 0.20 against phase 0's measured 0.01553.
The relation is a margin relation by choice, because a margin is what 160 matches per cell resolves
to 1/160 and what the bands are defined on; the cost is that it does not imply a majority, and the
flag that bounds the cost is named.

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

