# EXP-068. Does a Robo Rumble match replay bit-identically on hardware we do not control?

**Status: PRE-REGISTERED 2026-07-30. NOT RUN. DESIGN gate: round 1 (2026-07-30)
BUILD_WITH_CHANGES, six changes applied below and recorded in the verdict section; round 2
(2026-07-30) BUILD_WITH_CHANGES, changes NOT applied. No workflow written yet, and none may be
written until they are.**

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
have only ever been checked on the author's box. That box runs **OTP 29.0.2, erts 17.0.2**, pinned
in `faber-tweann/.tool-versions`. The repository moved to OTP 29 on 2026-07-21 (commit `20fdfe3`,
from a pinned 27.3.4.3), and all four vectors were first committed on 2026-07-29 and 2026-07-30,
after that migration. **So no vector has ever been evaluated under any OTP release other than 29.**
There is **no CI configuration in `faber-tweann`** (`.github/workflows/` does not exist), so there
has never been a second observer.

A design argument for determinism is not a measurement of it, and this front's own standard is that
a claim the record cannot reproduce is an assertion.

---

## The question, asked so that every answer is signable

Do the four frozen golden vectors reproduce **exactly** on platforms other than the author's?

| Vector | Test | How it is compared |
|---|---|---|
| `robo_sim_tests` GOLDEN_HASH, a full match trace hash | `golden_replay_vector_test` | sha256 over `term_to_binary` |
| `robo_net_tests` GOLDEN_FORWARD, the forward pass | `golden_forward_vector_test` | sha256 over `term_to_binary` |
| `robo_match_tests` golden match vector `DFCD8106…B3895E88` | `golden_match_vector_test` | sha256 over `term_to_binary` |
| `robo_pilot_tests` GOLDEN_CHANNELS, the sensor encoder | `golden_channels_test` | **a literal list of 17 integers, compared directly** |

That last row matters and is not a detail. `golden_channels_test` is
`?assertEqual(?GOLDEN_CHANNELS, robo_pilot:channels(...))` against
`[64, 256, 0, 0, -100, -75, 0, 256, 256, 0, 256, 0, 256, 0, 128, 0, 0]`
(`faber-tweann/test/robo_pilot_tests.erl:58-61, 88-89`). **No hash, no serializer.** It is therefore
a serializer-free control on the other three, which is load-bearing below.

---

## The primary endpoint

**The number of golden-vector mismatches across the tested platform matrix, on the MATCH PATH.**
Pre-committed bar: **zero**. Any non-zero value blocks the mesh half.

"Match path" is doing real work in that sentence and is defined below, because two of the tests in
the suite are deliberately not on it.

---

## What this matrix can and cannot falsify

Stated up front, because the title says "hardware we do not control" and GitHub-hosted runners are
close to the most controlled, homogeneous hardware available.

**It CAN falsify:**

- **The hashing and serialization chain.** `term_to_binary` output bytes are not guaranteed stable
  across OTP releases. Decode compatibility is guaranteed; encode bytes are not, and two of the
  three hashed terms contain atoms, whose external encoding has changed across releases before.
  This is the single most plausible way this matrix goes red.
- **crypto availability.** `robo_sim:trace_hash/1` calls `crypto:hash/2`, so an image whose OpenSSL
  or NIF build differs is on the path.
- **The two float oracles.** They call libm at test time, and libm is not bit-identical across libc
  versions.
- **Suite invocation.** Whether the endpoint tests actually run at all on a foreign machine.

**It CANNOT falsify:**

- **The pure integer arithmetic of the match path.** `grep` over `faber-tweann/src/robo_*.erl` finds
  no `math:`, `rand:`, `os:timestamp` or monotonic-time call anywhere; the single `math:` hit is the
  word "math:tanh" inside a comment in `robo_net.erl:5`. What remains is `band`, `bsr`, `bsl`,
  `div`, `rem`, `*`, `+`, `-`, `element/2` and `lists` functions, all exactly specified by the
  language, arbitrary-precision so no overflow, and unaffected by whether BeamAsm or the interpreter
  executes them. **No conforming BEAM can falsify this part, on this matrix or any other.** The
  matrix is not evidence about it, and this document must not be read as though it were.
