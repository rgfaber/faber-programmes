#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% EXP-066 cross-play, TWO RECOMPUTATIONS OWED TO THE EXP-067 DESIGN GATE.
%%% READ-ONLY over persisted phase 0 records. No genome is loaded, no match is
%%% replayed, no arm is re-run, no engine module is touched.
%%%
%%% WHY THIS EXISTS. The EXP-067 phase 1 pre-registration's DESIGN gate
%%% (2026-07-30, verdict BUILD_WITH_CHANGES) raised two findings that both
%%% require a number the corpus does not persist:
%%%
%%%   RC-8. The seeding section and IF-12 lean on the claim that the entire
%%%   within-tier cyclic residue of phase 0's kill-mode tier routes through
%%%   seeds 2003 and 2013, so that the remaining 11 champions carry ZERO
%%%   cycles at every band. That recomputation came from an adversarial
%%%   review pass and was persisted in no record. A pre-registration may not
%%%   hang a verdict label (POCKET RETAINED vs POCKET ENTERED OR CREATED) on
%%%   a number that exists only in a reviewer's notes. Section B is that
%%%   recomputation.
%%%
%%%   RC-3. The phase 1 decision rule's NO CYCLING branch contained an
%%%   ABSOLUTE condition, "the median A1 run's INV = 0 at band 0.10", while
%%%   SC3a simultaneously forces the phase 1 panel to reproduce
%%%   exp066_crossplay.txt cell for cell. So the 13 seeds' checkpoint-0
%%%   inversion counts are already determined by data on disk and were never
%%%   checked. Section C computes them. If the median is 1 or more, the
%%%   absolute condition was unreachable before the first run and the phase 1
%%%   negative had to be restated relative to this baseline.
%%%
%%% WHAT IT IS NOT. This is not a phase 1 runner and it measures nothing new.
%%% It is arithmetic over the win-rate matrix persisted in
%%% exp066_crossplay.txt. It signs nothing on its own; it supplies two
%%% baselines that the phase 1 pre-registration cites.
%%%
%%% NOTHING RANDOM HAPPENS HERE. There is no RNG call, no bootstrap and no
%%% permutation sample in this script, so there is no seed to persist: every
%%% number below is a deterministic function of the persisted matrix. Null C's
%%% closed form is evaluated exactly instead of sampled.
%%%
%%% THE COUNTER IS THE INTEGER COUNTER phase 1 pre-registers. Cells are wins
%%% out of 160, bands are 8, 16 and 24 out of 160, and the test is strict >
%%% on the integers. The float counter phase 0 used is ALSO run, and both are
%%% gated against the persisted records so a parse error cannot pass silently.
%%%
%%% Usage: scripts/exp066_residue_and_inv0.escript [OutFile]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(ARCH, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").
-define(XP, ?ARCH "exp066_crossplay.txt").
-define(VERIFY, ?ARCH "exp066_within_tier_verify.txt").
-define(RECOUNT, ?ARCH "exp066_within_tier_recount.txt").
-define(OUT, ?ARCH "exp066_residue_and_inv0.txt").

-define(MATCHES, 160).

%% band, and the same band on the integer grid of 160 matches per cell.
-define(BANDS, [{0.05, 8}, {0.10, 16}, {0.15, 24}]).

%% Phase 0's kill-mode tier, which is exactly the phase 1 seed set, and the two
%% long-standoff members the gate's finding is about.
-define(KILL, [2001, 2002, 2003, 2004, 2005, 2006, 2008,
               2010, 2012, 2013, 2017, 2019, 2020]).
-define(LONG_STANDOFF, [2003, 2013]).

%% GATE 1. The float counter over all 20 champions must reproduce
%% exp066_crossplay.txt's own counts: {cycles, ordered, forward, backward,
%% decisive}.
-define(STATED_FLOAT, [{0.05, {49, 73, 24, 25, 169}},
                       {0.10, {18, 28, 10, 8, 152}},
                       {0.15, {12, 18, 6, 6, 141}}]).

