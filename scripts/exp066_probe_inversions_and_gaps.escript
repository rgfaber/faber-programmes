#!/usr/bin/env escript
%%! -noshell
%%
%% EXP-066 CLAIM-gate probe, READ-ONLY. Answers two questions from the FEED ONLY:
%%
%%   (a) LADDER INVERSIONS: how many champions beat predictive_gun while losing
%%       to a LOWER rung, under four increasingly weak definitions of "losing",
%%       and would inverted/1 have fired on each champion?
%%   (b) MEMORISERS: the train-to-held-out gap for every seed of every arm.
%%
%% It reads NOTHING but the raw feed. No genome is loaded, no match is replayed,
%% no runner function is called, so it cannot contend with the amendment in
%% flight. Every printed number traces to one line of the feed.
%%
%% Usage: escript scripts/exp066_probe_inversions_and_gaps.escript <feed>

main([Feed]) ->
    {ok, Bin} = file:read_file(Feed),
    Flat = flatten(Bin),
    {B, RLine} = constants(Flat),
    Arms = [{A, seeds(Flat, A), profiles(Flat, A)} || A <- [s, l, d]],
    io:format("SOURCE = ~s~n", [Feed]),
    io:format("B = ~.4f   R_line = ~.4f  (parsed from the FROZEN CONSTANTS line)~n", [B, RLine]),
    %% PROVENANCE. The seed line's W and the predictive_gun row of the same
    %% seed's rung profile are two independent emits of one measurement. If they
    %% agree on all 40 champions, the rung profile belongs to the champion whose
    %% W the addendum already reconciled against the archived genome.
    %% The seed line prints W to 4 decimals and the profile term is exact, so
    %% agreement is to half of the last printed digit.
    Dis = [{A, S, maps:get(w, M), pg(prof(S, Profs))}
           || {A, Seeds, Profs} <- Arms, {S, M} <- Seeds,
              abs(maps:get(w, M) - pg(prof(S, Profs))) > 0.00005],
    io:format("seed-line W vs profile's predictive_gun row: disagreements beyond~n"
              "  the seed line's 4-decimal rounding = ~p~n"
              "  (so every W below is taken EXACT from the profile term, not the rounded line)~n~n",
              [Dis]),
    part_a(Arms, B, RLine),
    part_b(Arms, B),
    part_c(Arms),
    ok.

%%%--------------------------------------------------------------------------
%%% PART C: what separates the two modes found in part B, and whether the
%%% near-parity mode's ladder is monotone.
%%%--------------------------------------------------------------------------
part_c(Arms) ->
    io:format("~n================ PART C: MODE STRUCTURE ================~n"),
    io:format("LADDER ORDER = ~p~n", [ladder()]),
    io:format("MONOTONE := W non-increasing along that order (no inversion of ANY kind)~n~n"),
    lists:foreach(
      fun({A, Seeds, Profs}) ->
          io:format("---- ARM ~s : {seed, gap, W_strafer, W_duck, W_spinner, shots, monotone} ----~n",
                    [string:uppercase(atom_to_list(A))]),
          Rows = [{S, r5(1.0 - pg(prof(S, Profs))), r5(rung(circle_strafer, prof(S, Profs))),
                   r5(rung(sitting_duck, prof(S, Profs))), r5(rung(spinner, prof(S, Profs))),
                   r2(maps:get(shots, M)), monotone(prof(S, Profs))}
                  || {S, M} <- Seeds],
          lists:foreach(fun(R) -> io:format("    ~p~n", [R]) end, Rows),
          Hi = [R || {_, G, _, _, _, _, _} = R <- Rows, G > 0.15],
          Lo = [R || {_, G, _, _, _, _, _} = R <- Rows, G =< 0.15],
          io:format("  HIGH-gap: n=~p  W_strafer max=~p  monotone=~p/~p~n",
                    [length(Hi), lists:max([0.0] ++ [C || {_, _, C, _, _, _, _} <- Hi]),
                     length([1 || {_, _, _, _, _, _, true} <- Hi]), length(Hi)]),
          io:format("  LOW-gap : n=~p  W_strafer min=~p  monotone=~p/~p~n~n",
                    [length(Lo), lists:min([9.9] ++ [C || {_, _, C, _, _, _, _} <- Lo]),
                     length([1 || {_, _, _, _, _, _, true} <- Lo]), length(Lo)])
      end, Arms).

ladder() -> [sitting_duck, spinner, rammer, circle_strafer, predictive_gun].