- **Big-endian hosts and non-BEAM verifiers.** Neither is in the matrix.
- **Anything about hosts outside the named matrix.**

A consequence worth stating: this harness's value as a future regression check against a float
leaking into the match path is **weak** on an all-x86-64 glibc matrix, because IEEE double
arithmetic is bit-identical across those images and only a libm transcendental would diverge. The
ARM cell is what gives that check any teeth.

---

## THE DISTINCTION THIS EXPERIMENT EXISTS TO PRE-COMMIT

Without this section a red result on another platform would be ambiguous, and the tempting repair
would be exactly the wrong one.

**Two float oracles exist in the suite, not one.**

1. **The tanh recomputation** in `robo_net_tests:tanh_table_recomputes_test/0`, asserting
   `round(4096 * math:tanh(I / 32)) =:= robo_net:tanh(I * 128)` exactly, entry by entry.
2. **The angle_of oracle** in `robo_match_tests:angle_of_is_unbiased_test/0`, whose helper `err/2`
   computes `math:atan2(Y, X) * 256 / (2 * math:pi())` and asserts `max(Errs) =< 0.5`,
   `min(Errs) >= -0.5` and `abs(Mean) < 0.01` (`test/robo_match_tests.erl:142-152`).

Both are test-time only. Neither is consulted at match time. So either can legitimately disagree
across platforms **while the engine remains perfectly deterministic**.

Three outcomes, distinguished in advance. They partition every result the endpoint can take;
anything they do not cover is an instrument failure, not a reading.

| # | What differs | Reading | Response, PRE-COMMITTED |
|---|---|---|---|
| **(i)** | nothing | Determinism holds **on the tested matrix**. Not "the mesh precondition is met" without qualification: no non-x86-64 host beyond the single ARM cell has been observed, and **ranked visits must not admit a host outside the observed set until it has been observed**. | Proceed, scoped. CI keeps measuring. |
| **(ii)** | ONLY a FLOAT-ORACLE test, either the tanh recomputation or `angle_of_is_unbiased_test`, while all four golden vectors pass | **The table is right and an ORACLE differs.** A platform difference in libm, not in the engine. | Bounded response, next section. **NEVER change the table.** Changing the table to satisfy a local libm would import the exact non-determinism the table exists to remove. |
| **(iii)** | ANY of the four golden vectors | **The match path did not reproduce.** The mesh half is BLOCKED either way, but the cause must be discriminated before it is read, per the next section. | BLOCK the mesh half. Discriminate engine from serializer before writing any conclusion. |

---

## Engine or serializer: pre-committed, because the record must be able to tell them apart

This front has already been bitten once by `term_to_binary` non-canonicity, within a single release:
the first golden match vector hashed result maps directly and produced a different digest under
eunit than under a plain `erl`, from byte 14 onward, while the terms compared byte-identical when
printed (`test/robo_match_tests.erl:168-180`). Flattening to tuples plus the `deterministic` option
closed the **map-ordering** case. It does **not** promise cross-release byte identity of
`term_to_binary`, which is a different hazard and the live one here. So outcome (iii) is not
self-explanatory, and recording only the differing hash would make the correct reading unrecoverable
from the record forever.

**Pre-committed, before any run:**

- On ANY golden-vector mismatch, the workflow persists the **pre-hash flattened terms** for every
  golden vector, not only the hash. For the three hashed vectors that is the term passed to
  `term_to_binary`; for GOLDEN_CHANNELS the value is already the plain list.

  *How, without editing a test.* The helpers that build those terms (`replay/0`, `forward_trace/0`,
  `match_trace/0`) are private: `eunit_autoexport` exports only `*_test` and `*_test_` functions, so
  a diagnostic cannot call them. It must instead **reconstruct the terms through the engine's public
  API**, which is enough, because every input is public (`robo_sim:new/1`, `robo_sim:step/2`,
  `robo_net:eval_q12/3`, `robo_match:match/3`, `robo_match:starts/0`, `robo_pilot:channels/2`). This
  keeps the order-matters rule intact: no test and no vector is touched. **The cost is a drift
  hazard**, since a reconstruction that diverges from the helper would compare the wrong terms, so the
  diagnostic must assert it reproduces the reference hash on a cell that passes, before its output
  is read on a cell that fails. Recorded here so the workflow cannot skip it.
