# EXP-069. How narrow is the phase 0 floor result? Two perturbations of the opponent, read independently

**Status: PRE-REGISTERED 2026-07-30. NOT RUN. DESIGN gate: round 1 (2026-07-30)
BUILD_WITH_CHANGES, seven changes applied below; round 2 (2026-07-30) BUILD_WITH_CHANGES, changes
NOT applied. No runner exists, and none may be written until they are.**

Small by design. **ONE endpoint, ONE bar shape, applied INDEPENDENTLY to two arms.** Not a
conjunction: each arm is read on its own and neither gates the other. EXP-067 needed four gate rounds
because one decision rule had to serve a positive branch, a negative branch, an instrument-failure
branch and two sub-labels at once. This document does not do that.

**No evolution runs anywhere.** Every number comes from replaying archived champions, and the phase 0
null genomes regenerated from their recorded seeds, through the existing match loop. No genome is
modified, no optimiser is called.

---

## Why this exists

Insight 066 signed a median held-out win rate of **0.9750** against `predictive_gun`, against a
pre-registered bar of **0.5748**. It also names, in its own caveats, two reasons that result may be
narrower than it reads, and **tests neither**:

> **The floor is bot-specific by construction**, and narrower than "non-trivial evasion": the win is
> a damage exchange at a range where the opponent halves its own gun power.

> **Champion aim is fitted to one trajectory family.** A 0.574 hit rate with no lead solver, against
> an opponent whose movement is identical in every start, has no support against an opponent that
> moves differently. That is the largest risk to reading any phase 1 matrix as a fact about the
> substrate.

Both are cheap to test and both can NARROW a signed result of ours. That is the point of running
them. The corpus's standing habit is to attack its own claims before someone else does, and these
two attacks are already written down in the claim itself, unexecuted.

---

## The question, asked so that every answer is signable

Does the phase 0 competence result survive an opponent that does **not move the same way**, and an
opponent whose **range-power rule is removed**? The first draft asked this as "the same strength but
not the same shape", which assumed the answer to the strength question. Strength is now MEASURED per
arm (IF-1), not assumed.

---

## The primary endpoint

**Median held-out win rate of the 20 archived arm S champions against a PERTURBED `predictive_gun`,
over the same 80 pre-registered held-out starts, both seats, 160 matches per champion.**

Win definition unchanged and carried verbatim from phase 0: the opponent tank **DEAD** and the
subject tank **ALIVE** at match end; **draws count as not beating**.

---

## The two arms, each read independently

### Arm P: the orbit is mirrored

`robo_gauntlet:steer/3` (robo_gauntlet.erl:316-319) computes the orbiting body heading as

```
Tangent = wrap(Aim + 64 - range_error(Dist))
```

where `+64` is the quarter turn that makes the bot circle its contact and `range_error/1` pulls it
off tangent in proportion to the range error. **The perturbation mirrors both terms:**

```
Tangent = wrap(Aim - 64 + range_error(Dist))
```

**What this perturbation exactly is: a reflection.** Under a reflection of the world the contact
bearing `Aim` maps to `-Aim`, so `wrap(Aim + 64 - range_error(Dist))` maps to
`wrap(-Aim - 64 + range_error(Dist))`, which is the negation of the PERTURBED tangent at the original
bearing. The perturbed `steer/3` is the exact mirror image of the original, and it is exact because
every other term commutes with reflection: `range_error/1` depends only on a scalar distance,
`wall_push/2` is antisymmetric about the arena mid-lines because the arena is a rectangle
(robo_gauntlet.erl:325-331), the engine's sine table is exactly odd (robo_sim.erl:62-95;
`sin(255) = -804 = -sin(1)`), and `angle_of/1` was audit-fixed to round to nearest **precisely so
that a mirrored match is the mirror of the original** (robo_gauntlet.erl:500-507).

That is why the perturbation is credible, and it is a stronger argument than the first draft's
hand-wave. It cannot smuggle in a systematic wall-pinning change or a change in held range, because
reflection commutes with the wall push and the range loop.

