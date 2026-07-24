# EXP-061 — Flatland rung 3a (INSTRUMENT): does the open many-agent population sustain predator-prey COEXISTENCE and produce population CYCLES (Lotka-Volterra)?

Pre-registration. Rung 3a of the Flatland front. DESIGN gate REDESIGNED a first draft (an open-population
ARMS-RACE question whose favoured null was foregone -- from four rungs of optimizer under-convergence --
AND uninterpretable -- mean benchmark competence over live samples confounds adaptation with demography).
This is the gate's prescribed split: build the coexistence/cycling INSTRUMENT first; the arms-race claim
is deferred to rung 3b (exp062) with the controls it requires.

- **Programme:** P7 x P5 (many-agent substrate) — the Flatland/ALife front, rung 3a (dynamics instrument)
- **Opened:** 2026-07-24
- **Engine pin:** `eaf10819a37781c28caa098779d0f4027487ae77`
- **Builds:** `experiments/exp061_flatland_open_population_tests.erl` (reuses `flatland_sim`)
- **Raw feed / insight:** `faber-ecosystem/insights/061-*`

## The claim under test (the smallest non-foregone open-population question)

Rungs 057-060 used PAIRWISE contests + a generational EA and found no arms race; the arms-race question in
the many-agent setting is BOTH foregone (the optimizer under-converges everywhere) and uninterpretable
without controls. So rung 3a does NOT ask it. It builds and validates the open-population INSTRUMENT the
arms-race rung requires, by asking the one thing that setting can answer cleanly:

**Does the open many-agent population -- prey and predators living and REPRODUCING in one shared world --
sustain predator-prey COEXISTENCE over a long horizon, and does it produce population CYCLES with the
Lotka-Volterra signature (predator abundance lagging prey abundance)?**

Coexistence is NOT guaranteed (predator-prey systems tend to extinction or blow-up) and is itself a signed
ALife result. NO net evolution / benchmark competence is measured here (that is rung 3b) -- only the
population dynamics of competent FIXED-behaviour agents, isolating the ECOLOGY from evolution.

## The world (open many-agent Flatland; fixed competent behaviours)

A toroidal WxW world holding, at all times, a population of PREY and a population of PREDATOR avatars plus
regrowing plants. To isolate ecological dynamics from evolution, agents use FIXED hand-coded competent
behaviours (no nets, no mutation in 3a): PREY = forage-and-flee (move toward the nearest plant when no
predator is within a danger radius, else move away from the nearest predator); PREDATOR = greedy-hunt
(move toward the nearest prey). Per step, every agent senses, moves, pays an energy step-cost:
- **Prey energy:** start E0, -Em/step, +Ep on stepping onto a plant (which regrows elsewhere).
- **Predator energy:** start E0p, -Emp/step, +Epred on catching an adjacent prey (Chebyshev<=1; the prey dies).
- **Reproduction (endogenous):** an agent with energy >= repro-threshold spawns one offspring (a CLONE --
  behaviours are fixed in 3a), splitting its energy with the child.
- **Death:** energy <= 0 -> removed.
- **Population cap (the cull rule, SPECIFIED):** if a role's count exceeds Nmax, remove the LOWEST-energy
  agents of that role down to Nmax. This is a named selection operator (starvation-order culling), applied
  per role; its selective effect (favours high-energy agents) is acknowledged, not hidden.
Run horizon H (thousands of steps), well past several population turnovers.

## Measurement (population dynamics ONLY; no benchmark, no evolution)

Track prey-count(t) and predator-count(t) over the horizon. Report:
1. **COEXISTENCE:** both counts > 0 at H (neither role extinct), and both stay within (0, cap] for the
   whole horizon -- measured as coexistence PROBABILITY across independent measurement seeds.
2. **CYCLES (Lotka-Volterra signature):** the cross-correlation of prey-count and predator-count peaks at
   a POSITIVE lag (predator abundance lags prey abundance -- the LV phase relationship), with a non-trivial
   oscillation amplitude. Report the peak-lag, its sign, and the amplitude, vs a non-cycling null (flat /
   damped-to-equilibrium).

## Controls + validity (the gate's required guards)