%% GATE 2. The integer counter over all 20 champions must reproduce
%% exp066_within_tier_verify.txt section K's exact rows: {decisive, cyclable,
%% cycles}.
-define(STATED_EXACT_FULL, [{0.05, {168, 789, 49}},
                            {0.10, {150, 582, 18}},
                            {0.15, {141, 487, 12}}]).

%% GATE 3. The same, over the 13-member kill tier.
-define(STATED_EXACT_KILL, [{0.05, {74, 243, 8}},
                            {0.10, {70, 204, 4}},
                            {0.15, {67, 179, 4}}]).

main(Args) ->
    Out = out(Args),
    {Seeds, Wm} = xp_matrix(?XP),
    Idx = lists:seq(1, length(Seeds)),
    Km = int_matrix(Wm, Idx),
    Dev = worst_dev(Wm, Idx),
    Gates = gates(Wm, Km, Idx, Seeds),
    GLines = gate_lines(Seeds, Dev, Gates),
    io:put_chars(GLines),
    ok = gate(Dev, Gates),
    {BLines, BTerm} = residue(Km, Idx, Seeds),
    {CLines, CTerm} = inv0(Km, Idx, Seeds),
    Lines = lists:append([head(Out, Seeds), GLines, BLines, CLines, foot(),
                          term(Out, Seeds, Dev, Gates, BTerm, CTerm)]),
    ok = file:write_file(Out, [Lines]),
    io:format("~nwritten: ~ts~n", [Out]).

out([P | _]) -> P;
out([]) -> ?OUT.

%%---------------------------------------------------------------------------
%% THE MATRIX. Parsed out of the persisted report's machine-readable term, never
%% retyped. Cells are WIN RATES of ROW against COLUMN over 160 matches, diagonal
%% 0.0. W(J,I) is never inferred from W(I,J): 472 of the 30,400 matches were
%% draws, so W(I,J) + W(J,I) can fall short of 1.0.
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

%% THE INTEGER MATRIX. At 160 matches per cell every win rate is an exact
%% multiple of 1/160, so K(I,J) = W(I,J) * 160 is an integer and the recovery is
%% lossless. worst_dev/2 measures the distance of every cell from its integer
%% numerator and gates on it rather than assuming it.
int_matrix(Wm, Idx) ->
    list_to_tuple([list_to_tuple([round(el(Wm, I, J) * ?MATCHES) || J <- Idx])
                   || I <- Idx]).

worst_dev(Wm, Idx) ->
    lists:max([abs(el(Wm, I, J) * ?MATCHES - round(el(Wm, I, J) * ?MATCHES))
               || I <- Idx, J <- Idx]).

%%---------------------------------------------------------------------------
%% THE COUNTERS. exp066's convention, character for character, parametrised by a
%% margin function and a band so the same code runs on the float grid (band 0.05)
%% and on the integer grid (band 8 of 160).
%%---------------------------------------------------------------------------
mg(M) -> fun(I, J) -> el(M, I, J) - el(M, J, I) end.

el(M, I, J) -> element(J, element(I, M)).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

triples(Idx) -> [{I, J, Z} || I <- Idx, J <- Idx, Z <- Idx, I < J, J < Z].

%% exp057's counter, over ORDERED tuples. NOT a cycle count: one cyclic triangle
%% contributes twice in one rotation and once in the other.
ordered(Mg, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]).

forward(Mg, Idx, B) ->
    [{I, J, Z} || {I, J, Z} <- triples(Idx),
                  Mg(I, J) > B, Mg(J, Z) > B, Mg(Z, I) > B].

backward(Mg, Idx, B) ->
    [{I, Z, J} || {I, J, Z} <- triples(Idx),
                  Mg(I, Z) > B, Mg(Z, J) > B, Mg(J, I) > B].

cyc_list(Mg, Idx, B) -> forward(Mg, Idx, B) ++ backward(Mg, Idx, B).

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

