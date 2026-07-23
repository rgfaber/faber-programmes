# EXP-058 — Flatland rung 1 (INSTRUMENT): build the scape, a foraging/fleeing-DECOMPOSED benchmark, and re-baseline the 057 coupling test on it

Pre-registration. FIRST rung of the Flatland front (see `faber-ecosystem/plans/PLAN_FLATLAND.md`).
DESIGN gate PASSED WITH REDESIGN (2026-07-23): the gate split instrument from claim. This rung is the
INSTRUMENT rung -- it makes NO ecology/coupling claim. The energy-economy coupling question is exp059
(rung 2); many-agent open population is rung 3.

- **Programme:** P7 (Coevolution) x P5/P6 convergence — the Flatland/ALife front, rung 1 (instrument)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Builds:** `faber-tweann/src/flatland_sim.erl` (new `scape` behaviour callback) + a forager morphology;
  runner `experiments/exp058_flatland_instrument_tests.erl`
- **Raw feed / insight:** `faber-ecosystem/insights/058-*` (once built + signed)

## What this rung IS (and is NOT)

The 053-056 discipline is "instrument before claim; an instrument dressed as a finding is the recurring
error". This rung builds the Flatland instrument and validates it. It signs ONLY that the instrument
works and behaves as specified. It does NOT ask whether an ecology rescues the arms race -- that claim
(rung 2, exp059) requires this validated instrument first.

## Three signed deliverables (all instrument-level, no dynamics claim)

1. **The scape works (0a).** `flatland_sim` runs episodes end-to-end under the DXNN2 scape protocol
   (sense -> percept, action -> {fitness, halt}); plant regrowth keeps food density constant; energy
   accounting (start E0, step cost Em, eat gain Ep, death at 0) behaves; deterministic given a seed. A
   hand-coded greedy-forager gains energy; a random agent starves. Report both.
2. **Representability (0b, KILL gate).** Evolve a network IN ISOLATION on each capability against a fixed
   world: (i) solo PREY with plants and NO predator evolves competent FORAGING (energy gain >> random,
   approaching the hand-coded greedy-forager); (ii) PREDATOR vs a fixed fleeing prey evolves competent
   HUNTING (capture-rate >> random). If the `[n]` net class cannot express foraging or hunting here, the
   whole front is INVALID at rung 1 (capacity/instrument limit) -- STOP and fix before anything else.
