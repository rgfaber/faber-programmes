# EXP-068. Does a Robo Rumble match replay bit-identically on hardware we do not control?

**Status: PRE-REGISTERED 2026-07-30. NOT RUN. DESIGN gate not yet passed.**

Small by design. **ONE endpoint, ONE bar, three pre-committed readings.** The four gate rounds
EXP-067 needed were caused by one experiment carrying a compound question and a compound decision
rule, so every repair to one branch broke another. This document deliberately answers one thing.

---

## Why this exists

The Robo Rumble front's mesh half rests on a single property: **a match result is verifiable by
recomputation on a machine you do not trust.** That is the whole reason the engine is integer-only,
carries a checked-in sine table, and forbids libm, floats, clocks, randomness and processes anywhere
in the match path. `PLAN_ROBO_RUMBLE.md` section 3 calls determinism a day-one design decision
rather than a property to retrofit, and section 7's commit-reveal scheme is worthless without it: if
two honest hosts compute different results, a leaderboard cannot distinguish a cheat from a
platform.

**That property has never been measured off one machine.** Four golden vectors exist and all four
have only ever been checked on the author's box (Linux, OTP 28, erts 16.1). There is **no CI
configuration anywhere in `faber-tweann`**, so there has never been a second observer. A design
argument for determinism is not a measurement of it, and this front's own standard is that a claim
the record cannot reproduce is an assertion.

This is cheap, it is a precondition for everything in the mesh half, and if it fails we want to know
before a leaderboard is built on it rather than after.

---

## The question, asked so that every answer is signable

Do the four frozen golden vectors reproduce **exactly** on platforms other than the author's?

- `robo_sim_tests` GOLDEN_HASH, a full match trace hash: the whole simulation.
- `robo_net_tests` GOLDEN_FORWARD: the forward pass, named by the plan as the real determinism
  hazard because a controller calling `math:tanh/1` would come out of libm.
- `robo_match_tests` golden match vector `DFCD8106…B3895E88`: the match loop, the scoring rule and
  the start ensemble together.
- `robo_pilot_tests` GOLDEN_CHANNELS: the sensor encoder, extracted into the engine on 2026-07-30.

---

## The primary endpoint

**The number of golden-vector mismatches across the tested platform matrix, on the MATCH PATH.**
Pre-committed bar: **zero**. Any non-zero value blocks the mesh half.

"Match path" is doing real work in that sentence and is defined in the next section, because one of
the four tests is deliberately not on it.

---

## THE DISTINCTION THIS EXPERIMENT EXISTS TO PRE-COMMIT

Without this section a red result on another platform would be ambiguous, and the tempting repair
would be exactly the wrong one.

`robo_net_tests` **recomputes the tanh table against libm at test time.** Its own header says so:
"Floats appear in this file and only in this file, in the recomputation oracle. That is the point:
the table is CHECKED against libm here, at test time, and never consults libm at match time."

libm is **not** bit-identical across libc versions. That is the exact hazard the integer engine was
built to avoid. So the oracle can legitimately disagree across platforms **while the engine remains
perfectly deterministic**, because the engine never calls it. Three outcomes, distinguished in
advance:

| # | What differs | Reading | Response, PRE-COMMITTED |
|---|---|---|---|
| **(i)** | nothing | Determinism holds on the tested matrix. The mesh half's precondition is met, and CI keeps measuring it. | Proceed. |
| **(ii)** | ONLY the tanh recomputation oracle, while GOLDEN_FORWARD and the three match-path vectors all pass | **The table is right and the ORACLE differs.** This is a platform difference in libm, not in the engine, and it is the anticipated case. | Platform-gate or widen the ORACLE's tolerance, and record the platform and the magnitude. **NEVER change the table.** Changing the table to satisfy a local libm would import the exact non-determinism the table exists to remove. |
| **(iii)** | ANY match-path vector: GOLDEN_HASH, GOLDEN_FORWARD, the match vector, or GOLDEN_CHANNELS | **Determinism is broken.** | The mesh half is BLOCKED. The specific differing vector localises the cause, since the four cover simulation, forward pass, match loop and encoder separately. |

