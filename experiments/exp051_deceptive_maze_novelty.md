# EXP-051 — the deception test: does novelty search (and MAP-Elites) solve a DECEPTIVE maze where objective search stalls?

Pre-registration. Written BEFORE the runner. DESIGN gate runs against this first.
Second Programme 4 experiment (the one 050 said P4 needs: a task with a quality GRADIENT).

- **Programme:** P4 (Objectives / selection pressure)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp051_deceptive_maze_novelty_tests.erl`
- **Raw feed:** `faber-ecosystem/insights/051-raw-deceptive-maze.txt`
- **Insight:** `faber-ecosystem/insights/051-*.md` (once signed)

## The claim under test

The QD/novelty thesis (Lehman & Stanley 2011, "Abandoning objectives"): when the objective
landscape is DECEPTIVE (its gradient leads AWAY from the solution), rewarding behavioural
NOVELTY (ignore the objective, seek new behaviours) solves the task where objective-driven
search stalls in the deceptive local optimum. Insight 050 established the QD machinery but on an
un-deceptive, too-easy pole (everything hit the cap); 050's own conclusion: the interesting QD
claims need a task with a quality GRADIENT. DPNV was the candidate deceptive task but insight 028
localised its wall to optimizer+representation, NOT deception. So this builds a task that is
GENUINELY deceptive and tests the deception hypothesis directly. Report as replication of
Lehman & Stanley, not discovery.

## The task (a deceptive grid maze -- implemented in the runner, no engine change)

A small deterministic 2D grid maze (~11x11). Start S, goal G. The wall layout is DECEPTIVE: the
Euclidean-nearest approach to G leads into a CUL-DE-SAC; the solution path must first move AWAY
from G (increasing distance) to round a barrier. Agent = a feedforward net. Sensors: 4 local
wall bits (open/blocked N/E/S/W) + 2 goal-direction bits (sign of dx, dy to G) = 6 inputs.
Actuator: 4 outputs (N/E/S/W); argmax picks the move; blocked moves are no-ops. Fixed budget T
steps (e.g. 60). The maze and start are deterministic (no noise); a genome maps to one final
cell. `[6, H, 4]` net.

- **Objective fitness** = closeness to G = 1/(1 + manhattan(final cell, G)) (higher = nearer).
- **Behavioural descriptor** = the final cell (x, y) -- the standard novelty behaviour.
- **Solved** = the agent's path reaches G within T steps.

## The searches (equal operator + budget)

All use the SAME Gaussian mutation (sigma=0.1) and the SAME eval budget E, per 050's
operator-fair lesson:
- **objective** = (1+lambda) hill-climb (and multi-restart) maximising closeness-to-G. Predicted
  to STALL in the cul-de-sac (the deceptive local optimum).
- **novelty** = (1+lambda) but fitness = novelty (mean distance of the genome's final cell to
  the k nearest final cells in a novelty archive of past behaviours). Ignores the objective.
- **MAP-Elites** = illuminate the final-cell grid; does the G cell get filled?
- **random search** at budget E (the 050 control) and **sep-CMA-ES on the objective** (strong-
  optimizer ceiling) -- both as comparators.

## Hypothesis (with direction)

Novelty search and MAP-Elites REACH G (solve the maze) on most runs; objective hill-climb and
multi-restart do NOT (they stall in the cul-de-sac, plateauing at high closeness but never
rounding the barrier). Surprise / null: objective search also solves it (the maze is not
actually deceptive) OR novelty also fails (the maze is unsolvable within T / the sensors are
insufficient).

## Controls + validity (pre-committed)

- **Deceptiveness is a PRE-RUN CHECK, frozen before the main run:** confirm that pure objective
  hill-climb (n>=10 restarts) does NOT reach G but plateaus in the cul-de-sac. If objective search
  solves it, the maze is NOT deceptive -> redesign the maze before the deception claim (this is
  the whole validity of the experiment).
- **Solvability check:** confirm a hand-coded or novelty path CAN reach G within T (else the task
  is impossible, not deceptive).
- **n >= 10 independent runs** per search (different rand seeds); report solve RATE with a Wilson CI.
- Same operator (Gaussian sigma=0.1), same budget E, across objective / novelty / MAP-Elites /
  random. sep-CMA-ES labelled as a ceiling.

## Decision rule (pre-committed, both outcomes reachable)

Over n>=10 runs/search:
- **DECEPTION CONFIRMED (novelty wins)** iff novelty's solve-rate exceeds objective hill-climb's
  by a margin whose 95% Wilson CIs do not overlap, AND objective's pre-run stall is confirmed
  (it plateaus in the cul-de-sac). MAP-Elites filling the G cell corroborates.
- **NO DECEPTION** iff objective search solves at the same rate as novelty (the maze's gradient
  is not misleading) -> the task failed to be deceptive; report and redesign (do not sign a
  deception claim).
- **INVALID** iff neither novelty nor MAP-Elites reaches G (task unsolvable within T / sensors
  insufficient) -> fix the task, do not interpret.

## Fallback interpretation (committed in advance)

If novelty solves and objective stalls: the canonical deception result replicates on faber, and
P4's reason-for-being (deception is a real failure mode a different selection pressure fixes) is
demonstrated -- the thing DPNV could not show. If objective ALSO solves: the maze is not
deceptive enough; a genuine negative about maze design, and a reminder that constructing
deception is itself non-trivial (cf 050's descriptor iteration).

## Kill criterion

If the pre-run deceptiveness check fails (objective search reaches G), STOP and redesign the maze
before any main run -- a non-deceptive maze cannot test the hypothesis.

## DESIGN gate verdict (faber-adversary/Fable, 2026-07-23) — REDESIGN (accepted)

Confounded as drafted; recreated the 050 artifacts. Four fixes:
1. **Sensor leak.** Goal-direction sign bits = a per-cell gradient POINTER -> reactive
   toward-goal+avoid-walls rounds the barrier -> deceptive in FITNESS space, trivial in POLICY
   space -> objective wouldn't stall for a deception reason. Removing goal bits -> memoryless
   net hits PERCEPTUAL ALIASING (same local pattern needs different actions) -> unsolvable. FIX:
   sensors = normalised current POSITION (x,y) + 4 wall-legality bits, NO goal sensor. Markov +
   solvable by a memoryless net, but closeness-fitness still points into the cul-de-sac
   (deception in the LANDSCAPE, not leaked). Capacity-check the net can express a solution path.
2. **Population-vs-single-thread (050 redux).** novelty = archive-backed population; objective =
   single (1+lambda) greedy -> "novelty beats objective" = "population beats one thread". FIX:
   ONE (mu+lambda) EA, same pop/archive/operator/budget; treatments differ in ONE line -- the
   score (novelty k-NN vs closeness). sep-CMA-ES = ceiling, random = floor.
3. **MAP-Elites is tautological** (optimizes coverage -> fills the G cell by definition, cannot be
   deceived). Demote to a REACHABILITY floor only (INVALID iff NO search reaches G); never scored
   as a positive deception result.
4. **Deceptiveness gate worthless as drafted** (a weak greedy stalls regardless; argmax + sigma=0.1
   -> neutral piecewise-constant landscape, stalling may be NEUTRALITY not a trap). Certify
   deception with a MATCHED PAIR + a strong optimizer, and report mutation-effectiveness.

## Redesign (the gate's, adopted) — supersedes the design above

- **Sensors:** normalised position (x,y) + 4 wall-legality bits (NO goal sensor). `[6,H,4]`,
  capacity-checked against a hand-coded solution path (frozen pre-run).
- **Matched maze PAIR:** D (deceptive: barrier forces an initial move AWAY from G; closeness
  basin -> cul-de-sac) and N (non-deceptive twin: identical start/goal/size, barrier moved/removed
  so the greedy-closeness route reaches G). Both solvable by construction.
- **One (mu+lambda) EA**, same sigma/budget/archive; ONE line differs: objective-EA (score =
  closeness to G) vs novelty-EA (score = k-NN novelty of the behaviour descriptor; use a
  TRAJECTORY bitmap, not just final cell, so novelty != a MAP-Elites duplicate). + sep-CMA-ES
  objective (ceiling), random (floor), MAP-Elites (reachability control only).
- **Report mutation-effectiveness** (fraction of mutations that change the final cell); if tiny,
  raise sigma or use stochastic action selection during search (else neutrality masquerades as a
  trap).
- **n = 40 per cell** (Wilson at n=10 only separates 0/10 vs 10/10).
- **Decision rule (ALL FOUR for CONFIRMED):** (1) objective-EA solves twin N, Wilson LB > 0.8
  (competent); (2) objective-EA on D, Wilson UB < 0.2 (deception-specific stall); (3) sep-CMA-ES
  objective on D, UB < 0.3 (strong optimizer ALSO trapped -> landscape deception); (4) novelty-EA
  on D > objective-EA on D, non-overlapping 95% Wilson CIs (novelty advantage). Every failure
  mode is a distinct signed result (novelty-no-help / maze-not-deceptive / optimizer-broken /
  greedy-weakness-not-deception).

Status: REDESIGNED, build-ready. Bigger than 050 (two mazes + mu+lambda EA + novelty archive +
twin/strong-optimizer controls + n=40). Session paused here; the redesigned runner is the next build.

## Provenance

*Stamped manually (erl -noshell; eunit swallows the feed).*

## Result

<one line once signed>
