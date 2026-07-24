# EXP-062 — Flatland rung 3b (precondition): does any regime PERSIST for many predator generations, and does the open-population EA OPTIMISE at all?

Pre-registration. Rung 3b of the Flatland front. DESIGN gate REDESIGNED a first draft (an evolved-restraint
+ viscosity experiment that was DEAD ON ARRIVAL: 061 collapses in ~39 steps = zero-to-one predator
generations, so "evolution can't rescue coexistence" would be trivially true because no evolution can
occur; plus a self-starving trait, a mutation-artifact within-lineage read, and an ecology/selection
confound). The gate split rung 3b: this rung (062) is the upstream PRECONDITION -- persistence + open-
population learnability -- the unproven foundation the restraint experiment (063) needs.

- **Programme:** P7 x P5 — the Flatland/ALife front, rung 3b precondition
- **Opened:** 2026-07-24
- **Engine pin:** `eaf10819a37781c28caa098779d0f4027487ae77`
- **Builds:** `experiments/exp062_flatland_persistence_tests.erl` (extends the exp061 open-population sim)
- **Raw feed / insight:** `faber-ecosystem/insights/062-*`

## The claim under test (the precondition, in two parts)

061 found fixed-GREEDY predators collapse the open population (median 39 steps). Before ANY evolved-
restraint claim is measurable, two things must hold, neither shown by 061:

**Part A -- PERSISTENCE.** Does any regime with a fixed PRUDENT predator (one that self-limits under local
prey depletion, unlike greedy) sustain predator-prey COEXISTENCE for MANY PREDATOR GENERATIONS (target
tens of generations, measured by an explicit generations-elapsed counter -- NOT step count)? Greedy over-
consumes; a prudent predator MIGHT persist. If NO regime persists even with hand-set prudence, evolution
is untestable on this substrate -> a clean signed negative, and rung 3b STOPS here.

**Part B -- OPEN-POPULATION LEARNABILITY (only if A finds a persistent regime).** On that persistent
regime, give predators one heritable, DIRECTLY-individually-beneficial trait -- metabolic THRIFT m (lower
step energy cost) -- and ask: does m evolve UP over generations? This proves the ENDOGENOUS in-world EA
optimises AT ALL in the OPEN population (something 057-060's pairwise generational EA showed, but the open
population never has). If thrift does NOT evolve, the open-world EA is paralysed and NO evolved-trait claim
(incl. rung 063's restraint) is interpretable.

## The prudent predator (Part A; the costless restraint lever the gate prescribed)

Reuse the 061 sim. Replace greedy-hunt with a fixed PRUDENT predator using a prey-density THRESHOLD: it
hunts the nearest prey only if the LOCAL prey count (prey within its perception radius) is >= theta;
otherwise it wanders (leaving a sparse local patch to recover). theta=1 is ~greedy; higher theta = more
prudent (only hunts dense patches, spares depleted ones). This restraint is COSTLESS in abundance (theta
never triggers) and self-limits exactly under local depletion -- it does NOT self-starve (the flaw of a
satiation lever). Prey keep fixed forage-and-flee. Sweep theta x plant-density x initial-predators.

## Generations-elapsed counter (the gate's required timescale instrument)

Track predator REPRODUCTION events; report generations-elapsed = (cumulative predator births) / (mean
standing predator count), i.e. how many times the predator population has turned over. Persistence is
defined in GENERATIONS, not steps: a regime "persists" iff both roles are alive AND >= G_MIN predator
generations have elapsed (G_MIN target ~20) before any extinction, across measurement seeds.

## Part B measurement (learnability; only on a persistent regime)

Give each predator a heritable scalar m (thrift): step energy cost = base - m*unit, m in [0, M_MAX],
inherited with +-1 mutation. m LOWERS individual death rate -> under individual selection it MUST rise.
Report population-mean m(t) over generations (end-window vs start-window, bootstrap CI over runs) AND the
Price-equation SELECTION term Cov(relative-reproduction, m) (the correct adaptation read, not offspring-
minus-parent which is a symmetric-mutation artifact). Thrift evolving up (both the mean AND a positive
selection covariance) = the open EA optimises -> learnability PASSES.

## Decision rule (pre-committed; all outcomes reachable)

- **PRECONDITION MET** iff (A) some (theta, density) regime persists >= G_MIN predator generations across
  seeds AND (B) on it, thrift m evolves UP (resolved end-vs-start AND positive Price selection covariance),
  reproduced. The substrate then supports eco-evo dynamics -> rung 063 (evolved restraint under viscosity)
  becomes reachable and non-foregone.
- **NO PERSISTENCE (signed negative, STOP)** iff NO (theta, density) regime persists >= G_MIN generations
  even with fixed prudent predators -- this open ALife substrate admits no eco-evolutionary timescale;
  the restraint/viscosity question is unmeasurable here and rung 3b halts (needs a different substrate).
- **PERSISTS BUT NO LEARNABILITY** iff a regime persists but thrift does NOT evolve up -- the open-world EA
  is paralysed (too weak/noisy an endogenous selection signal); evolved-trait claims blocked pending a
  stronger selection mechanism.
- **INVALID** iff the generations counter or Price term cannot be computed (e.g. persistence too marginal
  to estimate).

## Kill gates / validity (pre-committed)

- Persistence measured in GENERATIONS (explicit counter), not steps -- the gate's timescale precondition.
- The prudent lever (theta) is COSTLESS in abundance and does NOT self-starve (unlike satiation) -- so a
  persistence null is about the substrate, not the trait energetically self-destructing.
- Learnability read is the Price SELECTION covariance, not the symmetric-mutation offspring-minus-parent.
- Calibration/measurement seed split; reproduce resolved effects; compared to the fixed-greedy 061 baseline.
- Scoped honestly: a persistence null is "no eco-evo timescale on THIS substrate with THESE behaviours",
  not "open populations cannot evolve".

## Hypothesis (with direction)

Given 061's robust collapse, the honest prior is that even a fixed PRUDENT (theta-threshold) predator may
NOT find a many-generation persistent regime (NO PERSISTENCE, a signed negative) -- prudent hunting spares
prey but may itself starve the predators. But a prudent predator not exhausting its local prey is exactly
the mechanism that COULD persist where greedy cannot, so PERSISTENCE MET (then a learnable EA) is the
non-foregone positive that unlocks rung 063.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-24) — REDESIGN accepted (evolved-restraint -> persistence precondition)