rung(K, P) -> element(2, lists:keyfind(K, 1, P)).

monotone(P) ->
    Ws = [rung(K, P) || K <- ladder()],
    Ws =:= lists:reverse(lists:sort(Ws)).

%%%--------------------------------------------------------------------------
%%% PART A: ladder inversions.
%%%--------------------------------------------------------------------------
part_a(Arms, B, RLine) ->
    io:format("================ PART A: LADDER INVERSIONS ================~n"),
    io:format("beats the floor bot := W(predictive_gun) >= B = ~.4f~n", [B]),
    io:format("LOSS      := L(rung) > W(rung)          (inverted/1's own criterion)~n"),
    io:format("SUBLINE   := W(rung) < R_line = ~.4f    (the run's own per-seed line)~n", [RLine]),
    io:format("DRAWPARK  := D(rung) > W(rung) and D(rung) > L(rung)~n"),
    io:format("ORDER     := W(rung) < W(predictive_gun)~n~n"),
    lists:foreach(fun(Arm) -> arm_a(Arm, B, RLine) end, Arms),
    totals_a(Arms, B, RLine).

arm_a({A, Seeds, Profs}, B, RLine) ->
    io:format("---- ARM ~s, ~p champions ----~n", [string:uppercase(atom_to_list(A)),
                                                   length(Seeds)]),
    Med = median_seed(Seeds),
    io:format("median champion (median_res/1) = seed ~p, W=~.4f~n", [Med, w_of(Med, Seeds)]),
    lists:foreach(fun(S) -> row_a(S, Seeds, Profs, B, RLine) end, [S || {S, _} <- Seeds]),
    io:format("  inverted/1 WOULD fire on seeds: ~p~n", [[S || {S, _} <- Seeds,
                                                              inverted(prof(S, Profs))]]),
    io:format("  inverted/1 DOES fire (median champion ~p only) = ~p~n~n",
              [Med, inverted(prof(Med, Profs))]).

row_a(S, Seeds, Profs, B, RLine) ->
    P = prof(S, Profs),
    Wpg = pg(P),
    Beats = Wpg >= B,
    io:format("  seed ~p  W_pg=~.5f beats=~p | LOSS=~p SUBLINE=~p DRAWPARK=~p ORDER=~p~n",
              [S, Wpg, Beats,
               hits(P, fun(_K, W, L, _D) -> L > W end),
               hits(P, fun(_K, W, _L, _D) -> W < RLine end),
               hits(P, fun(_K, W, L, D) -> D > W andalso D > L end),
               hits(P, fun(_K, W, _L, _D) -> W < Wpg end)]),
    ok = detail(S, P, Seeds).

%% Print the offending cells for any champion with a LOSS or a SUBLINE.
detail(S, P, Seeds) ->
    Bad = [{K, W, L, D} || {K, W, L, D} <- lower(P), L > W orelse W < 0.4968],
    detail(S, Bad, Seeds, length(Bad)).

detail(_S, _Bad, _Seeds, 0) -> ok;
detail(S, Bad, Seeds, _N) ->
    io:format("      seed ~p shots=~.2f  offending cells: ~p~n",
              [S, shots_of(S, Seeds), [{K, r4(W), r4(L), r4(D)} || {K, W, L, D} <- Bad]]),
    ok.

totals_a(Arms, B, RLine) ->
    io:format("---- TOTALS (champions that BEAT predictive_gun and ...) ----~n"),
    lists:foreach(
      fun({A, Seeds, Profs}) ->
          Bs = [S || {S, _} <- Seeds, pg(prof(S, Profs)) >= B],
          Cnt = fun(F) -> length([S || S <- Bs, hits(prof(S, Profs), F) =/= []]) end,
          Which = fun(F) -> [{S, hits(prof(S, Profs), F)} || S <- Bs,
                                                             hits(prof(S, Profs), F) =/= []] end,
          io:format("arm ~s: beat pg = ~p/~p~n", [A, length(Bs), length(Seeds)]),
          io:format("   ... LOSS to a lower rung     : ~p  ~p~n",
                    [Cnt(fun(_K, W, L, _D) -> L > W end),
                     Which(fun(_K, W, L, _D) -> L > W end)]),
          io:format("   ... SUBLINE on a lower rung  : ~p  ~p~n",
                    [Cnt(fun(_K, W, _L, _D) -> W < RLine end),
                     Which(fun(_K, W, _L, _D) -> W < RLine end)]),
          io:format("   ... DRAWPARK on a lower rung : ~p  ~p~n",
                    [Cnt(fun(_K, W, L, D) -> D > W andalso D > L end),
                     Which(fun(_K, W, L, D) -> D > W andalso D > L end)]),
          %% ORDER is per-seed: each rung is compared with ITS OWN champion's
          %% W_pg, so it cannot be expressed through the arm-wide Cnt above.
          Ord = [{S, order_hits(prof(S, Profs)), r5(worst_deficit(prof(S, Profs)))}
                 || S <- Bs, order_hits(prof(S, Profs)) =/= []],
          io:format("   ... ORDER inversion          : ~p  ~p~n",
                    [length(Ord), Ord]),
          io:format("   ... largest ORDER deficit in the arm (W_pg - W_rung) = ~p~n~n",
                    [lists:max([0.0] ++ [D || {_, _, D} <- Ord])])
      end, Arms).

