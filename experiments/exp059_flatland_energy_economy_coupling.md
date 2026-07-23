# EXP-059 — Flatland rung 2: is there a FORAGE/FLEE frontier, and does predator pressure move the prey along it?

Pre-registration. SECOND rung of the Flatland front (see `faber-ecosystem/plans/PLAN_FLATLAND.md`);
builds on the rung-1 INSTRUMENT (insight 058: scape works, net forages+hunts, benchmark decomposes
foraging/fleeing into ORTHOGONAL axes, 057's no-coupling refusal reproduces plants-OFF). DESIGN gate
REDESIGNED a first draft (a coupling-verdict question that conflated coupling with a train-test move-
budget shift + an M confound, had a vacuous predator side, and mostly re-confirmed 058). This is the
gate's prescribed redesign: the forage/flee TRADE-OFF, the one degree of freedom the bare game cannot pose.

- **Programme:** P7 (Coevolution) x P5/P6 convergence — the Flatland/ALife front, rung 2
- **Opened:** 2026-07-24
- **Engine pin:** `eaf10819a37781c28caa098779d0f4027487ae77` (faber-tweann with `flatland_sim`)
- **Builds:** `experiments/exp059_flatland_forage_flee_frontier_tests.erl` (reuses `flatland_sim` + the 058 benchmark)
- **Raw feed / insight:** `faber-ecosystem/insights/059-*` (once run + signed)

## The claim under test (falsifiable, not foregone)

The energy economy adds a capability the bare pursuit-evasion game cannot: FORAGING, which competes with
FLEEING for the prey's limited move budget. The 058 instrument reads foraging-skill and fleeing-skill as
ORTHOGONAL axes (validated: a pure-forager scores forage 27.6 / flee 0.31, a pure-fleer 3.5 / flee 0.69).
Two questions, neither answerable from 057/058:

1. **Is there a FRONTIER?** Can a prey be maximal on BOTH axes at once, or does gaining fleeing-skill cost
   foraging-skill? A prey that is high on both REFUTES a trade-off; a downward-sloping (forage, flee)
   frontier confirms one.
2. **Does PREDATOR PRESSURE move the prey along it?** As the predator gets stronger (no predator ->
   weak -> coevolving -> strong), does the prey champion move DOWN the frontier (forage DOWN, flee UP)?
   Movement along the frontier is the trade-off signature; a Pareto read distinguishes it from the prey
   simply getting globally worse.

## The ecological episode (plants ON + energy; the rung-1 world, both roles alive)

Identical geometry/sensing to 057/058 (9x9 torus, 4-way argmax, 5-float relative-position sensor). One
predator + one prey + plants; the prey on an energy budget (start E0, step cost Em, +Ep per plant,
regrow to constant density). The prey must FORAGE (not starve) AND FLEE (not be caught); it dies if
energy 0 OR captured (Chebyshev<=1). The prey skips 1 move every M steps (speed lever). Episode ends at
T or prey death. Prey co-fitness = SURVIVAL fraction (steps alive / T) -- the gate confirmed this is
APPROPRIATE here: we are measuring where survival pressure LANDS the prey on the forage/flee frontier,
not isolating a pure-pursuit construct. The predator is a graded pressure source, not itself under study
(pairwise, its "ecology" reduces to capture-speed; only the prey side is live -- no symmetric claim).

## Balance (pinned by argument, not outcome)

The predator speed lever M is set so a hand-coded greedy-hunt predator catches a hand-coded forage-and-
flee prey at a per-episode capture probability in [0.4, 0.7] (a real but not overwhelming pressure, so
the prey has a live forage/flee choice), at the rung-1 plant density (plants=8). E0/Em/Ep/T pinned by the
rung-1 argument. No outcome-tuned calibration; the frontier read does not depend on a 50/50 balance.

## Method (a LADDER of predator pressure; the prey read as a 2D point on the 058 instrument)

For each predator-pressure condition, evolve a prey (co-fitness = ecological survival vs that predator),
then FREEZE the champion and measure its (FORAGE-skill, FLEE-skill) on the 058 graded benchmark
(forage-skill = plants eaten, no predator; flee-skill = escape-rate vs the frozen strong predator HoF,
plants OFF). n independent runs per condition; each axis aggregated (median + bootstrap CI).

Conditions (a monotone ladder of predator pressure):
- **P0 — no predator** (pure foraging pressure): the forage-max anchor.
- **WEAK-STATIC** — prey evolves vs a FIXED weak predator (frozen gen-0 net).
- **COEVO** — prey coevolves vs a STRENGTHENING predator population (the moving opponent).
- **STRONG-STATIC** — prey evolves vs a FIXED strong predator (hand-coded greedy-hunt / evolved).

Reads:
- **Frontier existence:** plot the four (forage, flee) points. A FRONTIER exists iff forage-skill falls
  as flee-skill rises across the ladder (a prey cannot be maximal on both). NO frontier iff some
  condition is high on BOTH (the net expresses both cheaply -> no trade-off).
- **Movement driven by pressure:** does forage-skill DECREASE and flee-skill INCREASE monotonically with
  predator pressure? The COEVO-minus-WEAK-STATIC difference on each axis (bootstrap CI) is the key
  contrast: a strengthening opponent should push the prey further down the frontier (lower forage, higher
  flee) than a static weak one.
- **Pareto / degradation control:** movement ALONG a frontier requires the higher-pressure prey to be
  BETTER on flee while WORSE on forage (a trade). If a higher-pressure prey is WORSE on BOTH axes, that
  is global degradation, NOT a frontier -- reported as such (a distinct, also-informative outcome).

## Decision rule (pre-committed; all outcomes reachable)

- **FRONTIER + PRESSURE MOVES ALONG IT** iff forage-skill decreases and flee-skill increases across the
  ladder (both trends resolved), the points are mutually non-dominated (a trade, not degradation), and
  the COEVO-vs-WEAK-STATIC axis differences are resolved (flee up, forage down) and reproduced.
- **FRONTIER BUT PRESSURE DOES NOT MOVE THE PREY** iff a static trade-off exists across conditions but
  COEVO does not differ from WEAK-STATIC (the moving opponent adds nothing over a weak fixed one).
- **NO FRONTIER** iff some condition is high on BOTH axes (forage and flee both near their single-axis
  maxima) -- the net expresses both without a trade-off; the energy economy does not force a choice.
- **GLOBAL DEGRADATION (not a frontier)** iff higher predator pressure lowers BOTH axes -- pressure hurts
  the prey everywhere rather than reallocating it.
- **INVALID** iff a balance with real-but-not-overwhelming predator pressure cannot be found, or either
  benchmark axis cannot be verified un-saturated for ecology-trained champions.

## Kill gates / validity (pre-committed)

- Rung-1 instrument already validated (058). Here: (i) the ecological episode admits a live forage/flee
  choice at the pinned balance (predator pressure real but not overwhelming); (ii) BOTH benchmark axes
  are verified un-saturated for ECOLOGY-TRAINED champions (the gate's dynamic-range gate -- a floored
  flee-skill or ceilinged forage-skill would manufacture a false "no movement").
- Read is the 2D (forage, flee) POINT, never a scalar; the Pareto/degradation branch is explicit.
- COEVO-vs-WEAK-STATIC axis differences via bootstrap CI; reproduce any resolved movement (the 057/058
  lesson: apparent per-condition trends can be low-n noise).
- Only the PREY side is claimed (the predator's ecology is vacuous pairwise; no symmetric claim).

## Hypothesis (with direction)

A frontier most likely EXISTS (a fixed move budget makes forage and flee compete), and predator pressure
most likely moves the prey DOWN it (forage down, flee up). But NO-FRONTIER is fully in play: the net has
5 sensor inputs and could learn to interleave foraging and fleeing cheaply (plants and predator are
sensed on separate channels), expressing both without a real trade-off -- which would be the surprise and
a signed negative about how easily a small net escapes an ecological trade-off.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-24) — REDESIGN accepted (coupling-verdict -> forage/flee frontier)

The gate REFUSED the first draft's coupling-verdict question: (1) training in the ecology and measuring
pure pursuit-evasion plants-OFF conflates coupling with a per-arm, per-generation forage/flee move-budget
reallocation -- a positive "change" would be an ecology artifact, not coupling; (2) the between-condition
CI compared 058 (its M, seed, n) against exp059 (M recalibrated for the ecology) so a "change" is
attributable to M as readily as to plants -- INVALID by confound; (3) the predator's ecology is vacuous
pairwise (only the prey side is live); (4) survival co-fitness rewards avoidance, orthogonal to the
measured fleeing-skill, making no-coupling near-foregone; (5) the question mostly re-confirms 058. The
gate's prescribed reframe -- the forage/flee TRADE-OFF, read as a 2D point on the validated 058 axes,
with a frontier-existence test and a Pareto/degradation control -- is adopted in full: it asks what the
bare game cannot, uses the signed instrument, and its outcome is not predictable from 057/058.

## Result

SIGNED as insight 059 (SIGN-WITH-CHANGES after the CLAIM gate). NOT a frontier result: the 058 REACTIVE-
flee axis is never engaged by the ecological survival fitness -- flee sits at ~0.29 (barely above the
gen-0 random-net floor 0.254, far below a dedicated fleer 0.39-0.69) in EVERY condition including
no-predator, so no forage/reactive-flee trade-off can be OBSERVED (fleeing is not learned, not a declined
trade). Predator PRESENCE lowers realized foraging (24.5 -> 3.4-4.5, resolved; mechanism not identified,
magnitude confounded with EA budget). COEVO-vs-static is an UNDERPOWERED NULL (n=20 single-run,
unresolved) -- consistent with 057/058 but not independently established. The missing instrument is an
encounter-conditional AVOIDANCE metric (rung 2b/3). File retained under its original name; the runner is
`exp059_flatland_forage_flee_frontier_tests.erl`.
