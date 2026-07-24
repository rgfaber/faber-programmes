# EXP-065 — Is the Flatland competence gap REPRESENTATION or SEARCH? A construction, not an optimization.

Pre-registration. Opened directly by the exp064 CLAIM gate's blind-spot finding: "nothing in the corpus
has yet asked whether the 15 percent gap is a REPRESENTATION limit rather than a SEARCH limit ... the
cheapest probe is not another optimizer, it is fitting the weights to imitate the greedy policy's moves
directly and asking whether the net class can even represent greedy."

- **Programme:** P2 (search strategies) x the Flatland front, diagnostic rung
- **Opened:** 2026-07-24
- **Engine pin:** `eaf10819a37781c28caa098779d0f4027487ae77`
- **Builds:** `experiments/exp065_representation_vs_search_tests.erl`
- **Upstream:** exp063 feed (three optimizers all ~85% of greedy at 2000 evals, n=24);
  `exp064_optimizer_strength_flatland.md` (held pending redesign)

## The question

Every Flatland rung's evolved forager lands ~15% below the hand-coded greedy, and the corpus has
called this "EA under-convergence" throughout, i.e. assumed a SEARCH limit. exp063 showed three
optimizer classes share the shortfall. The untested alternative: the `[5,6,4]` tanh net on the 5-float
sensor may not EXPRESS greedy's computation, in which case no optimizer and no budget ever closes the
gap and the whole under-convergence framing is the wrong diagnosis.

## Part A — constructive representability (search-free, and therefore decisive)

The gate proposed behavioural cloning. A stronger instrument is available, because the greedy policy is
an exact function of the observation:

- `flatland_sim:sense/6` returns `[ODX/N, ODY/N, PDX/N, PDY/N, Energy/E0]`, where `PDX,PDY` is the
  shortest-wrap delta to the NEAREST plant.
- `decide(greedy, ...)` is `toward(Self, nearest(Self,Plants,W), W)` = `axis_move(PDX, PDY)`.

So greedy depends on sensor inputs 3 and 4 only, via `axis_move`, whose four branches partition the
(DX,DY) plane into four convex cones meeting at the origin (boundaries: the diagonals |DX|=|DY|). An
argmax over four linear readouts represents exactly that partition. Therefore we do not need to SEARCH
for the weights, we can WRITE them:

- hidden: `h1 = tanh(a * s3)`, `h2 = tanh(a * s4)`, all other hidden units and all biases zero
- output: `o_E = c(1+eps) h1`, `o_W = -c(1+eps) h1`, `o_S = c h2`, `o_N = -c h2`

`tanh` is odd and strictly monotone, so `|tanh(a*DX)| > |tanh(a*DY)| iff |DX| > |DY|`, and the output
`tanh` is monotone so `argmax(tanh(z)) = argmax(z)`. The `(1+eps)` factor gives the DX axis priority on
exact diagonal ties, matching `axis_move`'s `abs(DX) >= abs(DY)` guard. The all-zero-input case
(agent on the plant) yields all-zero outputs and `argmax/1` returns index 0 = North, matching
`axis_move(_,_) -> 0`.

**Measurement.** Evaluate the CONSTRUCTED net on the identical foraging fitness exp063 used (8 layouts,
T=40, dim-64 weight vector), and separately report its per-step ACTION AGREEMENT with greedy over all
states visited. Compare to greedy (34.25) and to exp063's evolved median (~29.0).

**Honesty about foregone-ness:** the argument above says Part A should SUCCEED, and we state that in
advance rather than pretend the outcome is open. Part A is a VERIFICATION of an analytic claim, and its
value is closing a live confound in the corpus, not suspense. It can still fail in informative ways:
tanh saturation at the chosen `a`, an unexpected flat-weight-vector layout in `set_weights/2`, or
tie-breaking divergence. The weight-vector layout will be established empirically by probing
`set_weights/2` with canonical basis vectors, NOT assumed.

## Part B — if representation is fine, WHY does search underperform? (not foregone)