**What is NOT mirrored, and it is the only way this arm can weaken the bot.** The perturbation
touches `steer/3` only. Four chiral residues remain: the radar sweep is always `+?SWEEP = +32`
(robo_gauntlet.erl:95, used at :428 and :442), the lock wobble alternates on tick parity (:445-446),
the unlocked hunt curve is a fixed `turn_body = 2` (:428), and `nearest_angle/2` and `ccw/2` break
ties inclusively (:516-517, :531). The perturbed bot therefore orbits one way while sweeping and
hunting the other, which changes the orbit-relative radar reacquisition geometry. `shoot/4` holds
fire unless the track is from THIS turn (:451), so a chirality-dependent track-loss rate is a
chirality-dependent FIRE rate. That is the mechanism IF-1 has to look for.

**What it changes is ORIENTATION, not shape.** The mirrored trajectories are CONGRUENT to the
originals: same radii, same curvature magnitude, same speeds, same held ranges. This bounds what a
SURVIVES on this arm can mean, and the bound is written into the scope section.

### Arm G: the range-power rule is flattened

`robo_gauntlet:range_power/1` (robo_gauntlet.erl:466-468) is

```
range_power(D) when D < ?FP * 150 -> 30;
range_power(D) when D < ?FP * 350 -> 20;
range_power(_D)                   -> 10.
```

The standoff champions hold a mean range of **196.82 whole units**, above the 150-unit boundary where
the bot drops from power 30 to power 20, while the champions fire at 29.22 tenths throughout. The
split is not a chosen threshold: no arm S seed has a mean range between 129.3 and 182.7, so any cut
in that 53-unit gap gives the same two groups (exp066_policy_probe.txt, part D). The perturbation
replaces the rule with a **constant 30**.

**THE DIRECTION OF THIS BIAS IS UNKNOWN.** The first draft claimed constant 30 makes the bot
"strictly stronger at every range". That claim is refuted by the engine. Power is coupled to six
other quantities, four of which move AGAINST the bot as power rises:

| P | bullet speed, units/turn | turns between shots | energy per shot | damage per hit | energy back on hit | power throttled below |
|---|---|---|---|---|---|---|
| 10 | 17 | 12 | 1.0 | 4 | 3.0 | 20 units |
| 20 | 14 | 14 | 2.0 | 10 | 6.0 | 40 units |
| 30 | 11 | 16 | 3.0 | 16 | 9.0 | 60 units |

Sources: `Speed = fp(20) - (3 * ?FP * P) div 10` (robo_sim.erl:280); `Heat = ?FP + (?FP * P) div 50`
(robo_sim.erl:271) against `?GUN_COOL = 26` per turn (robo_sim.erl:53, :348), so turns between shots
is `ceil(Heat/26)`; `Cost = P * ?FP div 10` (robo_sim.erl:270); `damage/1` (robo_sim.erl:317-318);
`Reward = (3 * ?FP * P) div 10` (robo_sim.erl:307); `budget(P, E) -> min(P, E div ?SHOT_BUDGET)`
with `?SHOT_BUDGET = 512` (robo_gauntlet.erl:474, :109).

Against the standoff band this means the perturbed bot's bullet takes **27% longer** to arrive
(196.8 units at 11 rather than 14 units per turn, 17.9 turns against 14.1), so the lead solver's
error grows with it; it fires **one shot per 16 turns rather than one per 14**; it spends 3.0 rather
than 2.0 units of energy per shot; and it is energy-throttled below 60 units of remaining energy
rather than below 40, so it weakens fastest exactly while it is losing. Against that it deals 16
rather than 10 damage per hit and recovers 9.0 rather than 6.0 energy per hit.

Damage per turn is `16*h30/16` against `10*h20/14`, so constant 30 breaks even only if the perturbed
bot retains **h30 >= 0.714 * h20** of its hit rate against a 27% longer flight. Nothing in the corpus
measures `h30` against a champion orbit. Whether constant 30 is stronger or weaker at the range the
champions hold is an EMPIRICAL question, answered by IF-1 and by nothing else.

