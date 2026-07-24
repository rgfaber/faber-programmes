# EXP-064 — P2 x Flatland: does a STRONGER optimizer close the competence gap, and does it OVERTURN the 059 no-fleeing negative?

Pre-registration. Programme 2 (search strategies) applied to the Flatland front. This is the P2
charter's stated payoff executed against our OWN signed corpus: "many findings are 'inconclusive at
this budget'; several are really 'inconclusive with this optimizer'." Every Flatland rung (058-062)
ran a plain (mu+lambda) truncation EA that visibly under-converged. If that optimizer was the binding
constraint, then at least one signed Flatland negative is an ARTEFACT and must be amended.

- **Programme:** P2 (operators) x the Flatland/ALife front
- **Opened:** 2026-07-24
- **Engine pin:** `eaf10819a37781c28caa098779d0f4027487ae77`
- **Builds:** `experiments/exp064_optimizer_strength_flatland_tests.erl`
- **Precursor (unsigned):** `experiments/exp063_optimizer_diag_tests.erl` — scoping diagnostic; at a
  2000-eval budget on Flatland foraging (n=8 each) `sep_cma_es` reached median 88.1% of the hand-coded
  greedy vs `mu_lambda_es` 82.3%, and removed mu+lambda's failure tail (floor 28.9 vs 16.4). Direction
  established; NOTHING about budget scaling or about any Flatland conclusion was tested.
- **Numbering:** 063 carries no signed insight (it is the unsigned diagnostic above, and 062's text
  refers to the BLOCKED evolved-restraint rung as "063"). Signed result here is insight 064.

## Why this is not foregone

The diagnostic settles only "sep-CMA-ES beats mu+lambda by ~6 median points at one budget on one
task". It does NOT settle either question below, and both have a real two-sided outcome:

- Part A can fail: 6 points at 2k evals may be a fixed offset that never reaches the hand-coded
  ceiling at ANY budget (representation-limited, not optimizer-limited). The diagnostic's best sep run
  (35.0) EXCEEDED greedy, but its median did not, so the ceiling question is open.
- Part B is genuinely at risk in BOTH directions. Either the 059 negative survives a stronger
  optimizer (which strengthens it from "not learned at this budget" to "not learned by a competent
  searcher") or it falls (which forces a scope amendment on a signed insight). We pre-commit to
  publishing either.

## Part A — the competence curve (the direct P2 measurement)

Fixed-topology `[5,6,4]` weight vector (dim 64), the same nets the Flatland rungs used. Two
optimizers (`mu_lambda_es`, `sep_cma_es`) x four evaluation budgets (2k, 5k, 10k, 20k evals) x the
three Flatland task axes, n>=8 independent runs per cell, matched budget accounting (evaluations, not
generations).

Tasks (all already instrumented in 058/060; the hand-coded policy is the reference, NOT a proven
optimum):
1. **FORAGE** — plants eaten over T steps, no predator; reference = hand-coded greedy forager.
2. **HUNT** — captures over T steps against a fixed fleeing prey; reference = hand-coded greedy hunter.
3. **FLEE** — the 058 graded flee axis against a fixed greedy hunter; reference = the dedicated
   hand-coded fleer, floor = the gen-0 random-net level.

Report per cell: median + bootstrap CI of best fitness, and the **competence ratio** (median / hand-coded
reference). COMPETENCE REACHED for a cell iff the run distribution's CI lower bound is >= the hand-coded
reference (i.e. matches or exceeds it, since a net exceeding greedy is possible and observed).

## Part B — the payoff: is the 059 negative optimizer-limited?

059 signed: "REACTIVE FLEEING is never learned under ecological survival fitness -- the 058 flee axis
stays ~0.29, barely above the gen-0 random floor 0.254, vs a dedicated fleer 0.39-0.69, in every
condition." That was measured under the weak optimizer.

Re-run 059's central condition (prey evolved under SURVIVAL fitness with a predator present; NOT
directly rewarded for fleeing) using the Part-A winner at the largest budget that Part A shows is
worth spending. Then measure, on the champion, the SAME three readouts the corpus already has:
the 058 flee axis, the 058 forage axis, and the 060 interventional `avoid_near` probe.

