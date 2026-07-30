# EXP-067. Robo Rumble phase 1, the CYCLING question: does coevolution FIND AND EXPLOIT the cyclic pockets, or CLIMB THE TRANSITIVE BACKBONE past them?

Pre-registration. Phase 1 of the Robo Rumble front, unlocked by phase 0's cleared competence
floor (insight 066, verdict CLEARED at a median held-out win rate of 0.9750 against a
pre-registered bar of 0.5748). `PLAN_ROBO_RUMBLE.md` section 6 states phase 1's question as
"does this substrate produce intransitivity where the bare grid did not", and both answers are
signable.

**That question as the plan states it is not the question this document asks, because phase 0
made it too coarse.** Phase 0's cross-play probe (EXPLORATORY, POST HOC, unregistered, signs
nothing) suggests a landscape that is very nearly a single transitive competence ladder carrying a
small residue of cyclic pockets. **That suggestion is not a precondition and it does not decide
whether phase 1 runs; the cleared floor does that, and it is cleared.** What the suggestion does is
make the plan's binary question inadequate, because in such a landscape coevolution can do two
things that produce nearly identical champion trajectories and completely opposite conclusions:

- **(a) FIND AND EXPLOIT the cyclic pockets.** Non-transitive dynamics, a Red Queen with a return.
- **(b) CLIMB THE TRANSITIVE BACKBONE** while the pockets sit there unvisited. Not that.

**Distinguishing (a) from (b) IS the experiment.** A count of cyclic triples in a coevolutionary
archive does not distinguish them, because (b) also produces a non-zero count from binomial noise
around a total order, and (a) at a low rate is indistinguishable from (b) at a high one unless the
reference is a strength model rather than a coin. Everything below is built around that
separation.

- **Programme:** P7 (Coevolution) x the Robo Rumble front, phase 1
- **Opened:** 2026-07-30
- **Engine pin:** `a5e8bcfc5646827e9be49a9629f8a6a9678c814b`, the same pin phase 0 ran at. The
  engine is NOT modified: `robo_sim`, `robo_net`, `robo_gauntlet` and `robo_match` are untouched
  and gate 1 recomputes `robo_match_tests`' golden match vector `DFCD8106…B3895E88` to prove it
  rather than assert it. One pin, and it is the provenance.
- **Builds:** one runner in `experiments/`, and nothing else. `experiments/` is not built by
  `rebar3 compile`; `rebar3 as test compile`, beams under
  `_build/test/lib/faber_programmes/experiments`. Erlang only, elvis `faber_min` clean
  (`no_deep_nesting` level 2, `no_if_expression`, `no_nested_try_catch`), `warnings_as_errors`.
- **Raw feed / insight:** `faber-ecosystem/insights/067-*`
- **Upstream:** `PLAN_ROBO_RUMBLE.md` sections 2, 4, 6; insight 066 (the cleared floor and its four
  design notes) **together with its dated section "APPENDED CORRECTION AND POINTER, 2026-07-30"
  (`faber-ecosystem` commit 224247f), which REFUTES the candidate intransitive triple the signed
  insight's own final section asked for and which is what this document cites wherever that claim would
  otherwise be cited**; `066-note-crossplay-intransitivity-UNSIGNED.md` (its section "What phase 1 should
  take from this"); `SYNTHESIS_P7.md` (the closed programme's limitations, which this design is
  built to avoid reproducing); and phase 1's own three calibration records,
  `exp067_null_a_calibration.txt`, `exp067_null_a_verification.txt` and
  `exp067_panel_discriminator_redesign.txt`, which are inputs to this
  pre-registration rather than results of the experiment.

---

## Status

**Pre-registration. Nothing has been executed, and this document is NOT CLEARED TO BUILD.** No arm
has been run, no runner has been written, no panel has been measured and no verdict exists. The
DESIGN gate has returned four verdicts: BUILD_WITH_CHANGES in round 1 with nine required changes,
BUILD_WITH_CHANGES in round 2 with six, **REDESIGN in round 3 with seven**, scoped to the negative's
panel discriminator, and **REDESIGN AGAIN IN ROUND 4, UNANSWERED**. The first twenty-two changes are
applied. Round 4's three directions are recorded in PART 6 and are NOT applied.