Both readings stay informative once IF-1 reports the strength. A champion that still wins has beaten
an opponent of measured, not assumed, strength. A champion that collapses against an opponent IF-1
shows is no weaker tells us the win was an exploit of one scripted rule.

---

## Decision rule, pre-committed, computed on held-out only, every outcome reachable

Applied to **each arm separately**. There is no conjunction and no combined verdict.

Let `W` be the arm's median held-out win rate. The bar and the null are the arm's OWN, measured
against the arm's own perturbed bot before any champion runs, because phase 0's `B` and `R` are
properties of a MATCHUP and not of the question:

- **`B' = P' + 4*SE'`.** `P'` is the perturbed bot against its own clone over the same 80 held-out
  starts, both seats: 160 scripted matches per arm, no evolution. `SE'` is exp066's rule carried
  verbatim: start-level bootstrap over the 80 starts with both seats of a resampled start kept
  together, 10,000 resamples, seed persisted, floored at the binomial `sqrt(P'(1-P')/160)`, larger of
  the two used.
- **`R'`** is the best of the same 30 random genomes (phase 0 null seeds 1..30, frozen arm S
  encoding, regenerated deterministically) replayed against the perturbed bot, 160 matches each.

Phase 0's numbers, `B = 0.5748` from parity `P = 0.4188` with cap share 0.1625, and `R = 0.0125`, are
**reported beside `B'` and `R'` for continuity and decide nothing.**

| Reading | Condition | What it means |
|---|---|---|
| **SURVIVES** | `W >= B'` | The competence claim holds against this perturbation, at the same distance above clone-level play that phase 0 required. |
| **NARROWED** | `R' < W < B'` | The champions retain some competence but the signed 0.9750 does not generalise across this perturbation. Insight 066's scope must be tightened by an appended correction naming this arm. |
| **REFUTED AS GENERAL** | `W =< R'` | Performance falls to the untrained baseline against THIS opponent. The phase 0 result is specific to the exact opponent instance, and every downstream use of "cleared the competence floor" must say so. |

**The drop from 0.9750 is reported as an EFFECT SIZE and gates nothing.** It is the interesting
number and it is not a threshold, because no threshold on it was registered before the data existed.

**Per-tier reporting is required, not optional, and the tiers are fixed HERE.** Phase 0's 20
champions split by exp066's published tier rule (held-out `W` below 0.62 low, above 0.93 high, else
mid) into **13 high, 1 mid, 6 low** (exp066_flag_fixes.txt, `tier_sizes`). The mid champion is
**seed 2016** at `W = 0.8000`, and it is reported on its own line, never folded into either tier. The
policy probe publishes a SECOND, geometry-based split, standoff 14 against brawl 6, which places 2016
in standoff (exp066_policy_probe.txt, part D). **Both splits are reported**, so no tier assignment can
be chosen after the perturbed numbers are on screen. A median over the whole 20 hides which mode
broke; report the median, both tiers, and 2016.

---

## Instrument failure, distinguished from a real negative

- **IF-1 THE PERTURBATION CHANGED THE BOT'S STRENGTH.** Measured where the matches are decided.
  exp066_policy_probe.txt records the standoff exchange as champion hit rate 0.5740 at 29.22 tenths
  against bot 0.3533 at 17.75, damage dealt 107.03 per match against damage taken 37.24. Strength
  here is DAMAGE THE BOT PUTS ON THE CHAMPIONS, and both numbers already exist in runs this design
  requires. **Control, mandatory, no new matches:** for each of the 20 champions, the perturbed bot's
  mean damage dealt per match over that champion's own 160 endpoint matches, against the ORIGINAL
  bot's mean over the same 160 matches from the IF-4 replay. Paired by champion, 20 pairs, the
  independent unit. **Pre-committed:** if the paired mean difference (perturbed minus original) sits
  below zero by more than `2*SE` of that difference across the 20 champions, the perturbation
  weakened the bot where the matches are decided and the arm is **UNGRADEABLE**. The difference and
  its SE are **reported with every reading**: a SURVIVES whose difference straddles zero supports
  "the champions beat an opponent of INDISTINGUISHABLE strength", not "a harder opponent", and must
  be written that way.
