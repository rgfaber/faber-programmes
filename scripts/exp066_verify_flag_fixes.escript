#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% Verify EXP-066's FLAG FIXES record against itself and against the feed.
%%% READ-ONLY: nothing is written, nothing is re-run, no genome is touched.
%%%
%%% The record exp066_flag_fixes.txt carries 40 champions' held-out rung profiles
%%% recomputed from the archived genomes, plus the two IF-10 predicates evaluated
%%% on them. Two things then have to be true, and neither should be taken on
%%% trust:
%%%
%%%   CHECK 1  THE RECORD RE-DERIVES ITS OWN COUNTS. Both predicates are
%%%            recomputed here from the profiles in the record's own term, by code
%%%            that shares nothing with the runner, and compared with the per-row
%%%            flags, the per-arm counts, the median champion and the tier sizes
%%%            the record states.
%%%
%%%   CHECK 2  THE RECOMPUTED PROFILE IS THE PROFILE THE RUN MEASURED. The feed's
%%%            as-run rung profile for every one of the 40 champions is parsed out
%%%            of exp066_floor_feed.txt and compared with the recomputed one, term
%%%            for term. The feed's W=, margin= and fit= fields are compared too,
%%%            to the precision the feed prints them at. If the archived genome
%%%            were not the champion the feed measured, this is where it shows.
%%%
%%% usage: scripts/exp066_verify_flag_fixes.escript [record_path [feed_path]]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(ARCH, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").

%% The feed prints W and fit with ~.4f and margin with ~.2f, so a comparison with
%% the record's full-precision floats is a comparison at the printed precision.
%% Half of one printed step in each case, and no wider.
-define(TOL4, 5.0e-5).
-define(TOL2, 5.0e-3).

main(Args) ->
    Rec = arg(Args, 1, ?ARCH "exp066_flag_fixes.txt"),
    Feed = arg(Args, 2, ?ARCH "exp066_floor_feed.txt"),
    {flag_fixes, Fields} = term_after_marker(read(Rec)),
    Arms = keyget(arms, Fields),
    io:format("record : ~s~n", [Rec]),
    io:format("feed   : ~s~n", [Feed]),
    io:format("arms   : ~p~n~n", [[{A, keyget(champions, F)} || {arm, A, F} <- Arms]]),
    Flat = flatten(read(Feed)),
    Ok1 = [check_counts(A) || A <- Arms],
    Ok2 = [check_feed(Flat, A) || A <- Arms],
    All = lists:all(fun(X) -> X end, Ok1 ++ Ok2),
    io:format("~nVERDICT: ~s~n", [verdict(All)]),
    halt(status(All)).

arg(Args, N, Default) -> nth_or(lists:nthtail(min(N - 1, length(Args)), Args), Default).

nth_or([V | _], _Default) -> V;
nth_or([], Default) -> Default.

read(Path) ->
    {ok, Bin} = file:read_file(Path),
    binary_to_list(Bin).

%%%---------------------------------------------------------------------------
%%% The record is human-readable text with ONE Erlang term at the foot.
%%%---------------------------------------------------------------------------
term_after_marker(Text) ->
    [_Prose, Rest] = string:split(Text, "== MACHINE-READABLE TERM"),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, Fields) -> element(2, lists:keyfind(K, 1, Fields)).

%%%---------------------------------------------------------------------------
%%% CHECK 1. The two predicates, reimplemented from their stated definitions and
%%% run over the profiles the record itself carries.
%%%---------------------------------------------------------------------------
as_run(Profile) ->
    lists:any(fun({K, W, L, _D}) ->
                  lists:member(K, [sitting_duck, spinner]) andalso L > W
              end, Profile).

widened(Profile) ->
    lists:any(fun({K, W, L, D}) ->
                  lists:member(K, [sitting_duck, spinner, rammer, circle_strafer])
                      andalso (L > W orelse D > 0.5)
              end, Profile).

tier(W) when W < 0.62 -> low;
tier(W) when W > 0.93 -> high;
tier(_W) -> mid.

