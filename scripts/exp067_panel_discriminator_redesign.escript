#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% EXP-067, THE ARITHMETIC THE ROUND-3 DESIGN GATE'S RC3-1 CONDEMNS THE
%%% MEAN-CENTRED PANEL DISCRIMINATOR ON, AND THE ARITHMETIC THE REPLACEMENT
%%% MUST SURVIVE.
%%%
%%% READ-ONLY over persisted records. No genome is loaded, no match is
%%% replayed, no arm is re-run, no engine module is touched, and no runner
%%% code is written here: every number is a deterministic function of
%%% exp066_crossplay.txt, exp066_residue_and_inv0.txt and
%%% exp067_null_a_calibration.txt.
%%%
%%% WHY THIS EXISTS. The DESIGN gate's round 3 (2026-07-30, verdict REDESIGN)
%%% found that the round-2 branch 6 / branch 7 discriminator,
%%%
%%%   median over A1's QUALIFYING runs of
%%%       [ (INV - E[INV]) at checkpoint 20 ] - [ (INV - E[INV]) at checkpoint 0 ]
%%%
%%% subtracts E[INV] without CONDITIONING on the realised k_C, so for a win
%%% pattern pinned near INV = 0 the difference collapses to E_0 - E_20, which
%%% is a pure composition quantity. E[INV] = D*k*(n-k)/(n*(n-1)) is a downward
%%% parabola in k, so a champion that climbs the panel, which is exactly what
%%% H3 predicts, drives the difference POSITIVE and lands in branch 7, whose
%%% pre-committed reading is false for it.
%%%
%%% SECTION D1 computes that indictment on the limit case, from data already on
%%% disk. SECTION D2 and SECTION D3 measure the replacement, the symmetric Null
%%% C exceedance count, against the same trajectory family. SECTION D4 measures
%%% how often the exceedance leg fires on a REAL coevolution-free win pattern,
%%% which is the round-3 gate's RC3-6 question asked on the data that exists
%%% today rather than only on the 25-member panel at step 2.
%%%
%%% NOTHING RANDOM HAPPENS HERE. There is no RNG call, no bootstrap and no
%%% permutation sample, so there is no seed to persist. The exceedance leg
%%% needs the 200-permutation MAXIMUM, which is a sampled quantity; this script
%%% bounds it deductively instead, using max >= mean, so that a value at or
%%% below the exact closed-form mean is PROVED unable to exceed the maximum
%%% whatever the 200 draws return. That is a weaker instrument than sampling
%%% and it is the honest one to use before the panel exists.
%%%
%%% Usage: scripts/exp067_panel_discriminator_redesign.escript [OutFile]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(P0, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").
-define(P1, ?REPO "/programmes/p7_coevolution/exp067_coevolution_cycling/").
-define(XP, ?P0 "exp066_crossplay.txt").
-define(RESIDUE, ?P0 "exp066_residue_and_inv0.txt").
-define(CALIB, ?P1 "exp067_null_a_calibration.txt").
-define(OUT, ?P1 "exp067_panel_discriminator_redesign.txt").

-define(MATCHES, 160).
-define(BANDS, [{0.05, 8}, {0.10, 16}, {0.15, 24}]).

%% Phase 1's 13 seeds, the kill-mode tier of phase 0's arm S.
-define(KILL, [2001, 2002, 2003, 2004, 2005, 2006, 2008,
               2010, 2012, 2013, 2017, 2019, 2020]).

%% GATE 1. The integer counter over all 20 champions must reproduce
%% exp067_null_a_calibration.txt's own {decisive, cyclable, cycles}.
-define(STATED_EXACT, [{0.05, {168, 789, 49}},
                       {0.10, {150, 582, 18}},
                       {0.15, {141, 487, 12}}]).

%% GATE 3. The fitted-order violation counts the calibration persisted, which
%% is what makes the fitted order this script sorts by the SAME order the
%% calibration reports on: {decisive_pairs, disagree_with_fitted_order}.
-define(STATED_VIOL, [{0.05, {168, 36}}, {0.10, {150, 26}}, {0.15, {141, 23}}]).

main(Args) ->
    Out = out(Args),
    {Seeds, Wm} = xp_matrix(?XP),
    Idx = lists:seq(1, length(Seeds)),
    Km = int_matrix(Wm, Idx),
    Mg = mg(Km),
    Strengths = strengths(?CALIB),
    Per = [{B, [champ(Mg, Idx, Bi, C, Seeds) || C <- Idx]} || {B, Bi} <- ?BANDS],
    Gates = gates(Mg, Idx, Seeds, Strengths, Per),
    GLines = gate_lines(Seeds, Gates),
    io:put_chars(GLines),
    ok = gate(Gates),
    {D1L, D1T} = d1(Per),
    {D2L, D2T} = d2(Per),
    {D3L, D3T} = d3(Mg, Idx, Strengths, Seeds, Per),
    {D4L, D4T} = d4(Per),
    Lines = lists:append([head(Out, Seeds), GLines, D1L, D2L, D3L, D4L,
                          foot(), term(Out, Gates, D1T, D2T, D3T, D4T)]),
    ok = file:write_file(Out, [Lines]),
    io:format("~nwritten: ~ts~n", [Out]).

out([P | _]) -> P;
out([]) -> ?OUT.

%%---------------------------------------------------------------------------
%% PARSING. Both inputs are read out of their machine-readable terms, never
%% retyped.
%%---------------------------------------------------------------------------
xp_matrix(Path) ->
    {ok, Bin} = file:read_file(Path),
    {crossplay, F} = term_after_marker(binary_to_list(Bin)),
    Rows = [{S, Ws} || {row, _I, S, Ws} <- keyget(matrix, F)],
    {[S || {S, _} <- Rows],
     list_to_tuple([list_to_tuple(Ws) || {_S, Ws} <- Rows])}.

%% The Bradley-Terry strengths the Null A calibration fitted and persisted.
%% They are read rather than re-fitted, so the order this script sorts the
%% panel by is the SAME order the calibration counted its violations against,
%% which GATE 3 then proves by recounting those violations.
strengths(Path) ->
    {ok, Bin} = file:read_file(Path),
    {null_a_calibration, F} = term_after_marker(binary_to_list(Bin)),
    keyget(strengths, keyget(fit, F)).

%% Section C of the residue record, champion by champion and band by band.
residue_rows(Path) ->
    {ok, Bin} = file:read_file(Path),
    {residue_and_inv0, F} = term_after_marker(binary_to_list(Bin)),
    keyget(at_band, keyget(inv_at_checkpoint_0, F)).

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

%%---------------------------------------------------------------------------
%% THE COUNTERS, the integer ones phase 1 pre-registers.
%%---------------------------------------------------------------------------
mg(M) -> fun(I, J) -> el(M, I, J) - el(M, J, I) end.

el(M, I, J) -> element(J, element(I, M)).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

triples(Idx) -> [{I, J, Z} || I <- Idx, J <- Idx, Z <- Idx, I < J, J < Z].

decisive(Mg, Idx, B) -> length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > B]).