3. **A DECOMPOSED, verified-graded benchmark + a re-baselined 057 (the gate's core requirement).** Build
   a benchmark that reads each capability ORTHOGONALLY so a later coupling verdict cannot be foraging drift
   wearing an arms-race label:
   - **prey FLEEING-skill:** survival vs a frozen graded predator HoF, plants held identical/absent.
   - **prey FORAGING-skill:** energy gain vs plants with NO predator.
   - **predator CAPTURE-skill:** capture vs a frozen graded fleeing-prey HoF.
   Verify each sub-metric is difficulty-GRADED and un-saturated (the 057 machinery: continuous metrics
   where a binary one saturates; a frozen seed-fixed graded HoF including strong evolved opponents).
   **Then RE-BASELINE 057:** re-run the bare-grid (ecology-free) decoupled coupling control using THIS new
   graded, decomposed benchmark. Confirm the 057 "no coupling" refusal REPRODUCES on the new instrument --
   ruling out that 057's refusal was an artifact of binary-capture saturation. If the refusal does NOT
   reproduce (coupling appears on the bare grid with the graded metric), that is itself the finding: 057's
   refusal was instrument-limited, and the whole coupling story is re-opened BEFORE any ecology is added.

## The world (minimal Flatland; identical geometry/sensors to 057, plants+energy added)

Per the gate: hold geometry and sensing IDENTICAL to 057 so the ONLY thing added is the energy economy
(range sensors are deferred to a later rung as a gratuitous confound here). A 9x9 torus (as 057). Avatar
sensing = opponent's shortest wrap-around relative position (as 057) PLUS nearest-plant relative position
and own-energy. Movement = 4-way argmax (as 057). Additions over 057, and ONLY these:
- **Plants:** P food cells; stepping onto one gives +Ep energy and it regrows elsewhere (constant density).
- **Energy:** start E0; each step costs Em; eating gives Ep (prey), catching gives a reward (predator);
  energy 0 = death (episode ends for that avatar). Capture = adjacency (Chebyshev<=1, as 057).
- Pairwise episode (one predator, one prey, plus plants), T steps or death -- kept pairwise so this rung
  isolates the ENERGY ECONOMY, not many-agent structure (rung 3).

## Pre-committed knob discipline (the gate's calibration hazard)

No "calibrate a 50/50 balance" in this rung (there is no coupling claim to place). The scape knobs
(P plants, E0, Em, Ep, capture reward, T) are pinned by ARGUMENT before any run and reported: plant
density set so a competent forager can sustain positive energy but a random one cannot; Em/Ep set so an
episode without eating ends in ~T/3 steps; capture reward set so a predator that never catches also
starves. These are instrument-sanity settings, not outcome-tuned. Rung 2 (exp059) will pre-register a
single balance SCALAR (steady-state per-episode capture probability = 0.5 +/- band at fixed plant density)
and require its coupling verdict stable across a band -- but that belongs to the claim rung, not here.

## Decision rule (instrument-level; all outcomes reachable)

- **INSTRUMENT VALIDATED** iff 0a passes, 0b passes (both roles beat random and approach hand-coded), and
  each decomposed sub-metric is verified graded + un-saturated. Sign the instrument; proceed to exp059.
- **057 REFUSAL ROBUST** iff the re-baselined bare-grid decoupled control again shows no coupling on the
  graded decomposed metric -- 057 stands, and exp059's head-to-head is clean.
- **057 REFUSAL INSTRUMENT-LIMITED** (a real finding) iff coupling appears on the bare grid with the graded
  metric -- re-open the coupling story before adding ecology; do NOT proceed to exp059 as designed.
- **INVALID** iff representability fails or a sub-metric cannot be verified graded (capacity/instrument).

## Kill criterion

If a network cannot forage or hunt (0b fails), or a sub-metric cannot be graded, STOP and fix the
instrument -- no dynamics claim rests on a broken scape. This rung exists precisely to find that first.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — BUILD WITH CHANGES; instrument split from claim

The gate passed the scape build (0a/0b) but REFUSED the original rung-1 arms-race claim as confounded and
partly foregone, and prescribed this redesign:
- **Foraging confound (most dangerous):** reading coupling off composite energy fitness would manufacture
  the positive (a weaker co-adapting predator lets prey forage more -> higher fitness, zero arms-race
  content). FIX: a DECOMPOSED benchmark; coupling read ONLY on the pursuit-evasion sub-metric. (Adopted.)
- **Uncontrolled head-to-head:** sensors + fitness signal + episode length + benchmark all change at once;
  057's refusal might be binary-capture saturation, not a real absence. FIX: hold geometry/sensors
  identical to 057, and RE-BASELINE 057 on the new graded decomposed instrument. (Adopted.)
- **Scope / smallest step:** SPLIT instrument from claim -- make rung 1 the instrument rung (this doc),
  sign it, and move the energy-economy coupling claim to rung 2 (exp059). (Adopted.)
- **Honesty on scope:** rung 1 adds the ENERGY ECONOMY only, NOT reproduction or many-agent population
  (two of the three ingredients the 057 post-mortem named). A later "refusal survives" must be scoped to
  "energy-economy alone", never "ecology cannot rescue". Many-agent open population is rung 3. (Adopted.)
- **De-teleologise:** drop "does ecology RESCUE the arms race" (leading; the 057 refusal may be correct
  for pairwise pursuit-evasion). Rung 2 reframes symmetrically: "does an energy economy CHANGE the
  coupling verdict, in either direction, on which decomposed sub-metric". (Adopted for exp059.)

## Result

<one line once signed>