%%---------------------------------------------------------------------------
%% A. THE GATES. Three of them, each against a literal quoted from a persisted
%% record rather than against something this script computed itself. A parse
%% error, an index error or a counter defect fails at least one, and the script
%% stops rather than writing numbers nobody can trust.
%%---------------------------------------------------------------------------
gates(Wm, Km, Idx, Seeds) ->
    Kill = idx_of(?KILL, Seeds),
    [{float_full, B, float_row(Wm, Idx, B), St} || {B, St} <- ?STATED_FLOAT]
        ++ [{exact_full, B, exact_row(Km, Idx, Bi), St}
            || {{B, Bi}, {_B2, St}} <- lists:zip(?BANDS, ?STATED_EXACT_FULL)]
        ++ [{exact_kill, B, exact_row(Km, Kill, Bi), St}
            || {{B, Bi}, {_B2, St}} <- lists:zip(?BANDS, ?STATED_EXACT_KILL)].

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
     f("worst distance of any cell from its integer numerator over 160 = ~.1f~n",
       [Dev]),
     f("  (so K(I,J) = W(I,J) * 160 is exact and the integer counter is lossless)~n~n", []),
     f("tag          band  mine                      stated                    verdict~n", [])]
        ++ [f("~-12w ~.2f  ~-25w ~-25w ~s~n", [T, B, Mine, St, agree(Mine =:= St)])
            || {T, B, Mine, St} <- Gates]
        ++ [f("~nfloat_full  = {cycles,ordered,forward,backward,decisive} against~n"
              "              ~ts (its own counts, float counter)~n", [?XP]),
            f("exact_full  = {decisive,cyclable,cycles} against ~ts~n"
              "              section K (the exact-arithmetic recount)~n", [?VERIFY]),
            f("exact_kill  = the same over the 13-member kill tier, same section~n~n", []),
            f("All three gate. Any DISAGREE stops the script.~n~n", [])].

agree(true) -> "AGREE";
agree(false) -> "DISAGREE";
agree(_Other) -> "?".

idx_of(Ss, Seeds) ->
    [I || {I, S} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), lists:member(S, Ss)].

seeds_at(Is, Seeds) -> [lists:nth(I, Seeds) || I <- Is].

%%---------------------------------------------------------------------------
%% B. THE WITHIN-TIER RESIDUE WITHOUT THE TWO LONG-STANDOFF SEEDS (RC-8).
%%
%% Phase 0's kill-mode tier is 13 champions and 286 unordered triples, and its
%% cyclic residue is 8 / 4 / 4 at bands 0.05 / 0.10 / 0.15. The design's seeding
%% section claims every one of those contains seed 2003 or seed 2013, so the
%% remaining 11 champions and 165 triples carry zero. That is the claim this
%% section either confirms or refutes, on the integer grid, at all three bands.
%%
%% A zero here is NOT evidence that the residue is unreal. It locates the
%% residue: at the boundary between the long-standoff regime and the orbit
%% regimes. That is what IF-12's POCKET RETAINED label rests on.
%%---------------------------------------------------------------------------
residue(Km, _Idx, Seeds) ->
    Kill = idx_of(?KILL, Seeds),
    Res = idx_of(?KILL -- ?LONG_STANDOFF, Seeds),
    Mg = mg(Km),
    Rows = [{B, Bi, counts(Mg, Kill, Bi), counts(Mg, Res, Bi),
             [seeds_at([I, J, Z], Seeds) || {I, J, Z} <- cyc_list(Mg, Kill, Bi)]}
            || {B, Bi} <- ?BANDS],
    {[f("-- B. THE KILL TIER'S CYCLIC RESIDUE WITHOUT SEEDS 2003 AND 2013 --~n~n", []),
      f("Answers the DESIGN gate's RC-8. Integer counter, strict > on the 160~n"
        "grid, bands 8 / 16 / 24 of 160. Nothing is swept and no band is moved.~n~n", []),
      f("kill tier   = ~w  (13 champions, ~p pairs, ~p unordered triples)~n",
        [?KILL, length(pairs(Kill)), length(triples(Kill))]),
      f("removed     = ~w  (the two long-standoff regimes)~n", [?LONG_STANDOFF]),
      f("residue set = ~w~n", [?KILL -- ?LONG_STANDOFF]),
      f("              (11 champions, ~p pairs, ~p unordered triples)~n~n",
        [length(pairs(Res)), length(triples(Res))]),
      f("band  set      cycles  cyclable  triples  decisive  of_pairs  share    E_orient~n", [])]
         ++ lists:append([res_lines(B, Kill, Res, Kc, Rc) || {B, _Bi, Kc, Rc, _Cy} <- Rows])
         ++ [f("~nshare    = cycles / cyclable triples, the only scale-matched quantity~n"
               "           across index sets of different size.~n", []),
             f("E_orient = cyclable / 4, the closed-form expectation of a random~n"
               "           orientation of the same decisive edges. REPORTED as a~n"
               "           reference, not used as a test: the orientation null~n"
               "           preserves no strength structure, so any matrix carrying a~n"
               "           dominance ordering falls far below it.~n~n", []),
             f("EVERY CYCLE OF THE 13-MEMBER KILL TIER, with whether it contains a~n"
               "long-standoff seed. The residue count above must equal the number of~n"
               "cycles containing NEITHER, which is checked on the last line of each~n"
               "band block rather than asserted.~n~n", [])]
         ++ lists:append([cyc_block(B, Ms, Rc) || {B, _Bi, _Kc, Rc, Ms} <- Rows])
         ++ [f("~n", [])],
     {residue,
      [{kill_tier, ?KILL}, {removed, ?LONG_STANDOFF},
       {residue_set, ?KILL -- ?LONG_STANDOFF},
       {kill_pairs, length(pairs(Kill))}, {kill_triples, length(triples(Kill))},
       {residue_pairs, length(pairs(Res))}, {residue_triples, length(triples(Res))},
       {at_band, [{B, [{kill, ct(Kc)}, {residue, ct(Rc)},
                       {kill_cycle_members, Ms},
                       {cycles_with_a_long_standoff_seed, length(Ms) - free(Ms)},
                       {cycles_with_neither, free(Ms)},
                       {residue_count_equals_cycles_with_neither,
                        element(1, Rc) =:= free(Ms)}]}
                  || {B, _Bi, Kc, Rc, Ms} <- Rows]}]}}.

