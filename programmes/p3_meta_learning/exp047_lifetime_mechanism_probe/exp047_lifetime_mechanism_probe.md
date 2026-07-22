# EXP-047 — lifetime mechanism probe: is 045's low-pass story real, or a just-so narrative?

Pre-registration. Written BEFORE the runner. This is the re-scoped EXP-047: the DESIGN gate
killed the original fitness-race design (recorded at the bottom), and Raf approved this
mechanistic probe as the true P3 closer (2026-07-23).

- **Programme:** P3 (closes it)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp047_lifetime_mechanism_probe_tests.erl`
- **Raw feed:** `faber-ecosystem/insights/047-raw-mechanism-probe.txt`
- **Insight:** `faber-ecosystem/insights/047-*.md` (once signed)

## The claim under test

P3's unifying principle (045): lifetime-learning mechanisms CONVERGE (043-045 nulls) because
"integration is a low-pass filter that averages away per-step differences between the
substrates". Three fitness nulls are consistent with TWO incompatible mechanisms:
- (a) the substrates internally compute the SAME thing (genuinely converge), or
- (b) they compute DIFFERENT things that happen to wash out at the action (low-pass).

The principle asserts (b). Fitness cannot tell (a) from (b): it is an identifiability
problem, and a fourth fitness race cannot resolve it (that is why the original EXP-047 was
killed). Only MEASURING the internal state can. This is the lifetime-learning analogue of
insight 035, which measured the memory-arc mechanism directly (cfc state leaky, plastic
imprint stable) with the same `get_internal_state/1` probe.

## Hypothesis (both directions stated)

If the low-pass story (b) is real: all substrates TRACK the current good arm internally
(decodable), their PER-STEP estimates DIFFER (there is something for integration to average
away), yet the integrated ACTION converges (045 replicated).

If it is a just-so story: either the substrates do NOT track equally well (unequal decoding
-> action convergence was coincidence, not averaging), or their per-step estimates already
AGREE (nothing to average -> "low-pass" explains nothing; the convergence has another cause).

## Method

### Phase 1 — regenerate the 045 champions (the deletion tax)

The 045/043 champions were in deleted runners; the raw feeds hold only fitness summaries, no
genomes (verified 2026-07-23). So the probe is NOT zero-evolution: first re-evolve the
converging lifetime cell and PERSIST the champions.

- Scape: `prob_reversal_bandit_sim`, the 043 fair-contest cell (reward as sensor input so
  storage competes fairly). p_hi 0.8, single reversal at mid-life, lifetime ~60.
- Arms (matched to 043, same population / generations / survival / activation):
  | Arm | Evaluator | What CMA-ES evolves | Internal state to probe |
  |---|---|---|---|
  | fixed | `evaluate/2` | base weights | none (constant) -> decoder MUST be at chance |
  | cfc | `evaluate_with_state/2` | base weights (+ per-neuron tau in meta) | `get_internal_state/1` hidden state |
  | nm_global | `evaluate_with_neuromod/4` {A,B,C,D,Eta} | base weights + 5 rule params | the drifting plastic weight vector |
  | nm_pc | `evaluate_with_neuromod/4` {pc,Coeffs,Eta} | base weights + 4 coeffs/synapse + Eta | the drifting plastic weight vector |
- `sep_cma_es:evolve/3`; champion = `best => {BestVector, Fitness}`. n>=10 independent runs
  per arm. Persist each champion vector + its arm decode spec (this is what faber-programmes
  now keeps, so the probe is never blocked on deletion again).
- **Validation check against the corpus (topology PINNED from the 043 feed):** the 043
  fair-contest cell is `[3 inputs, 10 hidden, 1 output]` tanh (51 weight+bias params). The
  reconstructed genome dims MUST reproduce the feed exactly: fixed 51, nm_global 51+5=56,
  cfc 51+10 tau=61, nm_per_layer 51+8+1=60, nm_pc 51 + 4/synapse + 1 Eta (confirm against
  the 043 pc line). Cross-checked: nm_global=56 and cfc=61 both imply H=10 independently.
  If my encoding gives other dims, the harness is wrong -> STOP. Fitnesses must replicate
  043 (all arms ~92-93); if they do not converge, the probe has no null to explain.

### Phase 2 — instrumented replay + decode (the actual probe)

Replay each persisted champion on a FIXED held-out set of flip_seed instances (disjoint from
evolver seeds). Per trial record: the arm's internal state, the action logit, the true
current good arm, the reward.

- **Decoder:** logistic regression from internal state -> current good arm. Train on half the
  reversal episodes, test on the held-out half. Report per-arm test AUC.
- **Disagreement:** threshold each arm's single-trial decoded estimate; report the fraction
  of trials on which the arms' estimates disagree.

### Pre-committed decoder-leakage controls (the claim gate will verify these)

- Decode ONLY from the network's own hidden/plastic state, NEVER from the sensor vector
  `[last_reward, last_action, bias]`. Otherwise the decoder reads good-arm off last_reward
  (trivially correlated) rather than off genuine internal tracking.
- The fixed arm is the leakage sentinel: its state is constant, so it MUST decode at chance
  (AUC ~0.5). If it decodes above chance, the decoder is leaking (e.g. from trial index or a
  reward-correlated feature) and every AUC is void -> fix before reading anything.
- Evaluate decoding on the post-reversal trials specifically, where last_reward is a stale
  guide, so the decoder is forced to use internal tracking, not the reactive one-step cue.

## Decision rule (pre-committed, both outcomes bite)

Over n>=10 champions per arm:

- **Principle SURVIVES** iff ALL THREE hold:
  1. each adaptive substrate tracks: AUC >= 0.75 for cfc, nm_global, nm_pc, with pairwise
     |AUC difference| < 0.10 (they track EQUALLY well);
  2. per-step estimates genuinely DIFFER pre-integration: disagreement > 15% of trials;
  3. the action converges: normalised regret within one within-arm spread across arms
     (043/045 replicated).
- **Principle FALSIFIED** iff EITHER:
  - decoding AUC differs across the adaptive substrates by > 0.10 (they do NOT track equally
    -> action convergence was coincidence, not low-pass averaging), OR
  - per-step estimates agree on >= 85% of trials (nothing for integration to average away
    -> the low-pass story explains nothing; convergence has another cause).
- **Probe INVALID** iff the fixed-arm leakage sentinel decodes above chance (AUC > ~0.6):
  the decoder is compromised; fix and re-run, sign nothing.

The second falsification branch is the one that should scare us: 045's elegant mechanism
turning out to be a post-hoc narrative. That is what makes this a test, not a confirmation.

## Fallback interpretation (committed in advance)

- SURVIVES: P3 closes with a MEASURED mechanism (035 for memory, 047 for learning), not just
  fitness nulls. Strongest close.
- FALSIFIED via unequal AUC: the arms are NOT interchangeable internally; 043-045's fitness
  convergence hid a real mechanism difference the action masked. Retract the "mechanisms
  converge" reading, keep the fitness facts.
- FALSIFIED via >=85% agreement: retract the low-pass EXPLANATION (045's headline) while
  keeping the fitness nulls (043-045) and seeking the real cause of convergence.

## Kill criterion

If Phase 1 fails to replicate the 043 convergence (arms do NOT all reach ~92-93) or genome
dims do not match the 042 record, STOP: the harness reconstruction is wrong, fix it before
any probing. Do not run Phase 2 on a harness that cannot reproduce the null it exists to
explain.

---

## Prior design, KILLED at the DESIGN gate (2026-07-23) — kept as record

The original EXP-047 was a fitness race: drive `prob_reversal_bandit_sim` to a "non-integrable
corner" (p_hi -> 1.0, period -> 1..2) and predict the mechanisms separate. The faber-adversary
DESIGN gate killed it with a confound the sweep could not escape: on this bandit the only
within-lifetime signal is `[last_reward, last_action]`, and reward directly reveals whether the
last action hit the good arm. So integrability and reactive-solvability are ONE knob: p_hi<1
means noisy-so-must-integrate (integrable AND adaptation-requiring); p_hi=1 means
reward-labels-last-action (non-integrable AND reactively-solvable, fixed net wins via WSLS).
No cell is both valid and decisive: fast cells are design-invalid (fixed solves them), slow
cells are known-null (043 replicated), and the one live cell (p_hi=1, period=2) separates only
because WSLS cannot track dwell-time from this sensor -- a recurrence-vs-feedforward TIMING
contrast (031-041), not the nm-vs-cfc question. The metric compounded it: "post-reversal
recovery within k trials" presupposes an integration window, which the corner removes. The
gate's deeper point drives this re-scope: the principle is mechanistic, so only a mechanistic
measurement can close it. Full verdict in git history of this file.

## CLAIM gate verdict, run 1 (faber-adversary/Fable, 2026-07-23) — DO NOT SIGN

The n=10 run fired FALSIFIED, but the CLAIM gate found the verdict is a DECODER ARTIFACT,
verified by hand. Recorded per the discipline.

**Verdict-changing bug (accepted).** `holdout_instances()` alternates initial good arm by index
(odd Idx = GoodArm 0, even Idx = GoodArm 1). `decode_champion` split train/test on `Idx rem 2`,
so the decoder trained ONLY on GoodArm-0 episodes and tested ONLY on GoodArm-1 episodes. Under
`good_at` the training label then equals "trial >= 30" (pure episode-time), and the test set
inverts that relation. Any time-drifting state decodes BELOW chance on test -> cfc 0.289 is the
signature of the bug, not "does not track linearly". Phase 2 measured a split confound.

**Second (accepted).** The "reactive baseline" used `last_action`, the arm's OWN output, so
sensor_auc is an endogenous echo of internal tracking; "state must beat sensor" was doomed.
**Third (accepted).** disagreement 0.75 = 1 - 2/8, the chance non-unanimity of 3 random binary
predictors, and computed from run-1 only. Meaningless.

**What STANDS:** Phase 1 (fitness replication of 043: cfc 92.22 sd0.67, nm_global 88.26 sd1.22,
nm_pc 91.13 sd0.33, fixed 77.06 sd4.93, n=10) is valid. And a POSITIVE: nm_pc decodes the good
arm at 0.789 (sd0.062, n=10) DESPITE the sabotaged split -> a lower bound indicating genuine
arm-identity coding in nm_pc's plastic weights. Nearly opposite the draft. 045 NOT retracted.

**Required Phase-2 fixes (champions persisted -> no re-evolution):**
1. Balanced split (Idx =< 8 vs Idx > 8; both halves carry both polarities) so pure episode-time
   no longer predicts the label.
2. Add a TIME-ONLY control probe (decode label from trial index): must sit ~0.5 under the fixed
   split. This is the confound sentinel the constant-state fixed arm cannot be.
3. Exclude transition trials [RevAt, RevAt+2] (or report separately); assert the sim flip index
   against `good_at`.
4. Drop "state > sensor" from the rule (endogenous). Judge state_auc vs chance AND vs time-control.
5. Recompute disagreement over all 10 champions, or drop it.
6. Non-linear probe only if cfc still < ~0.6 after the split fix.
Then re-run Phase 2 from `exp047_champions.eterm`, re-examine, and re-gate before signing.

## Provenance

*Stamped manually: run via `erl -noshell` not `scripts/run_experiment.sh`, because eunit
swallows the runner's io:format for a passing test and the runner writes its own feed file.
(TODO: teach run_experiment.sh a direct `-eval` entry for feed-to-file runners.)*

### Run 2026-07-23 (corrected split; the signed record)

| Field | Value |
|---|---|
| Runner | `experiments/exp047_lifetime_mechanism_probe_tests.erl` |
| Champions | `experiments/exp047_champions.eterm` (38009 bytes, 4 arms x 10 runs) |
| Engine commit (built == pin) | `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` |
| OTP / ERTS | 28 / 16.1 |
| rebar3 | 3.25.1 |
| Phase 1 entry | `run_full/0` (evolve + persist) |
| Phase 2+3 entry | `run_phase2_from_file/0` (decode + shifted-reversal, from persisted champions) |
| Raw feed | `faber-ecosystem/insights/047-raw-mechanism-probe.txt` (+ `047-raw-run1-flawed-split.txt`) |

## CLAIM gate run 2 (corrected) + shifted-reversal control (2026-07-23) — SIGNED

Run 2 (balanced split, both sentinels at 0.500) flipped the run-1 artifact: cfc 0.965,
nm_global 0.908, nm_pc 0.956 (spread 0.057), disagreement 0.101. CLAIM gate confirmed the split
is clean and the FALSIFIED-of-045's-mechanism verdict is sound, but blocked "tracking"/"same
solution" pending a clock-vs-tracking control (reversal fixed at 30 => a clock passes the
sentinels). Ran the prescribed shifted-reversal control (replay at 20/30/40): FLAT fitness, all
adaptive clock_drops <= the reactive-only fixed arm => NOT a clock => evidence-based tracking
licensed. Signed insight `047-lifetime-substrates-converge-by-tracking-not-by-low-pass.md`.

## Result

SIGNED 047 (2026-07-23). 045's low-pass MECHANISM refuted; the lifetime substrates converge
because each independently learns genuine, equally-accurate, evidence-based (non-clock) good-arm
tracking (decode AUC cfc 0.965 / nm_pc 0.956 / nm_global 0.908, spread 0.057; sentinels 0.500;
shifted-reversal flat). 045's fitness nulls (043-045) stand. Run-1's FALSE falsification (cfc
0.29, split confounded with arm-polarity) caught at the CLAIM gate before signing.