**Positive control (representability kill gate).** In the SAME optimizer/budget configuration, evolve
a prey with the flee axis as the DIRECT fitness. If that does not clear the random floor decisively,
the flee axis is not reachable by this optimizer/representation at all and Part B is UNINTERPRETABLE
(reported as such, no claim about 059 either way). 058 showed a hand-coded fleer scores 0.39-0.69, so
the behaviour exists in the world; this gate tests that the SEARCH can find it when it is the target.

## Decision rule (pre-committed; all outcomes reachable and publishable)

Primary endpoint = Part B's flee axis under survival fitness, vs the 059 random-net floor.

- **059 CONFIRMED AND STRENGTHENED** iff Part A shows the stronger optimizer reaches competence on
  FORAGE (so the searcher is demonstrably competent), the positive control clears the floor (so
  fleeing IS findable when targeted), and yet the survival-fitness flee axis STILL sits at the random
  floor. Then 059's negative is a property of the FITNESS LANDSCAPE, not of the optimizer, and the
  signed insight is amended upward in strength.
- **059 OVERTURNED (scope amendment required)** iff the survival-fitness flee axis rises decisively
  above the random floor (resolved, reproduced on measurement seeds). Then 059 was optimizer-limited;
  we amend insight 059 in place with a dated correction, update PLAN_FLATLAND, and publish the
  retraction in the notebook. Pre-committed: we do this loudly, not quietly.
- **OPTIMIZER IS NOT THE LEVER** iff Part A shows NO budget at which either optimizer reaches
  competence on FORAGE. Then the gap is representation/task, not search; Part B is not run to a claim
  and the Flatland negatives stand unchanged (their optimizer caveat neither strengthened nor removed).
- **UNINTERPRETABLE** iff the positive control fails (flee axis unreachable even when directly
  targeted) — reported as an instrument limit, no claim about 059.

## Kill gates / validity (pre-committed)

- **Matched budget accounting** in EVALUATIONS, not generations (the P2 charter's rule; population
  sizes differ per optimizer).
- **Seed split**: calibration seeds fix budgets/hyperparameters; a disjoint measurement-seed set
  produces every reported number. Resolved effects reproduced on a second measurement set.
- **Primary endpoint pre-committed** (Part B flee axis) so the 2 x 4 x 3 Part-A grid cannot be mined
  for a headline; Part A is reported as a full curve, not as a best cell.
- **The hand-coded reference is a reference, not an optimum.** Exceeding it is possible (already
  observed at 35.0 vs 34.25) so "competence" is defined as CI lower bound >= reference, never as
  "100% of greedy".
- **No ecology claim.** This experiment cannot and will not speak to 061/062 (collapse and the
  restraint squeeze are ECOLOGICAL results about fixed behaviours and energetics; a stronger optimizer
  does not bear on them). Any temptation to read Part A as "the front reopens" is out of scope.
- **Hyperparameters held equal where shared** (lambda, init sigma); each optimizer otherwise run at
  its own documented defaults, disclosed.

## Hypothesis (with direction)

Part A: sep-CMA-ES reaches FORAGE competence at some budget in 5k-20k (the diagnostic's best run
already exceeded greedy at 2k); HUNT plausibly likewise; FLEE-as-direct-target is the uncertain one.
Part B: the honest prior from 059/060 is that survival fitness still does not produce reactive fleeing
even with a competent searcher (060 found only single-step repulsion, which is a different and weaker
behaviour), so **059 CONFIRMED AND STRENGTHENED** is the expected outcome. But 059's negative was
always vulnerable to the under-convergence objection, and that is precisely why this must be run.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-24) — REDESIGN, then KILLED by its own premise audit

The gate returned REDESIGN with 14 attacks. Its FIRST and decisive attack: the pre-reg's founding
premise ("every Flatland rung ran a plain (mu+lambda) EA that under-converged") CONTRADICTS signed
insight 058, which reports the weak EA reaching 33.7 ~= greedy 34.4 on foraging. The gate ruled that
three mutually exclusive readings existed (the diagnostic's optimizer is not the rungs' EA; 058's
number is a best-of-run reported as typical; the tasks differ) and prescribed ONE CHEAP CELL FIRST:
reproduce 058's exact EA configuration in the diagnostic harness before building anything.