- **IF-1 OBSERVABLE, no threshold: perturbed against original.** Played over the same 80 held-out
  starts, both seats, reported as `W/(W+L)` with its own draw and cap share. **The first draft's
  `0.40` trip is withdrawn**, for two reasons besides never having been derived. One pairwise win
  rate is not a strength scalar here: exp066_flag_fixes.txt records `rammer` beating arm D champions
  2003 and 2007 at 0.70625 and 0.63125, both of which beat `predictive_gun` above 0.93, while
  exp066_floor_feed.txt records `predictive_gun` beating `rammer` 158 of 160. That is an intransitive
  triangle in the numbers this front already signed. And on arm P the statistic is partly a symmetry:
  perturbed-against-original at a start is the mirror of original-against-perturbed at that start's
  MIRROR, so on a mirror-closed set it is pinned near `(1-draws)/2` whatever the strengths. The 80
  held-out starts are NOT mirror-closed (a modular generator with a per-index heading offset,
  `start/1` and `off/1`, exp066_single_population_floor_tests.erl:426 and :446), so the number can
  move, but a move confounds a real chiral effect with start-set asymmetry. The separating replay,
  the same control over the 80 starts PLUS their 80 mirrors, is named here and **not run**.
- **IF-2 TURN-CAP CENSORING.** If the perturbation drives matches into the turn cap, the win rate
  falls for a reason unrelated to competence. Report the cap share per arm. Phase 0's measured parity
  cap share is **0.1625** and its median champion's is **0.000**. A cap share above **0.40**, that is
  2.5x the measured parity share, precedent carried from exp066's IF-7, makes the arm
  **CAP-CONDITIONAL** and the reading must be labelled so.
- **IF-3 DRAWS.** Draws count as not beating, so a perturbation that manufactures draws depresses `W`
  without any loss of competence. Report the draw share; phase 0's whole-matrix share was 0.01553.
- **IF-4 THE HARNESS DIVERGED.** The perturbation-disabled replay must reproduce each champion's
  **per-start, per-seat OUTCOME VECTOR**, all 160 entries, not merely the aggregate win rate. Rate
  equality alone lets two extraction defects cancel inside 160 matches, one start flipped win to loss
  and another loss to win, and pass a check every later number then inherits. The vector is
  `robo_match:match/3`'s report per match (`damage`, `survived`, `alive` for both seats, and
  `turns`); `robo_sim:trace_hash/1` is available if two runs ever tie on the vector and still differ.
  Any mismatch means the harness is not the phase 0 harness and the arm is ungradeable. **This check
  runs first and halts on failure.**

---

## What would falsify what

- **Falsifies "champion competence is general across trajectory ORIENTATIONS":** arm P reading
  NARROWED or REFUTED.
- **Falsifies "the phase 0 win is not merely a range-power exploit":** arm G reading NARROWED or
  REFUTED, with IF-1 showing the perturbed bot is not weaker.
- **Falsifies this experiment's own hypothesis (below):** either arm reading SURVIVES.
- **Falsifies the measurement itself:** IF-1 or IF-4 firing.

---

## Out of scope, stated so it is not drifted into

- **A SURVIVES on arm P supports MIRROR-robustness and nothing wider.** The mirrored trajectory
  family is CONGRUENT to the original: same radii, same curvature magnitude, same speeds, same held
  ranges, only orientation flips. It therefore **cannot discharge** insight 066's caveat that
  "champion aim is fitted to one trajectory family", which is the caveat this arm cites as its
  motivation. The arm is asymmetrically informative: **P failing narrows 066; P surviving establishes
  almost nothing about the caveat.**
- **Nothing here bears on champion-versus-champion competence**, which is unregistered and lives in
  the unsigned cross-play note.