check_counts({arm, A, F}) ->
    Rows = keyget(rows, F),
    Old = [Seed || {row, Seed, _T, _O, _N, _Tr, _TW, _CW, _HW, _TF, _CF, _HF,
                    _TD, _CD, _HD, _Fa, _Fr, P} <- Rows, as_run(P)],
    New = [Seed || {row, Seed, _T, _O, _N, _Tr, _TW, _CW, _HW, _TF, _CF, _HF,
                    _TD, _CD, _HD, _Fa, _Fr, P} <- Rows, widened(P)],
    RowOk = lists:all(fun(R) -> row_flags_agree(R) end, Rows),
    SumOk = lists:all(fun(R) -> row_sums_to_one(R) end, Rows),
    TierOk = lists:all(fun(R) -> row_tier_agrees(R) end, Rows),
    Med = median_seed(Rows),
    %% median_champion is a FOUR-tuple, {median_champion, Seed, Old, New}, so it is
    %% destructured rather than read through keyget/2.
    {median_champion, MedSeed, MedOld, MedNew} = lists:keyfind(median_champion, 1, F),
    Stated = {keyget(if10_as_run_fires, F), keyget(if10_widened_fires, F)},
    Got = {length(Old), length(New)},
    io:format("arm ~s, ~p rows~n", [atom_to_list(A), length(Rows)]),
    io:format("  IF-10 counts recounted {as-run, widened} = ~p~n", [Got]),
    io:format("  stated                                   = ~p  ~s~n",
              [Stated, agree(Got =:= Stated)]),
    io:format("  seeds firing as-run  = ~p~n", [Old]),
    io:format("  seeds firing widened = ~p~n", [New]),
    io:format("  per-row flags agree with the profiles     : ~s~n", [agree(RowOk)]),
    io:format("  every profile cell has W + L + D = 1.0    : ~s~n", [agree(SumOk)]),
    io:format("  per-row tier agrees with held-out W       : ~s~n", [agree(TierOk)]),
    io:format("  median champion recounted ~p, stated ~p (~p / ~p)  ~s~n",
              [Med, MedSeed, MedOld, MedNew, agree(Med =:= MedSeed)]),
    io:format("  tier sizes stated ~p, recounted ~p  ~s~n",
              [keyget(tier_sizes, F), sizes(Rows), agree(keyget(tier_sizes, F) =:= sizes(Rows))]),
    lists:all(fun(X) -> X end,
              [Got =:= Stated, RowOk, SumOk, TierOk, Med =:= MedSeed,
               keyget(tier_sizes, F) =:= sizes(Rows)]).

row_flags_agree({row, _S, _T, O, N, Trips, _TW, _CW, _HW, _TF, _CF, _HF,
                 _TD, _CD, _HD, _Fa, _Fr, P}) ->
    O =:= as_run(P) andalso N =:= widened(P) andalso N =:= (Trips =/= []).

%% rates/1 divides three disjoint counts by the same N, so the three rates of one
%% cell must sum to exactly 1.0 up to float representation.
row_sums_to_one({row, _S, _T, _O, _N, _Tr, _TW, _CW, _HW, _TF, _CF, _HF,
                 _TD, _CD, _HD, _Fa, _Fr, P}) ->
    lists:all(fun({_K, W, L, D}) -> abs(W + L + D - 1.0) < 1.0e-12 end, P).

row_tier_agrees({row, _S, T, _O, _N, _Tr, _TW, _CW, HW, _TF, _CF, _HF,
                 _TD, _CD, _HD, _Fa, _Fr, _P}) ->
    T =:= tier(HW).

%% median_res/1's rule, restated: sort ascending by held-out W, take the LOWER
%% median. The rows are in the archive's ascending seed order and lists:sort/2 is
%% stable, so ties keep that order.
median_seed(Rows) ->
    S = lists:sort(fun(A, B) -> heldw(A) =< heldw(B) end, Rows),
    N = length(S),
    element(2, lists:nth(max(1, N div 2 + N rem 2), S)).

heldw({row, _S, _T, _O, _N, _Tr, _TW, _CW, HW, _TF, _CF, _HF,
       _TD, _CD, _HD, _Fa, _Fr, _P}) -> HW.

sizes(Rows) -> [{T, length([1 || R <- Rows, tier(heldw(R)) =:= T])}
                || T <- [low, mid, high]].

%%%---------------------------------------------------------------------------
%%% CHECK 2. The feed. Whitespace is stripped so the pretty-printer's line breaks
%%% stop mattering, and arm attribution is by byte window between the arm headers,
%%% which is why seeds 2001..2010 of arms L and D do not collide.
%%%---------------------------------------------------------------------------
flatten(Text) ->
    binary_to_list(re:replace(list_to_binary(Text), "\\s+", "", [global, {return, binary}])).

