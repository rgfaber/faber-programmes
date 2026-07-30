#!/usr/bin/env escript
%%! -noshell
%%
%% Verify that the pilot-extraction equivalence record RE-DERIVES its own claims.
%%
%% A record that cannot be recomputed from its own contents is not a record, it
%% is an assertion with a filename. This reads the persisted report, parses the
%% single Erlang term at its foot with erl_parse rather than with a regex, and
%% then checks the term against itself and against the two files it says it read.
%%
%% IT SHARES NO CODE WITH THE RUNNER OR WITH THE HARNESS. The feed is re-parsed
%% here by a scanner written for this script alone. That is the point: if the
%% harness had a parsing defect that fed it the wrong archived rates, comparing
%% the harness against itself would never show it.
%%
%% WHAT THIS IS NOT, stated because a passing run here is easy to over-read and
%% has been over-read once already. THIS SCRIPT REPLAYS NO MATCH. It runs no
%% engine, drives no controller and recomputes no outcome. Only two of its checks
%% reach outside the record: check 4 against the feed, and check 2 against
%% rebar.config. The turn count, the divergence counts, the per-match mismatch
%% counts and the red-check counts are READ OUT OF THE TERM and compared to
%% nothing, so a green here is consistency, not corroboration. Check 5's median
%% is the median of the record's own 20 pilot rates for the same reason.
%% Independent corroboration means a second implementation replaying the 3200
%% matches; that is a different job from this one and this script must not be
%% cited as it.
%%
%%   1. the foot is ONE parseable Erlang term
%%   2. the pin recorded equals the ref rebar.config declares
%%   3. all 20 arm S rows have feed == runner == robo_pilot, to the precision the
%%      feed records, with zero match-level mismatches
%%   4. every feed rate quoted in the term is the rate actually written in
%%      exp066_floor_feed.txt
%%   5. the median of the 20 recomputed win rates is 0.9750
%%   6. all three red-check perturbations produced divergences, so the suite that
%%      returned this green is a suite that can go red
%%
%% CHECK 4 IS THE ONE THAT MATTERS MOST. It is what would catch the record
%% quoting a feed value it invented. It scopes to the ARM S section first,
%% because arms L and D reuse the seed numbers 2001 to 2010 and a whole-file scan
%% would silently read arm D's rate into arm S's row and then report a
%% divergence that is really a parsing bug.
%%
%%   scripts/exp066_verify_pilot_extraction_equivalence.escript [record] [feed] [rebar.config]

main(Args) ->
    {RecPath, FeedPath, CfgPath} = paths(Args),
    Term = term_after_marker(read(RecPath)),
    {pilot_extraction_equivalence, F} = Term,
    io:format("record      : ~s~n", [RecPath]),
    io:format("feed        : ~s~n", [FeedPath]),
    io:format("status      : ~s~n~n", [get(status, F)]),
    Rows = keyget(rows, keyget(part_b, F)),
    Feed = feed_rates(read(FeedPath)),
    Checks =
        [check_pin(F, CfgPath),
         check_gates(F),
         check_part_a(F),
         check_rows(Rows),
         check_feed(Rows, Feed),
         check_median(Rows),
         check_red(F)],
    io:format("~nVERDICT: ~s~n", [verdict(lists:all(fun({_N, Ok}) -> Ok end, Checks))]),
    halt(status_code(lists:all(fun({_N, Ok}) -> Ok end, Checks))).

paths([R, F, C | _]) -> {R, F, C};
paths(_Other) ->
    Base = "programmes/p7_coevolution/exp066_competence_floor/",
    {Base ++ "exp066_pilot_extraction_equivalence.txt",
     Base ++ "exp066_floor_feed.txt",
     "rebar.config"}.

read(Path) ->
    {ok, Bin} = file:read_file(Path),
    binary_to_list(Bin).

%% The report is human-readable text with ONE Erlang term at the foot, after a
%% marker line. Everything before the marker is prose and is not parsed.
term_after_marker(Text) ->
    Marker = "== MACHINE-READABLE TERM",
    [_Prose, Rest] = string:split(Text, Marker),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, L) -> element(2, lists:keyfind(K, 1, L)).

get(K, L) -> keyget(K, L).

%%%---------------------------------------------------------------------------
%%% The checks
%%%---------------------------------------------------------------------------

%% The pin is the provenance. A record whose pin does not match the config it was
%% produced under is describing a different engine than the one that ran.
check_pin(F, CfgPath) ->
    {ok, Terms} = file:consult(CfgPath),
    {faber_tweann, {git, _U, {ref, Ref}}} =
        lists:keyfind(faber_tweann, 1, keyget(deps, Terms)),
    Recorded = binary_to_list(keyget(engine_pin_after, F)),
    report("pin recorded equals the ref rebar.config declares",
           Recorded =:= Ref andalso keyget(pin_constant_matches_rebar_config, F),
           Ref).

