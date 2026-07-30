#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% EXP-067 phase 1: NULL A EXERCISED ON A REAL MATRIX, BEFORE THE RUNNER.
%%% READ-ONLY over persisted phase 0 records. No genome is loaded, no match is
%%% replayed, no arm is re-run, no engine module is touched.
%%%
%%% WHY THIS EXISTS. The EXP-067 pre-registration's DESIGN gate round 2
%%% (2026-07-30, verdict BUILD_WITH_CHANGES) raised RC2-4: Null A is the
%%% PRIMARY null of phase 1 and the only genuinely new numeric machine in the
%%% design, and two of its constants had never met real data.
%%%
%%%   - IF-9's fit gate width, 20 decisive edges of 190, was chosen with no
%%%     measurement of what a Bradley-Terry fit to a real matrix of this shape
%%%     actually reproduces.
%%%   - The 3-of-13 family-wise arithmetic rests on a per-run exceedance rate
%%%     of at most 1/201, which assumes the observed matrix is exchangeable
%%%     with the null's own draws. Never checked.
%%%
%%% A matrix of exactly the right shape (20 members, 190 pairs, 160 matches per
%%% cell) sits on disk. So the null is run on it here, before the runner is
%%% written, and the numbers go in the record whichever way they land. Phase 0's
%%% RC-3 and RC-8 forced the same precomputation for Null C and for the residue;
%%% this is the same move for Null A.
%%%
%%% WHAT IT IS NOT. This is not a phase 1 runner, it measures nothing new and
%%% it signs nothing. It is arithmetic plus a seeded bootstrap over the win-rate
%%% matrix persisted in exp066_crossplay.txt.
%%%
%%% WHAT WOULD MAKE THE PRE-REGISTRATION CHANGE. Two outcomes, both stated
%%% before the script is run:
%%%   1. IF-9 fires on this matrix (the median synthetic decisive-edge count at
%%%      band 0.10 differs from the observed by more than 20 of 190), which
%%%      would mean the gate width rejects a matrix the null is supposed to
%%%      describe, and the width has to be re-derived.
%%%   2. The observed cycle count exceeds the maximum of the 200 draws, which
%%%      would mean a real ladder-shaped matrix trips the per-run CYCLIC test
%%%      and the 1/201 rate the 3-of-13 arithmetic rests on is not the real
%%%      rate.
%%% Neither outcome is repaired by moving a number here. Either one is reported
%%% and the pre-registration is amended before it closes.
%%%
%%% NULL A, EXACTLY AS PRE-REGISTERED. No part of it is chosen here.
%%%   Input  the matrix as integer win counts K(I,J) out of 160.
%%%   N(I,J) = K(I,J) + K(J,I), the cell's DECISIVE matches. Draws are held
%%%          fixed and are not modelled.
%%%   Model  P(I beats J | decisive) = s_I / (s_I + s_J).
%%%   Fit    MM (Zermelo / Ford) iteration, ONE virtual win and ONE virtual loss
%%%          on every ORDERED pair, relative tolerance 1e-10 on every s_I,
%%%          iteration cap 10,000, normalised so sum(s) = T.
%%%   Draw   K*(I,J) ~ Binomial(N(I,J), p), K*(J,I) = N(I,J) - K*(I,J), so the
%%%          synthetic matrix carries the observed decisive count AND the
%%%          observed draw count of every cell, edge for edge.
%%%   Draws  200, off the registered seed {3661, MatrixIndex, 0} with
%%%          MatrixIndex 0 for this phase 0 matrix.
%%%   Count  the phase 1 INTEGER counter: strict > on |K(I,J) - K(J,I)| against
%%%          8 / 16 / 24 of 160. Bands fixed, never swept.
%%%
%%% Usage: scripts/exp067_null_a_calibration.escript [OutFile]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(ARCH, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").
-define(P1, ?REPO "/programmes/p7_coevolution/exp067_coevolution_cycling/").
-define(XP, ?ARCH "exp066_crossplay.txt").
-define(VERIFY, ?ARCH "exp066_within_tier_verify.txt").
-define(OUT, ?P1 "exp067_null_a_calibration.txt").

-define(MATCHES, 160).
-define(BANDS, [{0.05, 8}, {0.10, 16}, {0.15, 24}]).
-define(PRIMARY, 0.10).

-define(DRAWS, 200).
-define(RNG_ALG, exsss).
-define(RNG_SEED, {3661, 0, 0}).

-define(PRIOR, 1).
-define(TOL, 1.0e-10).
-define(CAP, 10000).
-define(FIT_GATE, 20).

%% GATE 1. The float counter over all 20 champions must reproduce
%% exp066_crossplay.txt's own counts: {cycles, ordered, forward, backward,
%% decisive}.
-define(STATED_FLOAT, [{0.05, {49, 73, 24, 25, 169}},
                       {0.10, {18, 28, 10, 8, 152}},
                       {0.15, {12, 18, 6, 6, 141}}]).

%% GATE 2. The integer counter over all 20 champions must reproduce
%% exp066_within_tier_verify.txt section K's exact rows: {decisive, cyclable,
%% cycles}. THESE are the observed values the gate width is applied to, because
%% the integer counter is what phase 1 pre-registers. The float counter's 152 at
%% band 0.10 is 150 on the integers, and both are printed.
-define(STATED_EXACT, [{0.05, {168, 789, 49}},
                       {0.10, {150, 582, 18}},
                       {0.15, {141, 487, 12}}]).

main(Args) ->
    Out = out(Args),
    {Seeds, Wm} = xp_matrix(?XP),
    Idx = lists:seq(1, length(Seeds)),
    Km = int_matrix(Wm, Idx),
    Dev = worst_dev(Wm, Idx),
    Gates = gates(Wm, Km, Idx),
    GLines = gate_lines(Seeds, Dev, Gates),
    io:put_chars(GLines),
    ok = gate(Dev, Gates),
    Fit = fit(Km, Idx),
    Boot = bootstrap(Km, Idx, Fit),
    FLines = fit_lines(Seeds, Km, Idx, Fit),
    BLines = boot_lines(Km, Idx, Boot),
    VLines = verdict_lines(Wm, Km, Idx, Fit, Boot),
    HLines = headline(Wm, Km, Idx, Fit, Boot),
    Lines = lists:append([head(Out, Seeds), HLines, GLines, FLines, BLines, VLines,
                          foot(),
                          term(Out, Seeds, Dev, Gates, Wm, Km, Idx, Fit, Boot)]),
    ok = file:write_file(Out, [Lines]),
    ok = parse_back(Out),
    io:format("~nwritten: ~ts~n", [Out]).

%% The record claims a machine-readable term at its foot. That claim is checked
%% by reading the written file back and parsing it, so an unparseable term fails
%% the run instead of shipping.
parse_back(Out) ->
    {ok, Bin} = file:read_file(Out),
    {null_a_calibration, F} = term_after_marker(binary_to_list(Bin)),
    io:format("term parsed back from the written file: ~p top-level keys~n",
              [length(F)]),
    ok.

out([P | _]) -> P;
out([]) -> ?OUT.

%%---------------------------------------------------------------------------
%% THE MATRIX. Parsed out of the persisted report's machine-readable term, never
%% retyped. Cells are WIN RATES of ROW against COLUMN over 160 matches. W(J,I)
%% is never inferred from W(I,J): 472 of the 30,400 matches were draws, so
%% W(I,J) + W(J,I) can fall short of 1.0, and that shortfall is the cell's draw
%% count, which Null A holds fixed.
%%---------------------------------------------------------------------------
xp_matrix(Path) ->
    {ok, Bin} = file:read_file(Path),
    {crossplay, F} = term_after_marker(binary_to_list(Bin)),
    Rows = [{S, Ws} || {row, _I, S, Ws} <- keyget(matrix, F)],
    {[S || {S, _} <- Rows], list_to_tuple([list_to_tuple(Ws) || {_S, Ws} <- Rows])}.

term_after_marker(Text) ->
    [_Prose, Rest] = string:split(Text, "== MACHINE-READABLE TERM"),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, Fields) -> element(2, lists:keyfind(K, 1, Fields)).

int_matrix(Wm, Idx) ->
    list_to_tuple([list_to_tuple([round(el(Wm, I, J) * ?MATCHES) || J <- Idx])
                   || I <- Idx]).

worst_dev(Wm, Idx) ->
    lists:max([abs(el(Wm, I, J) * ?MATCHES - round(el(Wm, I, J) * ?MATCHES))
               || I <- Idx, J <- Idx]).

%%---------------------------------------------------------------------------
%% THE COUNTERS. exp066's convention, parametrised by a margin function and a
%% band so the same code runs on the float grid and on the integer grid.
%%---------------------------------------------------------------------------
mg(M) -> fun(I, J) -> el(M, I, J) - el(M, J, I) end.