**READ ROUND 4 BEFORE READING ANYTHING ELSE HERE AS SETTLED.** Its finding is that the round-3
rebuild has proven specificity and **measured-zero sensitivity**: it cannot fire on the synthetic
backbone climber, which is what round 3 required, and it also does not fire on the only real pocket
occupants this corpus contains (seeds 2003 and 2013, through which every measured cycle runs), per
the redesign record's own D4 table. A rule that fires on neither hypothesis gives both hypotheses
the same reading. Round 4 also finds the negative's panel conjunct is counted over arm A1 alone,
which is the arm this document declares biased against a positive, and that the count positive's
binding leg is one unreplicated number whose error direction points at this document's own modal
hypothesis. Its redesign direction is constructive and is summarised in PART 6: a LOCAL pocket
statistic with sensitivity demonstrated in advance, the count decision re-centred on the paired
coupled-against-decoupled contrast this document already builds and currently does not gate on, and
a consumer for the orphaned IF-4. **Round 3's redesign is a change of SHAPE and not of wording: the branch
6 / 7 discriminator was a mean-centred median of `INV - E[INV]`, which subtracts a mean without
conditioning on the realised composition and therefore sent a pure transitive climb to the branch
reserved for panel inversion (measured median +15.6000 at band 0.10). It is replaced by the
positive's own Null C exceedance conjunct, counted over the negative's own base, so this document
now uses ONE normalisation of `INV` for every panel decision it makes.** The two Null A
calibration records and the panel-discriminator redesign record are INPUTS to this pre-registration
rather than results of it. The full account of what has and has not been done is the Result
section, PART 6.

**Split 2026-07-30 at 2696 lines and 224790 bytes**, past the documentation rule that caps a plan
file at roughly 1500 lines and 75KB. The split is by top-level section boundary only. No line of
the pre-registration was rewritten by the split itself, proven byte-exactly by
`scripts/exp067_verify_split_lossless.sh` and recorded in `exp067_split_losslessness.txt`; the
cross-references that now cross a file boundary were repointed afterwards and carry an explicit
`(PART n)` locator, each one listed in that same record.

**SPLIT AGAIN 2026-07-30, five parts into six**, because PART 5 reached 86954 bytes once the round-3
DESIGN gate section was written into it. The DESIGN gate record and the Result moved to a new
PART 6 on a top-level section boundary. Byte-preserving, proven by
`scripts/exp067_verify_part5_split.sh` and recorded in the same `exp067_split_losslessness.txt`,
which carries both splits.

## The parts

| Part | One line |
|---|---|
| [PART 1](exp067_coevolution_cycling_PART1.md) | What phase 0 hands over and what may not be carried, the cycling question with its ten pre-committed outcomes, and the primary endpoint with the BEATS relation reconciled once. |
| [PART 2](exp067_coevolution_cycling_PART2.md) | The three registered nulls (A the Bradley-Terry bootstrap, B orientation, C row-permutation), what running Null A on a real matrix falsified, why the mean-centred panel discriminator was withdrawn and what replaced it, and the two instruments I1 and I2. |
| [PART 3](exp067_coevolution_cycling_PART3.md) | The 25-member reference panel, the coevolution design (fitness, the opponent set that is the experimental variable, seeding, optimisers), the protocol with its self-checks SC1 to SC15, and the frozen constants. |
| [PART 4](exp067_coevolution_cycling_PART4.md) | The decision rule: the precedence ladder, the reading table, the exhaustion argument, the secondary endpoints, the IF-1 to IF-14 instrument-failure table, and what would falsify what. |
| [PART 5](exp067_coevolution_cycling_PART5.md) | The largest threat to validity with its four artifact routes, how the under-convergence confound stays closed, what a negative would and would not mean, the compute budget, what is out of scope, and H1 to H4. |
| [PART 6](exp067_coevolution_cycling_PART6.md) | The DESIGN gate record, all four rounds (BUILD_WITH_CHANGES, BUILD_WITH_CHANGES, REDESIGN, REDESIGN-unanswered) with every required change and where it landed, and the Result. |

## Section index

Every section of the pre-registration, and the file it now lives in. Cross-references inside the
document resolve here.