Outcome (ii) is a real possibility rather than a hedge, and pre-committing it is most of this
document's value: a future reader seeing a red CI on a new platform must not "fix" it by editing a
frozen constant.

---

## Protocol

**The instrument is CI, not a one-off run.** A single manual run on a second box would answer the
question once. A CI matrix answers it continuously, on every commit, forever, and turns a one-time
reading into a standing regression check. That is strictly better for the same effort and it is what
this experiment installs.

1. Add a GitHub Actions workflow to `faber-tweann` running `rebar3 eunit` over a matrix of OTP
   releases and at least two runner images.
2. The matrix must include the author's own configuration (OTP 28) so a difference is attributable
   to the platform rather than to a version bump, and at least two other OTP releases.
3. Record which platforms ran, which passed, and the exact differing value for any mismatch.
4. The result is the CI run itself. The record for this experiment is the workflow file, the run
   URLs and a persisted summary.

**Order matters and is load-bearing.** The matrix runs the EXISTING suite unchanged. No golden
vector may be edited as part of installing this experiment, because a vector edited while the
instrument is being built is a vector fitted to the instrument.

---

## Instrument failure, distinguished from a real negative

Each of these makes the run UNGRADEABLE rather than negative, and each is checkable.

- **IF-1 CI DID NOT ACTUALLY RUN THE SUITE.** A misconfigured workflow that compiles and runs
  nothing exits 0. **Assert the reported test count is at least 1063**, the count on the author's
  machine at the time of writing. A silent zero-test pass is the single most likely way this
  experiment reports a false green.
- **IF-2 CACHE MASKED A REBUILD.** A restored `_build` can replay a previous platform's artefacts.
  Build from clean.
- **IF-3 NIF OR CRYPTO UNAVAILABLE.** The estate has a recorded gotcha that NIFs must be built from
  source or eunit's crypto usage fails. A crypto failure is an environment fault, not a determinism
  finding. `robo_sim:trace_hash/1` uses `crypto:hash/2`, so this is on the path.
- **IF-4 ONLY ONE PLATFORM ACTUALLY EXECUTED.** A matrix that silently collapses to one entry
  answers nothing. Assert at least three distinct (OTP, image) combinations reported.

---

## What would falsify what

- **Falsifies "the engine is deterministic across machines":** outcome (iii), any match-path vector
  differing on any platform.
- **Does NOT falsify it:** outcome (ii), the libm oracle alone differing.
- **Falsifies "this experiment measured anything":** any instrument-failure code firing.

---

## Out of scope, stated so it is not drifted into

- **Architectures other than those the CI images offer.** A green matrix on x86-64 Linux says
  nothing about ARM, and the claim must be scoped to what ran. Big-endian is untested and
  `term_to_binary` framing is a plausible hazard there.
- **Adversarial hosts.** This measures whether two HONEST machines agree. It says nothing about a
  host that lies about a result, which is what commit-reveal and a verifier are for.
- **Performance.** Throughput differences across platforms are irrelevant to this endpoint.
- **Any claim about the SCIENCE.** This is a precondition for the mesh half and bears on no result
  in insight 066.

---

## Hypothesis, with a prediction that can be wrong

**H1.** All four vectors reproduce on every tested platform, outcome (i). The engine is integer-only
by construction and every quantity in the match path is an Erlang integer, whose arithmetic is
defined by the language rather than by the host.

**H2, the interesting one.** If anything differs it will be the tanh recomputation oracle and
nothing else, outcome (ii), because it is the only float in the repository and libm is the only
component in the stack with a licence to differ.

**Both can be wrong.** `robo_sim:trace_hash/1` hashes a term, and this front has already been bitten
once by `term_to_binary` not being canonical for maps: a golden match vector was non-deterministic
between eunit and a plain shell until it was flattened to tuples and the `deterministic` option was
added. If that class of bug survives anywhere else in the hashing path, outcome (iii) fires and H1
is refuted.

---

## DESIGN gate verdict

*(empty; to be filled by the adversary before any workflow is written)*