- **Nothing here re-opens the floor verdict itself.** Insight 066's 0.9750 against the UNPERTURBED
  bot stands whatever this returns; what is at stake is how far it generalises.
- **Two perturbations are not a family.** A SURVIVES on both means competence survived THESE TWO
  changes, not that it is robust in general. The honest claim is enumerative.
- **Arm G moves the two tiers by different amounts.** The brawl six hold a mean range of 122.98
  units, below the 150-unit boundary the perturbation removes, so constant 30 changes them least. It
  is not inert there either: their mean shot power is already 23.36 tenths against the standoff
  fourteen's 17.75 (exp066_policy_probe.txt, part D). Movement in arm G's MEDIAN is therefore largely
  a statement about the standoff tier, which is one more reason the per-tier report is mandatory.
- **The radar and the fire gate are untouched**, and insight 066 measured real radar denial. A
  perturbation of `shoot/4`'s `age = 0` rule is the axis nearest the champions' actual mechanism and
  is NOT tested here.
- **No claim about prediction or tracking is available** to this front by pre-registration, since the
  controller cannot see bullets and reports estimated position NOW.

---

## Hypothesis, with a prediction that can be wrong

**H1, arm P: NARROWED.** Insight 066 measured that champions do not weave (lateral reversal 0.82 per
100 turns against a bullet flight of 8 to 22 turns) and that a constant-velocity ghost is hit at
essentially the same rate. The policy is a range-locked orbit, and an orbit's stability depends on
the relative circulation direction of both parties. Mirroring one of them is predicted to cost more
than a general policy would lose.

**H2, arm G: NARROWED, and more sharply than P.** The standoff champions park beyond the 150-unit
boundary where the bot halves its own power. That is the mechanism insight 066 identifies for the
win. Removing it removes the mechanism.

**If both SURVIVE, both hypotheses are refuted.** That is a genuinely good outcome and is why both
readings are pre-committed rather than only the pessimistic one. It does **not** license "insight 066
is broader than its own caveats allow": arm P cannot answer the trajectory-family caveat (see scope),
and arm G answers only the range-power caveat. The claim available on a double SURVIVES is the
enumerative one: competence survived these two specific changes.

**Arm G is the arm that can genuinely embarrass us**, because insight 066's own mechanistic account
says the champions win BECAUSE the bot halves its power above 150 units. Arm G either confirms that
against an opponent IF-1 shows is no weaker, or refutes a signed insight's stated mechanism.

---

## Reproduce

Archived champions: `programmes/p7_coevolution/exp066_competence_floor/exp066_champions_s.eterm`.

**Run pin.** `8556d7fd9177acfaf21c21569628775f06625faa`, the commit that extracted the controller into
`faber_tweann/src/robo_pilot.erl` on 2026-07-30. Phase 0's pin
`a5e8bcfc5646827e9be49a9629f8a6a9678c814b` is two commits earlier and is the REFERENCE the
equivalence proof is measured against, not the run pin. The first draft named only `a5e8bcfc`, which
was a provenance hole: `robo_pilot` postdates it, so no run of this experiment can sit there.

**How the perturbation is applied.** `robo_gauntlet` has no parameter. `init/1` takes a kind atom and
`steer/3` and `range_power/1` are hard constants (robo_gauntlet.erl:316-319, :466-468). The first
draft's "the modification must be a parameter, not an edit to the pinned module" is therefore
**unimplementable as written and is withdrawn**. The mechanism is two ADDED KINDS,
`predictive_gun_mirror` and `predictive_gun_flat`, which moves the pin again. The provenance is then
the demonstration that the addition is inert for everything else: `gates/0` passes all seven checks
and the golden match vector
`DFCD8106EDC9AE214F6AE99BB5F4988FE441243284A6D3769634D778B3895E88` is unchanged at the new pin. Two
added kinds are preferred to a runner-local copy of the gauntlet, because the perturbed and
unperturbed bots then share every unmodified code path inside one module and copy drift is
structurally impossible.