The gate ruled the evolved-restraint+viscosity build DEAD ON ARRIVAL: 061 dies in ~39 steps (zero-to-one
predator generations), so no selection can act and "evolution can't rescue coexistence" is foregone-by-
timescale, not a selection-level result; satiation as the restraint trait self-starves its bearer (the
"individual selection wins" outcome is then an energetic artifact); the offspring-minus-parent within-
lineage read is a symmetric-mutation artifact (needs a multilevel Price decomposition); and viscous-vs-
well-mixed confounds ecological clumping with selection level (needs a fixed-trait viscous control). It
prescribed splitting: THIS rung (062) establishes the PRECONDITION -- does any regime persist for many
predator generations (measured by a generations counter, with a costless non-self-starving prudent lever
theta) and does the open-population EA optimise at all (a directly-beneficial thrift trait + the Price
selection covariance). Only after 062 passes is the restraint/viscosity contrast (rung 063, with theta,
multilevel Price, and a fixed-trait viscous control) non-foregone.

## Result

SIGNED as insight 062 (Part A / precondition; CLAIM gate SIGN-WITH-CHANGES -> strong-corner check +
squeeze framing + region scoping). NO PERSISTENT REGIME: coexistence dies within ~1 predator generation
(max median 1.4, vs GMIN=20) across theta x plant-density, a predator-energetics sweep, AND the 061
strong-stabiliser corner (satiate=12/percept=2) -- all 0.00 persistence. A SQUEEZE: theta=1 (greedy,
non-starving) collapses by over-consumption; theta>1 (decline-to-hunt restraint) accelerates extinction
via starvation -- NO costless restraint lever exists in this family, and that coupling is the finding. So
no eco-evolutionary timescale: selection cannot act (the DESIGN gate's dead-on-arrival fatality confirmed).
Rung 3b (evolved restraint, now deferred as rung 063) is BLOCKED in this region; Part B (learnability) is
moot without a persistent regime. SCOPE: the searched region + decline-to-hunt family + these energetics
(world size / perception / prey reproduction / plant energy held FIXED), NOT open ALife in general. Runner
is `exp062_flatland_persistence_tests.erl`.
