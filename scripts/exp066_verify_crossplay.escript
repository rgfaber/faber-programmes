#!/usr/bin/env escript
%%! -noshell
%%
%% Verify that EXP-066's cross-play record RE-DERIVES its own counts.
%%
%% This reads the persisted report, parses the machine-readable term at its foot,
%% takes ONLY the win-rate matrix out of it, and recounts the intransitivity from
%% scratch with code that shares nothing with the runner. If the recount disagrees
%% with the counts the report states, the file is not a record and says so.
%%
%% This exists because the defect the CLAIM gate found was not an arithmetic error:
%% it was that the numbers lived in a shell nobody could re-open. A record that
%% cannot be recomputed from its own contents has the same defect in a quieter form.
%%
%%   scripts/exp066_verify_crossplay.escript [report_path]

main(Args) ->
    Path = path(Args),
    {ok, Bin} = file:read_file(Path),
    Term = term_after_marker(binary_to_list(Bin)),
    {crossplay, Fields} = Term,
    Rows = [{S, Ws} || {row, _I, S, Ws} <- keyget(matrix, Fields)],
    N = length(Rows),
    Mtx = list_to_tuple([list_to_tuple(Ws) || {_S, Ws} <- Rows]),
    io:format("report      : ~s~n", [Path]),
    io:format("champions   : ~p (seeds ~p..~p)~n",
              [N, element(1, hd(Rows)), element(1, lists:last(Rows))]),
    io:format("stated      : ~p~n", [[{B, Kvs} || {at_band, B, Kvs} <- keyget(counts, Fields)]]),
    Ok = [check(Mtx, N, B, Kvs) || {at_band, B, Kvs} <- keyget(counts, Fields)],
    io:format("~nVERDICT: ~s~n", [verdict(lists:all(fun(X) -> X end, Ok))]),
    halt(status(lists:all(fun(X) -> X end, Ok))).

path([P | _]) -> P;
path([]) ->
    "programmes/p7_coevolution/exp066_competence_floor/exp066_crossplay.txt".

%% The report is human-readable text with ONE Erlang term at the foot, after a
%% marker line. Everything before the marker is prose and is not parsed.
term_after_marker(Text) ->
    Marker = "== MACHINE-READABLE TERM",
    [_Prose, Rest] = string:split(Text, Marker),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, Fields) -> element(2, lists:keyfind(K, 1, Fields)).

%% Recounted independently: unordered cyclic triangles by out-degree, and the
%% ordered exp057 tuple count, both straight off the matrix.
check(Mtx, N, B, Kvs) ->
    Idx = lists:seq(1, N),
    Mg = fun(I, J) -> element(J, element(I, Mtx)) - element(I, element(J, Mtx)) end,
    Beats = fun(I, J) -> Mg(I, J) > B end,
    Cyc = length([1 || I <- Idx, J <- Idx, K <- Idx, I < J, J < K,
                       cyclic(Beats, I, J, K)]),
    Ord = length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                       Beats(A, X), Beats(X, C), Beats(C, A)]),
    Dec = length([1 || I <- Idx, J <- Idx, I < J, abs(Mg(I, J)) > B]),
    Want = {keyget(unordered_cycles, Kvs), keyget(ordered_exp057, Kvs),
            keyget(decisive_edges, Kvs)},
    Got = {Cyc, Ord, Dec},
    io:format("~nband ~.2f  recounted {cycles, ordered, decisive} = ~p~n", [B, Got]),
    io:format("           stated                                 = ~p  ~s~n",
              [Want, agree(Got =:= Want)]),
    Got =:= Want.

%% Exactly one of the two orientations can hold: the relation is asymmetric because
%% the margins are antisymmetric and the band is not negative.
cyclic(Beats, I, J, K) ->
    (Beats(I, J) andalso Beats(J, K) andalso Beats(K, I))
        orelse (Beats(I, K) andalso Beats(K, J) andalso Beats(J, I)).

agree(true) -> "AGREE";
agree(false) -> "DISAGREE".

verdict(true) ->
    "the report re-derives its own counts from its own matrix. It is a record.";
verdict(false) ->
    "the report does NOT re-derive its own counts. Do not quote it.".

status(true) -> 0;
status(false) -> 1.