ct({Cyc, Ord, Fw, Bw, Id, Dec, Cbl}) ->
    [{unordered_cycles, Cyc}, {ordered_exp057, Ord}, {forward, Fw}, {backward, Bw},
     {identity_2f_plus_b_equals_ordered, Id}, {decisive_edges, Dec},
     {cyclable_triples, Cbl}].

res_lines(B, Kill, Res, Kc, Rc) ->
    [res_line(B, "kill(13)", Kill, Kc), res_line(B, "residue(11)", Res, Rc)].

res_line(B, Tag, Is, {Cyc, _Ord, _Fw, _Bw, _Id, Dec, Cbl}) ->
    f("~.2f  ~-11s ~6w  ~8w ~8w  ~8w  ~8w  ~.4f   ~7.2f~n",
      [B, Tag, Cyc, Cbl, length(triples(Is)), Dec, length(pairs(Is)),
       Cyc / max(1, Cbl), Cbl / 4]).

cyc_block(B, Ms, {Cyc, _Ord, _Fw, _Bw, _Id, _Dec, _Cbl}) ->
    [f("band ~.2f : ~p cycles in the kill tier~n", [B, length(Ms)])]
        ++ [f("  ~w -> ~w -> ~w -> ~w   ~s~n", [S1, S2, S3, S1, tag_long([S1, S2, S3])])
            || [S1, S2, S3] <- Ms]
        ++ [f("  contains a long-standoff seed: ~p | contains neither: ~p | "
              "residue count ~p  ~s~n~n",
              [length(Ms) - free(Ms), free(Ms), Cyc, agree(Cyc =:= free(Ms))])].

free(Ms) -> length([1 || M <- Ms, not has_long(M)]).

has_long(M) -> lists:any(fun(S) -> lists:member(S, ?LONG_STANDOFF) end, M).

tag_long(M) -> long_tag(has_long(M)).

long_tag(true) -> "contains 2003 or 2013";
long_tag(false) -> "CONTAINS NEITHER".