- **If the pre-hash terms compare EQUAL across platforms while the hashes differ**, the finding is
  *"the hash instrument's serialization differs across OTP releases"*. That still **BLOCKS the mesh
  half**, because the mesh verifier compares exactly these hashes between hosts, so serializer
  instability is genuinely blocking. But it does **not** read as "the engine's determinism is
  broken", and it does not void the integer-engine design. The repair is to replace `term_to_binary`
  with a hand-rolled canonical integer encoding, not to touch the engine.
- **If the pre-hash terms DIFFER**, engine determinism is refuted. Mesh half blocked.

**Correcting the localisation claim.** An earlier draft of this document said the specific differing
vector localises the cause. That is only partly true, and the source says why. **Three** of the four
vectors hash through the same `crypto:hash(sha256, term_to_binary(_, [deterministic,
{minor_version, 2}]))` call shape (`src/robo_sim.erl:376`, `test/robo_net_tests.erl:157`,
`test/robo_match_tests.erl:187`), so a serializer change fires all three at once and localises
nothing about the simulation.

The gate's round-1 finding stated this of all four. Against the source that is wrong in a way that
helps: **GOLDEN_CHANNELS has no serializer in its path at all.** That makes it a free control.

- **Three hashed vectors fail together, GOLDEN_CHANNELS passes** → points hard at the serializer,
  not the simulation. Confirm with the persisted pre-hash terms.
- **GOLDEN_CHANNELS also fails** → the serializer cannot be the whole explanation, because it is not
  in that test's path.
- **GOLDEN_HASH and the match vector fail while GOLDEN_FORWARD and GOLDEN_CHANNELS pass** → a second
  free discriminator, and it points specifically at **atom encoding**. The sim and match terms carry
  atoms (`tank.id` is `a`/`b`, plus the `dead` and `alive :: boolean()` fields,
  `src/robo_match.erl:52-53, 172`), whereas `eval_q12/3` is specced
  `[non_neg_integer()], [integer()], [integer()] -> [integer()]` (`src/robo_net.erl:350`), so
  GOLDEN_FORWARD hashes **integers only and no atoms**. This split was not designed in; it falls out
  of what each vector happens to contain, and it costs nothing to read.

---

## The oracle response, bounded in advance

Widening an oracle tolerance is different in kind from changing a table, and this document is
entitled to that asymmetry provided it states it. The table is **the game**: on the match path,
inside the engine hash, and changing an entry changes every result. An oracle is **the instrument**:
test-time only, touching no replay. But that asymmetry does not on its own save an unbounded "widen
the tolerance", because widened far enough the recomputation check is vacuous and the table is
verified by nothing. So the bound is fixed now, before any reading:

- **tanh recomputation.** Tolerance may widen to **at most plus or minus 1 table unit**, one LSB of
  the 4096 scale. Any platform requiring more is **platform-gated, not accommodated**. The magnitude
  and the platform are recorded either way.
- **angle_of.** The `=< 0.5` bound may be treated as tolerated **only if the observed excess is
  smaller than one ULP of the computed quantity**, that is, only if the failure is a rounding-tie
  flip rather than a real bias. Anything larger is platform-gated. **The mean-bias assertion
  `abs(Mean) < 0.01` may NOT be widened at all**, because it tests the integer rounding fix, not
  libm.

### Which oracle is the live candidate, and a contradiction resolved

`src/robo_net.erl:104-107` states of the tanh table: *"No entry sits nearer than 0.00594 of a
rounding tie, so no two libm implementations can disagree about any of these values and the test is
safe to assert exactly."*

If that margin analysis is right, **outcome (ii) is near-impossible at the tanh oracle**, and an
earlier draft of this document was wrong to call it "the anticipated case". This document defers to
the source: the margin analysis is a computed claim about the table, and nothing here contradicts
it. **H2 is corrected accordingly below.**

