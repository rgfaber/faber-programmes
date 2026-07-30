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
-define(XP, ?ARCH "exp066_crossplay.txt").
-define(VERIFY, ?ARCH "exp066_within_tier_verify.txt").
-define(OUT, ?ARCH "exp066_null_a_calibration.txt").

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
    VLines = verdict_lines(Km, Idx, Fit, Boot),
    Lines = lists:append([head(Out, Seeds), GLines, FLines, BLines, VLines,
                          foot(),
                          term(Out, Seeds, Dev, Gates, Km, Idx, Fit, Boot)]),
    ok = file:write_file(Out, [Lines]),
    io:format("~nwritten: ~ts~n", [Out]).

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

%% The two quantities the bootstrap needs, and nothing else, because it runs
%% 200 times at three bands.
cyc_dec(Mg, Idx, B) ->
    {length(forward(Mg, Idx, B)) + length(backward(Mg, Idx, B)),
     decisive(Mg, Idx, B), cyclable(Mg, Idx, B)}.

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
        ++ [f("~nTHE FITTED ORDER IS NOT ADOPTED AS A RATING. It is here for two~n"
              "reasons only: the null draws from it, and its own violation count is~n"
              "the quantity IF-8 gates the phase 1 panel on.~n~n", []),
            f("band  decisive_pairs  disagree_with_fitted_order  share~n", [])]
        ++ [f("~.2f  ~14w  ~26w  ~.4f~n",
              [B, decisive(mg(Km), Idx, Bi), violations(Km, Idx, S, Bi),
               violations(Km, Idx, S, Bi) / max(1, decisive(mg(Km), Idx, Bi))])
            || {B, Bi} <- ?BANDS]
        ++ [f("~n", [])].

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
    Row = [{B, cyc_dec(mg(M), Idx, Bi)} || {B, Bi} <- ?BANDS],
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
    {ObsCyc, ObsDec, ObsCbl} = cyc_dec(mg(Km), Idx, Bi),
    Cs = [element(1, keyget(B, Row)) || Row <- Rows],
    Ds = [element(2, keyget(B, Row)) || Row <- Rows],
    Bs = [element(3, keyget(B, Row)) || Row <- Rows],
    [stat_line(B, "cycles  ", ObsCyc, Cs),
     stat_line(B, "decisive", ObsDec, Ds),
     stat_line(B, "cyclable", ObsCbl, Bs)].

stat_line(B, Tag, Obs, Xs) ->
    f("~.2f  ~s  ~8w  ~9w  ~12.1f  ~9w  ~p below, ~p equal~n",
      [B, Tag, Obs, lists:min(Xs), median(Xs), lists:max(Xs),
       length([1 || X <- Xs, X < Obs]), length([1 || X <- Xs, X =:= Obs])]).

verdict_lines(Km, Idx, {S, _It, Status}, {Rows, _Exp}) ->
    Bi = band_int(?PRIMARY),
    {ObsCyc, ObsDec, _ObsCbl} = cyc_dec(mg(Km), Idx, Bi),
    Ds = [element(2, keyget(?PRIMARY, Row)) || Row <- Rows],
    Cs = [element(1, keyget(?PRIMARY, Row)) || Row <- Rows],
    MedD = median(Ds),
    Diff = MedD - ObsDec,
    Fires = abs(Diff) > ?FIT_GATE orelse Status =:= hit_cap,
    [f("-- D. THE TWO PRE-STATED QUESTIONS, ANSWERED --~n~n", []),
     f("D1. DOES IF-9 FIRE ON THIS MATRIX, AND WITH WHAT SIGN?~n~n", []),
     f("  observed decisive edges at band ~.2f, INTEGER counter  = ~p of 190~n",
       [?PRIMARY, ObsDec]),
     f("  the same count on the FLOAT counter phase 0 printed    = 152 of 190~n", []),
     f("    (the pre-registered counter is the integer one, so the gate is~n"
       "     applied to ~p; the float value is printed because the DESIGN gate's~n"
       "     RC2-4 quoted it)~n", [ObsDec]),
     f("  median synthetic decisive edges                        = ~.1f~n", [MedD]),
     f("  median minus observed                                  = ~s~.1f~n",
       [plus(Diff), Diff]),
     f("  IF-9 width                                             = ~p of 190~n", [?FIT_GATE]),
     f("  fit hit the iteration cap                              = ~w~n", [Status =:= hit_cap]),
     f("  IF-9 FIRES                                             = ~w~n", [Fires]),
     f("  sign                                                   = ~s~n~n", [sign_of(Diff)]),
     f("D2. DOES THE OBSERVED CYCLE COUNT EXCEED ITS OWN NULL MAXIMUM?~n~n", []),
     f("  observed cycles at band ~.2f  = ~p~n", [?PRIMARY, ObsCyc]),
     f("  maximum of the 200 draws      = ~p~n", [lists:max(Cs)]),
     f("  median of the 200 draws       = ~.1f~n", [median(Cs)]),
     f("  minimum of the 200 draws      = ~p~n", [lists:min(Cs)]),
     f("  observed > maximum            = ~w~n", [ObsCyc > lists:max(Cs)]),
     f("    (this matrix is NOT a phase 1 archive matrix and this is NOT a phase 1~n"
       "     verdict. The question is whether a real ladder-shaped matrix of this~n"
       "     shape trips the per-run CYCLIC test, because the 3-of-13 family-wise~n"
       "     arithmetic assumes it does so with probability at most 1/201.)~n~n", []),
     f("  strengths, sorted descending, ~p members:~n    ~w~n~n",
       [length(S), [round(X * 100000) / 100000 || X <- lists:reverse(lists:sort(S))]])]
        ++ share_lines(Km, Idx, Rows)
        ++ if8_lines(Km, Idx, S).

