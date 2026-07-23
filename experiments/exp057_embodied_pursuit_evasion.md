# EXP-057 — the embodied rung: at the most-balanced competent-play point, does neural pursuit-evasion arms-race, disengage, or cycle?

Pre-registration. DESIGN gate REDESIGNED a first draft (a coarse 4-point speed sweep
that under-samples, never targets the competent-play crossover, has saturated dead
cells at the extremes, a circular pilot-HoF benchmark, an endpoint progress rule with
no cell for the overfitting winner, and the argmax champion 056 proved unreliable).
This is the gate's prescribed redesign: ONE balance done deeply, non-foregone, with the
instruments fixed.

- **Programme:** P7 (Coevolution / self-play) — the first embodied rung
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp057_embodied_pursuit_evasion_tests.erl` (once built; uses network_evaluator)
- **Raw feed:** `faber-ecosystem/insights/057-raw-embodied.txt`
- **Insight:** `faber-ecosystem/insights/057-*.md` (once signed)

## The claim under test

The 053-056 toolkit was validated on numbers games where truth was knowable; this applies it to real
faber-tweann networks coevolving on pursuit-evasion. The workbench exploration (unsigned) showed
disengagement at the SPEED EXTREMES (equal -> evader escapes; fast pursuer -> pursuer dominates) but
never characterised the one place a two-sided gradient could exist: the balance where COMPETENT play
is near 50/50. This rung characterises THAT single balance deeply and asks: is it a (possibly brief)
ARMS RACE, DISENGAGEMENT, or CYCLING? A non-foregone question, because the crossover was never
measured. Report as an embodied replication of Nolfi & Floreano 1998 and its known fragility.

## The game (neural pursuit-evasion, real engine)

9x9 torus. Pursuer P and evader E, each a `[2, 6, 4]` feedforward net (sensors = opponent's shortest
wrap-around relative position; argmax of 4 outputs = N/E/S/W; simultaneous moves). Capture = Chebyshev
<= 1. Episode T=40. The evader skips 1 move every m steps -> pursuer speed factor s. Two coevolving
(mu+lambda) populations, mu=lambda=20, sigma=0.2.

## Step 1 -- CALIBRATE the balance (frozen pre-run; it PLACES the experiment)

Hand-code a greedy pursuer (step to reduce Chebyshev distance) and an optimal-flee evader (step to
increase it). Play greedy-vs-flee across a FINE grid of speed factors s. **s\* = the s where competent
play is nearest 50/50** (catch-rate ~ 0.5). This is the only balance where a two-sided gradient can
exist, and the one the workbench skipped. The whole experiment runs at s\* (a single balance, done
deeply). Report the greedy-vs-flee catch-rate curve and s\*.

## Step 2 -- REPRESENTABILITY + HoF verification (kill gates)

- **Representability:** confirm the `[2,6,4]` net class can FIT the greedy pursuer and the flee evader
  (behavioural clone or champion-seed reaches high catch/survival). If not, INVALID (capacity limit,
  not dynamics) -- STOP.
- **Graded HoF verification:** harvest a hall-of-fame from a throwaway pilot coevolution at s\* PLUS a
  competence-tunable greedy family (greedy with probability p of a random move, p in {0.8..0.0} = weak
  ..strong) and the flee evader. **VERIFY the benchmark is difficulty-GRADED:** each rung's win-rate
  against a fixed probe must be monotone and spread across [0,1]. If the pilot HoF is degenerate
  (one-sided specialists, no spread -> saturation), REJECT it and use the graded greedy/flee family
  alone. A benchmark that cannot be verified graded is INVALID (the 054 saturation demon).

## Step 3 -- Coevolve at s\*, measure with the fixed toolkit (NOT co-fitness)

n coevolution runs at s\*, R generations. Every generation, measure BOTH sides against the frozen,
verified-graded benchmark: pursuer progress = catch-rate vs the benchmark evaders; evader progress =
survival vs the benchmark pursuers.
- **Progress on the FULL TRAJECTORY, not endpoints:** a side's progress = best-so-far (peak) benchmark
  reading minus its start, with a bootstrap CI. This captures the inverted-U (rise then overfit-fall)
  that IS the disengagement signature; endpoint-only would miss it.
- **Master-tournament (056), POPULATION-LEVEL:** save the whole population every K generations; score
  population_i vs population_j (mean win-prob), NOT an argmax champion (the 056 lesson: argmax over
  ~0.5 wanders). Count intransitive triples with a noise band re-derived for this game from the
  start-position/skip-phase variance. Distinguishes DISENGAGEMENT (monotone dominance) from CYCLING.
- **Co-fitness reported, NEVER used to judge progress (053).**

## The three questions (at s\*)

1. Does EITHER side show real progress (peak benchmark > start, disjoint CI)?
2. What is the WINNER's benchmark TRAJECTORY -- monotone rise, or inverted-U (rises then falls as it
   overfits the coevolving opponent and loses to the frozen benchmark)?
3. Is it disengagement (monotone dominance in the population master-tournament) or cycling
   (intransitive triples above the noise band)?

## Hypothesis (with direction)

At the balanced s\*, the most likely outcome is still DISENGAGEMENT (one side's benchmark progress rises
then plateaus/overfits, the other stalls) rather than a sustained two-sided arms race -- but because
s\* is the competent crossover, a brief two-sided race BEFORE one side breaks away is genuinely
possible, and that is the open, non-foregone content. Cycling is a third live outcome the population
master-tournament will catch.

## Controls + validity (pre-committed)

- Calibration (greedy-vs-flee) PLACES the run at s\* -- not a fixed a-priori grid.
- Representability + HoF-graded verification are KILL gates (above).
- Progress scored on the full trajectory (peak vs start); an explicit outcome cell exists for a
  coevolution winner whose FROZEN benchmark stalls or FALLS (overfitting to the live opponent).
- Population-level master-tournament with a game-specific noise band.
- **n set from the pilot's variance for disjoint-CI power** (local compute is free; power is not an
  afterthought). Report the power calc.

## Decision rule (pre-committed, all outcomes reachable) -- at s\* only

- **DISENGAGEMENT** iff exactly ONE side shows peak-progress (disjoint CI) and the population
  master-tournament shows monotone dominance (triples ~ 0) -> the favoured side improves, the other's
  gradient dies, even at the balanced crossover.
- **BRIEF ARMS RACE** iff BOTH sides show peak-progress (both peak-benchmarks rise, disjoint) before a
  breakaway -> a two-sided gradient existed at s\*, the non-foregone positive.
- **CYCLING** iff the population master-tournament shows intransitive triples above the noise band.
- **OVERFIT-WINNER** iff one side dominates head-to-head yet its FROZEN benchmark stalls/falls (an
  explicit cell): a coevolution winner that is not absolutely better -- itself a signed result about
  frozen-benchmark measurement in embodiment.
- **STASIS** iff neither side progresses and no cycling.
- **INVALID** iff representability fails or the benchmark cannot be verified graded.

## Fallback interpretation (committed in advance)

Whatever s\* shows is the first embodied P7 result, measured with validated instruments and read at the
one balance where a race could exist. If DISENGAGEMENT even at the crossover: neural pursuit-evasion
does not sustain an arms race, and Flatland-scale escape needs added structure (space, resources, many
agents) -- shaping P5/P6. If a BRIEF ARMS RACE: a two-sided gradient exists at s\*, the substrate for
denser sampling around s\* and the ecological rungs. Only THEN widen to a sweep around s\*.

## Kill criterion

If representability fails (the net class cannot express competent pursuit/evasion) or the benchmark
cannot be verified difficulty-graded, STOP and fix before interpreting.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN accepted (sweep -> one balance, deep)

The 4-point sweep was under-sampling dressed as a result: it never targeted the competent-play
crossover (the only place a two-sided race can live), its extremes were saturated dead cells, and
"disengagement dominates" merely restated the unsigned workbench. Three instrument defects: the
pilot-HoF benchmark was circular (a disengaged pilot -> degenerate one-sided benchmark -> the 054
saturation demon), the endpoint progress rule had no cell for the overfitting winner (whose frozen
benchmark falls), and it reverted to the argmax champion 056 proved unreliable. Redesign adopted:
calibrate s\* (competent crossover) and run there deeply; verify the HoF is difficulty-graded (reject
if degenerate; a tunable greedy family as fallback); score progress on the full trajectory (peak vs
start) with an explicit overfit-winner cell; population-level master-tournament with a game-specific
noise band; n powered from pilot variance. Widen to a sweep only after s\* is characterised.

## Kill-gate results (2026-07-23) — both PASS; coevolution step is next

- **Calibration (greedy pursuer vs optimal-flee evader, 72 starts, fine speed grid):** the transition
  from evader-wins to pursuer-wins is a KNIFE-EDGE just above equal speed, exactly as the gate warned.
  At s=1.0 catch-rate 0.000 (evader escapes always); it rises through 0.389 (s~1.07) and 0.667 (s~1.09)
  to 0.94+ (s>=1.14). **s\* ~ 1.08 (m=13/14)** is the competent-play crossover (catch-rate ~0.5). The
  whole two-sided window lives in s in [1.05, 1.10]. This is the balance the coevolution runs at.
- **Representability (evolve a [2,6,4] net per role vs the hand-coded opponent at s\*):** PASS. The
  evolved net PURSUER reaches catch-rate 0.857 (> greedy's 0.667); the net EVADER reaches survival
  0.286 (~86% of optimal-flee's 0.333). The net class expresses competent pursuit AND evasion, so any
  disengagement is a DYNAMICS result, not a capacity limit. INVALID branch closed.

Next: harvest + VERIFY a difficulty-graded HoF at s\*, then coevolve at s\* with population-level
master-tournament and full-trajectory (peak-vs-start) progress, n powered from pilot variance.

## Coevolution exploratory run (2026-07-23) — NOT signed; benchmark-saturation confound confirmed

Built the coevolution at s\* + a graded tunable-greedy/flee benchmark and ran n=20 (each run ~2.6s,
so power is not the constraint). Findings, exploratory:
- **The EVADER clearly OVERFITS** (robust): its frozen-benchmark competence rises to a peak (~0.77)
  then CRASHES back to its start (~0.22). It wins head-to-head against the coevolving pursuers but
  loses GENERAL competence -- the overfit-winner signature. No sustained evader progress.
- **The PURSUER benchmark SATURATES** (start ~0.86, near the ceiling) because s\*=1.083 is slightly
  pursuer-favoured (greedy catches 0.667 there); so pursuer peak-progress/overfit are tiny and noisy,
  and the classification flips between OVERFIT/DISENGAGEMENT and DISENGAGEMENT-toward-pursuer run to
  run. This is exactly the DESIGN gate's benchmark-grading (054 saturation) concern MATERIALISING: at
  the knife-edge crossover, one side's benchmark saturates, confounding a clean two-sided verdict.
- **Not signable as-is.** A clean signed result needs the benchmark grading FIXED so neither side
  saturates: harder benchmark opponents (harvest evolved evaders from an evader-dominated pilot at
  equal speed + evolved pursuers from a pursuer-dominated pilot) OR measure at the exact crossover
  where neither dominates. The overfit-winner dynamic is real and robust; the confound blocks the
  two-sided claim. NEXT UNIT: fix the benchmark grading, re-run, then sign.

## Benchmark-grading FIX (2026-07-23) — the four moves that de-confounded it

1. **Continuous metric where binary saturates (pursuer).** Binary catch-rate pins at ~1.0 at s* (the
   054 demon). Replaced with CAPTURE-SPEED (pscore = 1 - capture_step/T): a strong pursuer catches
   FAST even where it always catches. Pursuer benchmark now grades 0.288..0.867 (agg 0.632, off ceiling).
2. **The right axis per role (asymmetric).** At the catch-rate crossover capture happens LATE, so
   survival-TIME saturates for the evader (a random evader survives ~0.85 of the episode). The evader's
   skill lives in WHETHER it escapes -> measure ESCAPE-RATE (fraction not caught) vs STRONG pursuers
   only. Evader benchmark grades 0.083..0.333 (agg 0.222, off floor/ceiling, low ceiling = headroom).
3. **Frozen graded HoF.** Seed-fixed (identical across all runs): the graded tunable greedy/flee family
   PLUS 2 strong evolved-net pursuers + 2 strong evolved-net evaders harvested once. A fixed ruler.
4. **SUSTAINED = end-vs-start** (not peak-vs-start): a transient peak that collapses back to start is
   NOT sustained progress. Rise (peak-start) + gave-back (peak-end) + NET (end-start), bootstrap CIs.

## CLAIM gate verdict (faber-adversary / Fable, 2026-07-23) — REFUTE-as-worded; four fixes applied

The gate confirmed the metric fixes SURVIVE (the asymmetric axes do not bias direction: the evader's
escape-rate registered a real rise AND give-back, so its net~0 is a true trajectory, not truncation;
frozen HoF is a fixed ruler, not circular). But it REFUTED the headline for four reasons, all now fixed:
- **Master-tournament was pre-registered but never scored** (`run_metrics` discarded the saved pops).
  Cycling is a live outcome and an evader ending exactly at its start is also cycling's signature. FIX:
  implemented the cross-generation dominance tournament (intransitive-triple count + later-vs-earlier
  dominance, noise band 0.15), scored every run. Disengagement is only licensed if triples ~0.
- **Both sides' peak-progress is disjoint from 0** = the pre-registered BRIEF-ARMS-RACE cell; the
  NET-sustained criterion is POST-HOC (added after the n=20 look). FIX: reworded to "brief two-sided
  rise then breakaway"; NET-sustained + its 0.03 threshold declared post-hoc in the feed.
- **s\* was misplaced.** Calibration catch-rate is a coarse step function; the nearest point to 0.5 is
  0.389 (m=14..20, evader-favoured), NOT the hardcoded m=13's 0.667 (pursuer-favoured). The true 50/50
  is a plateau bracketed by m=14 and m=13. FIX: run BOTH brackets; if the direction FLIPS with the
  bracket it is calibration-placed (drop "toward pursuer", keep the no-sustained-race half).
- **"even at the 50/50 balance" is false** (it is 0.667 at m=13). FIX: reworded to "near-crossover".

Final study: n=40 per bracket, R=30, at m=14 (evader-favoured) AND m=13 (pursuer-favoured), each with
the master-tournament. Signable claim depends on (a) triples ~0 at both (disengagement not cycling) and
(b) whether the breakaway direction is consistent (dynamics) or flips (calibration-placed).

## Result

SIGNED as insight 057 (n=40/bracket, R=30, both brackets m=14 and m=13). Real neural pursuit-evasion
coevolves MONOTONICALLY with NO cycling (master-tournament intransitive-triples=0 at bands 0.05-0.15,
25-38/45 edges decisive, later-dominates-earlier 25-29 vs 0-1, both brackets). On the verified-graded
frozen benchmark the PURSUER sustains net progress at both brackets (+0.151, +0.189, disjoint from 0);
the EVADER is MARGINAL (+0.153 disjoint at m=14, +0.042 CI-includes-0 at m=13, and the between-bracket
difference 0.111 CI[-0.000,0.194] is NOT resolved). Clear non-cyclic two-sided PROGRESS, but a sustained
two-sided arms race is NOT cleanly established. Two CLAIM-gate passes deflated the headline from "arms
race / fragile / replicates N&F" (all overreach) to this. Then the DECOUPLED CONTROL was run with TWO
static baselines (frozen RANDOM + frozen STRONG-narrow) at n=40/60/80: coevolution does NOT reliably beat
a DIVERSE random static opponent (a n=60 pursuer hint did not reproduce at n=80); it DOES beat a NARROW
strong one (pursuer, reproduced) but that is curriculum-DIVERSITY (avoiding overfitting to a narrow
target), which the random baseline shares -- NOT reciprocal coupling. So "arms race" / coevolutionary
coupling REFUSED over a diverse opponent. Reproduction caught the n=60 single-run "coupling" as a fluke.
FOUR-BRACKET n=60 span (m=18/14/13/12, both catch-rate plateaus; m=18 deep evader-favoured, benchmark
verified un-saturated): no cycling at any of the four brackets. The evader balance-contingency is
REFUTED as unresolvable at this scale -- evader NET is roughly FLAT and weakly positive (~0.06-0.10)
across all four; widest extreme pair m=18-vs-m=12 = +0.028 CI[-0.042,0.111] includes 0. Both the earlier
evader "step" (m=14 +0.153 was high-side noise; n=60 gives +0.097) and the pursuer speed-edge trend did
NOT reproduce. Robust core: no cycling, pursuer sustains more than evader (~0.15-0.23 vs ~0.06-0.10),
both across the crossover, no arms race. Caveat: evader benchmark saturates high at deep evader-favoured
speeds, capping measurable evader NET. Next: richer world (Flatland, P5/P6) for a real two-sided gradient.