The live (ii) candidate is instead the **angle_of oracle, whose tie margin has never been
computed.** Its structure makes it tie-sensitive by construction: `angle_of/1` rounds to nearest, so
`|D| =< 0.5` holds with **equality attainable at an exact tie**, and at such a point a 1-ULP
difference in `atan2` pushes the assertion past its bound. Unlike the tanh table, no analysis
anywhere in the repository says how near the 6560-point grid gets to such a tie (81 by 81 minus the
origin, `test/robo_match_tests.erl:143-144`).

**Pre-committed:** the angle_of tie margin is not computed here, because computing it is analysis of
an existing test rather than part of this experiment, and this front does not write experiment code
before the gate returns BUILD. If `angle_of_is_unbiased_test` goes red on any cell, **the margin is
computed at that point and recorded**, and the bound above decides the response. If it never goes
red, the margin stays unanalysed and this document says so rather than implying it was checked.

---

## Protocol

**The instrument is CI, not a one-off run.** A single manual run on a second box would answer the
question once. A CI matrix answers it continuously, on every commit, and turns a one-time reading
into a standing regression check. That is what this experiment installs.

**The named matrix, pre-registered so it is not a free variable chosen at build time.** Five cells,
an anchored cross rather than a full 3x3, because the two axes probe different hazards and a full
cross buys repetition rather than reach:

| Cell | OTP | Runner image | What it adds |
|---|---|---|---|
| 1 | 29 | `ubuntu-24.04` | the author's release; baseline |
| 2 | 28 | `ubuntu-24.04` | OTP axis: serializer encoding across releases |
| 3 | 27 | `ubuntu-24.04` | OTP axis, one release further back |
| 4 | 29 | `ubuntu-22.04` | libc/libm/OpenSSL axis |
| 5 | 29 | `ubuntu-24.04-arm` | different CPU, toolchain and OpenSSL build |

Three distinct OTP releases, three distinct images, satisfying IF-4.

- **OTP 29 is the author's release and must be in the matrix** so a difference is attributable to
  the platform rather than to a version bump. Note the limit of that attributability: a runner image
  on OTP 29 shares a *version number* with the author's box, not a *configuration*. Attribution
  holds along the OTP axis only, and this document claims no more.
- **Floor: OTP 24.1.** `term_to_binary`'s `deterministic` option requires it. No earlier release may
  enter the matrix; it would `badarg` the hash path for an instrument reason and produce a red the
  table cannot classify. All five cells clear the floor by a wide margin.
- The ARM cell is free for public repositories. If the toolchain cannot be provisioned there for a
  given release, that cell is **IF-3, ungradeable**, not a result.

**What the workflow runs.** The four endpoint modules: `robo_sim_tests`, `robo_net_tests`,
`robo_match_tests`, `robo_pilot_tests`. These contain all four golden vectors and both float
oracles, so they cover the entire endpoint and both (ii) candidates.

*Why not the whole suite.* An earlier draft made the instrument a full `rebar3 eunit` over "at least
1063 tests". That is a bad instrument, and the reason is measured rather than assumed: on the
author's own box a full `rebar3 eunit` **does not finish within 1200 seconds**, the longest bound
tried. Reproduces from `scripts/exp068_suite_runtime_probe.sh`; reading in `suite_runtime_probe.txt`
beside this document. A CI cell that cannot finish in twenty minutes on the author's hardware is not
an instrument for a four-vector endpoint, and on a 2-core public runner it is worse.