check_gates(F) ->
    Gates = keyget(gates, F),
    Bad = [N || {N, false} <- Gates],
    report("exp066 gates/0: all seven pass at the new pin",
           length(Gates) =:= 7 andalso Bad =:= []
               andalso keyget(gates_all_pass, F) =:= true,
           {checks, length(Gates), failing, Bad,
            golden, keyget(golden_match_vector, F)}).

check_part_a(F) ->
    A = keyget(part_a, F),
    D = keyget(intent_divergences, A),
    M = keyget(state_mismatches, A),
    report("Part A: zero intent divergences and zero state mismatches",
           D =:= 0 andalso M =:= 0 andalso keyget(first_divergence, A) =:= none
               andalso keyget(pass, A) =:= true,
           {matches, keyget(matches, A), turns, keyget(turns_compared, A),
            divergences, D, state_mismatches, M}).

%% Rates compared at the precision the feed RECORDS, which is four decimals. Every
%% rate is k/160, spacing 0.00625, so four decimals identifies k uniquely and this
%% is an exact comparison rather than a tolerance.
check_rows(Rows) ->
    Bad = [S || {seed, S, {feed, FW, FL, FD, FM}, {runner, RW, RL, RD, RM},
                {robo_pilot, PW, PL, PD, PM}, _Wins, {match_mismatches, MM}} <- Rows,
                not (same4({FW, FL, FD}, {RW, RL, RD})
                     andalso same4({FW, FL, FD}, {PW, PL, PD})
                     andalso f2(FM) =:= f2(RM) andalso f2(FM) =:= f2(PM)
                     andalso MM =:= 0)],
    report("all 20 arm S rows: feed == runner == robo_pilot, zero match mismatches",
           length(Rows) =:= 20 andalso Bad =:= [], {rows, length(Rows), bad, Bad}).

%% The independent re-parse. Nothing here comes from the harness.
check_feed(Rows, Feed) ->
    Bad = [S || {seed, S, {feed, FW, FL, FD, FM}, _R, _P, _W, _M} <- Rows,
                maps:get(S, Feed, missing) =/= {f4(FW), f4(FL), f4(FD), f2(FM)}],
    report("every feed rate quoted in the term is the rate written in the feed",
           map_size(Feed) =:= 20 andalso Bad =:= [],
           {feed_rows_parsed, map_size(Feed), disagreeing, Bad}).

check_median(Rows) ->
    Ws = lists:sort([W || {seed, _S, _F, _R, {robo_pilot, W, _L, _D, _M}, _Wi, _MM} <- Rows]),
    Med = (lists:nth(10, Ws) + lists:nth(11, Ws)) / 2,
    report("median recomputed held-out win rate is 0.9750",
           f4(Med) =:= "0.9750", {median, f4(Med), n, length(Ws)}).

%% A green suite that cannot go red is not evidence.
check_red(F) ->
    Red = keyget(red_check, F),
    Silent = [M || {M, D, _First} <- Red, not (is_integer(D) andalso D > 0)],
    report("red check: every perturbation of robo_pilot produced divergences",
           length(Red) =:= 3 andalso Silent =:= [],
           [{M, D} || {M, D, _First} <- Red]).

same4({A1, B1, C1}, {A2, B2, C2}) ->
    {f4(A1), f4(B1), f4(C1)} =:= {f4(A2), f4(B2), f4(C2)}.

%%%---------------------------------------------------------------------------
%%% The feed, re-parsed by this script alone. ARM S ONLY.
%%%---------------------------------------------------------------------------

feed_rates(Text) ->
    [_Before, Rest] = string:split(Text, "-- ARM S ("),
    [Sec | _After] = string:split(Rest, "-- ARM L ("),
    Lines = string:split(Sec, "\n", all),
    maps:from_list([R || L <- Lines, R <- row(string:lexemes(L, " "))]).

row(["seed", S, "W=" ++ W, "L=" ++ L, "D=" ++ D, "margin=" ++ M | _T]) ->
    [{list_to_integer(S), {W, L, D, M}}];
row(_Other) -> [].

%%%---------------------------------------------------------------------------
%%% Plumbing
%%%---------------------------------------------------------------------------

report(Name, Ok, Detail) ->
    io:format("  ~s  ~s~n            ~p~n", [mark(Ok), Name, Detail]),
    {Name, Ok}.

mark(true) -> "PASS";
mark(false) -> "FAIL".

verdict(true) ->
    "the record is internally consistent, and its feed rates and its pin agree "
    "with the files it cites. NOT an independent recomputation: see the header.";
verdict(false) ->
    "the record does NOT re-derive its own claims. Do not cite it.".

status_code(true) -> 0;
status_code(false) -> 1.

f4(X) -> lists:flatten(io_lib:format("~.4f", [X * 1.0])).

f2(X) -> lists:flatten(io_lib:format("~.2f", [X * 1.0])).