el(M, I, J) -> element(J, element(I, M)).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

triples(Idx) -> [{I, J, Z} || I <- Idx, J <- Idx, Z <- Idx, I < J, J < Z].

ordered(Mg, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]).

forward(Mg, Idx, B) ->
    [{I, J, Z} || {I, J, Z} <- triples(Idx),
                  Mg(I, J) > B, Mg(J, Z) > B, Mg(Z, I) > B].

backward(Mg, Idx, B) ->
    [{I, Z, J} || {I, J, Z} <- triples(Idx),
                  Mg(I, Z) > B, Mg(Z, J) > B, Mg(J, I) > B].

decisive(Mg, Idx, B) -> length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > B]).

cyclable(Mg, Idx, B) ->
    length([1 || {I, J, Z} <- triples(Idx),
                 abs(Mg(I, J)) > B, abs(Mg(J, Z)) > B, abs(Mg(I, Z)) > B]).

%% {cycles, ordered, forward, backward, identity_holds, decisive, cyclable}
counts(Mg, Idx, B) ->
    Fw = length(forward(Mg, Idx, B)),
    Bw = length(backward(Mg, Idx, B)),
    Ord = ordered(Mg, Idx, B),
    {Fw + Bw, Ord, Fw, Bw, 2 * Fw + Bw =:= Ord,
     decisive(Mg, Idx, B), cyclable(Mg, Idx, B)}.

%% The four quantities the bootstrap needs, and nothing else, because it runs
%% 200 times at three bands. ORDERED is in the tuple because the DESIGN gate's
%% RC2-4 asks for the synthetic ordered count too, and because exp066's records
%% carry ordered beside cycles everywhere.
%% {cycles, ordered, decisive, cyclable}
quad(Mg, Idx, B) ->
    {length(forward(Mg, Idx, B)) + length(backward(Mg, Idx, B)),
     ordered(Mg, Idx, B), decisive(Mg, Idx, B), cyclable(Mg, Idx, B)}.

-define(I_CYC, 1).
-define(I_ORD, 2).
-define(I_DEC, 3).
-define(I_CBL, 4).

%%---------------------------------------------------------------------------
%% A. THE GATES. Against literals quoted from persisted records, not against
%% anything this script computed. A parse error, an index error or a counter
%% defect fails at least one, and the script stops.
%%---------------------------------------------------------------------------
gates(Wm, Km, Idx) ->
    [{float_full, B, float_row(Wm, Idx, B), St} || {B, St} <- ?STATED_FLOAT]
        ++ [{exact_full, B, exact_row(Km, Idx, Bi), St}
            || {{B, Bi}, {_B2, St}} <- lists:zip(?BANDS, ?STATED_EXACT)].

float_row(Wm, Idx, B) ->
    {Cyc, Ord, Fw, Bw, _Id, Dec, _Cbl} = counts(mg(Wm), Idx, B),
    {Cyc, Ord, Fw, Bw, Dec}.

exact_row(Km, Idx, Bi) ->
    {Cyc, _Ord, _Fw, _Bw, _Id, Dec, Cbl} = counts(mg(Km), Idx, Bi),
    {Dec, Cbl, Cyc}.

gate(Dev, Gates) -> halt_on(Dev < 1.0e-9 andalso lists:all(fun ok_gate/1, Gates)).

ok_gate({_Tag, _B, Mine, Stated}) -> Mine =:= Stated.

halt_on(true) -> ok;
halt_on(false) ->
    io:format("GATE FAILED. The parse or the counter does not reproduce the~n"
              "persisted records, so nothing below could be trusted. Stopping.~n"),
    halt(1).

gate_lines(Seeds, Dev, Gates) ->
    [f("-- A. GATES: THIS SCRIPT AGAINST THE PERSISTED RECORDS --~n~n", []),
     f("champions parsed = ~p, seeds ~p..~p~n", [length(Seeds), hd(Seeds), lists:last(Seeds)]),
     f("worst distance of any cell from its integer numerator over 160 = ~.1f~n", [Dev]),
     f("  (so K(I,J) = W(I,J) * 160 is exact and the integer counter is lossless)~n~n", []),
     f("tag          band  mine                      stated                    verdict~n", [])]
        ++ [f("~-12w ~.2f  ~-25w ~-25w ~s~n", [T, B, Mine, St, agree(Mine =:= St)])
            || {T, B, Mine, St} <- Gates]
        ++ [f("~nfloat_full = {cycles,ordered,forward,backward,decisive} against~n"
              "             ~ts (its own counts, float counter)~n", [?XP]),
            f("exact_full = {decisive,cyclable,cycles} against ~ts~n"
              "             section K (the exact-arithmetic recount)~n", [?VERIFY]),
            f("Both gate. Any DISAGREE stops the script.~n~n", [])].

agree(true) -> "AGREE";
agree(false) -> "DISAGREE";
agree(_Other) -> "?".

%%---------------------------------------------------------------------------
%% B. THE FIT. MM (Zermelo / Ford) iteration on the decisive matches only, with
%% one virtual win and one virtual loss on every ORDERED pair, so w'(I,J) =
%% K(I,J) + 1 and n'(I,J) = N(I,J) + 2. That prior is the standard fix for a win
%% graph that is not strongly connected and it is DECLARED IN THE
%% PRE-REGISTRATION, not chosen after a divergence.
%%---------------------------------------------------------------------------
fit(Km, Idx) ->
    Ws = [wins(Km, Idx, I) || I <- Idx],
    S0 = [1.0 || _ <- Idx],
    iterate(Km, Idx, Ws, S0, 0).

wins(Km, Idx, I) ->
    lists:sum([el(Km, I, J) + ?PRIOR || J <- Idx, J =/= I]).

iterate(_Km, _Idx, _Ws, S, N) when N >= ?CAP -> {S, N, hit_cap};
iterate(Km, Idx, Ws, S, N) ->
    S1 = normalise([update(Km, Idx, S, I, lists:nth(I, Ws)) || I <- Idx]),
    step(Km, Idx, Ws, S, S1, N + 1, converged(S, S1)).

step(_Km, _Idx, _Ws, _S, S1, N, true) -> {S1, N, converged};
step(Km, Idx, Ws, _S, S1, N, false) -> iterate(Km, Idx, Ws, S1, N).

update(Km, Idx, S, I, Wi) ->
    Si = lists:nth(I, S),
    Den = lists:sum([(el(Km, I, J) + el(Km, J, I) + 2 * ?PRIOR)
                     / (Si + lists:nth(J, S)) || J <- Idx, J =/= I]),
    Wi / Den.

normalise(S) ->
    T = length(S),
    Sum = lists:sum(S),
    [X * T / Sum || X <- S].

converged(A, B) ->
    lists:all(fun({X, Y}) -> abs(Y - X) / X < ?TOL end, lists:zip(A, B)).

%% The fitted order's own violations: band-decisive pairs whose direction
%% disagrees with descending fitted strength. Reported because it is the same
%% quantity IF-8 gates the phase 1 panel on (30 of 300 there, over 300 pairs),
%% and it has never been measured on a real matrix either.
violations(Km, Idx, S, Bi) ->
    Mg = mg(Km),
    length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > Bi,
                 disagrees(Mg(I, J), lists:nth(I, S) - lists:nth(J, S))]).

disagrees(M, D) -> M * D < 0.

fit_lines(Seeds, Km, Idx, {S, Iters, Status}) ->
    Ranked = lists:reverse(lists:sort(lists:zip(S, Seeds))),
    [f("-- B. THE BRADLEY-TERRY FIT (Null A's model, fitted to the observed matrix) --~n~n", []),
     f("iterations = ~p of a cap of ~p, status ~w~n", [Iters, ?CAP, Status]),
     f("tolerance  = relative change below ~w in EVERY s_I~n", [?TOL]),
     f("prior      = one virtual win and one virtual loss on every ORDERED pair~n", []),
     f("normalised = sum(s) = ~p~n", [length(Idx)]),
     f("cap hit    = ~w   (a cap hit would fire IF-9 by itself)~n~n",
       [Status =:= hit_cap]),
     f("rank  seed   strength    row_mean_observed~n", [])]
        ++ [f("~4w  ~w  ~9.5f    ~.4f~n", [R, Sd, St, row_mean(Km, Idx, idx_of(Sd, Seeds))])
            || {R, {St, Sd}} <- lists:zip(lists:seq(1, length(Ranked)), Ranked)]
        ++ ident_lines(Km, Idx)
        ++ [f("~nTHE FITTED ORDER IS NOT ADOPTED AS A RATING. It is here for two~n"
              "reasons only: the null draws from it, and its own violation count is~n"
              "the quantity IF-8 gates the phase 1 panel on.~n~n", []),
            f("band  decisive_pairs  disagree_with_fitted_order  share~n", [])]
        ++ [f("~.2f  ~14w  ~26w  ~.4f~n",
              [B, decisive(mg(Km), Idx, Bi), violations(Km, Idx, S, Bi),
               violations(Km, Idx, S, Bi) / max(1, decisive(mg(Km), Idx, Bi))])
            || {B, Bi} <- ?BANDS]
        ++ [f("~n", [])].

