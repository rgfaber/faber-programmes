# EXP-054 — coevolution: arms race or Red Queen? Pursuit-evasion with a trusted instrument

**DEFERRED (2026-07-23): the EMBODIED rung of the P7 ladder, several small steps up.** The
DESIGN gate ruled pursuit-evasion the wrong OPENER: its random benchmark saturates (arms-race
outcome unreachable), equal-speed pursuit is evader-dominated (disengagement is the modal
outcome), and instrument-validity would be confounded with task-pathology. The P7 ladder climbs
gradually (smallest steps first): 053 1D transitive numbers game (Red Queen + instrument vs
observable ground truth), then multi-D transitive, intransitive/cycling, disengagement, THEN
this neural embodied pursuit-evasion with an instrument we trust. **Required fixes to apply
before this runs** (DESIGN gate):
1. Replace the random benchmark with a GRADED frozen hall-of-fame ladder (weak->strong, from a
   throwaway pilot) + hard hand-coded anchors (greedy pursuer, optimal-flee evader), scored with
   a CONTINUOUS metric (mean time-to-capture / survival fraction), not binary catch-rate.
2. Add a COMPETENT-play balance KILL gate: hand-coded greedy pursuer vs hand-coded optimal-flee
   evader must NOT be near-always-escape (else no sustainable two-sided gradient -> retune
   asymmetry: capture radius, pursuer speed edge, multiple pursuers, "stay" action, arena/T).
   The gen-0 random-vs-random probe is insufficient (it measures incompetent play).
3. Put a hall-of-fame INTO the training loop (mix current opponents with sampled HoF) or run
   current-only vs +HoF as a pre-committed ablation, so a Red-Queen result is attributable to
   the game, not to known-pathological current-only training. Raise K to 10-15.
4. Operationalize CIAO/cycling (fraction of i<j pairs where champ_j loses champ_i beyond the
   co-fitness noise band; threshold pre-set) and the DISENGAGEMENT saturation/flat bands numerically.
5. Representability check: confirm the [2,8,4] net class can FIT greedy/flee (behavioural cloning
   or champion-seeding), separate from game-winnability.

Original pursuit-evasion pre-registration follows (to be revised per the fixes above).

---

