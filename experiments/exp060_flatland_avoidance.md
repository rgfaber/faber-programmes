# EXP-060 — Flatland rung 2b: interventional probe — does the pressured prey AVOID (step away / abandon near-predator plants), or is the 059 collapse DEGRADATION?

Pre-registration. Rung 2b of the Flatland front. DESIGN gate REDESIGNED a first draft (an observational
NEAR/FAR conditional-foraging read that conditions on a COLLIDER -- NEAR is a consequence of the prey's
own policy, so an avoider's rare NEAR steps are capture-imminent panic steps with no eating, manufacturing
a false "suppression"). This is the gate's prescribed INTERVENTIONAL redesign.

- **Programme:** P7 x P5/P6 — the Flatland/ALife front, rung 2b (mechanism of the 059 foraging collapse)
- **Opened:** 2026-07-24
- **Engine pin:** `eaf10819a37781c28caa098779d0f4027487ae77`
- **Builds:** `experiments/exp060_flatland_avoidance_tests.erl` (reuses `flatland_sim` + the exp059 prey)
- **Raw feed / insight:** `faber-ecosystem/insights/060-*`

## The claim under test

059: predator PRESENCE lowers realized foraging (24.5 -> 3.4-4.5) while REACTIVE fleeing is never learned.
Mechanism unidentified. **Does the pressured prey AVOID the predator (positional distance-keeping /
abandoning plants near the predator), or is the collapse DEGRADATION (no adaptive anti-predator behaviour)?**
Symmetric; either answer is signed. (059 showed no reactive-flee, so any avoidance is expected to be
POSITIONAL, not a startle reflex -- the readout measures sustained distance-conditioned choice, not a jump.)

## The interventional probe (distance is ASSIGNED, not policy-selected -> no collider)

Freeze each champion prey. Build controlled single-step configurations and read the prey's ONE chosen move
from its policy net (no episode, no starvation, no capture selection -> none of the collider/opportunity
confounds of an observational read):
- Prey at position P; predator at Chebyshev distance d in a cardinal direction e (d in 1..8, e in N/E/S/W);
  ONE plant at a FIXED reachable offset (1 step) from P.
- **Two geometries (opportunity held fixed, conflict controlled):**
  - **CONFLICT:** plant 1 step TOWARD the predator (foraging and avoiding OPPOSE -- the prey must choose).
  - **ALIGNED:** plant 1 step AWAY from the predator (foraging and avoiding agree -- a control; every prey
    should forage here regardless of d).
- Sweep over many P and all e; energy set mid (E0) so the energy channel is neutral.