%% Rungs strictly below the floor bot, in ladder order.
lower(P) -> [{K, W, L, D} || {K, W, L, D} <- P, K =/= predictive_gun].

hits(P, F) -> [K || {K, W, L, D} <- lower(P), F(K, W, L, D)].

order_hits(P) -> [K || {K, W, _L, _D} <- lower(P), W < pg(P)].

worst_deficit(P) -> lists:max([0.0] ++ [pg(P) - W || {_K, W, _L, _D} <- lower(P), W < pg(P)]).

pg(P) -> element(2, lists:keyfind(predictive_gun, 1, P)).

%% Verbatim transcription of inverted/1 at line 976 of the runner.
inverted(Profile) ->
    lists:any(fun({K, W, L, _D}) ->
                  lists:member(K, [sitting_duck, spinner]) andalso L > W
              end, Profile).

%%%--------------------------------------------------------------------------
%%% PART B: the train-to-held-out gap.
%%%--------------------------------------------------------------------------
part_b(Arms, B) ->
    io:format("================ PART B: TRAIN-TO-HELD-OUT GAP ================~n"),
    io:format("train split = 6 starts x 2 seats = 12 matches -> trainW step 1/12 = ~.4f~n",
              [1 / 12]),
    io:format("held-out    = 80 starts x 2 seats = 160 matches -> W step 1/160 = ~.5f~n~n",
              [1 / 160]),
    All = lists:append([[{A, S, M} || {S, M} <- Seeds] || {A, Seeds, _} <- Arms]),
    io:format("distinct trainW values over all ~p champions of all three arms = ~p~n",
              [length(All), lists:usort([maps:get(trainw, M) || {_, _, M} <- All])]),
    io:format("champions at trainW = 1.0000 : ~p of ~p~n~n",
              [length([1 || {_, _, M} <- All, maps:get(trainw, M) =:= 1.0]), length(All)]),
    lists:foreach(fun(Arm) -> arm_b(Arm, B) end, Arms),
    io:format("---- per-seed IF-8 conjunction (trainW >= B AND heldout W < B) ----~n"),
    lists:foreach(
      fun({A, Seeds, Profs}) ->
          F = [S || {S, M} <- Seeds, maps:get(trainw, M) >= B, pg(prof(S, Profs)) < B],
          Near = [{S, r5(pg(prof(S, Profs))), r5(pg(prof(S, Profs)) - B)}
                  || {S, _} <- Seeds, pg(prof(S, Profs)) >= B,
                     pg(prof(S, Profs)) - B < 0.01],
          io:format("arm ~s: fires on ~p of ~p seeds ~p ; within 0.01 ABOVE B: ~p~n",
                    [A, length(F), length(Seeds), F, Near])
      end, Arms).

arm_b({A, Seeds, Profs}, _B) ->
    Gaps = lists:sort([{r5(maps:get(trainw, M) - pg(prof(S, Profs))), S,
                        r5(pg(prof(S, Profs))),
                        r2(maps:get(shots, M))} || {S, M} <- Seeds]),
    io:format("---- ARM ~s: {gap, seed, heldoutW, shots} ascending ----~n",
              [string:uppercase(atom_to_list(A))]),
    lists:foreach(fun(G) -> io:format("    ~p~n", [G]) end, Gaps),
    Lo = [G || {G, _, _, _} <- Gaps, G =< 0.15],
    Hi = [G || {G, _, _, _} <- Gaps, G > 0.15],
    io:format("  gap <= 0.15 : ~p seeds (max ~p) | gap > 0.15 : ~p seeds (min ~p)~n",
              [length(Lo), lists:max([0.0 | Lo]), length(Hi), lists:min([9.9 | Hi])]),
    ShotsLo = [Sh || {G, _, _, Sh} <- Gaps, G =< 0.15],
    ShotsHi = [Sh || {G, _, _, Sh} <- Gaps, G > 0.15],
    io:format("  shots/match in the LOW-gap mode  : ~p~n", [lists:sort(ShotsLo)]),
    io:format("  shots/match in the HIGH-gap mode : ~p~n~n", [lists:sort(ShotsHi)]).