Separately and structurally, the suite carries process-based TWEANN tests whose neurons abandon a
tick on a **wall clock** (`src/neuron.erl:348`, `src/neuron_ltc.erl:318`, "input timeout after
~pms"). Wall-clock timeouts on a shared runner are the classic source of a red that means nothing,
which is what IF-5 exists for. **One number is deliberately absent here:** an unbounded ad-hoc run
emitted several hundred such warnings, but the bounded probe recorded **zero** at both 300 s and
1200 s, most likely because those runs spent their budget compiling and never reached the
neuroevolution tests. That count is therefore not reproducible from the record and is **not claimed**
as a number. The runtime alone settles the instrument choice.

Narrowing to the endpoint's own modules **removes no endpoint and adds no branch**; it makes the
instrument match the question, and it retires the unsourced 1063 figure with it.

**Order matters and is load-bearing.** The matrix runs the EXISTING tests unchanged. No golden
vector may be edited as part of installing this experiment, because a vector edited while the
instrument is being built is a vector fitted to the instrument.

**Recording.** Persist which cells ran, which passed, the pre-hash terms per RC3 on any mismatch,
and the run URLs. The record for this experiment is the workflow file, the run URLs and a persisted
summary beside this document, plain text plus one machine-readable Erlang term.

---

## Instrument failure, distinguished from a real negative

Each of these makes the affected cell UNGRADEABLE rather than negative, and each is checkable.

- **IF-1 CI DID NOT ACTUALLY RUN THE ENDPOINT.** A misconfigured workflow that compiles and runs
  nothing exits 0. **Assert, per cell, that all four named tests executed and passed:
  `golden_replay_vector_test`, `golden_forward_vector_test`, `golden_match_vector_test`,
  `golden_channels_test`**, checked against that cell's eunit verbose log by name. The earlier
  draft's "test count at least 1063" is **withdrawn, not demoted**: a count is gameable (the suite
  grows while the robo modules are silently filtered out, a false green on exactly the endpoint) and
  brittle (a refactor fails it spuriously, and the recorded repair would be to edit the threshold,
  training the re-pinning reflex the golden vectors exist to resist). RC5 permitted keeping it as a
  secondary check; under the narrowed instrument it measures nothing the four names do not.
- **IF-2 CACHE MASKED A REBUILD.** A restored `_build` can replay a previous platform's artefacts.
  Build from clean.
- **IF-3 TOOLCHAIN, NIF OR CRYPTO UNAVAILABLE.** The estate has a recorded gotcha that NIFs must be
  built from source or eunit's crypto usage fails. `robo_sim:trace_hash/1` uses `crypto:hash/2`, so
  this is on the path. A crypto failure, or a cell where the OTP release cannot be provisioned at
  all, is an environment fault, not a determinism finding. **A silent fallback to a different crypto
  implementation is also IF-3**; the check is that crypto is present and native, not merely that the
  call returned.
- **IF-4 THE MATRIX COLLAPSED.** A matrix that silently reduces to one entry answers nothing. Assert
  at least three distinct (OTP, image) combinations reported.
- **IF-5 A RED OUTSIDE THE ENDPOINT.** Any failing test that is neither one of the four golden
  vectors nor one of the two named float oracles renders that cell **UNGRADEABLE**, and it lands
  nowhere in the three-outcome table. Without IF-5 the tempting move is a post-hoc classification
  into whichever row fits, which is what pre-registration exists to prevent.

  Narrowing the instrument to the four modules already removes most of what IF-5 was written for:
  `grep` finds no mnesia use in any `test/robo_*.erl`, so the mnesia-dependent genotype tests cannot
  reach a cell. **One live case remains inside the instrument**, and it is the reason IF-5 is kept
  rather than dropped: `robo_match_tests` carries four `{timeout, 300}` gauntlet generators
  (`test/robo_match_tests.erl:28, 37, 51, 77`), which run the full field over the full start
  ensemble. On a 2-core public runner one of those can expire without any vector being wrong. That
  is IF-5, ungradeable, not outcome (iii).

---

## What would falsify what

- **Falsifies "the engine is deterministic across the tested matrix":** outcome (iii) **with the
  persisted pre-hash terms differing.**
- **Does NOT falsify it, but still blocks the mesh half:** outcome (iii) with the pre-hash terms
  equal and only the hashes differing. That is a serializer finding.
- **Does NOT falsify it:** outcome (ii), a float oracle alone differing.
- **Falsifies "this experiment measured anything" for that cell:** any instrument-failure code.

---

## Out of scope, stated so it is not drifted into

- **Architectures beyond the five named cells.** A green matrix says nothing about a host outside
  it. Big-endian is untested and `term_to_binary` framing is a plausible hazard there.
- **Adversarial hosts.** This measures whether two HONEST machines agree. It says nothing about a
  host that lies about a result, which is what commit-reveal and a verifier are for.
- **Two different applications agreeing.** Every cell runs the same test-suite entry point, which is
  the friendliest possible caller. The actual mesh transaction is two *different* Erlang
  applications embedding the same engine version and agreeing; nothing in this front checks that
  yet. Recorded here as a known gap, not answered.