- **CALIBRATION vs MEASUREMENT SEED SPLIT:** all viability knobs (W, plant density, E0/E0p, Em/Emp, Ep/Epred,
  repro-threshold, Nmax) are fixed on a PRE-REGISTERED coexistence criterion using CALIBRATION seeds, then
  the reported dynamics use DISJOINT measurement seeds. No knob is tuned on the seeds that are reported.
- **VIABLE-REGION VOLUME, not a point:** report coexistence probability across measurement seeds AND the
  WIDTH of the viable knob band (vary the key knob, e.g. plant density, and report the range that coexists).
  A single-seed knife-edge is NOT "a coexistence regime" -> reported as INVALID / no-stable-regime.
- **The cull rule is a specified selection operator** (starvation-order), acknowledged.
- **No net/benchmark/lineage machinery** (deferred to 3b) -- this rung is deliberately cheap and dynamics-only.

## Decision rule (pre-committed; all outcomes reachable)

- **COEXISTENCE + LV CYCLES** iff coexistence probability is high across measurement seeds over a non-trivial
  knob band AND the prey/predator cross-correlation peaks at a positive lag with non-trivial amplitude.
  The open-population instrument is validated and shows the canonical ecological dynamics -> rung 3b can
  ask the arms-race question on it.
- **COEXISTENCE, NO CYCLES (equilibrium)** iff both persist but populations settle to a steady state with
  no LV oscillation -- coexistence without cycles (still a viable instrument, a distinct dynamics result).
- **NO STABLE COEXISTENCE** iff extinction or blow-up dominates across seeds / the viable band is a
  knife-edge -- the open-population world has no robust coexistence regime with these behaviours; report
  as the signed negative and retune or reconsider before 3b.
- **INVALID** iff the dynamics are not reproducible across measurement seeds (chaotic single-seed artifact).

## Kill criterion

If no coexistence regime survives the calibration/measurement seed split over a non-trivial knob band,
STOP and report "no robust coexistence" -- do NOT proceed to the arms-race rung 3b on an unstable world.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-24) — REDESIGN accepted (arms-race -> coexistence instrument)

The gate refused the open-population arms-race question: (1) the favoured null (barrier survives) is
foregone from four rungs of optimizer under-convergence -- endogenous reproduction is a weaker, higher-
variance selection signal than the generational EA that already could not climb the flee axis, so a
two-sided-progress null would just re-confirm "this optimizer cannot learn", not "no arms race"; (2) mean
058 competence over sampled live agents confounds adaptation with DEMOGRAPHY (a famine culling non-
foragers raises the mean with no evolution) -- fatal on BOTH branches; (3) matched-compute vs pairwise is
apples-to-oranges and only supports the non-favoured "open wins" branch. Prescribed split adopted: rung 3a
is the coexistence/cycling INSTRUMENT (this doc) with a calibration/measurement seed split, viable-region
VOLUME not a point, and a specified cull rule; rung 3b (exp062) defers the arms-race claim and must add a
single-axis endogenous-LEARNABILITY positive control (can the open mechanism move the foraging axis?) and
a NEWBORN-vs-PARENT within-lineage read (adaptation, not demography). Build the instrument first.

## Result

SIGNED as insight 061 (CLAIM gate SIGN-WITH-CHANGES -> strong-corner probe + time-to-extinction + scoping).
NO COEXISTENCE: with FIXED-GREEDY behaviours the open population boom-busts to mutual extinction (median
time-to-first-extinction 39 steps, << the 300-step burn-in) across the density x initial-predator grid at
DEFAULT stabilisers (satiate=3/percept=6, 0/72 coexist) AND at the STRONG-stabiliser corner LV theory
prefers (satiate=12/percept=2 = large refuge, 0/72). Greedy-hunt cannot self-limit predation. SCOPE: a
negative about fixed-greedy behaviours in THIS game -- NOT that open populations cannot coexist in general,
NOR that evolved behaviours cannot coexist here. 3a REFRAMES rung 3b: not "does the open population
arms-race" but "can EVOLVED behaviours discover self-limiting predation and coexist where fixed-greedy
collapses?" Runner is `exp061_flatland_open_population_tests.erl`.