- **Programme:** P7 (Coevolution / self-play) — the SECOND experiment (opener = EXP-053)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp053_coevolution_arms_race_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/053-raw-coevolution.txt`
- **Insight:** `faber-ecosystem/insights/053-*.md` (once signed)

## The claim under test

P1-P6 optimise against a FIXED task. P7 makes the task itself move: fitness comes from
a co-evolving opponent. The canonical hope (Dawkins & Krebs arms races; Nolfi & Floreano
1998 predator-prey robots) is an ESCALATING ARMS RACE: each side keeps improving because
the other does. The canonical FAILURE modes are equally famous and must be distinguished:
- **Red Queen** (Van Valen): both sides run to stay in place; co-fitness (score against the
  CURRENT opponent) hovers, hiding whether either is really getting better.
- **Disengagement:** one side dominates so completely that the other's gradient vanishes and
  both stop improving (a mediocre stable state).
- **Cycling / intransitivity:** A beats B beats C beats A; apparent progress is a loop.

The core methodological commitment: **co-fitness is NOT progress.** Progress is measured only
against a FIXED, non-coevolving benchmark. Report as a replication of Nolfi & Floreano /
Cliff & Miller (CIAO / master-tournament methodology), not discovery.

## The task — pursuit-evasion on a torus (implemented in the runner, no engine change)

A 13x13 TORUS grid (wrap-around, so no edge/corner-camping artifacts). A pursuer P and an
evader E, each a feedforward net `[2, 8, 4]`. Sensors (both): the opponent's relative position
on the torus, `(dx, dy)` as the shortest signed wrap distance, normalised to [-1, 1] (2 inputs;
translation-invariant, the legitimate task input, not a leak). Actuator: 4 outputs, argmax picks
a move N/E/S/W; both move SIMULTANEOUSLY each step. Episode length T=50. **Capture** = pursuer
within Chebyshev distance 1 of the evader at the end of a step (gives the pursuer a fighting
chance against an equal-speed evader; the balance is validated pre-run). Pursuer wants to
capture early; evader wants to survive T.

- **Pursuer episode fitness** = captured (1) else 0; tie-break by 1/(1+time-to-capture).
- **Evader episode fitness** = survival fraction (steps survived / T); 1.0 if never caught.

## The searches (two coevolving populations)

Two (mu+lambda) populations, mu=lambda=30 each, Gaussian mutation sigma=0.15 (matched to the
051/052 operator). Each generation: every pursuer is evaluated against K=5 evaders sampled from
the current evader population (fitness = mean over the K); symmetrically for evaders; top mu of
each population survive. R=100 generations. This is the coevolution loop.

## Progress measurement (the crux — fixed benchmarks, NOT co-fitness)

Every 5 generations, freeze the champion pursuer and champion evader and score them against
FIXED, non-coevolving benchmark sets, pre-committed and frozen before the run:
- **B_evaders** = 40 fixed random evaders + the generation-0 champion evader. Champion pursuer's
  catch rate against B_evaders = the pursuer PROGRESS curve.
- **B_pursuers** = 40 fixed random pursuers + the generation-0 champion pursuer. Champion evader's
  survival rate against B_pursuers = the evader PROGRESS curve.
Also record **co-fitness** (champion pursuer vs champion evader, same generation) to CONTRAST
with the benchmark curves (the Red Queen check). Secondary: a **master tournament / CIAO** grid
(champion of gen i vs champion of gen j) to detect cycling/intransitivity.

## Hypothesis (with direction)

An ARMS RACE: both benchmark PROGRESS curves rise over generations (later champion pursuers catch
fixed evaders better; later champion evaders survive fixed pursuers better), while co-fitness stays
comparatively flat (the Red Queen signature of hidden mutual progress). Surprises / nulls:
Red Queen with NO real progress (benchmarks flat while co-fitness churns); disengagement (one side
dominates from early and both curves flatten); cycling (CIAO shows a loop, benchmark non-monotone).

## Controls + validity (pre-committed, frozen pre-run)

- **Balance probe (like 052's floor probe):** at generation 0, random pursuers vs random evaders
  must give an INTERMEDIATE catch rate (target 0.2-0.8). If ~0 (evaders trivially escape) or ~1
  (pursuers trivially win), the game has no two-sided gradient -> retune (arena size / T / capture
  radius) BEFORE the main run. Frozen and reported.
- **Capacity check:** a hand-coded greedy pursuer (step toward the evader) catches random evaders
  at a high rate, AND a hand-coded evader (step directly away) survives random pursuers at a high
  rate -> both roles are expressible and winnable (the nets are not being asked the impossible).
- **Benchmark composition frozen** (random + gen-0 champions) before the run; never drawn from the
  coevolving populations (that would reintroduce the Red Queen).
- **n = 20 independent coevolution runs** (different seeds); progress curves aggregated across runs
  (median + bootstrap CI per checkpoint), trend via Spearman(generation, benchmark performance).

## Decision rule (pre-committed, all outcomes reachable)

Over n=20 runs, R=100 generations, benchmark checkpoints every 5 generations:
- **ARMS RACE** iff BOTH benchmark curves show a significant positive trend (per-run Spearman
  gen-vs-perf > 0, median across runs with bootstrap CI excluding 0) AND end > start with disjoint
  CIs, for pursuer AND evader.
- **ASYMMETRIC RACE** iff exactly one side's benchmark trends up (the other flat or down) -> one
  role wins the race; a signed finding about the game's balance.
- **RED QUEEN / NO PROGRESS** iff co-fitness moves (variance across generations) but NEITHER
  benchmark curve trends -> churn without progress; a signed negative and a methodological
  demonstration that co-fitness misleads.
- **DISENGAGEMENT** iff co-fitness saturates near 0 or 1 within the first quarter of the run and
  both benchmark curves are flat -> gradient collapse.
- **CYCLING** iff benchmark curves are non-monotone AND the CIAO/master-tournament grid shows
  intransitivity (a later champion loses to a much earlier one).
- **INVALID** iff the balance probe fails (gen-0 catch rate ~0 or ~1) or the capacity check fails
  -> fix the game before interpreting.

## Fallback interpretation (committed in advance)

If ARMS RACE: P7's premise (interaction drives open-ended improvement) is demonstrated on faber,
and pursuit-evasion becomes the proto-Flatland substrate for later ecological experiments. If
RED QUEEN / DISENGAGEMENT / CYCLING: a signed negative that names WHICH pathology this minimal
game falls into, and what a Flatland-scale world must add to escape it (spatial structure,
resources, many agents) — directly shaping the P5/P6/Flatland roadmap. Every outcome advances P7.

## Kill criterion

If the balance probe or capacity check fails, STOP and retune the game before any coevolution run
(a game with no two-sided gradient cannot test the arms-race hypothesis).

## DESIGN gate verdict

<pending — faber-adversary/Fable>

## Result

<one line once signed>