**The extraction's own equivalence proof WAS owed and is a precondition of IF-4. It has been run,
on 2026-07-30, and it PASSED.** Until archived champions were shown to reproduce their phase 0
held-out per-match outcome vectors through the extracted pilot, this experiment could not
distinguish a perturbation effect from an extraction defect. They now are: 20 arm S champions over
all 80 held-out starts in both seats, 3,200 matches, **599,859 turns compared, 0 intent divergences
and 0 pilot-state mismatches**, and every individual match outcome identical, compared as
`{alive, opp_alive, dealt, taken, turns}` per match rather than as a rate
(`experiments/exp066_pilot_extraction_equivalence_tests.erl:354`). All 20 seeds agree exactly on W,
L and D across the feed, the runner's own `heldout/3` and `robo_pilot`, median held-out W **0.9750**
in all three columns. exp066's `gates/0` passes all seven at the bumped pin and the golden match
vector `DFCD8106EDC9AE214F6AE99BB5F4988FE441243284A6D3769634D778B3895E88` is unchanged. Record:
`programmes/p7_coevolution/exp066_competence_floor/exp066_pilot_extraction_equivalence.txt`.

**What that does and does not discharge for IF-4.** It discharges the precondition, so IF-4 is now a
check on THIS experiment's harness rather than on the extraction. It does not make IF-4 optional: the
equivalence holds on the states 3,200 matches against the UNPERTURBED `predictive_gun` visit, and
this experiment drives champions against two opponents that were never part of it. IF-4's
perturbation-disabled replay still runs first and still halts on failure.

**Cost, scripted replay only, no evolution.** Per arm: 3,200 endpoint matches, 160 parity matches for
`P'`, 4,800 null matches for `R'` (30 genomes x 160), 160 observable matches. 8,320 per arm, 16,640
for both. For scale, exp066's cross-play alone was 30,400 matches.

**One line of this accounting is corrected, 2026-07-30.** It said the 3,200-match IF-4 replay was
the already-owed equivalence work and therefore not new spend, which was why it sat outside the
8,320 and the 16,640. **That no longer holds.** The equivalence work was run that day in its own
harness against the UNPERTURBED bot and is spent. exp069's IF-4 replay is a separate 3,200 matches
inside THIS experiment's harness, and it is in neither total above. Whether it runs once for both
arms or once per arm is a build-time question this pre-registration does not settle, so no total is
invented here to cover it.

---

## DESIGN gate verdict

**Round 1, 2026-07-30. Verdict: BUILD_WITH_CHANGES.** All seven required changes applied; where each
landed:

| # | Required change | Landed |
|---|---|---|
| RC1 | Arm G's "strictly stronger" is refuted by the engine; replace with direction-unknown plus the three couplings | Arm G, the coupling table and the two paragraphs under it. Verified against source, and the gate's line citations were off by one for `robo_sim`: `Speed` is :280 not :281, `Heat` :271 not :272, `Cost` :270 not :271. The corrected numbers are used. The gate's break-even of ~0.55 used the power-10 fire cycle; against the standoff band's power 20 it is **0.714**, and that is the number stated. |
| RC2 | Replace IF-1's arm G trip with damage dealt to the champions | IF-1, applied to **both** arms rather than arm G only, since the argument that a pairwise rate is not a strength scalar holds for both. Paired by champion over 20 pairs with a `2*SE` trip, because a bare inequality on a mean fires half the time under the null and would not be an instrument. |
| RC3 | Name the mirror symmetry, the four chiral residues, make the observable draw-robust, derive or drop the 0.40 | Arm P ("a reflection", "what is NOT mirrored") and IF-1 OBSERVABLE. The `0.40` is **dropped, not derived**. One correction to the gate: the 80 held-out starts are **not** mirror-closed (`start/1`, `off/1`), so the observable is not pinned near `(1-draws)/2`; it is confounded instead. Either way it cannot carry a threshold. The mirror-closed separating replay is named and explicitly not run. |
| RC4 | Per-arm bar and null | Decision rule: `B' = P' + 4*SE'` from perturbed clone parity, `R'` from the same 30 null seeds against the perturbed bot. Phase 0's `B`, `P`, `R` reported beside them and deciding nothing. Cost stated in Reproduce. |
| RC5 | Per-match IF-4, resolve the parameter contradiction, name the run pin | IF-4 (per-start per-seat outcome vector, `trace_hash` as the tiebreak) and Reproduce (run pin `8556d7fd`, two added kinds with `gates/0` plus the golden vector as the inertness proof). The gate proposed a runner-local copy; two added kinds is used instead and the reason is on the page. |
| RC6 | Assign the 20th champion | Decision rule, per-tier paragraph: 13 high / 1 mid / 6 low, mid = **seed 2016** at `W = 0.8000`, reported on its own line, plus the policy probe's second split (standoff 14 / brawl 6, 2016 in standoff) so neither can be chosen after the fact. |
| RC7 | Scope the arm P SURVIVES to mirror-robustness; cut "broader than its own caveats allow" | Out of scope (first bullet, with the asymmetric informativeness stated) and Hypothesis (the sentence is cut and replaced by what a double SURVIVES actually licenses). |