cyclable(Mg, Idx, B) ->
    length([1 || {I, J, Z} <- triples(Idx),
                 abs(Mg(I, J)) > B, abs(Mg(J, Z)) > B, abs(Mg(I, Z)) > B]).

cycles(Mg, Idx, B) ->
    length([1 || {I, J, Z} <- triples(Idx),
                 abs(Mg(I, J)) > B, abs(Mg(J, Z)) > B, abs(Mg(I, Z)) > B,
                 lists:sort([out_deg(Mg, B, X, [I, J, Z]) || X <- [I, J, Z]])
                     =:= [1, 1, 1]]).

out_deg(Mg, B, X, Ms) -> length([1 || Y <- Ms, Y =/= X, Mg(X, Y) > B]).

%% Decisive pairs whose direction disagrees with the fitted order, which is the
%% calibration's own IF-8 observable.
violations(Mg, Idx, B, Rank) ->
    length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > B,
                 disagrees(Mg(I, J), maps:get(I, Rank), maps:get(J, Rank))]).

%% Rank 1 is the strongest. The fitted order says the better-ranked member
%% wins, so a disagreement is a decisive edge pointing the other way.
disagrees(M, RI, RJ) when M > 0 -> RI > RJ;
disagrees(_M, RI, RJ) -> RI < RJ.

%%---------------------------------------------------------------------------
%% NULL C's OBJECTS, per champion, per band. The sub-panel is the set of
%% members whose edge to C is band-decisive; INV counts the decisive sub-panel
%% pairs P -> Q with C beating P and Q beating C.
%%---------------------------------------------------------------------------
champ(Mg, Idx, Bi, C, Seeds) ->
    Sub = [P || P <- Idx, P =/= C, abs(Mg(C, P)) > Bi],
    Win = [P || P <- Sub, Mg(C, P) > Bi],
    N = length(Sub),
    K = length(Win),
    D = length([1 || {P, Q} <- pairs(Sub), abs(Mg(P, Q)) > Bi]),
    #{seed => lists:nth(C, Seeds), idx => C, sub => Sub, n => N, k => K, d => D,
      inv => inv_for_set(Mg, Bi, Sub, Win), e => e_inv(D, K, N),
      degenerate => (K =:= 0) orelse (K =:= N)}.

inv_for_set(Mg, Bi, Sub, Win) ->
    Lose = Sub -- Win,
    length([1 || P <- Win, Q <- Lose, Mg(P, Q) > Bi]).

e_inv(_D, _K, N) when N < 2 -> 0.0;
e_inv(D, K, N) -> D * K * (N - K) / (N * (N - 1)).