**Two readouts per prey, as functions of d:**
1. **avoid(d)** = P(the prey's move INCREASES predator distance). Pure positional avoidance, never routed
   through eating -> no opportunity/starvation confound. AVOIDANCE = avoid(d) HIGH at small d, tapering as
   d grows; a predator-ignoring prey sits near chance.
2. **forage_conflict(d)** = P(the prey's move goes TOWARD the plant | CONFLICT geometry). AVOIDANCE =
   forage_conflict FALLS at small d (the prey abandons plants near the predator); DEGRADATION / naive
   foraging = forage_conflict stays HIGH regardless of d (goes for the plant even next to the predator).
   forage_aligned(d) is the control: high and flat for every prey.

## The three champions (isolating avoidance from sensor-channel exposure -- the gate's required control)

- **NAIVE** = 059 P0-trained prey (NO predator in training): forages maximally, no predator response. The
  degradation anchor.
- **PROXIMITY-CONTROL** = prey trained WITH the greedy-hunt predator PRESENT (so it sees the predator
  sensor channel) but with CAPTURE DISABLED in training (being caught neither ends the episode nor reduces
  fitness = plants eaten). It has predator-sensor exposure but NO avoidance incentive.
- **PRESSURED** = 059 STRONG-static-trained prey (greedy-hunt, capture enabled): the test.

Attribution: PRESSURED - PROXIMITY isolates AVOIDANCE from mere predator-sensor exposure; PROXIMITY - NAIVE
measures the sensor-channel confound that an observational read would misattribute to avoidance.

## Decision rule (pre-committed; symmetric, mediation not a bare binary)

- **AVOIDANCE** iff the PRESSURED prey shows, vs BOTH controls, a RESOLVED distance dependence: avoid(d)
  rising as d->1 AND/OR forage_conflict(d) falling as d->1 (at least one, with the PRESSURED-minus-
  PROXIMITY contrast resolved so it is not sensor-channel exposure), reproduced. Report the MAGNITUDE
  (avoid(1) vs avoid(8); forage_conflict(1) vs forage_conflict(8)) as "how much of the collapse is
  distance-conditioned suppression", not just existence.
- **DEGRADATION** iff the PRESSURED prey shows NO resolved distance dependence beyond the proximity-control
  (moves the same regardless of predator distance) -- the 059 collapse is non-adaptive disruption.
- **MIXED / SENSOR-ONLY** iff PROXIMITY already shows the dependence (predator-sensor exposure alone changes
  movement) and PRESSURED does not exceed it -- report as sensor-channel, not avoidance.
- **INVALID** iff forage_aligned is not high-and-flat for the naive prey (the probe geometry is broken).

## Kill gates / validity (pre-committed)

- Distance is ASSIGNED (no collider); opportunity is held fixed (one plant, fixed offset); the readouts are
  single-step policy choices (no starvation/capture selection).
- forage_aligned(d) high-and-flat for NAIVE is the probe sanity gate.
- avoid uses predator distance only (independent of the plant); forage_conflict uses the plant (with the
  predator held at assigned d) -- the two readouts do not share a confound.
- n champions per type; each curve aggregated (median + bootstrap CI at each d); reproduce resolved effects.
- 059 EA-underpower caveat carried: a null must be read as "avoidance not learned at this EA budget", not
  "avoidance impossible".

## Hypothesis (with direction)

Given 059 (foraging collapses, reactive-flee never learned), the likely mechanism is POSITIONAL AVOIDANCE:
the PRESSURED prey should show forage_conflict(d) falling at small d (abandons plants near the predator)
and/or avoid(d) rising at small d, exceeding the proximity-control. DEGRADATION (no resolved distance
dependence) is a live null given the prey's under-convergence.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-24) — REDESIGN accepted (observational -> interventional)

The gate refused the observational NEAR/FAR conditional-foraging read: NEAR is a COLLIDER (a consequence of
the prey's policy), so an avoider's rare NEAR steps are capture-imminent panic steps -> false "suppression"
-> foregone AVOIDANCE confirmation under a null. Min-distance and survival share the collider (survival is
also downstream of foraging, since 059 death includes starvation). P0 alone cannot isolate avoidance from
predator-sensor exposure. Prescribed redesign adopted in full: an INTERVENTIONAL distance sweep with
opportunity held fixed (P(forage|d) and a plant-independent avoid(d)), a PROXIMITY-CONTROL to isolate
avoidance from sensor exposure, and a MEDIATION read (how much of the collapse) rather than an existence
binary.

## Result

SIGNED as insight 060 (CLAIM gate DO-NOT-SIGN-as-is -> reproduce + descope; RE-GATED after corrections ->
SIGN-WITH-CHANGES, title de-linked from the collapse). EARNED: the PRESSURED prey steps away from a near
(d=2) predator above chance (avoid_near 0.500 vs the analytic chance 0.250 for both the naive forager and
the capture-disabled proximity-control; PRESSURED-minus-PROXIMITY +0.250, RESOLVED and REPRODUCED across
two runs; raw per-champion values a genuine upward shift) -- a real anti-predator behaviour requiring the
CAPTURE gradient (the proximity-control with the same sensor exposure stays at chance), NOT whole-episode
fleeing (reconciles with 059). NOT earned: any link from this repulsion to the 059 foraging collapse
(measured separately, no mediation; in-episode forage read invalid since the forage sanity gate TRIPPED) --
whether the repulsion drives the collapse is UNTESTED. Runner is `exp060_flatland_avoidance_tests.erl`.
