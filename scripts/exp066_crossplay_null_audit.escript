#!/usr/bin/env escript
%%! -noshell
%%
%% AUDIT of the nulls EXP-066's cross-play probe compares itself against.
%%
%% The probe's counts are sound and re-derive from the persisted matrix
%% (scripts/exp066_verify_crossplay.escript proves that). What this audits is the
%% REFERENCES those counts are read against, because a cycle count means nothing
%% except relative to a null, and the probe's record carries three nulls of which
%% none is matched to the observed data.
%%
%% TWO DEFECTS, both in the reference rather than in the arithmetic.
%%
%%   1. SCALE. The synthetic nulls are built by xp_from_pairs/2, which stores a
%%      margin V at {I,J} and -V at {J,I}, and are then counted with xp_mg/1,
%%      which is a WIN-RATE differencing operator and returns V - (-V) = 2V. The
%%      observed matrix holds win rates and is differenced correctly. So every
%%      synthetic margin is DOUBLE its intended size and the band is effectively
%%      halved: the record's match-level null row at band 0.10 is a band-0.05 row.
%%      Harmless for the sign-only null (+/-2 clears every band either way);
%%      decisive for the match-level null, which exists precisely to make most
%%      edges INdecisive at the band.
%%
%%   2. CONDITIONING. A fair-coin-per-match null gives 20 equally strong players,
%%      so most of its edges are indecisive: 39 of 190 at band 0.10 once the scale
%%      is fixed, against 152 of 190 observed. A cyclic triple needs THREE
%%      decisive edges, so a null supplying a quarter as many cannot bound the
%%      observed count in either direction. The reference that can is the
%%      ORIENTATION null: keep every observed |margin| exactly as measured, so the
%%      decisive/indecisive structure at every band is preserved edge for edge,
%%      and randomise only the SIGNS. That asks the one question worth asking --
%%      given edges this separated, is the ORDERING more or less cyclic than
%%      chance -- and it is the null the record lacks.
%%
%% Everything here reads the persisted report. No genome is loaded and no match is
%% replayed, so this cannot disturb the run's own record.
%%
%%   scripts/exp066_crossplay_null_audit.escript [report_path] [draws]

-define(SEED, 661).

main(Args) ->
    {Path, Draws} = args(Args),
    {ok, Bin} = file:read_file(Path),
    {crossplay, F} = term_after_marker(binary_to_list(Bin)),
    Rows = [{S, Ws} || {row, _I, S, Ws} <- keyget(matrix, F)],
    N = length(Rows),
    Mtx = list_to_tuple([list_to_tuple(Ws) || {_S, Ws} <- Rows]),
    Idx = lists:seq(1, N),
    Cell = keyget(matches_per_cell, keyget(granularity, F)),
    _ = rand:seed(exsss, {?SEED, ?SEED * 7 + 1, ?SEED * 13 + 3}),
    hdr(Path, N, Cell, Draws),
    [band_row(Idx, Mtx, Cell, Draws, B) || B <- [0.05, 0.10, 0.15]],
    foot().

args([P, D | _]) -> {P, list_to_integer(D)};
args([P]) -> {P, 200};
args([]) -> {"programmes/p7_coevolution/exp066_competence_floor/exp066_crossplay.txt", 200}.

hdr(Path, N, Cell, Draws) ->
    io:format("== EXP-066 cross-play NULL AUDIT ==~n~n"
              "status      = EXPLORATORY, UNREGISTERED, SIGNS NOTHING~n"
              "reads       = ~s~n"
              "champions   = ~p~n"
              "matches/cell= ~p~n"
              "null draws  = ~p~n"
              "seed        = ~p~n"
              "reads only the persisted matrix; no genome loaded, no match replayed~n~n"
              "OBSERVED    = recounted from the persisted matrix~n"
              "ORIENTATION = observed |margin| kept edge for edge, SIGNS randomised~n"
              "  (the decisiveness-matched null; the reference the record lacks)~n"
              "ANALYTIC    = triples with all three edges decisive, divided by 4~n"
              "  (a cyclic orientation is 2 of 8 equally likely assignments)~n"
              "MATCH AS-BUILT  = the record's own match-level null, margins doubled~n"
              "MATCH CORRECTED = the same model with the margin differenced once~n~n",
              [Path, N, Cell, Draws, ?SEED]).

foot() ->
    io:format("~nREADING. The sign of the comparison depends entirely on which null is~n"
              "used, which is why the choice has to be argued rather than defaulted:~n"
              "against the record's as-built match-level null the observed count looks~n"
              "BELOW chance, against the same null corrected it looks ABOVE chance, and~n"
              "against the only null matched to the observed edge structure it is far~n"
              "below. The first two comparisons are unusable because that null does not~n"
              "reproduce the observed decisiveness; the third is the one that answers~n"
              "the question asked, and it is UNREGISTERED and self-calibrated like~n"
              "everything else in this probe.~n").