%%%--------------------------------------------------------------------------
%%% FEED PARSING. Whitespace is stripped so the pretty-printer's line breaks
%%% stop mattering; arm attribution is by byte offset of the arm headers, which
%%% is why seeds 2001..2010 of arms L and D do not collide.
%%%--------------------------------------------------------------------------
flatten(Bin) ->
    binary_to_list(re:replace(Bin, "\\s+", "", [global, {return, binary}])).

constants(Flat) ->
    {match, [Bs, Rs]} = re:run(Flat, "B=([0-9.]+)R_line=([0-9.]+)",
                               [{capture, all_but_first, list}]),
    {to_f(Bs), to_f(Rs)}.

%% Byte window of one arm's block: from its own header to the next header.
window(Flat, s) -> span(Flat, "--ARMS\\(", "--ARML\\(");
window(Flat, l) -> span(Flat, "--ARML\\(", "--ARMD\\(");
window(Flat, d) -> span(Flat, "--ARMD\\(", "armSCLEARED").

span(Flat, From, To) ->
    {match, [{A, _}]} = re:run(Flat, From, [{capture, first}]),
    {match, [{Z, _}]} = re:run(Flat, To, [{capture, first}]),
    string:slice(Flat, A, Z - A).

seeds(Flat, Arm) ->
    W = window(Flat, Arm),
    Pat = "seed([0-9]+)W=([0-9.]+)L=([0-9.]+)D=([0-9.]+)margin=(-?[0-9.]+)"
          "caps=([0-9.]+)shots=([0-9.]+)pulls=([0-9.]+)trainW=([0-9.]+)fit=([0-9.]+)",
    {match, Ms} = re:run(W, Pat, [global, {capture, all_but_first, list}]),
    [{list_to_integer(Sd), #{w => to_f(Wv), l => to_f(Lv), d => to_f(Dv),
                             margin => to_f(Mg), caps => to_f(Cp), shots => to_f(Sh),
                             pulls => to_f(Pl), trainw => to_f(Tw), fit => to_f(Ft)}}
     || [Sd, Wv, Lv, Dv, Mg, Cp, Sh, Pl, Tw, Ft] <- Ms].

profiles(Flat, Arm) ->
    W = window(Flat, Arm),
    {match, Ms} = re:run(W, "seed([0-9]+)rungprofile=(\\[.*?\\])",
                         [global, {capture, all_but_first, list}]),
    [{list_to_integer(Sd), term(T)} || [Sd, T] <- Ms].

term(S) ->
    {ok, Tk, _} = erl_scan:string(S ++ "."),
    {ok, T} = erl_parse:parse_term(Tk),
    T.

to_f(S) -> {F, _} = string:to_float(pad(S)), F.

%% "1.0000" parses; "0" and "12" do not, so give string:to_float a decimal point.
pad(S) -> pad(S, lists:member($., S)).
pad(S, true) -> S;
pad(S, false) -> S ++ ".0".

prof(S, Profs) -> element(2, lists:keyfind(S, 1, Profs)).
w_of(S, Seeds) -> maps:get(w, element(2, lists:keyfind(S, 1, Seeds))).
shots_of(S, Seeds) -> maps:get(shots, element(2, lists:keyfind(S, 1, Seeds))).

%% Verbatim transcription of median_res/1 at line 983 of the runner: sort
%% ASCENDING by W (lists:sort/2 is stable, so ties keep feed order) and take
%% element len div 2 + len rem 2.
median_seed(Seeds) ->
    S = lists:sort(fun({_, A}, {_, B}) -> maps:get(w, A) =< maps:get(w, B) end, Seeds),
    element(1, lists:nth(max(1, length(S) div 2 + length(S) rem 2), S)).

r2(X) -> round(X * 100) / 100.
r4(X) -> round(X * 10000) / 10000.
r5(X) -> round(X * 100000) / 100000.