%% IS THE FIT IDENTIFIED? Ford's condition: the MLE of a Bradley-Terry model
%% exists and is unique up to scale iff the win digraph is strongly connected.
%% The prior of one virtual win and one virtual loss on every ORDERED pair makes
%% the AUGMENTED digraph complete, so the augmented fit is always identified;
%% whether the RAW digraph is strongly connected is a fact about the matrix and
%% is measured rather than assumed, because it says whether the prior is doing
%% real work here or is only insurance.
ident_lines(Km, Idx) ->
    Zeros = [{I, J} || I <- Idx, J <- Idx, I =/= J, el(Km, I, J) =:= 0],
    Raw = strongly_connected(Km, Idx),
    [f("~nIDENTIFICATION (Ford's condition on the win digraph)~n", []),
     f("  ordered pairs with ZERO wins for the row, K(I,J) = 0     = ~p of 380~n",
       [length(Zeros)]),
     f("  those pairs                                             = ~w~n", [Zeros]),
     f("  RAW win digraph strongly connected                      = ~w~n", [Raw]),
     f("  AUGMENTED digraph (after the +1/+1 prior) complete       = true~n", []),
     f("    (the prior puts a positive win count on EVERY ordered pair, so the~n"
       "     augmented digraph is the complete digraph, which is strongly~n"
       "     connected, so the augmented MLE exists and is unique up to scale)~n", []),
     f("  scale fixed by                                          = sum(s) = ~p~n",
       [length(Idx)]),
     f("  so the fit is IDENTIFIED                                = true~n", [])].

strongly_connected(Km, Idx) ->
    Fwd = reach(Km, Idx, [hd(Idx)], [], fun(I, J) -> el(Km, I, J) > 0 end),
    Bwd = reach(Km, Idx, [hd(Idx)], [], fun(I, J) -> el(Km, J, I) > 0 end),
    length(Fwd) =:= length(Idx) andalso length(Bwd) =:= length(Idx).

reach(_Km, _Idx, [], Seen, _Edge) -> Seen;
reach(Km, Idx, [I | Rest], Seen, Edge) ->
    Next = [J || J <- Idx, not lists:member(J, Seen), not lists:member(J, [I | Rest]),
                 Edge(I, J)],
    reach(Km, Idx, Rest ++ Next, [I | Seen], Edge).

row_mean(Km, Idx, I) ->
    lists:sum([el(Km, I, J) / ?MATCHES || J <- Idx, J =/= I]) / (length(Idx) - 1).

idx_of(S, Seeds) ->
    hd([I || {I, X} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), X =:= S]).

%%---------------------------------------------------------------------------
%% C. THE PARAMETRIC BOOTSTRAP. 200 synthetic matrices off the registered seed.
%% Per cell the DECISIVE count N(I,J) is held at its observed value and the draw
%% count is therefore unchanged, so the synthetic matrix has the observed
%% decisiveness OPPORTUNITY edge for edge and differs only in orientation and
%% margin size.
%%---------------------------------------------------------------------------
bootstrap(Km, Idx, {S, _It, _St}) ->
    St0 = rand:seed_s(?RNG_ALG, ?RNG_SEED),
    {Rows, StN} = draws(Km, Idx, S, ?DRAWS, St0, []),
    {Rows, rand:export_seed_s(StN)}.

draws(_Km, _Idx, _S, 0, St, Acc) -> {lists:reverse(Acc), St};
draws(Km, Idx, S, N, St, Acc) ->
    {M, St2} = synth(Km, Idx, S, St),
    Row = [{B, quad(mg(M), Idx, Bi)} || {B, Bi} <- ?BANDS],
    draws(Km, Idx, S, N - 1, St2, [Row | Acc]).

