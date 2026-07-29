#!/usr/bin/env escript
%%! -noshell
%%
%% Verify the SCALE of EXP-066's cross-play match-level null.
%%
%% Why this exists. The cross-play probe builds its synthetic nulls with
%% xp_from_pairs/2, which stores a MARGIN V at {I,J} and -V at {J,I}, and then
%% counts with xp_mg/1, which is a WIN-RATE differencing operator:
%%
%%     xp_mg(M) -> fun(I,J) -> wr(M,I,J) - wr(M,J,I) end
%%
%% Applied to a matrix that already holds margins that yields V - (-V) = 2V, so
%% every synthetic margin is DOUBLE the margin it represents, while the observed
%% matrix (which holds win rates) is differenced correctly. A band read against
%% the synthetic null is therefore effectively HALVED.
%%
%% For the sign-only null this is harmless: |2 * (+/-1)| clears every band either
%% way. For the MATCH-LEVEL null it is not, because that null exists precisely to
%% make most edges INdecisive at the band.
%%
%% This script reproduces the runner's null exactly (AS-BUILT) and alongside it
%% the same null with the margin differenced once (CORRECTED), at the same draw
%% count and the same three bands, so the size of the effect is a measurement
%% rather than an argument.
%%
%%   scripts/exp066_verify_null_scaling.escript [draws]

-define(SEED, 660).
-define(N, 20).
-define(CELL, 160).

main(Args) ->
    Draws = draws(Args),
    _ = rand:seed(exsss, {?SEED, ?SEED * 7 + 1, ?SEED * 13 + 3}),
    Idx = lists:seq(1, ?N),
    io:format("champions ~p, matches per cell ~p, draws ~p, seed ~p~n~n",
              [?N, ?CELL, Draws, ?SEED]),
    io:format("AS-BUILT  = the runner's own construction: margin stored, then differenced again (2V)~n"),
    io:format("CORRECTED = the same draws with the margin differenced ONCE (V)~n~n"),
    Built = [matrix(Idx, fun(V) -> V end) || _ <- lists:seq(1, Draws)],
    _ = rand:seed(exsss, {?SEED, ?SEED * 7 + 1, ?SEED * 13 + 3}),
    Corr = [matrix(Idx, fun(V) -> V / 2 end) || _ <- lists:seq(1, Draws)],
    [report(B, Idx, Built, Corr) || B <- [0.05, 0.10, 0.15]],
    io:format("~nThe two columns differ by exactly a factor of two in the BAND, so the~n"
              "as-built null at band 0.10 is the corrected null at band 0.05.~n").

draws([D | _]) -> list_to_integer(D);
draws([]) -> 200.

%% Each edge: K wins of CELL fair matches, margin V = 2K/CELL - 1. Scale/1 is the
%% only difference between the two columns.
matrix(Idx, Scale) ->
    Vals = [{I, J, Scale(flips(?CELL) * 2.0 / ?CELL - 1.0)} || {I, J} <- pairs(Idx)],
    from_pairs(Idx, Vals).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

triples(Idx) -> [{I, J, K} || I <- Idx, J <- Idx, K <- Idx, I < J, J < K].

flips(M) -> length([1 || _ <- lists:seq(1, M), rand:uniform(2) =:= 1]).

from_pairs(Idx, Vals) ->
    Look = maps:from_list(lists:append([[{{I, J}, V}, {{J, I}, -V}] || {I, J, V} <- Vals])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

mg(M) -> fun(I, J) -> element(J, element(I, M)) - element(I, element(J, M)) end.

cycles(Mg, Idx, B) ->
    F = length([1 || {I, J, K} <- triples(Idx), Mg(I, J) > B, Mg(J, K) > B, Mg(K, I) > B]),
    Bw = length([1 || {I, J, K} <- triples(Idx), Mg(I, K) > B, Mg(K, J) > B, Mg(J, I) > B]),
    F + Bw.

ordered(Mg, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]).

decisive(Mg, Idx, B) -> length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > B]).

report(B, Idx, Built, Corr) ->
    io:format("band ~.2f~n", [B]),
    line("  as-built ", B, Idx, Built),
    line("  corrected", B, Idx, Corr).

line(Tag, B, Idx, Ms) ->
    Ord = [ordered(mg(M), Idx, B) || M <- Ms],
    Cyc = [cycles(mg(M), Idx, B) || M <- Ms],
    Dec = [decisive(mg(M), Idx, B) || M <- Ms],
    io:format("~s : ordered median ~.1f range ~p | cycles median ~.1f range ~p | "
              "decisive median ~.1f of ~p~n",
              [Tag, median(Ord), spread(Ord), median(Cyc), spread(Cyc),
               median(Dec), length(pairs(Idx))]).

median([]) -> 0.0;
median(Xs) ->
    S = lists:sort([float(X) || X <- Xs]),
    L = length(S),
    mid(S, L, L rem 2).

mid(S, L, 1) -> lists:nth(L div 2 + 1, S);
mid(S, L, 0) -> (lists:nth(L div 2, S) + lists:nth(L div 2 + 1, S)) / 2.

spread(Xs) -> {lists:min(Xs), lists:max(Xs)}.