Other attacks, recorded because they apply to any future version: Part B confounded optimizer with a
28x budget change (needs a 2x2, and the mu_lambda-at-large-budget cell is the one that can embarrass
the thesis); the competence gate (CI lower bound >= reference) is near-unreachable at n=8 so the modal
outcome was definitional mush; the competence ratio is in-sample on 8 fixed layouts so overfitting
grows with budget; the primary endpoint used the random floor rather than the directly-targeted
control as comparator, on a margin 059 itself already calls noise; the positive control differed from
the treatment in TWO ways (plants-off benchmark vs plants-on ecological episode); the 060
repulsion/fleeing distinction was pre-installed as an escape hatch absorbing any outcome; n=8 is
underpowered against an insight established at n=20; "champion" is a best-of-run max biased by budget;
sep-CMA-ES degrades under fitness noise so a winner picked on a deterministic task may be wrong for
the stochastic one; and the 059 amendment protocol named no sentence and no number, so it was
decorative.

## Status — NOT BUILT, NOT KILLED: PENDING REDESIGN (both gates)

**The premise audit below was run, appeared to falsify the premise, and a draft insight 063 was
written claiming "the optimizer is not the Flatland lever". The CLAIM gate REFUSED it
(REVISE-AND-REGATE) and its lead attack retracts the kill: the audit was run at 2000 evaluations on a
64-dimensional problem (~31 evals/dimension), where `sep_cma_es`'s covariance (learning rates O(1/N),
100 generations at N=64) has barely moved. At that budget all three arms are doing randomized local
search from initialization and NO separation was ever plausible. A null there is near-definitional,
not evidence.**

So the audit killed exp064 on its single weakest cell, and exp064's own 2k/5k/10k/20k budget sweep is
precisely the design that could separate the arms. The premise is UNTESTED, not falsified. The draft
insight was deleted rather than signed; the raw feed is retained here as
`exp063-raw-optimizer-comparison-n24.txt`.

### What must be fixed before this is re-gated

From the CLAIM gate, in addition to the 14 DESIGN-gate attacks above:

1. **At least one large-budget cell (20k evals) for all three arms, n>=24.** Without it "the optimizer
   is not the lever" is untestable rather than tested. Algorithm-class advantages appear as different
   SCALING CURVES, not as a fixed offset at a fixed spend.
2. **Persist per-run data.** The feed holds 12 summary numbers; the 72 per-run values, seeds, and each
   arm's returned `evaluations` were discarded, so nothing can be re-analysed. The feed is the record.
3. **Match on UNIQUE evaluations.** `ea058_loop/3` re-scores `Pop ++ Off` on a deterministic fitness,
   so it spends 20 x 50 = 1000 unique evaluations against 2000 for both library ESs. The tie is
   asymmetric (the EA ties at HALF the unique budget) and must be either fixed by caching parent
   fitness or disclosed in the headline.
4. **Reproduce 058 at its REAL configuration** before any correction to its number: 80 generations
   over 12 layouts (`forage_starts/0`), not 50 over 8. The current run gives the EA 62% of 058's
   generations on a smaller, different fitness.
5. **Drop the median permutation test.** The fitness is a mean of integer counts on a 0.125 grid, so
   medians of 24 values collide by construction; that is why two arms read exactly 29.00 and why a
   0.06-plant difference returned p=0.040. Report means with bootstrap CIs, a Mann-Whitney on full
   distributions, a lower-quantile comparison for the tail question, and a PRE-DECLARED EQUIVALENCE
   MARGIN (TOST) — `p=1.0000` on `diff=0.00` is a tautology, not evidence of equivalence.
6. **Disclose and fix configuration asymmetries.** `mu_lambda_es` ran at `lambda=20` against its own
   documented default (~70, ~7*mu); `sep_cma_es` initialises `x0` at the ZERO VECTOR (a zero-weight
   tanh net emits four equal outputs, so `argmax/1` returns a constant move) while the other two
   initialise from N(0,1). One untuned configuration per class cannot support "a materially different
   optimizer class buys nothing".