band_row(Idx, Mtx, Cell, Draws, B) ->
    Mg = mg(Mtx),
    io:format("band ~.2f~n", [B]),
    io:format("  OBSERVED        : ordered ~p | cycles ~p | decisive ~p of ~p~n",
              [ordered(Mg, Idx, B), cycles(Mg, Idx, B),
               decisive(Mg, Idx, B), length(pairs(Idx))]),
    Or = [orient(Idx, Mtx) || _ <- lists:seq(1, Draws)],
    stat("  ORIENTATION     ", Idx, Or, B),
    AllDec = tri_all_decisive(Mg, Idx, B),
    io:format("  ANALYTIC        : all-three-decisive triples ~p, expected cycles ~.2f, "
              "expected ordered ~.2f~n", [AllDec, AllDec / 4, AllDec * 3 / 8]),
    Ab = [synth(Idx, Cell, fun runner_pairs/2) || _ <- lists:seq(1, Draws)],
    stat("  MATCH AS-BUILT  ", Idx, Ab, B),
    Co = [synth(Idx, Cell, fun half_matrix/2) || _ <- lists:seq(1, Draws)],
    stat("  MATCH CORRECTED ", Idx, Co, B),
    io:format("~n").

stat(Tag, Idx, Ms, B) ->
    Ord = [ordered(mg(M), Idx, B) || M <- Ms],
    Cyc = [cycles(mg(M), Idx, B) || M <- Ms],
    Dec = [decisive(mg(M), Idx, B) || M <- Ms],
    io:format("~s: ordered med ~.1f ~p | cycles med ~.1f ~p | decisive med ~.1f of ~p~n",
              [Tag, median(Ord), spread(Ord), median(Cyc), spread(Cyc),
               median(Dec), length(pairs(Idx))]).

%% The ORIENTATION null. One fair coin per PAIR decides whether that pair KEEPS
%% its two observed win rates or SWAPS them. Swapping is exactly a sign flip on
%% that edge's margin and it carries the observed floats through untouched, so
%% |margin| is preserved BIT FOR BIT and decisive_edges is identical to the
%% observed value at every band by construction rather than approximately. (An
%% arithmetic reconstruction of the same null differed by one edge at band 0.05,
%% where an edge whose margin is exactly 0.05 came back as 0.050000000000000044
%% and crossed a strict inequality.)
orient(Idx, Mtx) ->
    Look = maps:from_list(lists:append([keep_or_swap(I, J, coin(), Mtx)
                                        || {I, J} <- pairs(Idx)])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

keep_or_swap(I, J, 1.0, Mtx) ->
    [{{I, J}, wr(Mtx, I, J)}, {{J, I}, wr(Mtx, J, I)}];
keep_or_swap(I, J, -1.0, Mtx) ->
    [{{I, J}, wr(Mtx, J, I)}, {{J, I}, wr(Mtx, I, J)}].

wr(M, I, J) -> element(J, element(I, M)).

%% The match-level null. The SAME draws under two encodings, and the encoding is
%% the whole defect: Build/2 is either the runner's own construction or the one it
%% should have used.
synth(Idx, Cell, Build) ->
    Vals = [{I, J, flips(Cell) * 2.0 / Cell - 1.0} || {I, J} <- pairs(Idx)],
    Build(Idx, Vals).

%% AS-BUILT: xp_from_pairs/2, character for character. Stores the MARGIN V at
%% {I,J} and -V at {J,I}, so the win-rate differencing operator mg/1 returns
%% V - (-V) = 2V and every synthetic margin is double its intended size.
runner_pairs(Idx, Vals) ->
    Look = maps:from_list(lists:append([[{{I, J}, V}, {{J, I}, -V}] || {I, J, V} <- Vals])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

%% CORRECTED: a WIN-RATE matrix carrying the given margins, W(I,J) = (1+V)/2 and
%% W(J,I) = (1-V)/2, so mg/1 returns V and not 2V. Same units as the observed
%% matrix, which is what makes the band mean the same thing on both.
half_matrix(Idx, Vals) ->
    Look = maps:from_list(lists:append([[{{I, J}, (1.0 + V) / 2}, {{J, I}, (1.0 - V) / 2}]
                                        || {I, J, V} <- Vals])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

triples(Idx) -> [{I, J, K} || I <- Idx, J <- Idx, K <- Idx, I < J, J < K].

coin() -> element(rand:uniform(2), {-1.0, 1.0}).

flips(M) -> length([1 || _ <- lists:seq(1, M), rand:uniform(2) =:= 1]).

mg(M) -> fun(I, J) -> element(J, element(I, M)) - element(I, element(J, M)) end.

%% exp057's counter, character for character.
ordered(Mg, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]).

cycles(Mg, Idx, B) ->
    F = length([1 || {I, J, K} <- triples(Idx), Mg(I, J) > B, Mg(J, K) > B, Mg(K, I) > B]),
    Bw = length([1 || {I, J, K} <- triples(Idx), Mg(I, K) > B, Mg(K, J) > B, Mg(J, I) > B]),
    F + Bw.

decisive(Mg, Idx, B) -> length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > B]).

tri_all_decisive(Mg, Idx, B) ->
    length([1 || {I, J, K} <- triples(Idx),
                 abs(Mg(I, J)) > B, abs(Mg(J, K)) > B, abs(Mg(I, K)) > B]).

term_after_marker(Text) ->
    [_Prose, Rest] = string:split(Text, "== MACHINE-READABLE TERM"),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, Fields) -> element(2, lists:keyfind(K, 1, Fields)).

median([]) -> 0.0;
median(Xs) ->
    S = lists:sort([float(X) || X <- Xs]),
    L = length(S),
    mid(S, L, L rem 2).

mid(S, L, 1) -> lists:nth(L div 2 + 1, S);
mid(S, L, 0) -> (lists:nth(L div 2, S) + lists:nth(L div 2 + 1, S)) / 2.

spread(Xs) -> {lists:min(Xs), lists:max(Xs)}.