| Section | File |
|---|---|
| What phase 0 hands over, and what may NOT be carried | PART 1 |
| Carried unchanged, and named so that nothing is silently re-derived | PART 1 |
| NOT carried, and each refusal is load-bearing | PART 1 |
| The question, asked so that every answer is signable | PART 1 |
| The primary endpoint, counted once and named | PART 1 |
| The BEATS relation, reconciled and stated ONCE | PART 1 |
| Granularity, fixed in advance and shown separable | PART 1 |
| THE NULLS, REGISTERED BEFORE THE MATRIX EXISTS | PART 2 |
| Null A, PRIMARY for the archive cycle count: the BRADLEY-TERRY PARAMETRIC BOOTSTRAP | PART 2 |
| NULL A HAS NOW BEEN RUN ON A REAL MATRIX, AND HALF OF WHAT WAS CLAIMED FOR IT IS FALSIFIED | PART 2 |
| Null B, SECONDARY and registered: the ORIENTATION NULL | PART 2 |
| Null C, PRIMARY for the panel-inversion instrument: the ROW-PERMUTATION NULL | PART 2 |
| EVERY PANEL-READING DECISION NOW CONSUMES NULL C, AND THE FIRST VERSION COMPUTED IT AND THEN BYPASSED IT (DESIGN gate round 2, RC2-1) | PART 2 |
| AND THE MEAN-CENTRED HALF OF THAT REPAIR IS ITSELF WITHDRAWN, BECAUSE SUBTRACTING A MEAN IS NOT CONDITIONING ON A COMPOSITION (DESIGN gate round 3, RC3-1) | PART 2 |
| CAN A REAL WIN PATTERN EXCEED ITS OWN NULL C MAXIMUM? THE DATA ON DISK SAYS NO, FOR ALL 20 (DESIGN gate round 3, RC3-6) | PART 2 |
| Alternatives named and REJECTED in advance | PART 2 |
| The two instruments, sharpened | PART 2 |
| Instrument I1: is the population INSIDE the cyclic pockets, or outside them? | PART 2 |
| The 13 seeds' `INV` at checkpoint 0, COMPUTED BEFORE ANY RUN, from data already on disk | PART 2 |
| Instrument I2: does a champion that lost the throne ever REGAIN it against a LATER opponent? | PART 2 |
| The reference panel: 25 members, measured once, frozen before any run | PART 3 |
| The coevolution design | PART 3 |
| The fitness | PART 3 |
| The opponent set, and this is the experimental variable | PART 3 |
| Seeding: WHICH champions, and it is a recorded pre-committed decision | PART 3 |
| The optimisers and the initial step size | PART 3 |
| Protocol, and the order is load-bearing | PART 3 |
| The archive | PART 3 |
| Seeds and every random quantity, persisted | PART 3 |
| The self-checks, and each one can go red | PART 3 |
| The frozen constants | PART 3 |
| Decision rule, pre-committed, computed on held-out only, every outcome reachable | PART 4 |
| Secondary endpoints, reported with the verdict, never gating | PART 4 |
| Instrument failure, distinguished from a real negative | PART 4 |
| What would falsify what | PART 4 |
| The largest threat to validity, and what this design does about it | PART 5 |
| How the search under-convergence confound stays CLOSED | PART 5 |
| What a negative would mean, and what it would NOT mean | PART 5 |
| Compute budget | PART 5 |
| Out of scope, stated so it is not drifted into | PART 5 |
| Hypothesis | PART 5 |
| DESIGN gate verdict (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all nine changes applied above | PART 6 |
| The nine required changes and where each landed | PART 6 |
| The blind spots the gate named, and where each is answered | PART 6 |
| What this pass added BEYOND the nine changes, labelled so the boundary is visible | PART 6 |
| DESIGN gate verdict ROUND 2 (faber-adversary / Fable, 2026-07-30): BUILD_WITH_CHANGES, all six changes applied | PART 6 |
| The six required changes and where each landed | PART 6 |
| The four blind spots the gate named, and where each is answered | PART 6 |
| What this pass added BEYOND the six changes, labelled so the boundary is visible | PART 6 |
| DESIGN gate verdict ROUND 3 (faber-adversary / Fable, 2026-07-30): REDESIGN, scoped to the negative's panel discriminator; all seven changes applied | PART 6 |
| The seven required changes and where each landed | PART 6 |
| The gate's landing check and coherence read, and where each finding is answered | PART 6 |
| What this pass added BEYOND the seven changes, labelled so the boundary is visible | PART 6 |
| Result | PART 6 |

## Records beside this pre-registration

| File | What it is |
|---|---|
| `exp067_null_a_calibration.txt` | Null A fitted, bootstrapped and gated on phase 0's persisted 20-champion matrix. RNG `exsss` seeded `{3661, 0, 0}`, 200 draws, end state persisted. |
| `exp067_null_a_verification.txt` | An independent check of that calibration sharing no code with it, plus a closed form with no RNG. 139 tested comparisons, 0 disagreements. |
| `exp067_panel_discriminator_redesign.txt` | Why the mean-centred branch 6 / 7 discriminator was withdrawn and what the replacement survives. No RNG: the exceedance leg's 200-permutation maximum is bounded below by the exact closed-form mean rather than sampled. md5 `686d59647c96da380b54a5821e081b3c`, gated against three persisted records including 60 of 60 per-champion rows of `exp066_residue_and_inv0.txt` section C. |
| `exp067_split_losslessness.txt` | The proof that BOTH splits lost nothing, and the list of every cross-reference repointed after each. |