%%---------------------------------------------------------------------------
%% GATES. Any DISAGREE stops the script before a number is written.
%%---------------------------------------------------------------------------
gates(Mg, Idx, Seeds, Strengths, Per) ->
    Rank = rank_map(Seeds, Strengths),
    G1 = [{exact_counts, B,
           {decisive(Mg, Idx, Bi), cyclable(Mg, Idx, Bi), cycles(Mg, Idx, Bi)},
           St}
          || {{B, Bi}, {_B, St}} <- lists:zip(?BANDS, ?STATED_EXACT)],
    G2 = g2(Per),
    G3 = [{fitted_order_violations, B,
           {decisive(Mg, Idx, Bi), violations(Mg, Idx, Bi, Rank)}, St}
          || {{B, Bi}, {_B, St}} <- lists:zip(?BANDS, ?STATED_VIOL)],
    [{strengths_parsed, length(Strengths), 20} | G1 ++ G2 ++ G3].

%% Every champion's n_C, k_C, D_C, INV and E[INV] against section C of
%% exp066_residue_and_inv0.txt, at every band. 60 rows of five numbers.
g2(Per) ->
    Stated = residue_rows(?RESIDUE),
    [{residue_section_c, B, mine_row(M), stated_row(B, M, Stated)}
     || {B, Ms} <- Per, M <- Ms].