%% D3. The scale-matched share, which is the only quantity comparable across
%% index sets of different size, for the observed matrix and for the null.
share_lines(Km, Idx, Rows) ->
    [f("D3. THE SCALE-MATCHED SHARE, OBSERVED AGAINST THE NULL.~n~n", []),
     f("  share = cycles / cyclable triples. Raw counts over different index~n"
       "  sets are not comparable; this is.~n~n", []),
     f("  band  obs_cycles  obs_cyclable  obs_share  null_median_share~n", [])]
        ++ [share_line(Km, Idx, Rows, B, Bi) || {B, Bi} <- ?BANDS]
        ++ [f("~n  THIS MATRIX IS 20 INDEPENDENTLY EVOLVED CHAMPIONS, one per phase 0~n"
              "  arm S run, that never met each other during evolution. There is no~n"
              "  coevolution anywhere in it and no Red Queen anywhere in it. So these~n"
              "  shares are what this substrate's competent controllers do to each~n"
              "  other WITHOUT any coevolutionary dynamic, and they are the reference~n"
              "  a phase 1 archive matrix's share should be printed beside.~n~n", [])].

share_line(Km, Idx, Rows, B, Bi) ->
    {Cyc, _Dec, Cbl} = cyc_dec(mg(Km), Idx, Bi),
    MedC = median([element(1, keyget(B, R)) || R <- Rows]),
    MedB = median([element(3, keyget(B, R)) || R <- Rows]),
    f("  ~.2f  ~10w  ~12w  ~9.4f  ~17.4f~n",
      [B, Cyc, Cbl, Cyc / max(1, Cbl), MedC / max(1.0, MedB)]).

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
     f("  IF-8's trigger is ~p over all 300.~n~n", [30]),
     f("  NO CONSTANT IS MOVED HERE. The two numbers are printed side by side and~n"
       "  the consequence is a pre-registration question, not an arithmetic one.~n~n", [])].

plus(D) when D > 0 -> "+";
plus(_D) -> "".

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
       "number.~n~n", [])].

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

term(Out, Seeds, Dev, Gates, Km, Idx, {S, Iters, Status}, {Rows, Exported}) ->
    Bi = band_int(?PRIMARY),
    {ObsCyc, ObsDec, _C} = cyc_dec(mg(Km), Idx, Bi),
    Ds = [element(2, keyget(?PRIMARY, R)) || R <- Rows],
    Cs = [element(1, keyget(?PRIMARY, R)) || R <- Rows],
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
          {per_band,
           [{B, [{observed, tup3(cyc_dec(mg(Km), Idx, B2))},
                 {synthetic_cycles, spread([element(1, keyget(B, R)) || R <- Rows])},
                 {synthetic_decisive, spread([element(2, keyget(B, R)) || R <- Rows])},
                 {synthetic_cyclable, spread([element(3, keyget(B, R)) || R <- Rows])}]}
            || {B, B2} <- ?BANDS]},
          {primary_band, ?PRIMARY},
          {if_9, [{width, ?FIT_GATE},
                  {observed_decisive_integer_counter, ObsDec},
                  {observed_decisive_float_counter_phase_0, 152},
                  {median_synthetic_decisive, median(Ds)},
                  {median_minus_observed, median(Ds) - ObsDec},
                  {fires, abs(median(Ds) - ObsDec) > ?FIT_GATE
                       orelse Status =:= hit_cap}]},
          {per_run_cyclic_test,
           [{observed_cycles, ObsCyc}, {null_max, lists:max(Cs)},
            {null_median, median(Cs)}, {null_min, lists:min(Cs)},
            {observed_exceeds_max, ObsCyc > lists:max(Cs)},
            {draws_strictly_below_observed, length([1 || X <- Cs, X < ObsCyc])},
            {draws_equal_observed, length([1 || X <- Cs, X =:= ObsCyc])}]}]},
    [f("~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n", []),
     f("~w.~n", [T])].

tup3({A, B, C}) -> [{cycles, A}, {decisive_edges, B}, {cyclable_triples, C}].

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