**Nothing was negotiated away and nothing was impossible.** Two of the gate's own factual claims were
corrected against source rather than copied: the `robo_sim` line numbers, and the premise that the
held-out start set is approximately mirror-balanced (it is not).

**Blind spot recorded, not fixed**, because fixing it means a second endpoint: an arm G NARROWED
cannot separate the removed power discount from the 27% longer bullet flight. The other two the gate
named, the untested fire-gate axis and the brawl tier sitting below the 150-unit boundary, are
already in the scope section and the per-tier rule.

**Document length: 203 lines before, 359 after.** That is over this front's rough 300-line ceiling,
and it is stated rather than hidden. The growth is RC1, RC3 and RC5, each of which replaces a
one-line assertion with an argument from engine source, plus this verdict record. The SHAPE did not
grow: one endpoint, two arms, one three-cell ladder, four instrument checks, exactly as before. If a
round 2 wants it shorter, the sourced engine arguments in arm P and arm G are the compressible part,
and compressing them puts back the assertions round 1 refused.

**Round 2, 2026-07-30. Verdict: BUILD_WITH_CHANGES.** The second round ran against the document as
amended by round 1 above and returned BUILD_WITH_CHANGES a second time.

**Its required-change list is NOT recorded here, and the reason is stated rather than papered over:
it is not in any file this front persisted.** Round 1's list survives because the agent that applied
it wrote each change and its landing site into the table above as it worked. Round 2's verdict
reached this record as a verdict and nothing else. Reconstructing a seven-line table from memory is
how a gate record turns into fiction, so the gap is left visible.

What is therefore known, and all that is claimed:

| | |
|---|---|
| Round 2 verdict | BUILD_WITH_CHANGES, 2026-07-30 |
| Where the round-2 changes landed | **NOWHERE. None is applied.** Everything above this line is the round-1 document. |
| What is owed before this experiment may be built | the round-2 change list, recovered from the gate rather than re-derived, applied, and each landing site recorded in a table like round 1's |

**Consequence, and it is a block, not a note.** This front's standing rule is no experiment code
before the gate returns BUILD. BUILD_WITH_CHANGES with the changes unapplied is not BUILD, so no
runner, no perturbed kinds and no `robo_gauntlet` edit may be written for exp069 until the round-2
changes are applied and recorded here. The equivalence replay named in Reproduce is exempt and was
always exempt: it is a faithfulness check on a code move that this front already owed, not exp069's
runner, and it re-ran no evolutionary arm.

**Size, restated so the round-1 figure above is not read as current.** Round 1 recorded 359 lines.
This document is now **412 lines**, the growth being this round-2 record, the discharged
equivalence precondition in Reproduce and the corrected cost line beneath it (`wc -l` on this
file). The round-1 figure is left as written, because it is a record of round 1 and not a live
measurement.