7. **Common random numbers across arms** (shared per-run-index seed), the programme's standard.
8. **Persist the n=8 runs or drop the sign-flip claim.** Only the FIRST n=8 read was ever written to a
   file; the second exists in no feed, so the "sign flipped +2.00 then -2.00" methodological warning
   is unsignable as it stands.

### The narrow residue that IS already earned (signable separately, much smaller than the draft)

- **058's 33.7 is a best-of-run maximum from a single execution.** Established by reading
  `exp058_flatland_instrument_tests:best/5` (`max(B, element(1, hd(Ranked)))`, called once) — no
  experiment needed. The representability KILL GATE STANDS (best-of-run is the right existence
  demonstration); only the "typical champion was a competent forager" reading needs correcting, and
  the corrected median must come from the faithful 80-gen/12-layout re-run, not from this one.
- **The n=8 tail claim did not replicate.** All three arms retain failure runs at n=24 (minima 13.38 /
  12.50 / 13.75), so "sep-CMA-ES removes mu+lambda's failure tail" is refuted.

Neither supports the draft's title, nor its finding 3, nor either proposed corpus correction. In
particular the proposed edits to 060's forward-look and `PLAN_FLATLAND`'s rung-3a rationale OVERREACH:
060's blocker is a single-step interventional AVOIDANCE probe on champions evolved under ecological
survival fitness WITH a predator, whereas this measured episode-level pure foraging with no predator;
and 3a's rationale rests on a second, independent ground (demography-confounded) untouched here.
Under-convergence itself is CONFIRMED by this run (all three arms ~15% below greedy), so replacing
"blocked by EA under-convergence" with "blocked by an untested factor" would delete an evidenced
caveat — a corpus regression.

### The experiment the corpus is actually missing (gate blind-spot, unprompted)

Nothing has asked whether the ~15% gap is a REPRESENTATION limit rather than a search limit. A
`[5,6,4]` net with 64 weights on a 5-float sensor may simply not express greedy's argmin-over-plants
computation, in which case no optimizer and no budget closes it and the whole under-convergence
framing is the wrong diagnosis. One cell discriminates them: fit the weights to IMITATE the greedy
policy's moves directly (supervised, not evolved) and ask whether the net class can represent greedy
at all. That is cheaper than the budget sweep and should probably precede it.

## The premise audit as run (2000 evals — now known to be an uninformative budget)

The prescribed premise audit was run (exp063 diagnostic, third arm = exp058's `evolve/3` verbatim:
(mu+lambda) truncation, mu=lambda=20, FIXED sigma=0.2, uniform parent pick, elitist over Pop++Off,
50 gens x 40 evals = 2000 matched). At n=24 runs per arm on the identical foraging fitness:

| optimizer | median | min | max | % of greedy |
|-----------|--------|-----|-----|-------------|
| exp058 EA (what the rungs ran) | 28.94 | 13.38 | 34.50 | 84.5 |
| `mu_lambda_es` | 29.00 | 12.50 | 35.00 | 84.7 |
| `sep_cma_es` | 29.00 | 13.75 | 35.00 | 84.7 |

Two-sided permutation tests on the median difference (10k shuffles): sep vs mu_lambda diff 0.00
p=1.000; mu_lambda vs exp058EA diff 0.06 p=1.000; sep vs exp058EA diff 0.06 p=0.040 (a 0.06-plant
difference, three uncorrected comparisons, discrete median -- an artifact, not an effect).

**The three optimizers are indistinguishable.** The rungs' hand-rolled EA is not weaker than either
library ES. The ~15% median gap to greedy is SHARED by all three and is therefore not an
optimizer-strength gap. All three EXCEED greedy at their best run (34.50/35.00/35.00 vs 34.25).

Consequently exp064 is KILLED, not redesigned: Part A's question is answered (the optimizer is not the
lever) and Part B's motivation (that 059 was optimizer-limited) has no premise left to stand on. The
earlier scoping read from exp063 at n=8 -- "sep-CMA-ES beats mu+lambda by ~6 median points and removes
its failure tail" -- did NOT replicate: across two n=8 runs the sign of the difference flipped
(+2.00 then -2.00), and at n=24 it is 0.00.

Signed as insight 063 (the negative + the two corpus corrections it forces).