- **Performance.** Throughput differences across platforms are irrelevant to this endpoint.
- **Any claim about the SCIENCE.** This is a precondition for the mesh half and bears on no result
  in insight 066.

---

## Hypothesis, with a prediction that can be wrong

**H1.** All four vectors reproduce on every tested cell, outcome (i). The engine is integer-only by
construction and every quantity in the match path is an Erlang integer, whose arithmetic is defined
by the language rather than by the host. **H1's arithmetic core is not falsifiable by this matrix**
and is not offered as a prediction the matrix tests; what the matrix tests is the surrounding
instrument chain.

**H2, corrected.** If anything differs it will be **the hashing chain**, not the engine: a
cross-release `term_to_binary` encoding change firing hashed vectors while GOLDEN_CHANNELS passes.
If the change is specifically in atom encoding, the sharper prediction is that **GOLDEN_HASH and the
match vector fail while GOLDEN_FORWARD passes**, because only the first two hash atoms. An earlier
draft predicted the tanh oracle instead, which contradicts `robo_net.erl:104`'s own margin analysis;
that draft was wrong and this is the correction. If a float oracle does differ, `angle_of` is the
likelier locus than tanh, because its tie margin has never been computed.

**Both can be wrong**, and the honest prior is that outcome (i) is likeliest, because the matrix is
homogeneous and the arithmetic is language-defined.

---

## DESIGN gate verdict

### Round 1, 2026-07-30. **BUILD_WITH_CHANGES.**

The gate found the three-outcome table was not a partition, that outcome (i) claimed more than the
matrix supports, that the most likely genuine failure mode is the serializer rather than the engine
and would have been filed under the one reading the evidence would not support, and that the central
instrument-failure check did not check the endpoint. All six required changes are applied. None adds
a branch, a sub-label or a second bar.

| RC | Where it landed |
|---|---|
| **RC1** rescope (i); add ARM; state what the matrix can and cannot falsify | New section *"What this matrix can and cannot falsify"*. Row (i) rewritten to "on the tested matrix" with the ranked-visits restriction. Cell 5, `ubuntu-24.04-arm`, added to the named matrix. |
| **RC2** repartition | Outcome (ii) redefined as "ONLY a FLOAT-ORACLE test", naming both the tanh recomputation and `angle_of_is_unbiased_test`. **IF-5** added: any red outside the four vectors and two oracles makes the cell ungradeable, explicitly including a `{timeout, 300}` expiry. |
| **RC3** engine-versus-serializer discrimination | New section *"Engine or serializer"*. Pre-hash terms persisted on any mismatch; terms-equal-hash-differs pre-committed as a serializer finding that still blocks the mesh but does not refute the engine; the localisation claim in row (iii) corrected. |
| **RC4** bound the oracle response; reconcile the contradiction | New section *"The oracle response, bounded in advance"*. tanh tolerance capped at plus or minus 1 table unit; angle_of tolerated only within one ULP; mean-bias assertion may not widen at all. Contradiction resolved **in favour of the source**: `robo_net.erl:104` is right, this document's earlier "anticipated case" was wrong, and `angle_of` is named as the live (ii) locus. |
| **RC5** replace the count | **IF-1** now asserts the four named tests executed and passed per cell, against the eunit verbose log. RC5 allowed keeping the count as a secondary check; it is **withdrawn instead**, because the narrowed instrument makes it measure nothing the four names do not. Recorded in IF-1 rather than done silently. |
| **RC6** name the exact matrix; note the OTP 24.1 floor | *Protocol*, "The named matrix" table: five cells, three OTP releases, three images, plus the OTP 24.1 floor for `term_to_binary`'s `deterministic` option. |

### Where the gate was wrong against the source, corrected rather than complied with

Per the standing rule that a factual claim about the engine is fixed against the source and not
against a paraphrase of it:

1. **RC3 states that all four golden vectors hash through the same `term_to_binary` call shape.**
   Three do. **`golden_channels_test` does not hash at all**: it compares a 17-integer literal
   directly (`test/robo_pilot_tests.erl:58-61, 88-89`). The correction strengthens RC3 rather than
   weakening it: GOLDEN_CHANNELS is a serializer-free control, so "three fail together, channels
   passes" discriminates the serializer for free. Applied that way.