%%---------------------------------------------------------------------------
%% C. THE 13 SEEDS' CHECKPOINT-0 PANEL INVERSION COUNTS (RC-3).
%%
%% INV(C) as the phase 1 design defines it, under Null C: restrict to the
%% sub-panel of members whose edge to C is band-decisive (size n_C, of which C
%% beats k_C); for each band-decisive pair (P,Q) inside that sub-panel, the
%% triple {C,P,Q} counts iff it is a cycle. Since a cycle needs all three edges
%% decisive, that is exactly the number of cyclic triples of the panel matrix
%% that contain C.
%%
%% SCOPE, STATED PLAINLY. The phase 1 panel has 25 members: these 20 champions
%% plus 5 scripted rungs. Only the 190 champion-versus-champion cells exist on
%% disk, and SC3a forces the phase 1 panel to reproduce them cell for cell, so
%% what is computed here is the CHAMPION-ONLY part of INV_0. Adding the rung
%% members can only add triples, never remove one, and the gunless-leg exclusion
%% removes only triples through sitting_duck or spinner, which cannot appear
%% here. So every number in this section is a LOWER BOUND on the same seed's
%% INV_0 against the full 25-member panel under the primary (gunless-excluded)
%% count.
%%
%% E[INV] is Null C's closed form, evaluated EXACTLY. No permutation is sampled,
%% so this section uses no RNG at all.
%%---------------------------------------------------------------------------
inv0(Km, Idx, Seeds) ->
    Mg = mg(Km),
    Rows = [{B, [inv_one(Mg, Idx, Bi, C, Seeds) || C <- Idx]} || {B, Bi} <- ?BANDS],
    Kill = ?KILL,
    {[f("-- C. THE 13 PHASE 1 SEEDS' INV AT CHECKPOINT 0 --~n~n", []),
      f("Answers the DESIGN gate's RC-3. INV(C) = the number of band-decisive~n"
        "cyclic triples of the panel matrix that contain C, which is Null C's~n"
        "statistic evaluated on the panel itself.~n~n", []),
      f("LOWER BOUND, and why: only the 190 champion-versus-champion cells of the~n"
        "25-member phase 1 panel exist on disk (SC3a forces the panel to reproduce~n"
        "them cell for cell). The 5 scripted rungs can only ADD triples. The~n"
        "gunless-leg exclusion removes triples through sitting_duck or spinner,~n"
        "neither of which is in this matrix, so it removes nothing here.~n~n", []),
      f("n_C   = members whose edge to C is band-decisive~n"
        "k_C   = how many of those C beats~n"
        "D_C   = band-decisive pairs inside that sub-panel~n"
        "INV   = cyclic triples containing C~n"
        "E_INV = D_C * k_C * (n_C - k_C) / (n_C * (n_C - 1)), Null C's closed form,~n"
        "        evaluated exactly, no permutation sampled, no RNG used~n~n", [])]
         ++ lists:append([inv_band_lines(B, Rs, Kill) || {B, Rs} <- Rows])
         ++ [f("CROSS-CHECK. Every cyclic triple has three members, so the sum of INV~n"
               "over all 20 champions must be three times the matrix's cycle count.~n", [])]
         ++ [inv_xc(B, Rs, Km, Idx, Bi) || {{B, Bi}, {_B, Rs}} <- lists:zip(?BANDS, Rows)]
         ++ [f("~n", [])],
     {inv_at_checkpoint_0,
      [{scope, "champion-only part of INV_0; a LOWER BOUND on the 25-member panel"},
       {panel_cells_on_disk, 190}, {rng_used, none},
       {at_band, [{B, [{seed, S, [{n_c, N}, {k_c, K}, {d_c, D}, {inv, V},
                                  {e_inv, E}, {members, Ms}]}
                       || {S, N, K, D, V, E, Ms} <- Rs]}
                  || {B, Rs} <- Rows]},
       {over_the_13_seeds,
        [{B, [{seeds, Kill},
              {inv, [V || {S, _N, _K, _D, V, _E, _Ms} <- Rs, lists:member(S, Kill)]},
              {median, median(kill_invs(Rs, Kill))},
              {min, lists:min(kill_invs(Rs, Kill))},
              {max, lists:max(kill_invs(Rs, Kill))},
              {seeds_with_inv_at_least_1,
               length([1 || V <- kill_invs(Rs, Kill), V >= 1])},
              {of_seeds, length(Kill)},
              {median_is_zero, median(kill_invs(Rs, Kill)) == 0.0}]}
         || {B, Rs} <- Rows]}]}}.