Part A alone converts "unknown confound" into "search limit", but does not say what about the search
fails. Part B measures the geometry of the constructed optimum, which is where the answer must live:

1. **Effective dimensionality.** The construction uses ~6 non-zero weights out of 64. Report how many
   of the 64 coordinates the fitness actually depends on, by zeroing each coordinate of the constructed
   optimum one at a time and recording the fitness change.
2. **Peak width.** Sample K perturbations of the constructed optimum at the EA's own step size
   (sigma=0.2) and at N(0,1) scale, and report the distribution of fitness change. A narrow peak in 64
   dimensions explains why search from an N(0,1) initialization rarely lands on it.
3. **Retention.** Seed the exp058 EA with the constructed optimum and run it. Does elitist selection
   HOLD 34.25, or does the objective/selection erode it?

Part B outcomes are genuinely open: the peak could be broad (in which case the search failure is about
initialization or budget) or narrow (in which case it is about dimensionality and step size), and
retention could pass or fail.

## Decision rule (pre-committed)

- **REPRESENTATION REFUTED (expected)** iff the constructed net scores within noise of greedy (>= 34.0
  on the 34.25 reference) with high action agreement. Then the net class provably expresses
  greedy-competitive foraging, the ~15% gap is a SEARCH/objective property, and the corpus's
  under-convergence framing is CORRECTLY aimed (though exp063 shows it is not about algorithm class).
- **REPRESENTATION LIMIT (would be a major correction)** iff no construction reaches greedy AND the
  best imitation fit also plateaus well below it. Then the Flatland rungs were mis-diagnosed
  throughout, and the fix is a different net/sensor, not a different optimizer or budget.
- **CONSTRUCTION INVALID** iff the construction fails for a mechanical reason (layout, saturation,
  tie-breaks) that is fixed on inspection; re-run before claiming anything.

## Kill gates / validity (pre-committed)

- The weight-vector layout for `set_weights/2` is established EMPIRICALLY by basis-vector probing and
  reported, never assumed from the `?NP` arithmetic.
- Action agreement is reported alongside return, so a net that matches return by a different policy is
  not miscounted as imitating greedy.
- Part A involves NO optimizer, so its result cannot be confounded by search quality. This is the whole
  point of preferring construction over the gate's suggested cloning.
- Scored on the same 8 fixed deterministic layouts as exp063 so the comparison is like-for-like; this
  is in-sample for the EVOLVED numbers but the constructed net was never fitted to anything, so it has
  no in-sample advantage.
- No claim about 061/062 (ecological results) and none about 059 (fleeing). Foraging only.
- Whether greedy is OPTIMAL is not claimed and not needed: the question is about the gap TO greedy.

## Hypothesis

Part A: the construction reproduces greedy exactly (agreement ~1.0, return 34.25), so REPRESENTATION
REFUTED. Part B: the optimum is a narrow peak with ~6 of 64 coordinates load-bearing, which would
identify effective-dimensionality-plus-step-size (not algorithm class, per exp063) as the real search
obstacle, and would predict that the exp064 budget sweep helps less than a better initialization or a
lower-dimensional parameterization would.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-24) — REDESIGN accepted