2. **RC4 attributes the 0.00594 tie-margin claim to `robo_net_tests`' header.** It is in
   `src/robo_net.erl:104-107`. Cited to the source.

### Facts this document had wrong, found while applying the changes

3. **The author's box is not OTP 28 / erts 16.1.** It is **OTP 29.0.2, erts 17.0.2**, pinned in
   `.tool-versions`. The repository went from 27.3.4.3 straight to 29 on 2026-07-21 (`20fdfe3`) and
   every golden vector was committed on 2026-07-29 or later, so **the vectors have only ever run
   under OTP 29** and the OTP axis is entirely unobserved. Left uncorrected, protocol step 2 would
   have pinned the matrix to the wrong anchor and destroyed the attributability it exists to give.
4. **The full suite is not a usable instrument.** Measured, not assumed: `rebar3 eunit` on the
   author's box does not finish within 1200 s. Reproduces from
   `scripts/exp068_suite_runtime_probe.sh`; reading in `suite_runtime_probe.txt` beside this
   document. The instrument is narrowed to the four endpoint modules, which removes no endpoint. The
   unsourced "1063 tests" figure is withdrawn with it. A second number was **dropped rather than
   reported**: an ad-hoc run showed several hundred neuron wall-clock timeout warnings, the bounded
   probe reproduced zero, so the count is not in the document. The wall-clock timeout *mechanism* is
   still cited, from the source rather than from a run.

### Not negotiated away, and one thing deliberately not done

Every required change is applied in full. One is applied in a bounded form, stated rather than
hidden: **RC4(b) offered a choice between computing the angle_of tie margin and naming angle_of as
the expected (ii) locus.** This document takes the naming option, because computing the margin is
analysis this front's standing rule keeps behind the gate, and pre-commits that the margin is
computed and recorded the moment that oracle goes red. It does not claim the margin was checked.

### Size

**450 lines, against a budget of roughly 300.** Saying so is the required response rather than
trimming substance to hit the number. The growth is the six required changes: four add a section
apiece (what the matrix can and cannot falsify, engine-versus-serializer, the bounded oracle
response, the named matrix), IF-5 adds a fifth instrument code, and the verdict record is about a
fifth of the file. A redundancy pass was run first and recovered only a few lines, so the remainder
is content, not padding.

**The experiment has not grown: still one endpoint, one bar, three readings, no sub-labels, no
second question.** The document got longer because the gate required it to say more about the same
single measurement. If round 2 wants it shorter, the compressible parts are the verdict record and
the two "corrected against source" subsections, not the decision rule.

### Round 2, 2026-07-30. **BUILD_WITH_CHANGES.**

The second round ran against the document as amended by round 1 above and returned
BUILD_WITH_CHANGES a second time.

**Its required-change list is NOT recorded here, and the reason is stated rather than papered
over: it is not in any file this front persisted.** Round 1's list survives because the agent that
applied it wrote each change and its landing site into the RC table above as it worked. Round 2's
verdict reached this record as a verdict and nothing else. Filling the table from memory is how a
gate record turns into fiction, so the gap is left visible instead.

What is therefore known, and all that is claimed:

| | |
|---|---|
| Round 2 verdict | BUILD_WITH_CHANGES, 2026-07-30 |
| Where the round-2 changes landed | **NOWHERE. None is applied.** Everything above this line is the round-1 document. |
| What is owed before this experiment may be built | the round-2 change list, recovered from the gate rather than re-derived, applied, and each landing site recorded in a table like round 1's |

**Consequence, and it is a block, not a note.** This front's standing rule is no experiment code
before the gate returns BUILD, and BUILD_WITH_CHANGES with the changes unapplied is not BUILD. So
no workflow file may be written for exp068 until the round-2 changes are applied and recorded here.
`scripts/exp068_suite_runtime_probe.sh` is not an exception to that rule and does not become one: it
measures the runtime of the EXISTING suite to justify narrowing the instrument, it compares no
golden vector, and it says so in its own header.

**Size, restated so the round-1 figure above is not read as current.** Round 1 recorded 450 lines.
This document is **478 lines** with this round-2 record in it (`wc -l` on this file). The round-1
figure is left as written, because it is a record of round 1 and not a live measurement.