inv_one(Mg, Idx, Bi, C, Seeds) ->
    Sub = [P || P <- Idx, P =/= C, abs(Mg(C, P)) > Bi],
    N = length(Sub),
    K = length([P || P <- Sub, Mg(C, P) > Bi]),
    Ps = [{P, Q} || P <- Sub, Q <- Sub, P < Q, abs(Mg(P, Q)) > Bi],
    Cyc = [{P, Q} || {P, Q} <- Ps, is_cycle(Mg, Bi, C, P, Q)],
    {lists:nth(C, Seeds), N, K, length(Ps), length(Cyc),
     e_inv(length(Ps), K, N), [seeds_at([C, P, Q], Seeds) || {P, Q} <- Cyc]}.

%% All three edges are decisive by construction of the caller, so the triple is
%% a cycle iff every member has out-degree exactly 1 inside it.
is_cycle(Mg, Bi, A, B, C) ->
    lists:sort([out_deg(Mg, Bi, X, [A, B, C]) || X <- [A, B, C]]) =:= [1, 1, 1].

out_deg(Mg, Bi, X, Ms) -> length([1 || Y <- Ms, Y =/= X, Mg(X, Y) > Bi]).

e_inv(_D, _K, N) when N < 2 -> 0.0;
e_inv(D, K, N) -> D * K * (N - K) / (N * (N - 1)).

kill_invs(Rs, Kill) ->
    [V || {S, _N, _K, _D, V, _E, _Ms} <- Rs, lists:member(S, Kill)].

inv_band_lines(B, Rs, Kill) ->
    Vs = kill_invs(Rs, Kill),
    [f("band ~.2f~n~n", [B]),
     f("seed  in_seed_set  n_C  k_C  D_C  INV  E_INV~n", [])]
        ++ [f("~w  ~-11w ~4w ~4w ~4w ~4w  ~6.2f~n",
              [S, lists:member(S, Kill), N, K, D, V, E])
            || {S, N, K, D, V, E, _Ms} <- Rs]
        ++ [f("~nover the 13 phase 1 seeds at band ~.2f:~n", [B]),
            f("  INV values in seed order ~w~n", [Vs]),
            f("  sorted ~w~n", [lists:sort(Vs)]),
            f("  median ~.1f | min ~p | max ~p | seeds with INV >= 1: ~p of 13~n",
              [median(Vs), lists:min(Vs), lists:max(Vs),
               length([1 || V <- Vs, V >= 1])]),
            f("  median is exactly 0: ~w~n~n", [median(Vs) == 0.0]),
            f("  the triples behind each nonzero seed:~n", [])]
        ++ lists:append([[f("    ~w : ~w~n", [S, Ms]) || {S, _N, _K, _D, V, _E, Ms} <- Rs,
                                                        lists:member(S, Kill), V > 0]])
        ++ [f("~n", [])].

inv_xc(B, Rs, Km, Idx, Bi) ->
    Sum = lists:sum([V || {_S, _N, _K, _D, V, _E, _Ms} <- Rs]),
    {Cyc, _O, _F, _Bw, _Id, _Dec, _Cbl} = counts(mg(Km), Idx, Bi),
    f("  band ~.2f  sum of INV over 20 = ~p | 3 x cycles = ~p  ~s~n",
      [B, Sum, 3 * Cyc, agree(Sum =:= 3 * Cyc)]).