**The design described ABOVE was NOT built.** The gate verified the analytic argument line by line and
found it CORRECT, which is exactly why it killed Part A: representability is already settled by
persisted data (exp063's per-arm MAXIMA 34.50/35.00/35.00 EXCEED greedy 34.25), and `sense/6` performs
the argmin and hands the net the nearest-plant delta, so greedy was never a hard function to express.
The exp064 gate's blind-spot worry ("the net may not express greedy's argmin-over-plants computation")
was itself wrong for that reason. Part A could not fail, so it is ceremony, and it was demoted to an
instrument check. All three Part B items were killed too: item 1 (effective dimensionality by
one-at-a-time ablation) is arithmetically tautological because 58 of 64 coordinates are already zero at
the construction; item 3 (retention) is a theorem about the elitist loop plus a running max, not an
outcome; item 2 (peak width) is ill-posed because the construction is SCALE-FREE (`(a,c)` and `(a,10c)`
are the same policy), so choosing `c` chooses the answer.

**What was built instead** is the gate's redesign, in
`exp065_greedy_ceiling_and_mixture_tests.erl`: the construction as an exhaustive 243-state instrument
check; a PRIMARY arm G (EA seeded with the constructed greedy) vs arm R (N(0,1) init) at exp058's REAL
configuration (80 gens, 12 layouts, mu=lambda=20, sigma=0.2, n=20, common random numbers by run index)
asking whether greedy is the ceiling; a SECONDARY mixture-vs-shortfall test on arm R; and a TERTIARY
champion-disagreement mechanism probe. Thresholds used in that redesign (1.02x / 1.10x for the
yardstick, 0.95x for the success line, 0.5 boundary mass, 20 distinct states) were introduced by the
redesign and are recorded HERE, after the fact. **That is a record-keeping failure: they are not
pre-registered in the sense this document is supposed to provide, and no artifact fixes their authoring
time relative to the run.** Any future claim resting on them must re-pre-register them first.

## Result — RUN, but NOT SIGNED (CLAIM gate: REVISE-AND-REGATE)

Feed: `exp065-raw-greedy-ceiling-and-mixture.txt` (all 40 per-run values, seeds, eval counts).

**Clean and confirmed by the gate:** the construction is exact (243/243 exhaustive agreement; return
34.4167, bit-identical to greedy on the 12 faithful layouts); the exp058 reproduction is faithful line
for line; common random numbers are genuinely shared across arms; `round(S3*N)` recovery of DX is
exact; the 12 dead coordinates and 18.75% are correct; every arithmetic figure recomputed from the
per-run values matches.

**The result the corpus most needs, and which the draft insight omitted:** at exp058's FAITHFUL
configuration the competence gap is about **6%**, not the ~15% the corpus has been arguing about
(arm R median 32.3333 / greedy 34.4167 = 93.9%). exp063's 84.5% was measured at 50 gens over 8
layouts. Budget and layout set are confounded, so the honest statement is that the gap is
CONFIGURATION-SPECIFIC and is ~6% under 058's real config.

**Why it was not signed.** The CLAIM gate returned REVISE-AND-REGATE on a draft insight 063, which was
deleted rather than corrected-and-slipped-through. Its findings:

1. The draft misstated its own feed twice, both times flattering the claim: champion agreement quoted
   as "0.92-0.94 / 7-9 distinct bad states" when the non-collapse ranges are **0.854-0.935 / 6-12**
   (the two counterexamples excluded were the same two runs); and "one run beats greedy" when the feed
   has **two** (35.0000 and 34.9167).
2. The disagreement map is **not exhaustive** (it enumerates only on-policy visited states) and the
   runner never records the visited-state denominator, so "7-9 of 81" divides an on-policy error count
   by an off-policy state space. The tertiary finding is uninterpretable as measured. One-line fix
   (`length(lists:usort([{DX,DY} || {DX,DY,_} <- Visits]))`) plus a re-run of section 4 only.
3. Champions at seeds 2001/2002/2004 return identical triples, so there are at most 7-8 distinct
   behaviours among the 10, and the reported median is the value of a triplicated policy.
4. The boundary/far indicator has **no null and a threshold below chance**: the "far" clause alone
   covers 56 of 81 states, so uniformly scattered errors would exceed the 0.5 verdict line. The
   observed 0.419 may be BELOW chance, which would evidence the opposite conclusion.
5. Arm G returned **exactly 34.4167 in 10 of 20 runs** (zero improvement), and elitism guarantees that
   floor by construction, so the arm G median is half an artifact. The informative statistic (10/20
   with no improvement at all) was in the feed and not in the draft. Also sigma=0.2 over 64 coordinates
   is a per-offspring perturbation of norm ~1.6 against a constructed vector of norm ~2.5, so arm G is
   a coarse scatter, not local refinement.
6. Finding 2's use was **circular**: validating the "% of greedy" yardstick against the weak EA's own
   reach, then licensing exp064 (whose entire purpose is testing whether a STRONGER optimizer exceeds
   that reach) to keep using it. If sep-CMA-ES at 20k lands at 40, "% of greedy" reads 116% and the
   yardstick has failed precisely in exp064's regime. The exp064 licence is struck.
7. "GRADED" was a positive characterization never tested. Sorted arm R shows 31.00 four times and
   33.6667 six times plus a starvation tail: a few attractors, not a smooth gradation. Both
   pre-declared branches were near-unsatisfiable a priori (the mixture branch required 5 of 10
   successes at or above greedy when only 2 of 20 runs exceed it at all).
8. Evaluation accounting repeats a defect the exp064 gate already flagged: **1620 unique** evaluations
   (20 + 80x20), not the 3200 stated, because parents are re-scored on a deterministic fitness.
9. Finding 5's corollary does not follow: `sep_cma_es` adapts a covariance over the nominal 64
   dimensions with O(1/N) rates regardless of twelve being flat, so the effective-dimensionality
   instruction for covariance accounting is wrong and is struck. The dead coordinates cost only
   `sqrt(52/64) = 0.90` of the isotropic step. Worth one sentence, not a corollary.

**Corpus debt this rung incurred and has NOT paid.** Arm R IS the faithful 80-gen/12-layout re-run that
the exp064 CLAIM gate demanded before 058 could be corrected. It gives median **32.3333** (modal value
33.6667), and half the runs fall below 0.95x greedy. Insight 058 still reads "a `[5,6,4]` network
EVOLVES competent FORAGING (33.7 ~= the near-optimal greedy 34.4)" and "at 80 gens / pop 20 over all
layouts the net matches greedy". That amendment is now evidenced and OWED.

### What must happen before any of this is signed

- **No new compute:** fix both feed misstatements; strip "graded"; name the accept threshold (1.02x),
  not only the reject threshold; disclose 1620 unique evaluations; report the ~6% faithful-config gap;
  state the 058 amendment; delete the exp064 licence and the effective-dimensionality instruction;
  demote the construction to a method note.
- **Re-run section 4 only** with the visited-state denominator recorded, distinct behaviours counted,
  and a resampled-error null for the boundary mass.
- **Arm D (degraded-seed control)** before finding 2 survives in any form stronger than "this EA
  improved a greedy seed by at most 1.9%, and not at all in 10 of 20 runs": seed with a greedy degraded
  to a calibrated 28-30 return and check the EA can climb at all at this budget. If it cannot, arm G
  measures the searcher, not greedy.
- **Arm P (planner bound)** to answer the question the exp064 gate actually asked: a width-2000 beam
  search over the exact deterministic forage MDP, no network, giving a searcher-independent lower bound
  on the achievable return. Reject the yardstick if it exceeds 1.10x greedy (37.86); accept at task
  level if at most 1.02x (35.11); otherwise use arm P as exp064's denominator instead of greedy.

### Untested mundane alternative (gate blind spot, recorded)

`regrow/2` places the replacement plant deterministically from the eaten cell, so the 12-layout world is
memorizable. Arm G beats greedy on 10/20 runs by 0.083 to 0.667 plants, i.e. one to eight extra plants
across 12 fixed regrowth sequences. A policy exploiting deterministic regrowth on two or three layouts
is indistinguishable from a better forager under this metric, and would explain both the tiny magnitude
and the hard edge near 35.0 shared by both arms. One held-out layout family scored on the arm G
champions separates them. Also unmeasured: greedy eats 34.4 of a trivial bound of 40 steps, so the
gap from greedy to the trivial bound (14%) is larger than the gap the corpus has been arguing about.
Finally, all five results are FORAGE-only with `Opp = none`; nothing transfers to hunt or flee, where
inputs 1-2 are live and ceiling, effective dimensionality and disagreement geometry are all different.