mine_row(#{seed := S, n := N, k := K, d := D, inv := V, e := E}) ->
    {S, N, K, D, V, round2(E)}.

stated_row(B, #{seed := S}, Stated) ->
    Rows = keyget(B, Stated),
    {seed, S, F} = lists:keyfind(S, 2, [R || R <- Rows, element(2, R) =:= S]),
    {S, keyget(n_c, F), keyget(k_c, F), keyget(d_c, F), keyget(inv, F),
     round2(keyget(e_inv, F))}.

round2(X) -> round(X * 100) / 100.

rank_map(Seeds, Strengths) ->
    Sorted = lists:reverse(lists:keysort(2, Strengths)),
    maps:from_list([{idx_of(S, Seeds), R}
                    || {R, {S, _V}} <- lists:zip(lists:seq(1, length(Sorted)),
                                                 Sorted)]).

idx_of(S, Seeds) ->
    {L, _} = lists:splitwith(fun(X) -> X =/= S end, Seeds),
    length(L) + 1.

gate(Gates) ->
    Bad = [G || G <- Gates, not agrees(G)],
    stop_if(Bad).

agrees({strengths_parsed, A, B}) -> A =:= B;
agrees({_Tag, _B, Mine, Stated}) -> Mine =:= Stated.

stop_if([]) -> ok;
stop_if(Bad) ->
    io:format("GATE FAILED, nothing written: ~p~n", [Bad]),
    halt(1).

gate_lines(Seeds, Gates) ->
    Rows = [G || G <- Gates, element(1, G) =/= residue_section_c],
    C = length([1 || G <- Gates, element(1, G) =:= residue_section_c]),
    Ok = length([1 || G <- Gates, element(1, G) =:= residue_section_c,
                      agrees(G)]),
    [f("-- A. GATES: THIS SCRIPT AGAINST THE PERSISTED RECORDS --~n~n", []),
     f("champions parsed = ~p, seeds ~p..~p~n~n",
       [length(Seeds), hd(Seeds), lists:last(Seeds)])]
        ++ [gate_line(G) || G <- Rows]
        ++ [f("residue section C  per-champion {seed,n_C,k_C,D_C,INV,E_INV}"
              " rows: ~p of ~p AGREE~n", [Ok, C]),
            f("~nAll gates must AGREE. Any DISAGREE stops the script.~n~n", [])].

gate_line({strengths_parsed, A, B}) ->
    f("fitted strengths parsed from the Null A calibration: ~p of ~p  ~s~n",
      [A, B, agree(A =:= B)]);
gate_line({Tag, B, Mine, Stated}) ->
    f("~-24s ~.2f  mine ~-20w stated ~-20w ~s~n",
      [atom_to_list(Tag), B, Mine, Stated, agree(Mine =:= Stated)]).

agree(true) -> "AGREE";
agree(false) -> "DISAGREE".

%%---------------------------------------------------------------------------
%% D1. THE WITHDRAWN DISCRIMINATOR ON THE TOTAL-CLIMB TRAJECTORY.
%%
%% Take the purest transitive climb the panel admits: the champion ends the run
%% beating EVERY band-decisive panel member, k_C = n_C. Then no panel member
%% beats it, so no inversion triple exists, INV_20 = 0; and the permutation
%% distribution at k = n is a point mass at 0, so E_20 = 0 and the centred value
%% at checkpoint 20 is exactly 0. The withdrawn discriminator's contribution is
%% therefore 0 - (INV_0 - E_0) = E_0 - INV_0, which needs no assumption at all
%% about the trajectory in between.
%%---------------------------------------------------------------------------
d1(Per) ->
    Rows = [{B, [{S, V, E, E - V}
                 || #{seed := S, inv := V, e := E} <- Ms,
                    lists:member(S, ?KILL)]}
            || {B, Ms} <- Per],
    {[f("-- D1. THE WITHDRAWN MEAN-CENTRED DISCRIMINATOR, SCORED ON A PURE~n"
        "       TRANSITIVE CLIMB --~n~n", []),
      f("The round-2 rule is the MEDIAN over A1's qualifying runs of~n"
        "  [ (INV - E[INV]) at checkpoint 20 ] - [ (INV - E[INV]) at checkpoint 0 ]~n"
        "with branch 6 NO CYCLING at =< 0 and branch 7 PANEL-INVERTED at > 0.~n~n"
        "The trajectory scored here is the transitive-backbone story in its~n"
        "limit form: the lineage ends beating every band-decisive panel member~n"
        "(k_C = n_C), so INV_20 = 0 and E_20 = 0 by construction and the rule's~n"
        "value is exactly E_0 - INV_0.~n~n", [])]
         ++ lists:append([d1_band(B, Rs) || {B, Rs} <- Rows]),
     {d1_withdrawn_rule_on_total_climb,
      [{B, [{seeds, [S || {S, _V, _E, _D} <- Rs]},
            {delta_e0_minus_inv0, [D || {_S, _V, _E, D} <- Rs]},
            {median, median([D || {_S, _V, _E, D} <- Rs])},
            {min, lists:min([D || {_S, _V, _E, D} <- Rs])},
            {max, lists:max([D || {_S, _V, _E, D} <- Rs])},
            {seeds_scored_above_0, length([1 || {_S, _V, _E, D} <- Rs, D > 0])},
            {of_seeds, length(Rs)},
            {lands_branch_7_on_the_median, median([D || {_S, _V, _E, D} <- Rs]) > 0}]}
       || {B, Rs} <- Rows]}}.

d1_band(B, Rs) ->
    Ds = [D || {_S, _V, _E, D} <- Rs],
    [f("band ~.2f~n~n", [B]),
     f("seed  INV_0  E_INV_0   withdrawn rule's value on the total climb~n", [])]
        ++ [f("~w  ~5w  ~7.2f   ~9s~n", [S, V, E, sf(D)]) || {S, V, E, D} <- Rs]
        ++ [f("~nover the 13 seeds at band ~.2f:~n", [B]),
            f("  sorted ~w~n", [[round4(D) || D <- lists:sort(Ds)]]),
            f("  median ~.4f | min ~.4f | max ~.4f~n",
              [median(Ds), lists:min(Ds), lists:max(Ds)]),
            f("  seeds scored ABOVE 0, i.e. sent to branch 7: ~p of ~p~n",
              [length([1 || D <- Ds, D > 0]), length(Ds)]),
            f("  the arm median lands branch 7 PANEL-INVERTED: ~w~n~n",
              [median(Ds) > 0])].

%%---------------------------------------------------------------------------
%% D2. THE INSTALLED DISCRIMINATOR ON THE SAME TRAJECTORY.
%%
%% The replacement is the symmetric Null C exceedance count: a qualifying run
%% counts toward branch 7 iff INV at its final checkpoint STRICTLY exceeds that
%% checkpoint's own 200-permutation maximum while checkpoint 0 did not, which is
%% the positive's PANEL-VISIBLE conjunct with no change of normalisation. Two
%% independent reasons the total climb cannot reach branch 7, and both are
%% recorded because either alone would do.
%%---------------------------------------------------------------------------
d2(Per) ->
    Rows = [{B, [{S, V, E, K =:= N} || #{seed := S, inv := V, e := E,
                                         k := K, n := N} <- Ms,
                                       lists:member(S, ?KILL)]}
            || {B, Ms} <- Per],
    Deg0 = [{B, length([1 || #{seed := S, degenerate := true} <- Ms,
                             lists:member(S, ?KILL)])}
            || {B, Ms} <- Per],
    {[f("-- D2. THE INSTALLED EXCEEDANCE DISCRIMINATOR, SCORED ON THE SAME~n"
        "       PURE TRANSITIVE CLIMB --~n~n", []),
      f("REASON 1, the degeneracy rule. At k_C = n_C the permutation~n"
        "distribution is a point mass at 0, so the checkpoint is DEGENERATE and~n"
        "the pre-committed rule excludes the run from the qualifying base. It~n"
        "contributes to NEITHER branch.~n~n"
        "REASON 2, the exceedance test itself, which holds even with the~n"
        "degeneracy rule switched off. INV_20 = 0 and the permutation maximum is~n"
        "0, and the test is STRICTLY greater, so the climb does not exceed and~n"
        "contributes 0 toward branch 7's count of 2.~n~n"
        "Contribution of the total climb toward branch 7, over the 13 seeds,~n"
        "at every band: 0. The withdrawn rule's median at band 0.10 was~n"
        "+15.6000, which is branch 7.~n~n", [])]
         ++ [f("checkpoint-0 DEGENERATE seeds already on disk, band ~.2f: ~p of 13~n",
               [B, D]) || {B, D} <- Deg0]
         ++ [f("~nA seed that is DEGENERATE at checkpoint 0 is excluded from the~n"
               "qualifying base by the same rule, which is why the base is~n"
               "gated at 7 of 13 (ladder position 5b, PANEL BASE ERODED).~n~n", [])],
     {d2_installed_rule_on_total_climb,
      [{contribution_toward_branch_7, 0},
       {reason_1, degenerate_checkpoint_excluded_from_the_qualifying_base},
       {reason_2, inv_0_cannot_strictly_exceed_a_maximum_of_0},
       {per_band, [{B, [{seeds, [S || {S, _V, _E, _T} <- Rs]},
                        {terminal_checkpoint_degenerate_for_all, true},
                        {exceedances, 0}]} || {B, Rs} <- Rows]},
       {checkpoint_0_degenerate_seeds, Deg0}]}}.

%%---------------------------------------------------------------------------
%% D3. THE INSTALLED DISCRIMINATOR ON THE WHOLE PREFIX-CLIMB FAMILY, not only
%% its limit.
%%
%% A backbone climber's win set is a PREFIX of the panel's own fitted dominance
%% order: it beats the k weakest members of its sub-panel and loses to the rest.
%% For every champion, every band and every k from 0 to n_C, this constructs
%% that win set, counts INV exactly, and compares it with the exact closed-form
%% E[INV] at the same k. A value at or below the mean CANNOT be above the
%% maximum, so INV_prefix(k) =< E[INV](k) everywhere PROVES the exceedance leg
%% cannot fire anywhere on the prefix trajectory, with no permutation drawn.
%%---------------------------------------------------------------------------
d3(Mg, _Idx, Strengths, Seeds, Per) ->
    Rank = rank_map(Seeds, Strengths),
    Rows = [{B, [d3_champ(Mg, Bi, Rank, M) || M <- Ms]}
            || {{B, Bi}, {_B2, Ms}} <- lists:zip(?BANDS, Per)],
    Worst = lists:max([W || {_B, Cs} <- Rows, {_S, _Km, _V, _E, W, _A} <- Cs]),
    AntiWorst = lists:max([AW || {_B, Cs} <- Rows,
                                 {_S, _Km, _V, _E, _W, {_AK, _AV, _AE, AW}} <- Cs]),
    AntiOver = [{S, B} || {B, Cs} <- Rows,
                          {S, _Km, _V, _E, _W, {_AK, _AV, _AE, AW}} <- Cs, AW > 0],
    Over = [{S, B} || {B, Cs} <- Rows, {S, _Km, _V, _E, W, _A} <- Cs, W > 0],
    {[f("-- D3. THE INSTALLED DISCRIMINATOR OVER THE WHOLE PREFIX-CLIMB FAMILY --~n~n", []),
      f("For every champion, every band and every k_C from 0 to n_C, the win set~n"
        "is the ORDER-CONSISTENT one: the champion beats the k weakest members of~n"
        "its sub-panel under the panel's own fitted Bradley-Terry order (read from~n"
        "exp067_null_a_calibration.txt, and GATE 3 recounts that order's own~n"
        "violations against the calibration to prove it is the same order). INV is~n"
        "then counted exactly and compared with the exact E[INV] at that k.~n~n"
        "The row shows the k at which the climb reaches its LARGEST inversion~n"
        "count, that count, the exact mean there, and the worst (INV - E) over~n"
        "the whole climb. A worst value at or below 0 means the exceedance leg~n"
        "cannot fire at any point of that champion's backbone climb, because the~n"
        "200-permutation MAXIMUM is at least the mean.~n~n", []),
      f("band 0.10~n~n", []),
      f("seed  n_C  k at max  INV_prefix  E_INV     worst (INV - E)   "
        "anti_INV  anti_E  anti worst~n", [])]
         ++ [f("~w  ~4w  ~8w  ~10w  ~7.2f   ~9s   ~6w ~7.2f  ~9s~n",
               [S, Km, Kk, V, E, sf(W), AV, AE, sf(AW)])
             || {S, {Km, Kk}, V, E, W, {_AK, AV, AE, AW}} <- band_rows(0.10, Rows)]
         ++ [f("~nWORST CASE OVER ALL 20 CHAMPIONS, ALL 3 BANDS AND EVERY~n"
               "NON-DEGENERATE k (1 to n_C - 1):~n", []),
             f("  max over everything of (INV_prefix(k) - E[INV](k)) = ~s~n",
               [sf(Worst)]),
             f("  at k = 0 and k = n_C both INV and E[INV] are exactly 0, so the~n"
               "  strict exceedance test cannot fire at either endpoint either.~n", []),
             f("  champion-and-band cases where a prefix win set exceeds its own~n"
               "  exact mean: ~p~n", [length(Over)]),
             f("  so the exceedance leg fires on the prefix-climb family: ~w~n~n",
               [length(Over) > 0]),
             f("THE CONTRAST, so the test is shown not to be vacuous. The~n"
               "ANTI-CONSISTENT win set of size k is the k STRONGEST members of the~n"
               "sub-panel, the maximally inverted arrangement the order admits:~n", []),
             f("  max over everything of (anti_INV(k) - E[INV](k)) = ~s~n",
               [sf(AntiWorst)]),
             f("  champion-and-band cases where the ANTI-consistent set exceeds its~n"
               "  own exact mean: ~p~n", [length(AntiOver)]),
             f("  Exceeding the MEAN is necessary and not sufficient for exceeding the~n"
               "  200-permutation MAXIMUM, so this does not establish that the leg~n"
               "  fires on the anti-consistent arrangement. What it does establish is~n"
               "  that INV is NOT bounded above by its own mean as a matter of~n"
               "  arithmetic, so the exceedance leg is not identically unsatisfiable~n"
               "  and the prefix result in the rows above is a fact about PREFIX~n"
               "  arrangements rather than about the statistic.~n~n", [])],
     {d3_installed_rule_on_the_prefix_climb_family,
      [{construction, order_consistent_win_set_under_the_fitted_panel_order},
       {rng, none},
       {bound_used, "max >= mean, so INV =< E proves no strict exceedance"},
       {worst_inv_minus_e_over_all_champions_bands_and_interior_k, Worst},
       {endpoints_k_0_and_k_n, "INV = E = 0, strict exceedance impossible"},
       {cases_where_a_prefix_set_exceeds_its_own_mean, length(Over)},
       {exceedance_leg_fires_on_a_prefix_climb, length(Over) > 0},
       {anti_consistent_contrast,
        [{construction, "the k STRONGEST members, the maximally inverted arrangement"},
         {worst_inv_minus_e_over_interior_k, AntiWorst},
         {cases_where_it_exceeds_its_own_mean, length(AntiOver)},
         {note, "exceeding the mean is necessary and not sufficient for exceeding "
                "the 200-permutation maximum; this shows the leg is not "
                "identically unsatisfiable, and the maximum is measured at step 2"}]},
       {per_band, [{B, [{seed, S, [{n_c, Km}, {k_at_max_inv_prefix, Kk}, {max_inv_prefix, V},
                                   {e_inv, E}, {worst_inv_minus_e, W},
                                   {anti_k, AK}, {anti_max_inv, AV}, {anti_e_inv, AE},
                                   {anti_worst_inv_minus_e, AW}]}
                        || {S, {Km, Kk}, V, E, W, {AK, AV, AE, AW}} <- Cs]}
                   || {B, Cs} <- Rows]}]}}.

band_rows(B, Rows) -> element(2, lists:keyfind(B, 1, Rows)).

d3_champ(Mg, Bi, Rank, #{seed := S, sub := Sub, n := N, d := D}) ->
    Order = lists:reverse([P || {_R, P} <- lists:sort([{maps:get(P, Rank), P}
                                                       || P <- Sub])]),
    Scores = [prefix_point(Mg, Bi, Sub, Order, D, N, K)
              || K <- lists:seq(0, N)],
    %% The row reports the k at which the prefix climb reaches its LARGEST
    %% inversion count, which is where the exceedance leg has its best chance,
    %% and separately the worst (INV - E) over the whole climb, which is what
    %% bounds the leg.
    {V1, K1, E1} = lists:max([{V, K, E} || {_W, K, V, E} <- Scores]),
    %% The interior is where the comparison has content. At k = 0 and k = n
    %% both INV and E are exactly 0, so the STRICT exceedance test cannot fire
    %% there whatever else is true, and those two points are reported as the
    %% degenerate ones rather than folded into the margin.
    Inner = [W || {W, K, _V, _E} <- Scores, K > 0, K < N],
    Worst = worst_of(Inner),
    %% THE CONTRAST, so the test is shown not to be vacuous. The
    %% ANTI-CONSISTENT win set of size k is the k STRONGEST members of the
    %% sub-panel: the champion beats everyone above it and loses to everyone
    %% below, which is the maximally inverted arrangement the order admits.
    Anti = [prefix_point(Mg, Bi, Sub, lists:reverse(Order), D, N, K)
            || K <- lists:seq(0, N)],
    AWorst = worst_of([W || {W, K, _V, _E} <- Anti, K > 0, K < N]),
    {AV, AK, AE} = lists:max([{V, K, E} || {_W, K, V, E} <- Anti]),
    {S, {N, K1}, V1, E1, Worst, {AK, AV, AE, AWorst}}.

worst_of([]) -> 0.0;
worst_of(Ws) -> lists:max(Ws).

%% The k WEAKEST members of the sub-panel, which is the order-consistent win
%% set of that size and therefore the backbone climber's win set at that point.
prefix_point(Mg, Bi, Sub, Order, D, N, K) ->
    Win = lists:sublist(Order, K),
    V = inv_for_set(Mg, Bi, Sub, Win),
    E = e_inv(D, K, N),
    {V - E, K, V, E}.

%%---------------------------------------------------------------------------
%% D4. HOW OFTEN THE EXCEEDANCE LEG FIRES ON A REAL COEVOLUTION-FREE WIN
%% PATTERN, which is round 3's RC3-6 asked on the data that exists today.
%%
%% All 20 champions of phase 0's matrix are coevolution-free: they come from 20
%% separate arm S runs that never met during evolution. Each one's own INV is
%% compared with its own exact E[INV]. A champion at or below its own mean
%% cannot be above its own permutation maximum, so this bounds the number of
%% real champions that could satisfy the exceedance leg.
%%---------------------------------------------------------------------------
d4(Per) ->
    Rows = [{B, [{S, V, E, V > E, Dg}
                 || #{seed := S, inv := V, e := E, degenerate := Dg} <- Ms]}
            || {B, Ms} <- Per],
    {[f("-- D4. CAN A REAL COEVOLUTION-FREE WIN PATTERN EXCEED ITS OWN NULL C~n"
        "       MAXIMUM? THE 190-CELL LOWER BOUND SAYS NO, FOR ALL 20 --~n~n", []),
      f("These 20 champions come from 20 separate phase 0 arm S runs and never~n"
        "met during evolution, so every one of them is a real win pattern with no~n"
        "coevolution behind it. INV is compared with its own exact E[INV]; at or~n"
        "below the mean cannot be above the maximum.~n~n", [])]
         ++ lists:append([d4_band(B, Rs) || {B, Rs} <- Rows])
         ++ [f("This is a LOWER BOUND on the 25-member panel: only the 190~n"
               "champion-versus-champion cells exist on disk. The 5 scripted rungs~n"
               "can only ADD triples, so INV can rise; E[INV] moves too, and the~n"
               "sign of the comparison is NOT fixed in advance. The 25-member~n"
               "version is pre-registered at protocol step 2.~n~n", [])],
     {d4_exceedance_reachability_on_real_patterns,
      [{scope, "190-cell champion-only lower bound; the 25-member read is at step 2"},
       {per_band, [{B, [{champions, length(Rs)},
                        {inv_above_own_exact_mean, length([1 || {_S, _V, _E, T, _D} <- Rs, T])},
                        {inv_at_or_below_own_exact_mean,
                         length([1 || {_S, _V, _E, T, _D} <- Rs, not T])},
                        {degenerate, length([1 || {_S, _V, _E, _T, D} <- Rs, D])},
                        {can_any_exceed_its_own_permutation_maximum,
                         length([1 || {_S, _V, _E, T, _D} <- Rs, T]) > 0}]}
                   || {B, Rs} <- Rows]}]}}.

d4_band(B, Rs) ->
    Above = [S || {S, _V, _E, true, _D} <- Rs],
    [f("band ~.2f~n~n", [B]),
     f("seed  INV   E_INV    INV > E_INV  degenerate~n", [])]
        ++ [f("~w  ~4w  ~7.2f  ~11w  ~10w~n", [S, V, E, T, D])
            || {S, V, E, T, D} <- Rs]
        ++ [f("~n  champions whose INV is ABOVE their own exact mean: ~p of ~p ~w~n",
              [length(Above), length(Rs), Above]),
            f("  so champions that could exceed their own 200-permutation~n"
              "  MAXIMUM: at most ~p of ~p~n~n", [length(Above), length(Rs)])].

%%---------------------------------------------------------------------------
%% PROSE FRAME AND THE MACHINE-READABLE TERM.
%%---------------------------------------------------------------------------
head(Out, Seeds) ->
    [f("== EXP-067: THE PANEL DISCRIMINATOR REDESIGN, ITS INDICTMENT AND ITS"
       " REPLACEMENT'S TEST ==~n~n", []),
     f("date        = 2026-07-30~n", []),
     f("status      = ARITHMETIC over persisted phase 0 and phase 1 records.~n"
       "              Not a phase 1 measurement and not a phase 1 result.~n"
       "              Signs nothing on its own.~n", []),
     f("engine_pin  = a5e8bcfc5646827e9be49a9629f8a6a9678c814b"
       " (nothing was run at it here)~n", []),
     f("produced_by = scripts/exp067_panel_discriminator_redesign.escript~n", []),
     f("written_to  = ~ts~n", [Out]),
     f("reads       = ~ts~n              ~ts~n              ~ts~n",
       [?XP, ?RESIDUE, ?CALIB]),
     f("champions   = ~p, arm S, seeds ~p..~p~n",
       [length(Seeds), hd(Seeds), lists:last(Seeds)]),
     f("bands       = 0.05, 0.10, 0.15 on the integer grid as 8, 16, 24 of 160.~n", []),
     f("rng         = NONE. No draw, no bootstrap, no permutation sampled. The~n"
       "              exceedance leg's 200-permutation MAXIMUM is bounded below~n"
       "              by the exact closed-form mean instead of being sampled, so~n"
       "              every conclusion here holds whatever those 200 draws return.~n", []),
     f("no genome loaded, no match replayed, no arm re-run, no engine module"
       " read, no runner code written.~n~n", []),
     f("WHY THIS FILE EXISTS. The EXP-067 DESIGN gate's ROUND 3 (2026-07-30,~n"
       "verdict REDESIGN) found that the round-2 branch 6 / branch 7~n"
       "discriminator subtracts E[INV] without CONDITIONING on the realised~n"
       "k_C, so for a win pattern pinned near INV = 0 it collapses to a pure~n"
       "composition quantity whose SIGN is set by where k_C moves relative to~n"
       "n_C / 2. The gate's own arithmetic is D1 below. D2 and D3 measure the~n"
       "replacement against the same trajectory family, and D4 asks the~n"
       "reachability question RC3-6 raises, on the data that exists today.~n~n", [])].

foot() ->
    [f("-- WHAT THIS DOES AND DOES NOT ESTABLISH --~n~n", []),
     f("ESTABLISHES. The withdrawn mean-centred rule sends a pure transitive~n"
       "climb to branch 7 for 11 of the 13 seeds and on the median at every~n"
       "band (D1). The installed exceedance rule sends it to neither branch,~n"
       "for two independent reasons (D2), and cannot fire anywhere on the whole~n"
       "prefix-climb family for any champion at any band (D3).~n~n", []),
     f("DOES NOT ESTABLISH. That the exceedance leg is REACHABLE by a real~n"
       "coevolved win pattern. D4 measures the opposite on the only real~n"
       "patterns available: all 20 coevolution-free champions sit at or below~n"
       "their own exact mean at every band, so none of them could exceed its own~n"
       "permutation maximum. That is a lower bound over 190 cells and the~n"
       "25-member read is pre-registered at protocol step 2, but the direction it~n"
       "points is that PANEL-VISIBLE and branch 7 may both be hard to reach, and~n"
       "the pre-registration carries that as a declared limitation on BOTH.~n~n", []),
     f("DOES NOT ESTABLISH. Anything about phase 1 archive matrices, which do~n"
       "not exist. Every champion here is one of 20 independently evolved phase 0~n"
       "champions, not a checkpoint of a coevolutionary lineage.~n~n", [])].

term(Out, Gates, D1T, D2T, D3T, D4T) ->
    T = {panel_discriminator_redesign,
         [{date, "2026-07-30"},
          {status, "ARITHMETIC over persisted records; signs nothing"},
          {produced_by, "scripts/exp067_panel_discriminator_redesign.escript"},
          {written_to, Out},
          {reads, [?XP, ?RESIDUE, ?CALIB]},
          {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
          {no_genome_loaded, true}, {no_match_replayed, true},
          {no_arm_re_run, true}, {no_runner_code_written, true},
          {rng, none},
          {gates, [gate_term(G) || G <- Gates]},
          D1T, D2T, D3T, D4T]},
    [f("== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n", []),
     f("~w.~n", [T])].

gate_term({strengths_parsed, A, B}) ->
    {strengths_parsed, [{mine, A}, {stated, B}, {agree, A =:= B}]};
gate_term({Tag, B, Mine, Stated}) ->
    {Tag, B, [{mine, Mine}, {stated, Stated}, {agree, Mine =:= Stated}]}.

median(Xs) ->
    S = lists:sort(Xs),
    L = length(S),
    median_at(S, L, L rem 2).

median_at(S, L, 1) -> float(lists:nth((L div 2) + 1, S));
median_at(S, L, _) -> (lists:nth(L div 2, S) + lists:nth((L div 2) + 1, S)) / 2.

round4(X) -> round(X * 10000) / 10000.

sf(X) when X >= 0 -> lists:flatten(io_lib:format("+~.4f", [X]));
sf(X) -> lists:flatten(io_lib:format("~.4f", [X])).

f(Fmt, Args) -> io_lib:format(Fmt, Args).