%%---------------------------------------------------------------------------
%% Report scaffolding.
%%---------------------------------------------------------------------------
head(Out, Seeds) ->
    [f("== EXP-066 cross-play: THE RESIDUE WITHOUT 2003/2013, AND THE 13 SEEDS' INV AT CHECKPOINT 0 ==~n~n", []),
     f("date        = 2026-07-30~n", []),
     f("status      = RECOMPUTATION over persisted phase 0 records. Not a phase 1~n"
       "              measurement and not a phase 1 result. Signs nothing on its own.~n", []),
     f("engine_pin  = a5e8bcfc5646827e9be49a9629f8a6a9678c814b (nothing was run at it here)~n", []),
     f("produced_by = scripts/exp066_residue_and_inv0.escript~n", []),
     f("written_to  = ~ts~n", [Out]),
     f("reads       = ~ts   (the matrix, parsed from its machine-readable term)~n", [?XP]),
     f("              ~ts   (gate literals, sections C and K)~n", [?VERIFY]),
     f("              ~ts   (the cycle listing this cross-checks against)~n", [?RECOUNT]),
     f("champions   = ~p, arm S, seeds ~p..~p~n", [length(Seeds), hd(Seeds), lists:last(Seeds)]),
     f("bands       = 0.05, 0.10, 0.15 on the integer grid as 8, 16, 24 of 160.~n"
       "              FIXED. Not swept, not moved, not chosen after a count.~n", []),
     f("rng         = NONE. No draw, no bootstrap, no permutation sample. Every~n"
       "              number here is a deterministic function of the matrix, so~n"
       "              there is no seed to persist.~n", []),
     f("no genome loaded, no match replayed, no arm re-run, no engine module read.~n~n", []),
     f("WHY THIS FILE EXISTS. The EXP-067 phase 1 pre-registration's DESIGN gate~n"
       "(2026-07-30, BUILD_WITH_CHANGES) required two numbers that the corpus did~n"
       "not persist:~n~n", []),
     f("  RC-8. The claim that phase 0's whole within-tier cyclic residue routes~n"
       "  through seeds 2003 and 2013, on which IF-12's POCKET RETAINED label and~n"
       "  hypothesis H4 both rest, came from an adversarial review pass and was~n"
       "  persisted nowhere. Section B recomputes it.~n~n", []),
     f("  RC-3. The phase 1 NO CYCLING branch carried an ABSOLUTE condition, the~n"
       "  median A1 run's INV = 0, while SC3a forces the phase 1 panel to reproduce~n"
       "  this same matrix cell for cell. So the 13 seeds' INV at checkpoint 0 was~n"
       "  already fixed by data on disk and had never been read. Section C reads it.~n~n", [])].

foot() ->
    [f("-- WHAT THIS ESTABLISHES AND WHAT IT DOES NOT --~n~n", []),
     f("ESTABLISHES. Two baselines, both deterministic functions of a persisted~n"
       "matrix, both reproducible by re-running this script: where phase 0's~n"
       "within-tier cyclic residue sits with respect to the two long-standoff~n"
       "seeds, and what the 13 phase 1 seeds' inversion counts are before any~n"
       "coevolution run touches them.~n~n", []),
     f("DOES NOT ESTABLISH. Nothing about coevolution, nothing about phase 1, and~n"
       "nothing new about the substrate. No match was played. The counts are the~n"
       "same 190 cells phase 0 measured, read with the integer counter phase 1~n"
       "pre-registers instead of the float counter phase 0 used.~n~n", []),
     f("NOT A NULL. E_orient and E_INV are closed forms printed for context. No~n"
       "threshold in this file gates anything, and no phase 1 verdict is decided~n"
       "here. The phase 1 decision rule cites these numbers as BASELINES only.~n~n", [])].

term(Out, Seeds, Dev, Gates, BTerm, CTerm) ->
    T = {residue_and_inv0,
         [{date, "2026-07-30"},
          {status, "RECOMPUTATION over persisted phase 0 records; signs nothing"},
          {produced_by, "scripts/exp066_residue_and_inv0.escript"},
          {written_to, Out},
          {reads, [?XP, ?VERIFY, ?RECOUNT]},
          {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
          {no_genome_loaded, true}, {no_match_replayed, true},
          {no_arm_re_run, true}, {rng_used, none},
          {champions, length(Seeds)}, {seeds, Seeds},
          {bands, [{B, Bi, ?MATCHES} || {B, Bi} <- ?BANDS]},
          {counter, "integer, strict > on wins out of 160"},
          {worst_cell_distance_from_integer_numerator, Dev},
          {gates, [{T0, B, [{mine, Mine}, {stated, St}, {agree, Mine =:= St}]}
                   || {T0, B, Mine, St} <- Gates]},
          BTerm, CTerm]},
    [f("~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n", []),
     f("~w.~n", [T])].

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