window(Flat, s) -> span(Flat, "--ARMS\\(", "--ARML\\(");
window(Flat, l) -> span(Flat, "--ARML\\(", "--ARMD\\(");
window(Flat, d) -> span(Flat, "--ARMD\\(", "armSCLEARED").

span(Flat, From, To) ->
    {match, [{A, _}]} = re:run(Flat, From, [{capture, first}]),
    {match, [{Z, _}]} = re:run(Flat, To, [{capture, first}]),
    string:slice(Flat, A, Z - A).

feed_profiles(Flat, Arm) ->
    {match, Ms} = re:run(window(Flat, Arm), "seed([0-9]+)rungprofile=(\\[.*?\\])",
                         [global, {capture, all_but_first, list}]),
    [{list_to_integer(Sd), parse(T)} || [Sd, T] <- Ms].

%% The as-run per-seed line. won_opp_shots is absent from it (that was defect
%% D10, recovered in the first addendum), so it is not in this pattern.
feed_seeds(Flat, Arm) ->
    Pat = "seed([0-9]+)W=([0-9.]+)L=([0-9.]+)D=([0-9.]+)margin=(-?[0-9.]+)"
          "caps=([0-9.]+)shots=([0-9.]+)pulls=([0-9.]+)trainW=([0-9.]+)fit=([0-9.]+)",
    {match, Ms} = re:run(window(Flat, Arm), Pat, [global, {capture, all_but_first, list}]),
    [{list_to_integer(Sd), to_f(W), to_f(Mg), to_f(Tw), to_f(Ft)}
     || [Sd, W, _L, _D, Mg, _Cp, _Sh, _Pl, Tw, Ft] <- Ms].

parse(S) ->
    {ok, Tk, _} = erl_scan:string(S ++ "."),
    {ok, T} = erl_parse:parse_term(Tk),
    T.

to_f(S) -> {F, _} = string:to_float(pad(S, lists:member($., S))), F.

pad(S, true) -> S;
pad(S, false) -> S ++ ".0".

check_feed(Flat, {arm, A, F}) ->
    Rows = keyget(rows, F),
    Ps = feed_profiles(Flat, A),
    Ss = feed_seeds(Flat, A),
    Bad = [B || R <- Rows, B <- [feed_row(R, Ps, Ss)], B =/= ok],
    io:format("~narm ~s against the feed: ~p rung profiles and ~p per-seed lines parsed~n",
              [atom_to_list(A), length(Ps), length(Ss)]),
    io:format("  recomputed profile equals the as-run profile, all ~p seeds : ~s~n",
              [length(Rows), agree(Bad =:= [])]),
    io:format("  disagreements = ~p~n", [Bad]),
    io:format("  feed trainW is 1.0000 on every seed of this arm             : ~s~n",
              [agree(lists:all(fun({_S, _W, _M, Tw, _Ft}) -> Tw =:= 1.0 end, Ss))]),
    Bad =:= [].

%% One champion: the recomputed held-out profile against the as-run profile, then
%% the three printed columns the record also carries.
feed_row({row, Seed, _T, _O, _N, _Tr, _TW, _CW, HW, _TF, _CF, _HF,
          _TD, _CD, HD, Fa, _Fr, P}, Ps, Ss) ->
    {Seed, FeedP} = lists:keyfind(Seed, 1, Ps),
    {Seed, FeedW, FeedM, _Tw, FeedFit} = lists:keyfind(Seed, 1, Ss),
    verdict_row(Seed,
                [{profile, FeedP =:= P},
                 {heldout_w, abs(FeedW - HW) < ?TOL4},
                 {heldout_margin_raw, abs(FeedM - HD) < ?TOL2},
                 {fit, abs(FeedFit - Fa) < ?TOL4}]).

verdict_row(Seed, Checks) -> row_ok(Seed, [K || {K, false} <- Checks]).

row_ok(_Seed, []) -> ok;
row_ok(Seed, Failed) -> {Seed, Failed}.

agree(true) -> "AGREE";
agree(false) -> "DISAGREE".

verdict(true) ->
    "the record re-derives its own IF-10 counts from its own profiles, and every\n"
    "recomputed profile equals the as-run profile in the feed. It is a record.";
verdict(false) ->
    "the record does NOT re-derive. Do not quote it until the disagreement is\n"
    "explained.".

status(true) -> 0;
status(false) -> 1.