synth(Km, Idx, S, St) ->
    {Cells, St2} = lists:foldl(fun(P, {Acc, St0}) -> cell(P, Km, S, Acc, St0) end,
                               {#{}, St}, pairs(Idx)),
    {list_to_tuple([list_to_tuple([maps:get({I, J}, Cells, 0) || J <- Idx])
                    || I <- Idx]), St2}.

cell({I, J}, Km, S, Acc, St) ->
    N = el(Km, I, J) + el(Km, J, I),
    Si = lists:nth(I, S),
    Sj = lists:nth(J, S),
    {K, St2} = binom(N, Si / (Si + Sj), St, 0),
    {Acc#{{I, J} => K, {J, I} => N - K}, St2}.

binom(0, _P, St, Acc) -> {Acc, St};
binom(N, P, St, Acc) ->
    {U, St2} = rand:uniform_s(St),
    binom(N - 1, P, St2, Acc + hit(U < P)).

hit(true) -> 1;
hit(false) -> 0.

%%---------------------------------------------------------------------------
%% D. THE READINGS. Everything the gate asked for, per band, with the primary
%% band's IF-9 verdict and the observed cycle count's position in the 200.
%%---------------------------------------------------------------------------
boot_lines(Km, Idx, {Rows, Exported}) ->
    [f("-- C. THE 200 SYNTHETIC MATRICES --~n~n", []),
     f("rng          = ~w, seed ~w, the REGISTERED Null A seed with~n",
       [?RNG_ALG, ?RNG_SEED]),
     f("               MatrixIndex 0 for this phase 0 matrix~n", []),
     f("exported_seed_state_after = ~w~n", [Exported]),
     f("draws        = ~p~n", [?DRAWS]),
     f("held fixed   = every cell's decisive count N(I,J), so every cell's draw~n"
       "               count is unchanged too~n~n", []),
     f("band  quantity  observed  synth_min  synth_median  synth_max  obs_position~n", [])]
        ++ lists:append([band_block(Km, Idx, Rows, B, Bi) || {B, Bi} <- ?BANDS])
        ++ [f("~nobs_position = how many of the 200 draws are STRICTLY BELOW the~n"
              "               observed value, then how many EQUAL it. The per-run~n"
              "               CYCLIC test is one-sided: observed > max of the 200.~n~n", [])].

band_block(Km, Idx, Rows, B, Bi) ->
    {ObsCyc, ObsOrd, ObsDec, ObsCbl} = quad(mg(Km), Idx, Bi),
    [stat_line(B, "cycles  ", ObsCyc, col(Rows, B, ?I_CYC)),
     stat_line(B, "ordered ", ObsOrd, col(Rows, B, ?I_ORD)),
     stat_line(B, "decisive", ObsDec, col(Rows, B, ?I_DEC)),
     stat_line(B, "cyclable", ObsCbl, col(Rows, B, ?I_CBL))].

col(Rows, B, Which) -> [element(Which, keyget(B, Row)) || Row <- Rows].

stat_line(B, Tag, Obs, Xs) ->
    f("~.2f  ~s  ~8w  ~9w  ~12.1f  ~9w  ~p below, ~p equal~n",
      [B, Tag, Obs, lists:min(Xs), median(Xs), lists:max(Xs),
       length([1 || X <- Xs, X < Obs]), length([1 || X <- Xs, X =:= Obs])]).

verdict_lines(Wm, Km, Idx, {S, _It, Status}, {Rows, _Exp}) ->
    counter_lines(Wm, Km, Idx)
        ++ if9_lines(Wm, Km, Idx, Status, Rows)
        ++ cyclic_lines(Km, Idx, S, Rows)
        ++ share_lines(Km, Idx, Rows)
        ++ if8_lines(Km, Idx, S)
        ++ consequence_lines(Wm, Km, Idx, Status, Rows).

%% D0. BOTH COUNTERS, SIDE BY SIDE. RC2-4 quotes the float counter's numbers
%% (49 / 18 / 12 cycles, 152 decisive at band 0.10) and asks for the integer
%% recount beside them. The integer counter is the one phase 1 pre-registers.
counter_lines(Wm, Km, Idx) ->
    [f("-- D0. THE FLOAT COUNTER AND THE INTEGER COUNTER, SIDE BY SIDE --~n~n", []),
     f("  Both count the same definition with strict >. The float counter compares~n"
       "  W(I,J) - W(J,I) against 0.05 / 0.10 / 0.15 in IEEE doubles; the integer~n"
       "  counter compares K(I,J) - K(J,I) against 8 / 16 / 24 out of 160. A margin~n"
       "  that is mathematically ON a band comes out a few times 1.0e-17 ABOVE it in~n"
       "  doubles, so the float counter calls it decisive and the integer counter does~n"
       "  not. The integer one is what EXP-067 pre-registers.~n~n", []),
     f("  band  counter  cycles  ordered  decisive  cyclable~n", [])]
        ++ lists:append([counter_rows(Wm, Km, Idx, B, Bi) || {B, Bi} <- ?BANDS])
        ++ [f("~n  pairs whose |K(I,J) - K(J,I)| is EXACTLY the band integer:~n", [])]
        ++ lists:append([on_band_lines(Wm, Km, Idx, B, Bi) || {B, Bi} <- ?BANDS])
        ++ [f("~n  Every number in the rest of this file is on the INTEGER counter.~n~n", [])].

counter_rows(Wm, Km, Idx, B, Bi) ->
    {FC, FO, FD, FB} = quad(mg(Wm), Idx, B),
    {IC, IO, ID, IB} = quad(mg(Km), Idx, Bi),
    [f("  ~.2f  float    ~6w  ~7w  ~8w  ~8w~n", [B, FC, FO, FD, FB]),
     f("  ~.2f  integer  ~6w  ~7w  ~8w  ~8w~n", [B, IC, IO, ID, IB])].

on_band_lines(Wm, Km, Idx, B, Bi) ->
    Mg = mg(Km),
    Mf = mg(Wm),
    Ps = [{I, J} || {I, J} <- pairs(Idx), abs(Mg(I, J)) =:= Bi],
    [f("    ~.2f  ~p of 190 on the band exactly~n", [B, length(Ps)])]
        ++ [f("      cells {~p,~p} int |margin| ~p/160, float |margin| ~.20f,~n"
              "        float strict > band = ~w, integer strict > band = ~w~n",
              [I, J, Bi, abs(Mf(I, J)), abs(Mf(I, J)) > B, abs(Mg(I, J)) > Bi])
            || {I, J} <- Ps].

%% D1. IF-9, evaluated against BOTH observed values, because RC2-4 names the
%% float one and the pre-registration counts on the integer one.
if9_lines(Wm, Km, Idx, Status, Rows) ->
    Bi = band_int(?PRIMARY),
    ObsDec = element(?I_DEC, quad(mg(Km), Idx, Bi)),
    FltDec = element(?I_DEC, quad(mg(Wm), Idx, ?PRIMARY)),
    Ds = col(Rows, ?PRIMARY, ?I_DEC),
    MedD = median(Ds),
    [f("-- D1. DOES IF-9 FIRE ON THIS MATRIX, AND WITH WHAT SIGN? --~n~n", []),
     f("  median synthetic decisive edges at band ~.2f            = ~.1f of 190~n",
       [?PRIMARY, MedD]),
     f("  synthetic decisive edges, min .. max                   = ~p .. ~p~n",
       [lists:min(Ds), lists:max(Ds)]),
     f("  IF-9 width                                             = ~p of 190~n",
       [?FIT_GATE]),
     f("  fit hit the iteration cap                              = ~w~n",
       [Status =:= hit_cap]),
     f("    (a cap hit fires IF-9 by itself)~n~n", []),
     f("  observed  counter  median_minus_observed  fires  sign~n", []),
     if9_row("integer", ObsDec, MedD, Status),
     if9_row("float  ", FltDec, MedD, Status),
     f("~n  The pre-registered counter is the INTEGER one, so the gate verdict of~n"
       "  record is the first row. The float row is printed because RC2-4 quoted~n"
       "  152. Both rows are shown so a reader can see the two-edge gap does not~n"
       "  change the verdict.~n~n", [])].

if9_row(Tag, Obs, MedD, Status) ->
    Diff = MedD - Obs,
    f("  ~8w  ~s  ~s~19.1f  ~5w  ~s~n",
      [Obs, Tag, plus(Diff), Diff, fires(Diff, Status), sign_of(Diff)]).

fires(Diff, Status) -> abs(Diff) > ?FIT_GATE orelse Status =:= hit_cap.

%% D2. The per-run CYCLIC test, at all three bands, because the observed count's
%% position in its own 200 draws is what the 1/201 rate is about.
cyclic_lines(Km, Idx, S, Rows) ->
    [f("-- D2. DOES THE OBSERVED CYCLE COUNT EXCEED ITS OWN NULL MAXIMUM? --~n~n", []),
     f("  The per-run CYCLIC test, applied to this matrix as if it were one phase 1~n"
       "  run's above-floor submatrix. It is NOT one: this matrix is 20~n"
       "  independently evolved champions. The question is only whether a real,~n"
       "  ladder-shaped matrix of the right shape trips the test.~n~n", []),
     f("  band  observed  null_min  null_median  null_max  exceeds_max  below  equal~n", [])]
        ++ [cyclic_row(Km, Idx, Rows, B, Bi) || {B, Bi} <- ?BANDS]
        ++ [f("~n  strengths, sorted descending, ~p members:~n    ~w~n~n",
              [length(S), [round(X * 100000) / 100000
                           || X <- lists:reverse(lists:sort(S))]])].

cyclic_row(Km, Idx, Rows, B, Bi) ->
    Obs = element(?I_CYC, quad(mg(Km), Idx, Bi)),
    Xs = col(Rows, B, ?I_CYC),
    f("  ~.2f  ~8w  ~8w  ~11.1f  ~8w  ~11w  ~5w  ~5w~n",
      [B, Obs, lists:min(Xs), median(Xs), lists:max(Xs), Obs > lists:max(Xs),
       length([1 || X <- Xs, X < Obs]), length([1 || X <- Xs, X =:= Obs])]).

%% D3. The scale-matched share, which is the only quantity comparable across
%% index sets of different size, for the observed matrix and for the null.
share_lines(Km, Idx, Rows) ->
    [f("D3. THE SCALE-MATCHED SHARE, OBSERVED AGAINST THE NULL.~n~n", []),
     f("  share = cycles / cyclable triples. Raw counts over different index~n"
       "  sets are not comparable; this is.~n~n", []),
     f("  band  obs_cycles  obs_cyclable  obs_share  null_median_share  null_mean_share~n", [])]
        ++ [share_line(Km, Idx, Rows, B, Bi) || {B, Bi} <- ?BANDS]
        ++ [f("~n  THIS MATRIX IS 20 INDEPENDENTLY EVOLVED CHAMPIONS, one per phase 0~n"
              "  arm S run, that never met each other during evolution. There is no~n"
              "  coevolution anywhere in it and no Red Queen anywhere in it. So these~n"
              "  shares are what this substrate's competent controllers do to each~n"
              "  other WITHOUT any coevolutionary dynamic, and they are the reference~n"
              "  a phase 1 archive matrix's share should be printed beside.~n~n", [])].

share_line(Km, Idx, Rows, B, Bi) ->
    {Cyc, _Ord, _Dec, Cbl} = quad(mg(Km), Idx, Bi),
    Cs = col(Rows, B, ?I_CYC),
    Bs = col(Rows, B, ?I_CBL),
    MedC = median(Cs),
    MedB = median(Bs),
    f("  ~.2f  ~10w  ~12w  ~9.4f  ~17.4f  ~15.6f~n",
      [B, Cyc, Cbl, Cyc / max(1, Cbl), MedC / max(1.0, MedB),
       mean(Cs) / max(1.0, mean(Bs))]).

mean(Xs) -> lists:sum(Xs) / length(Xs).

%% D4. The other chosen constant this matrix can already speak to: IF-8's
%% order-violation trigger for the phase 1 panel. Reported, not moved.
if8_lines(Km, Idx, S) ->
    Bi = band_int(?PRIMARY),
    [f("D4. IF-8's ORDER-VIOLATION TRIGGER, MEASURED ON THE CELLS THAT EXIST.~n~n", []),
     f("  IF-8 voids instrument I1 when more than 30 of the 25-member panel's 300~n"
       "  band-decisive pairs disagree with its own fitted order. The 190~n"
       "  champion-versus-champion cells of that panel are these cells, and SC3a~n"
       "  forces the panel to reproduce them exactly.~n~n", []),
     f("  band ~.2f: ~p of ~p band-decisive pairs already disagree with the~n",
       [?PRIMARY, violations(Km, Idx, S, Bi), decisive(mg(Km), Idx, Bi)]),
     f("  fitted order, on 190 pairs of the eventual 300.~n", []),
     f("  IF-8's trigger is ~p over all 300.~n", [30]),
     f("  HEADROOM LEFT for the remaining 110 pairs (the 5 scripted rungs against~n"
       "  the 20 champions and against each other) = ~p violations.~n~n",
       [30 - violations(Km, Idx, S, Bi)]),
     f("  NO CONSTANT IS MOVED HERE. The two numbers are printed side by side and~n"
       "  the consequence is a pre-registration question, not an arithmetic one.~n~n", [])].

%%---------------------------------------------------------------------------
%% E. THE CONSEQUENCE. RC2-4 states it: if the phase 0 matrix fires IF-9 or
%% exceeds its own Null A maximum, the gate width and the 3-of-13 arithmetic must
%% be RE-DERIVED before the pre-registration closes. So both conditions are
%% evaluated here, the registered arithmetic is recomputed exactly, and the
%% replacement numbers are computed IF one is owed. Nothing is moved in this
%% file; the pre-registration is a different document and a different agent's
%% edit.
%%---------------------------------------------------------------------------
%% The two RC2-4 trigger conditions, computed in ONE place and consumed by both
%% the prose and the machine-readable term, so the record cannot say two things.
triggers(Wm, Km, Idx, Status, Rows) ->
    Bi = band_int(?PRIMARY),
    ObsDec = element(?I_DEC, quad(mg(Km), Idx, Bi)),
    FltDec = element(?I_DEC, quad(mg(Wm), Idx, ?PRIMARY)),
    MedD = median(col(Rows, ?PRIMARY, ?I_DEC)),
    Fires = fires(MedD - ObsDec, Status) orelse fires(MedD - FltDec, Status),
    Exceed = [B || {B, B2} <- ?BANDS,
                   element(?I_CYC, quad(mg(Km), Idx, B2))
                       > lists:max(col(Rows, B, ?I_CYC))],
    {Fires, Exceed, Fires orelse Exceed =/= []}.

consequence_lines(Wm, Km, Idx, Status, Rows) ->
    Bi = band_int(?PRIMARY),
    ObsDec = element(?I_DEC, quad(mg(Km), Idx, Bi)),
    FltDec = element(?I_DEC, quad(mg(Wm), Idx, ?PRIMARY)),
    Ds = col(Rows, ?PRIMARY, ?I_DEC),
    MedD = median(Ds),
    {Fires, Exceed, _Owed} = triggers(Wm, Km, Idx, Status, Rows),
    e1_lines(ObsDec, FltDec, MedD, Fires, Exceed)
        ++ e2_lines()
        ++ e3_lines(Km, Idx, Rows)
        ++ e4_lines(ObsDec, MedD, Ds)
        ++ e5_lines(Fires, Exceed)
        ++ e6_lines(Exceed).

e1_lines(ObsDec, FltDec, MedD, Fires, Exceed) ->
    [f("-- E. THE CONSEQUENCE FOR THE PRE-REGISTRATION (RC2-4) --~n~n", []),
     f("E1. THE TWO CONDITIONS RC2-4 NAMES, EVALUATED.~n~n", []),
     f("  condition 1: IF-9 fires on this matrix~n", []),
     f("    median synthetic decisive ~.1f against observed ~p (integer) and~n",
       [MedD, ObsDec]),
     f("    ~p (float), width ~p of 190           -> ~w~n",
       [FltDec, ?FIT_GATE, Fires]),
     f("  condition 2: the observed cycle count exceeds its own Null A maximum~n", []),
     f("    bands where it does                                  -> ~w~n", [Exceed]),
     f("    (empty list means the count is inside the null at every band)~n~n", [])].

%% E2. The registered arithmetic, recomputed. The pre-registration states
%% P(>=1) = 0.0628, P(>=2) = 0.00186, P(>=3) = 3.3e-5 at p = 1/201 over 13 runs,
%% about 6.7e-5 over two arms and about 1.0e-4 over three. Those five numbers are
%% recomputed here from the binomial rather than quoted, so the document's own
%% arithmetic is checked at the same time.
e2_lines() ->
    P = 1 / 201,
    T3 = tail(13, P, 3),
    [f("E2. THE REGISTERED FAMILY-WISE ARITHMETIC, RECOMPUTED FROM THE BINOMIAL.~n~n", []),
     f("  per-run rate p = 1/201 = ~.7f, runs per arm = 13~n~n", [P]),
     f("  k   P(at least k of 13)   document's stated value~n", []),
     f("  1   ~.9f           0.0628~n", [tail(13, P, 1)]),
     f("  2   ~.9f           0.00186~n", [tail(13, P, 2)]),
     f("  3   ~.9f           3.3e-5~n", [T3]),
     f("  4   ~.9f           (not stated)~n~n", [tail(13, P, 4)]),
     f("  two verdict-carrying arms  1 - (1 - P(>=3))^2 = ~.9f  (stated 6.7e-5)~n",
       [1 - math:pow(1 - T3, 2)]),
     f("  three, with a gradeable A4 1 - (1 - P(>=3))^3 = ~.9f  (stated 1.0e-4)~n~n",
       [1 - math:pow(1 - T3, 3)]),
     f("  So the level the 3-of-13 threshold buys, per arm, is ~.3e, and the~n"
       "  family-wise level over three arms is ~.3e. Any re-derivation has to~n"
       "  hold that level, not a level chosen afterwards.~n~n",
       [T3, 1 - math:pow(1 - T3, 3)])].

%% E3. What per-run rate THIS matrix implies. One matrix cannot estimate a rate,
%% so the bootstrap p-value is reported as the calibrated per-matrix quantity and
%% the 0-or-1 empirical outcome is reported beside it as what it is.
e3_lines(Km, Idx, Rows) ->
    [f("E3. THE PER-RUN RATE THIS MATRIX IMPLIES.~n~n", []),
     f("  band  observed  draws_>=_obs  bootstrap_p  fires  zero_cycle_draws  all_200_cycles~n", [])]
        ++ [rate_row(Km, Idx, Rows, B, Bi) || {B, Bi} <- ?BANDS]
        ++ [f("~n  bootstrap_p = (draws >= observed + 1) / 201, the standard one-sided~n"
              "  parametric-bootstrap p-value for the cycle count under Null A. It is~n"
              "  at its FLOOR of 1/201 at all three bands, so it cannot distinguish~n"
              "  'just above the maximum' from 'far above it': read it beside the raw~n"
              "  counts in D2, not instead of them. fires is the pre-registered per-run~n"
              "  CYCLIC test, observed > max of 200, the event whose rate the 3-of-13~n"
              "  arithmetic caps at 1/201.~n~n", []),
            f("  zero_cycle_draws and all_200_cycles are the same fact from the null's~n"
              "  side: how many of the 200 synthetic matrices contain no banded cycle~n"
              "  at all, and how many cycles the whole bootstrap produced across all~n"
              "  200 matrices together. Compare the last column with the observed~n"
              "  count in ONE matrix.~n~n", []),
            f("  ONE matrix gives a 0-or-1 outcome, not a rate. What it can do is~n"
              "  show whether a real matrix of the right shape sits where the null~n"
              "  says a null matrix sits. That is what the p-value column reports.~n~n", [])].

rate_row(Km, Idx, Rows, B, Bi) ->
    Obs = element(?I_CYC, quad(mg(Km), Idx, Bi)),
    Xs = col(Rows, B, ?I_CYC),
    Ge = length([1 || X <- Xs, X >= Obs]),
    f("  ~.2f  ~8w  ~12w  ~11.6f  ~5w  ~16w  ~14w~n",
      [B, Obs, Ge, (Ge + 1) / (?DRAWS + 1), Obs > lists:max(Xs),
       length([1 || X <- Xs, X =:= 0]), lists:sum(Xs)]).

%% E4. What the width would have to be, and what width is pure sampling noise.
e4_lines(ObsDec, MedD, Ds) ->
    Need = ceil(abs(MedD - ObsDec)),
    Spread = lists:max([abs(X - MedD) || X <- Ds]),
    [f("E4. THE GATE WIDTH, MEASURED AGAINST WHAT IT IS SUPPOSED TO ACCEPT.~n~n", []),
     f("  registered width                                       = ~p of 190~n",
       [?FIT_GATE]),
     f("  |median synthetic - observed| on this matrix           = ~.1f~n",
       [abs(MedD - ObsDec)]),
     f("  smallest integer width that accepts this matrix        = ~p~n", [Need]),
     f("  the null's OWN sampling spread of the decisive count,~n", []),
     f("    max |draw - median| over the ~p draws                = ~.1f~n",
       [?DRAWS, Spread]),
     f("    min .. max                                          = ~p .. ~p~n",
       [lists:min(Ds), lists:max(Ds)]),
     f("~n  Read the three together. A width below the null's own sampling spread~n"
       "  would reject matrices the null itself generates. A width far above the~n"
       "  observed |median - observed| accepts this matrix with room to spare. The~n"
       "  gap between the two is the gate's real slack and it had never been~n"
       "  measured.~n~n", [])].

e5_lines(false, []) ->
    [f("E5. IS A RE-DERIVATION OWED? NO.~n~n", []),
     f("  IF-9 does not fire on this matrix and the observed cycle count does not~n"
       "  exceed its own Null A maximum at any band. RC2-4's two trigger conditions~n"
       "  are both false, so the gate width of ~p of 190 and the 3-of-13 arithmetic~n"
       "  stand as pre-registered. They are now CALIBRATED rather than merely~n"
       "  chosen: E4 says what the width's slack is on a real matrix and E3 says~n"
       "  where a real matrix's count sits in the null's own draws.~n~n",
       [?FIT_GATE]),
     f("  WHAT THIS DOES NOT LICENCE. It does not say the width is right for a~n"
       "  phase 1 archive matrix. An archive matrix is 20 checkpoints of ONE~n"
       "  lineage, its dependence structure is not this matrix's, and its decisive~n"
       "  edge count could be anywhere. The calibration establishes that the null~n"
       "  fits, draws and accepts a real 20-member matrix at 160 matches per cell.~n"
       "  Nothing more.~n~n", [])];
e5_lines(Fires, Exceed) ->
    [f("E5. IS A RE-DERIVATION OWED? YES.~n~n", []),
     f("  IF-9 fires                                             = ~w~n", [Fires]),
     f("  bands where the observed count exceeds its null maximum = ~w~n", [Exceed]),
     f("~n  RC2-4's second condition holds, so the gate width AND the 3-of-13~n"
       "  arithmetic are both owed a re-derivation before the pre-registration~n"
       "  closes. They are owed for different reasons and the reasons should not be~n"
       "  merged:~n~n", []),
     f("  THE WIDTH is not damaged by what fired. It was measured directly (E4):~n"
       "  the registered ~p accepts this matrix with |median - observed| of 4 and~n",
       [?FIT_GATE]),
     f("  the null's own sampling spread of the same count is 10, min .. max~n"
       "  146 .. 164. A width of ~p sits above the null's own spread and well above~n",
       [?FIT_GATE]),
     f("  what this matrix needs. The measurement supports the width as written.~n"
       "  What the measurement also shows is that the width cannot be relied on to~n"
       "  detect non-scalar structure, because it did not (headline 4).~n~n", []),
     f("  THE 3-OF-13 ARITHMETIC IS THE ONE THAT BREAKS, and the break is not~n"
       "  arithmetic. E2 recomputes the document's own five numbers and they are~n"
       "  all correct: at p = 1/201 over 13 runs, P(>=3) = 3.39e-5 and the~n"
       "  three-arm family-wise level is 1.02e-4. The defect is the INPUT p. 1/201~n"
       "  is the probability that a matrix DRAWN FROM Null A exceeds the maximum of~n"
       "  200 further draws from Null A. The event the threshold actually counts is~n"
       "  a PHASE 1 ARCHIVE MATRIX exceeding it, and the only real matrix available~n"
       "  exceeds it at every band by a wide margin while containing no coevolution~n"
       "  at all. E6 gives the arithmetic for what the threshold would have to be.~n~n", []),
     f("  NOTHING IS MOVED HERE. This file computes; the pre-registration is a~n"
       "  different document and a different agent's edit.~n~n", [])].

%% E6. What the threshold would have to be, at the rate this matrix implies and
%% at the most conservative rate one observation licenses. Both are shown because
%% one matrix cannot estimate a rate and pretending otherwise would be the same
%% error the design made with 1/201.
e6_lines([]) ->
    [f("E6. WHAT THE THRESHOLD WOULD HAVE TO BE. Not owed: E5 says no.~n~n", [])];
e6_lines(_Exceed) ->
    Target = tail(13, 1 / 201, 3),
    [f("E6. WHAT THE THRESHOLD WOULD HAVE TO BE, AT WHAT RATE.~n~n", []),
     f("  The level to hold is the one 3-of-13 buys at p = 1/201: P(>=3) = ~.3e~n",
       [Target]),
     f("  per arm. So the question is the smallest k of 13 whose tail is at or~n"
       "  below that level, at a given per-run rate q.~n~n", []),
     f("  q          what q is                              smallest k of 13~n", []),
     f("  ~-9.5f  the registered rate, a matrix drawn FROM   ~w~n",
       [1 / 201, min_k(13, 1 / 201, Target)]),
     f("             Null A~n", []),
     f("  ~-9.5f  Clopper-Pearson one-sided 95% LOWER bound  ~w~n",
       [0.05, min_k(13, 0.05, Target)]),
     f("             from 1 exceedance in 1 matrix: solve~n"
       "             1 - (1 - q) = 0.05, so q >= 0.05~n", []),
     f("  ~-9.5f  the point estimate from 1 of 1             ~w~n",
       [1.0, min_k(13, 1.0, Target)]),
     f("~n  Read the last row first. At q = 1 no k of 13 holds the level, because~n"
       "  P(>=13 of 13) = 1. The threshold cannot be repaired by raising k. At the~n"
       "  95% lower bound the threshold would be ~w of 13 rather than 3, and that~n",
       [min_k(13, 0.05, Target)]),
     f("  is the MOST FAVOURABLE reading one exceedance in one matrix allows.~n~n", []),
     f("  AND RAISING k IS STILL NOT THE REPAIR. q here is not a Type I rate. It~n"
       "  is the rate at which this substrate's matrices are non-scalar, which the~n"
       "  phase 0 matrix says is the default and not the exception. A threshold of~n"
       "  ~w of 13 would require that ~w of 13 phase 1 runs be non-scalar, which is~n",
       [min_k(13, 0.05, Target), min_k(13, 0.05, Target)]),
     f("  a bar this substrate clears without any coevolution. The quantity that~n"
       "  survives the arithmetic is a COMPARISON against a no-coevolution~n"
       "  reference of the same shape, and D3 already prints one: the observed~n"
       "  share of cyclable triples that are cyclic, against the null's share and~n"
       "  against this matrix's own share. Which reference the pre-registration~n"
       "  adopts is a design decision and is NOT taken here.~n~n", [])].

min_k(N, Q, Target) ->
    first_k([K || K <- lists:seq(1, N), tail(N, Q, K) =< Target]).

first_k([K | _]) -> K;
first_k([]) -> none.

plus(D) when D > 0 -> "+";
plus(_D) -> "".

%%---------------------------------------------------------------------------
%% Exact binomial upper tail, integer coefficients, no approximation.
%%---------------------------------------------------------------------------
tail(N, P, K) ->
    lists:sum([choose(N, J) * math:pow(P, J) * math:pow(1 - P, N - J)
               || J <- lists:seq(K, N)]).

choose(_N, 0) -> 1;
choose(N, K) -> choose(N, K - 1) * (N - K + 1) div K.

sign_of(D) when D > 0 -> "INFLATED (the null over-produces decisive edges)";
sign_of(D) when D < 0 -> "DEFLATED (the null under-produces decisive edges)";
sign_of(_D) -> "exact".

band_int(B) -> element(2, lists:keyfind(B, 1, ?BANDS)).

%%---------------------------------------------------------------------------
%% Report scaffolding.
%%---------------------------------------------------------------------------
head(Out, Seeds) ->
    [f("== EXP-067 phase 1: NULL A EXERCISED ON PHASE 0'S 20-CHAMPION MATRIX ==~n~n", []),
     f("date        = 2026-07-30~n", []),
     f("status      = CALIBRATION of a phase 1 instrument over a persisted phase 0~n"
       "              record. Not a phase 1 measurement, not a phase 1 result,~n"
       "              signs nothing on its own.~n", []),
     f("engine_pin  = a5e8bcfc5646827e9be49a9629f8a6a9678c814b (nothing was run at it here)~n", []),
     f("produced_by = scripts/exp067_null_a_calibration.escript~n", []),
     f("written_to  = ~ts~n", [Out]),
     f("              (RC2-4's own wording says 'persist the record beside~n"
       "              exp066_residue_and_inv0.txt', which is in the exp066~n"
       "              directory. The work package directed the exp067 directory~n"
       "              instead, on the ground that this is phase 1 machinery. The~n"
       "              discrepancy is recorded rather than resolved silently; the~n"
       "              file reads exp066 records either way.)~n", []),
     f("reads       = ~ts   (the matrix, parsed from its machine-readable term)~n", [?XP]),
     f("              ~ts   (gate literals, section K)~n", [?VERIFY]),
     f("champions   = ~p, arm S, seeds ~p..~p~n", [length(Seeds), hd(Seeds), lists:last(Seeds)]),
     f("bands       = 0.05, 0.10, 0.15 on the integer grid as 8, 16, 24 of 160.~n"
       "              FIXED. Not swept, not moved, not chosen after a count.~n", []),
     f("rng         = ~w seeded ~w, the REGISTERED Null A seed at MatrixIndex 0.~n",
       [?RNG_ALG, ?RNG_SEED]),
     f("              ~p draws. The state after the last draw is exported and~n"
       "              printed, so the whole bootstrap is reproducible.~n", [?DRAWS]),
     f("no genome loaded, no match replayed, no arm re-run, no engine module read.~n~n", []),
     f("WHY THIS FILE EXISTS. The EXP-067 DESIGN gate round 2 (2026-07-30,~n"
       "BUILD_WITH_CHANGES) raised RC2-4: Null A is phase 1's PRIMARY null and the~n"
       "only genuinely new numeric machine in the design, and it had never been run~n"
       "on a real matrix. Two of its numbers were uncalibrated:~n~n", []),
     f("  - IF-9's fit gate width, 20 decisive edges of 190.~n", []),
     f("  - The per-run exceedance rate of at most 1/201, on which the 3-of-13~n"
       "    family-wise arithmetic rests.~n~n", []),
     f("A matrix of exactly the right shape was already on disk, so the null meets~n"
       "real data HERE rather than mid-experiment on the branch that decides the~n"
       "verdict. What would change the pre-registration was stated before the run:~n"
       "IF-9 firing on this matrix, or the observed cycle count exceeding its own~n"
       "null maximum. Either is reported and amended, never repaired by moving a~n"
       "number.~n~n", []),
     f("SECTIONS. A gates this script against the persisted records. B fits the~n"
       "model and reports identification. C draws the 200 synthetic matrices. D0~n"
       "prints both counters side by side, D1 the fit gate, D2 the per-run cyclic~n"
       "test, D3 the scale-matched share, D4 IF-8's order-violation trigger. E~n"
       "answers RC2-4's consequence question and, where one is owed, shows the~n"
       "arithmetic a re-derivation would rest on.~n~n", [])].

%% THE HEADLINE. Placed before the gates and the arithmetic because the
%% instruction under which this ran says a mis-calibration must be stated at the
%% top of the record and not buried. Every number in it is computed, and each one
%% appears again below with its section.
headline(Wm, Km, Idx, {_S, _It, Status}, {Rows, _Exp}) ->
    Bi = band_int(?PRIMARY),
    ObsDec = element(?I_DEC, quad(mg(Km), Idx, Bi)),
    MedD = median(col(Rows, ?PRIMARY, ?I_DEC)),
    {Fires, Exceed, Owed} = triggers(Wm, Km, Idx, Status, Rows),
    [f("== HEADLINE: ONE HALF OF NULL A HOLDS, THE OTHER HALF DOES NOT ==~n~n", []),
     f("1. THE FIT GATE HOLDS. IF-9 does not fire (D1). The median synthetic~n", []),
     f("   decisive-edge count at band ~.2f is ~.1f of 190 against the observed~n",
       [?PRIMARY, MedD]),
     f("   ~p, a difference of ~s~.1f against a registered width of ~p. The fit~n",
       [ObsDec, plus(MedD - ObsDec), MedD - ObsDec, ?FIT_GATE]),
     f("   converges, is identified, and reproduces the observed decisiveness~n"
       "   structure. IF-9 fires = ~w.~n~n", [Fires]),
     f("2. THE PER-RUN CYCLIC TEST FIRES ON A MATRIX WITH NO COEVOLUTION IN IT.~n", []),
     f("   The observed cycle count exceeds the MAXIMUM of its own 200 Null A~n"
       "   draws at EVERY band (D2):~n", [])]
        ++ [headline_row(Km, Idx, Rows, B, B2) || {B, B2} <- ?BANDS]
        ++ [f("~n   bands where the observed count exceeds its own null maximum = ~w~n",
              [Exceed]),
            f("   This matrix contains NO COEVOLUTION. It is 20 champions from 20~n"
              "   separate phase 0 runs that never met each other during evolution.~n"
              "   The pre-registered per-run CYCLIC test, applied to it, signs CYCLIC~n"
              "   at all three bands. So on this substrate that test does not, on its~n"
              "   own, separate coevolutionary cycling from the substrate's ordinary~n"
              "   non-scalar structure: the second alone is enough to pass it.~n~n", []),
            f("   THE LIMIT OF THAT SENTENCE, STATED HERE AND NOT ONLY IN THE FOOT.~n"
              "   A phase 1 archive matrix is 20 checkpoints of ONE lineage, not 20~n"
              "   independent champions. The pre-registration's own 'Alternatives~n"
              "   named and REJECTED' section describes insight 057's objects as ten~n"
              "   checkpoints along one monotone trajectory already known to lie on a~n"
              "   near-total order, with a cycle count of zero. So it is NOT~n"
              "   established here that a phase 1 archive matrix will exceed the null~n"
              "   too. What is established is that a real matrix of exactly the shape~n"
              "   the test consumes, with no coevolution in it, does exceed it, so~n"
              "   1/201 cannot be ASSUMED to be the rate at which phase 1 matrices~n"
              "   trip the test. The assumption was never checked and is now~n"
              "   contradicted by the one matrix available.~n~n", []),
            f("3. SO THE 1/201 PER-RUN RATE IS NOT THIS SUBSTRATE'S RATE, and the~n"
              "   3-of-13 threshold derived from it does not do the work it was~n"
              "   given (E2, E3, E6). 1/201 is a correct TYPE I rate for a matrix~n"
              "   drawn FROM Null A. It is not the rate at which a real matrix of~n"
              "   this substrate exceeds Null A, which is the event the threshold~n"
              "   counts. Re-derivation owed = ~w.~n~n", [Owed]),
            f("4. AND THE FIT GATE CANNOT SEE WHAT THE COUNT SEES. The~n"
              "   pre-registration argues that a matrix whose margins no scalar~n"
              "   strength can reproduce makes the fit compress those pairs toward~n"
              "   0.5 and therefore UNDER-produce decisive edges, which is the~n"
              "   NULL-UNFIT (DEFLATED) fingerprint. On this matrix the null~n"
              "   slightly OVER-produces them (~s~.1f) while the cycle count exceeds~n",
              [plus(MedD - ObsDec), MedD - ObsDec]),
            f("   the null maximum by a factor of ~p at band ~.2f. A matrix can pass~n",
              [ratio(element(?I_CYC, quad(mg(Km), Idx, Bi)),
                     lists:max(col(Rows, ?PRIMARY, ?I_CYC))), ?PRIMARY]),
            f("   the fit gate comfortably and still be nowhere near scalar. The fit~n"
              "   gate is not a proxy for scalar adequacy and must not be read as~n"
              "   one.~n~n", []),
            f("5. WHAT IS NOT WRONG WITH NULL A. It fits, it is identified, it~n"
              "   draws, it holds every cell's decisive and draw count exactly, and~n"
              "   it reproduces the observed decisiveness structure. Its rejection~n"
              "   on this matrix is a real rejection of the scalar-strength model.~n"
              "   The defect is in what the DESIGN concluded from a rejection, not~n"
              "   in the null's construction.~n~n", []),
            f("   IN PARTICULAR IT IS NOT UNDER-SUPPLYING THE INGREDIENT. The~n"
              "   pre-registration rejects the fair-coin null on exactly that ground~n"
              "   (it leaves too few decisive edges to bound the count in either~n"
              "   direction). Null A cannot be rejected on that ground: at band~n", []),
            f("   ~.2f its median count of all-three-decisive CYCLABLE triples is~n",
              [?PRIMARY]),
            f("   ~.1f against the observed ~p, so the null has MORE cycle~n",
              [median(col(Rows, ?PRIMARY, ?I_CBL)),
               element(?I_CBL, quad(mg(Km), Idx, Bi))]),
            f("   opportunity than the observed matrix and still produces ~.3f~n",
              [mean(col(Rows, ?PRIMARY, ?I_CYC))]),
            f("   cycles per draw. The shortfall is ORIENTATION, not opportunity:~n"
              "   in the fitted model a band-decisive edge almost always points the~n"
              "   way the strengths do. That is what makes the exceedance a real~n"
              "   finding rather than an artifact of a badly matched null.~n~n", [])].

headline_row(Km, Idx, Rows, B, B2) ->
    Obs = element(?I_CYC, quad(mg(Km), Idx, B2)),
    Xs = col(Rows, B, ?I_CYC),
    f("     band ~.2f: observed ~p, null median ~.1f, null max ~p, exceeds = ~w~n",
      [B, Obs, median(Xs), lists:max(Xs), Obs > lists:max(Xs)]).

ratio(_Obs, 0) -> infinite;
ratio(Obs, Max) -> Obs / Max.

foot() ->
    [f("-- WHAT THIS ESTABLISHES AND WHAT IT DOES NOT --~n~n", []),
     f("ESTABLISHES. That Null A, as pre-registered, fits and draws on a real~n"
       "20-member matrix at 160 matches per cell; what its fit reproduces of the~n"
       "observed decisiveness structure; whether IF-9's chosen width accepts a~n"
       "matrix the null is meant to describe; and where a real, largely~n"
       "ladder-shaped matrix's cycle count sits in the null's own 200 draws.~n~n", []),
     f("DOES NOT ESTABLISH. Nothing about coevolution and nothing about phase 1.~n"
       "This matrix is 20 INDEPENDENTLY EVOLVED champions from twenty separate~n"
       "phase 0 runs, not 20 checkpoints of one coevolutionary lineage, so its~n"
       "dependence structure is not an archive matrix's. It calibrates the~n"
       "instrument; it does not predict what the instrument will read.~n~n", []),
     f("NOT A VERDICT. No phase 1 outcome is decided here, no threshold in this~n"
       "file gates anything, and the phase 0 matrix is not a phase 1 run.~n~n", [])].

term(Out, Seeds, Dev, Gates, Wm, Km, Idx, {S, Iters, Status}, {Rows, Exported}) ->
    Bi = band_int(?PRIMARY),
    {ObsCyc, _ObsOrd, ObsDec, _C} = quad(mg(Km), Idx, Bi),
    FltDec = element(?I_DEC, quad(mg(Wm), Idx, ?PRIMARY)),
    Ds = col(Rows, ?PRIMARY, ?I_DEC),
    Cs = col(Rows, ?PRIMARY, ?I_CYC),
    P201 = 1 / 201,
    T = {null_a_calibration,
         [{date, "2026-07-30"},
          {status, "CALIBRATION of a phase 1 instrument over a persisted phase 0 record"},
          {produced_by, "scripts/exp067_null_a_calibration.escript"},
          {written_to, Out},
          {reads, [?XP, ?VERIFY]},
          {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
          {no_genome_loaded, true}, {no_match_replayed, true}, {no_arm_re_run, true},
          {champions, length(Seeds)}, {seeds, Seeds},
          {bands, [{B, B2, ?MATCHES} || {B, B2} <- ?BANDS]},
          {counter, "integer, strict > on wins out of 160"},
          {worst_cell_distance_from_integer_numerator, Dev},
          {gates, [{Tg, B, [{mine, M}, {stated, St}, {agree, M =:= St}]}
                   || {Tg, B, M, St} <- Gates]},
          {rng, [{alg, ?RNG_ALG}, {seed, ?RNG_SEED}, {draws, ?DRAWS},
                 {exported_state_after, Exported}]},
          {fit, [{prior, "one virtual win and one virtual loss per ordered pair"},
                 {tolerance, ?TOL}, {cap, ?CAP}, {iterations, Iters},
                 {status, Status}, {hit_cap, Status =:= hit_cap},
                 {normalised_sum, length(Idx)},
                 {strengths, [{Sd, St} || {Sd, St} <- lists:zip(Seeds, S)]}]},
          {fitted_order_violations,
           [{B, [{decisive_pairs, decisive(mg(Km), Idx, B2)},
                 {disagree_with_fitted_order, violations(Km, Idx, S, B2)}]}
            || {B, B2} <- ?BANDS]},
          {identification,
           [{zero_win_ordered_pairs,
             length([1 || I <- Idx, J <- Idx, I =/= J, el(Km, I, J) =:= 0])},
            {raw_win_digraph_strongly_connected, strongly_connected(Km, Idx)},
            {augmented_digraph_complete, true},
            {identified, true}]},
          {observed_both_counters,
           [{B, [{float, tup4(quad(mg(Wm), Idx, B))},
                 {integer, tup4(quad(mg(Km), Idx, B2))}]}
            || {B, B2} <- ?BANDS]},
          {per_band,
           [{B, [{observed, tup4(quad(mg(Km), Idx, B2))},
                 {synthetic_cycles, spread(col(Rows, B, ?I_CYC))},
                 {synthetic_ordered, spread(col(Rows, B, ?I_ORD))},
                 {synthetic_decisive, spread(col(Rows, B, ?I_DEC))},
                 {synthetic_cyclable, spread(col(Rows, B, ?I_CBL))},
                 {observed_cycles_draws_below,
                  length([1 || X <- col(Rows, B, ?I_CYC),
                               X < element(?I_CYC, quad(mg(Km), Idx, B2))])},
                 {observed_cycles_draws_equal,
                  length([1 || X <- col(Rows, B, ?I_CYC),
                               X =:= element(?I_CYC, quad(mg(Km), Idx, B2))])},
                 {observed_cycles_exceeds_null_max,
                  element(?I_CYC, quad(mg(Km), Idx, B2)) > lists:max(col(Rows, B, ?I_CYC))},
                 {bootstrap_p_one_sided,
                  (length([1 || X <- col(Rows, B, ?I_CYC),
                                X >= element(?I_CYC, quad(mg(Km), Idx, B2))]) + 1)
                  / (?DRAWS + 1)}]}
            || {B, B2} <- ?BANDS]},
          {primary_band, ?PRIMARY},
          {if_9, [{width, ?FIT_GATE},
                  {observed_decisive_integer_counter, ObsDec},
                  {observed_decisive_float_counter, FltDec},
                  {median_synthetic_decisive, median(Ds)},
                  {median_minus_observed_integer, median(Ds) - ObsDec},
                  {median_minus_observed_float, median(Ds) - FltDec},
                  {fires_on_integer, fires(median(Ds) - ObsDec, Status)},
                  {fires_on_float, fires(median(Ds) - FltDec, Status)},
                  {smallest_width_that_accepts_this_matrix,
                   ceil(abs(median(Ds) - ObsDec))},
                  {null_own_max_abs_deviation_from_median,
                   lists:max([abs(X - median(Ds)) || X <- Ds])}]},
          {per_run_cyclic_test,
           [{observed_cycles, ObsCyc}, {null_max, lists:max(Cs)},
            {null_median, median(Cs)}, {null_min, lists:min(Cs)},
            {observed_exceeds_max, ObsCyc > lists:max(Cs)},
            {draws_strictly_below_observed, length([1 || X <- Cs, X < ObsCyc])},
            {draws_equal_observed, length([1 || X <- Cs, X =:= ObsCyc])}]},
          {family_wise_arithmetic,
           [{per_run_rate, P201}, {runs_per_arm, 13},
            {p_at_least_1, tail(13, P201, 1)},
            {p_at_least_2, tail(13, P201, 2)},
            {p_at_least_3, tail(13, P201, 3)},
            {p_at_least_4, tail(13, P201, 4)},
            {two_arms, 1 - math:pow(1 - tail(13, P201, 3), 2)},
            {three_arms, 1 - math:pow(1 - tail(13, P201, 3), 3)}]},
          {rc2_4_consequence, rc2_4(Wm, Km, Idx, Status, Rows)}]},
    [f("~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n", []),
     f("~w.~n", [T])].

rc2_4(Wm, Km, Idx, Status, Rows) ->
    {Fires, Exceed, Owed} = triggers(Wm, Km, Idx, Status, Rows),
    Bi = band_int(?PRIMARY),
    ObsDec = element(?I_DEC, quad(mg(Km), Idx, Bi)),
    MedD = median(col(Rows, ?PRIMARY, ?I_DEC)),
    Target = tail(13, 1 / 201, 3),
    [{if_9_fires, Fires},
     {bands_where_observed_exceeds_null_max, Exceed},
     {re_derivation_owed, Owed},
     {registered_gate_width, ?FIT_GATE},
     {gate_width_measurement_supports_registered_value, abs(MedD - ObsDec) =< ?FIT_GATE},
     {three_of_thirteen_input_rate_contradicted, Exceed =/= []},
     {level_the_threshold_must_hold, Target},
     {smallest_k_of_13_at_registered_rate, min_k(13, 1 / 201, Target)},
     {smallest_k_of_13_at_95pc_lower_bound_rate_0_05, min_k(13, 0.05, Target)},
     {smallest_k_of_13_at_point_estimate_rate_1_0, min_k(13, 1.0, Target)},
     {note, "the width's own measurement supports it; RC2-4 requires both the "
            "width and the threshold re-derived because condition 2 holds; the "
            "threshold is the one whose INPUT RATE is contradicted"}].

tup4({A, B, C, D}) ->
    [{cycles, A}, {ordered, B}, {decisive_edges, C}, {cyclable_triples, D}].

spread(Xs) ->
    [{min, lists:min(Xs)}, {median, median(Xs)}, {max, lists:max(Xs)},
     {mean, lists:sum(Xs) / length(Xs)}].

%%---------------------------------------------------------------------------
%% Small helpers.
%%---------------------------------------------------------------------------
f(Fmt, Args) -> io_lib:format(Fmt, Args).

median([]) -> 0.0;
median(Xs) ->
    S = lists:sort([float(X) || X <- Xs]),
    L = length(S),
    mid(S, L, L rem 2).

mid(S, L, 1) -> lists:nth(L div 2 + 1, S);
mid(S, L, 0) -> (lists:nth(L div 2, S) + lists:nth(L div 2 + 1, S)) / 2.
