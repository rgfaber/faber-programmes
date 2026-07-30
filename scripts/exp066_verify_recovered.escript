#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% Verify EXP-066's RECOVERED-RATES record against itself, against the feed and
%%% against arithmetic. READ-ONLY: nothing is written, nothing is re-run, no
%%% genome is loaded and no match is replayed.
%%%
%%% The record exp066_recovered_rates_and_null_fix.txt carries, for every measured
%%% pair, both directions of a W/L/D triple, plus a triple search over them, plus
%%% six null columns. Five things then have to be true and none of them should be
%%% taken on trust.
%%%
%%%   CHECK 1  THE PAIRS ARE INTERNALLY CONSISTENT. Every direction's three rates
%%%            sum to 1.0, every rate is a whole number of matches out of the
%%%            stated cell size, and the transpose identity the record claims per
%%%            pair is recomputed from the record's own numbers.
%%%
%%%   CHECK 2  THE TRIPLE SEARCH RE-DERIVES. The relation and the cycle test are
%%%            reimplemented here from their stated definitions and run over the
%%%            record's own pair list. The per-class counts and the exact set of
%%%            cyclic triples must come out the same.
%%%
%%%   CHECK 3  THE CHAMPION RATES ARE THE RATES THE RUN MEASURED. The feed's
%%%            as-run rung profile for each of the 40 champions is parsed out of
%%%            exp066_floor_feed.txt and compared with the champion side of the
%%%            corresponding pair, term for term.
%%%
%%%   CHECK 4  THE SIX NULL COLUMNS REPRODUCE. Each is redrawn here from the
%%%            stated seed and draw count with an independent implementation of
%%%            all three encodings and of the exact-integer counter, and compared
%%%            with the record's numbers.
%%%
%%%   CHECK 5  THE THREE ENCODINGS, COMPARED DIRECTLY. For every K of 0..M the
%%%            margin under each encoding is computed in both directions and the K
%%%            values where they disagree about "margin > band" are listed. This
%%%            is what turns section F1b's claim into a table.
%%%
%%% usage: scripts/exp066_verify_recovered.escript [record_path [feed_path]]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(ARCH, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").
-define(BANDS, [0.05, 0.10, 0.15]).

%% The feed prints the rung profile as full-precision floats, so that comparison is
%% exact. Nothing here compares a printed-precision number.
main(Args) ->
    Rec = arg(Args, 1, ?ARCH "exp066_recovered_rates_and_null_fix.txt"),
    Feed = arg(Args, 2, ?ARCH "exp066_floor_feed.txt"),
    {recovered, F} = term_after_marker(read(Rec)),
    Pairs = keyget(pairs, F),
    Tris = keyget(cyclic_triples, F),
    {nulls, NF} = lists:keyfind(nulls, 1, F),
    M = keyget(matches_per_ordered_cell, F),
    io:format("record   : ~s~n", [Rec]),
    io:format("feed     : ~s~n", [Feed]),
    io:format("relation : ~s~n", [keyget(relation, F)]),
    io:format("pairs    : ~p, matches per ordered cell ~p~n~n", [length(Pairs), M]),
    Ok1 = check_pairs(Pairs, M),
    Ok2 = check_triples(Pairs, Tris, F),
    Ok3 = check_feed(flatten(read(Feed)), Pairs),
    Ok4 = check_nulls(NF),
    Ok5 = check_encodings(keyget(matches_per_cell, NF)),
    All = lists:all(fun(X) -> X end, [Ok1, Ok2, Ok3, Ok4, Ok5]),
    io:format("~nVERDICT: ~s~n", [verdict(All)]),
    halt(status(All)).

arg(Args, N, Default) -> nth_or(lists:nthtail(min(N - 1, length(Args)), Args), Default).

nth_or([V | _], _Default) -> V;
nth_or([], Default) -> Default.

read(Path) ->
    {ok, Bin} = file:read_file(Path),
    binary_to_list(Bin).

term_after_marker(Text) ->
    [_Prose, Rest] = string:split(Text, "== MACHINE-READABLE TERM"),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, Fields) -> element(2, lists:keyfind(K, 1, Fields)).

%%%---------------------------------------------------------------------------
%%% CHECK 1. The pairs.
%%%---------------------------------------------------------------------------
check_pairs(Pairs, M) ->
    Sums = [P || P <- Pairs, not sums_ok(P)],
    Quant = [P || P <- Pairs, not quantised(P)],
    Tr = [P || P <- Pairs, not transpose_ok(P)],
    Claim = [P || P <- Pairs, element(7, P) =/= transpose_ok(P)],
    Cell = [P || P <- Pairs, element(8, P) =/= M],
    Cls = [{C, length([1 || {pair, _A, _B, Cc, _F, _R, _O, _Mm} <- Pairs, Cc =:= C])}
           || C <- [preregistered, new_post_hoc]],
    io:format("CHECK 1: the pairs~n"),
    io:format("  every direction has W + L + D = 1.0                  : ~s~n",
              [agree(Sums =:= [])]),
    io:format("  every rate is a whole number of matches out of ~p    : ~s~n",
              [M, agree(Quant =:= [])]),
    io:format("  transpose identity holds, recomputed here             : ~s (~p pairs fail)~n",
              [agree(Tr =:= []), length(Tr)]),
    io:format("  the record's own transpose flag agrees with that     : ~s~n",
              [agree(Claim =:= [])]),
    io:format("  every pair states ~p matches                          : ~s~n",
              [M, agree(Cell =:= [])]),
    io:format("  pairs by provenance                                   : ~p~n", [Cls]),
    lists:all(fun(X) -> X end, [Sums =:= [], Quant =:= [], Tr =:= [], Claim =:= [],
                                Cell =:= []]).

sums_ok({pair, _A, _B, _C, {W, L, D}, {RW, RL, RD}, _O, _M}) ->
    near(W + L + D, 1.0) andalso near(RW + RL + RD, 1.0).

quantised({pair, _A, _B, _C, {W, L, D}, {RW, RL, RD}, _O, M}) ->
    lists:all(fun(R) -> near(R * M, round(R * M)) end, [W, L, D, RW, RL, RD]).

transpose_ok({pair, _A, _B, _C, {W, L, D}, {RW, RL, RD}, _O, _M}) ->
    {RW, RL, RD} =:= {L, W, D}.

near(A, B) -> abs(A - B) < 1.0e-9.

%%%---------------------------------------------------------------------------
%%% CHECK 2. The relation and the cycle test, reimplemented.
%%%---------------------------------------------------------------------------
beats(Wm, A, B) -> maps:get({A, B}, Wm, 0.0) > 0.5.

oriented(Wm, A, B) -> beats(Wm, A, B) orelse beats(Wm, B, A).

measured(Wm, A, B) -> maps:is_key({A, B}, Wm) andalso maps:is_key({B, A}, Wm).

check_triples(Pairs, Stated, F) ->
    Wm = maps:from_list(
           lists:append([[{{A, B}, W}, {{B, A}, RW}]
                         || {pair, A, B, _C, {W, _L, _D}, {RW, _RL, _RD}, _O, _M} <- Pairs])),
    Cm = maps:from_list([{{A, B}, C} || {pair, A, B, C, _F, _R, _O, _M} <- Pairs]),
    Ids = lists:usort(lists:append([[A, B] || {pair, A, B, _C, _F, _R, _O, _M} <- Pairs])),
    Tris = [tri(Wm, Cm, T) || T <- triples(Ids)],
    Cyc = lists:sort([Ids3 || {tri, Ids3, _Me, _O, true, _Fw, _Cl} <- Tris]),
    StatedCyc = lists:sort([Ids3 || {tri, Ids3, _Me, _O, true, _Fw, _Cl} <- Stated]),
    Counts = [{C, length([1 || {tri, _I, _Me, _O, _Cy, _Fw, Cl} <- Tris, Cl =:= C]),
               length([1 || {tri, _I, _Me, _O, true, _Fw, Cl} <- Tris, Cl =:= C])}
              || C <- [preregistered, extended, unmeasured]],
    Fwd = [T || T <- Tris, not fwd_ok(Wm, T)],
    io:format("~nCHECK 2: the triple search, reimplemented from the stated relation~n"),
    io:format("  objects ~p, triples enumerated ~p, stated ~p        : ~s~n",
              [length(Ids), length(Tris), keyget(triples_enumerated, F),
               agree(length(Tris) =:= keyget(triples_enumerated, F))]),
    io:format("  per-class {class, triples, cyclic} recounted        : ~p~n", [Counts]),
    io:format("  stated                                             : ~p  ~s~n",
              [keyget(triples_by_class, F),
               agree(Counts =:= keyget(triples_by_class, F))]),
    io:format("  the SET of cyclic triples matches the record       : ~s (~p vs ~p)~n",
              [agree(Cyc =:= StatedCyc), length(Cyc), length(StatedCyc)]),
    io:format("  every cyclic triple's stated orientation is right  : ~s~n",
              [agree(Fwd =:= [])]),
    lists:all(fun(X) -> X end,
              [length(Tris) =:= keyget(triples_enumerated, F),
               Counts =:= keyget(triples_by_class, F), Cyc =:= StatedCyc, Fwd =:= []]).

triples(Ids) -> [{A, B, C} || A <- Ids, B <- Ids, C <- Ids, A < B, B < C].

tri(Wm, Cm, {A, B, C}) ->
    Me = measured(Wm, A, B) andalso measured(Wm, B, C) andalso measured(Wm, A, C),
    Or = oriented(Wm, A, B) andalso oriented(Wm, B, C) andalso oriented(Wm, A, C),
    Fw = beats(Wm, A, B) andalso beats(Wm, B, C) andalso beats(Wm, C, A),
    Bw = beats(Wm, A, C) andalso beats(Wm, C, B) andalso beats(Wm, B, A),
    {tri, {A, B, C}, Me, Or, Fw orelse Bw, Fw, tclass(Cm, {A, B, C})}.

tclass(Cm, {A, B, C}) ->
    Cs = [maps:get({A, B}, Cm, unmeasured), maps:get({B, C}, Cm, unmeasured),
          maps:get({A, C}, Cm, unmeasured)],
    tc(lists:member(unmeasured, Cs), lists:member(new_post_hoc, Cs)).

tc(true, _New) -> unmeasured;
tc(false, true) -> extended;
tc(false, false) -> preregistered.

%% A cyclic triple's forward flag has to be the orientation that actually closes.
fwd_ok(_Wm, {tri, _Ids, _Me, _Or, false, _Fw, _Cl}) -> true;
fwd_ok(Wm, {tri, {A, B, C}, _Me, _Or, true, true, _Cl}) ->
    beats(Wm, A, B) andalso beats(Wm, B, C) andalso beats(Wm, C, A);
fwd_ok(Wm, {tri, {A, B, C}, _Me, _Or, true, false, _Cl}) ->
    beats(Wm, A, C) andalso beats(Wm, C, B) andalso beats(Wm, B, A).

%%%---------------------------------------------------------------------------
%%% CHECK 3. The feed's as-run rung profiles.
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

parse(S) ->
    {ok, Tk, _} = erl_scan:string(S ++ "."),
    {ok, T} = erl_parse:parse_term(Tk),
    T.

%% The champion side of a champion-versus-rung pair. The record stores pairs in
%% canonical term order, and {script,_} sorts before {champ,_,_}, so the champion
%% side is the REVERSE triple whenever the rung is the A slot.
champ_rates(Pairs, Champ, Kind) ->
    side(lists:keyfind({script, Kind}, 2, [P || P <- Pairs, has(P, Champ)]), Champ).

has({pair, A, B, _C, _F, _R, _O, _M}, Id) -> A =:= Id orelse B =:= Id.

side({pair, A, _B, _C, _F, R, _O, _M}, Id) when A =/= Id -> R;
side({pair, _A, _B, _C, F, _R, _O, _M}, _Id) -> F.

check_feed(Flat, Pairs) ->
    Rows = lists:append([[{Arm, Sd, P} || {Sd, P} <- feed_profiles(Flat, Arm)]
                         || Arm <- [s, l, d]]),
    Bad = [B || R <- Rows, B <- [feed_row(Pairs, R)], B =/= ok],
    io:format("~nCHECK 3: the feed's as-run rung profiles~n"),
    io:format("  champions parsed out of the feed                    : ~p~n", [length(Rows)]),
    io:format("  the record's champion side equals the as-run profile: ~s~n",
              [agree(Bad =:= [])]),
    io:format("  disagreements                                       : ~p~n", [Bad]),
    Bad =:= [].

feed_row(Pairs, {Arm, Seed, Profile}) ->
    Champ = {champ, Arm, Seed},
    Diff = [K || {K, W, L, D} <- Profile, champ_rates(Pairs, Champ, K) =/= {W, L, D}],
    row_ok({Arm, Seed}, Diff).

row_ok(_Id, []) -> ok;
row_ok(Id, Failed) -> {Id, Failed}.

%%%---------------------------------------------------------------------------
%%% CHECK 4. The six null columns, redrawn.
%%%---------------------------------------------------------------------------
check_nulls(NF) ->
    N = keyget(champions, NF),
    M = keyget(matches_per_cell, NF),
    Draws = keyget(draws, NF),
    Seed = keyget(seed, NF),
    Idx = lists:seq(1, N),
    io:format("~nCHECK 4: the null columns, redrawn at seed ~p, ~p draws, ~p champions,"
              " ~p matches per cell~n", [Seed, Draws, N, M]),
    Cols = [{sign_as_built, fun() -> sign_draws(Seed, N, Draws, fun as_built/2, -1.0) end},
            {sign_corrected, fun() -> sign_draws(Seed, N, Draws, fun win_rate/2, 0.0) end},
            {match_as_built, fun() -> match_draws(Seed, N, Draws, M, fun as_built/2, fun mv/2) end},
            {match_corrected, fun() -> match_draws(Seed, N, Draws, M, fun win_rate/2, fun wv/2) end},
            {match_corrected_half_encoding,
             fun() -> match_draws(Seed, N, Draws, M, fun as_built/2, fun hv/2) end}],
    Oks = [check_col(NF, Idx, C) || C <- Cols],
    OkX = check_exact(NF, Idx, M, Seed, N, Draws),
    lists:all(fun(X) -> X end, Oks ++ [OkX]).

check_col(NF, Idx, {Key, Gen}) ->
    Ms = Gen(),
    Got = [stat(Ms, Idx, B) || B <- ?BANDS],
    Want = [common(element(3, lists:keyfind(B, 2, keyget(Key, NF)))) || B <- ?BANDS],
    io:format("  ~-32s recomputed = stated : ~s~n", [atom_to_list(Key), agree(Got =:= Want)]),
    io:format("    recomputed ~p~n", [Got]),
    io:format("    stated     ~p~n", [Want]),
    Got =:= Want.

check_exact(NF, Idx, M, Seed, N, Draws) ->
    Maps = int_draws(Seed, N, Draws, M),
    Got = [int_stat(Maps, Idx, M, B) || B <- ?BANDS],
    Rows = keyget(match_corrected_exact_integer, NF),
    Want = [int_common(element(3, lists:keyfind(B, 2, Rows))) || B <- ?BANDS],
    io:format("  ~-32s recomputed = stated : ~s~n",
              ["match_corrected_exact_integer", agree(Got =:= Want)]),
    io:format("    recomputed ~p~n", [Got]),
    io:format("    stated     ~p~n", [Want]),
    Got =:= Want.

common(Kvs) ->
    [{ordered_median, keyget(ordered_median, Kvs)},
     {ordered_range, keyget(ordered_range, Kvs)},
     {cycles_median, keyget(cycles_median, Kvs)},
     {cycles_range, keyget(cycles_range, Kvs)},
     {decisive_median, keyget(decisive_median, Kvs)}].

int_common(Kvs) ->
    common(Kvs) ++ [{integer_threshold, keyget(integer_threshold, Kvs)},
                    {edges_exactly_on_band_median,
                     keyget(edges_exactly_on_band_median, Kvs)}].

%% The three matrix builders, written out rather than shared with the runner.
as_built(V, _M) -> {V, -V}.
win_rate(W, _M) -> {W, 1.0 - W}.

%% The three edge-value forms, one per column.
mv(K, M) -> K * 2.0 / M - 1.0.
wv(K, M) -> K / M.
hv(K, M) -> (K * 2.0 / M - 1.0) / 2.

sign_draws(Seed, N, Draws, Split, Lo) ->
    seed(Seed),
    Idx = lists:seq(1, N),
    [build(Idx, [{I, J, coin(Lo)} || {I, J} <- pairs(Idx)], Split, N) || _ <- lists:seq(1, Draws)].

match_draws(Seed, N, Draws, M, Split, Val) ->
    seed(Seed),
    Idx = lists:seq(1, N),
    [build(Idx, [{I, J, Val(flips(M), M)} || {I, J} <- pairs(Idx)], Split, N)
     || _ <- lists:seq(1, Draws)].

int_draws(Seed, N, Draws, M) ->
    seed(Seed),
    Idx = lists:seq(1, N),
    [maps:from_list(lists:append([int_cell(M, P) || P <- pairs(Idx)]))
     || _ <- lists:seq(1, Draws)].

int_cell(M, {I, J}) ->
    K = flips(M),
    [{{I, J}, 2 * K - M}, {{J, I}, M - 2 * K}].

build(Idx, Vals, Split, N) ->
    Look = maps:from_list(
             lists:append([begin
                               {A, B} = Split(V, N),
                               [{{I, J}, A}, {{J, I}, B}]
                           end || {I, J, V} <- Vals])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

seed(S) -> rand:seed(exsss, {S, S * 7 + 1, S * 13 + 3}).

coin(Lo) -> element(rand:uniform(2), {Lo, 1.0}).

flips(M) -> length([1 || _ <- lists:seq(1, M), rand:uniform(2) =:= 1]).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

tri3(Idx) -> [{I, J, K} || I <- Idx, J <- Idx, K <- Idx, I < J, J < K].

mg(Mt) -> fun(I, J) -> element(J, element(I, Mt)) - element(I, element(J, Mt)) end.

imf(Mp) -> fun(I, J) -> maps:get({I, J}, Mp, 0) end.

ordered(Mf, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mf(A, X) > B, Mf(X, C) > B, Mf(C, A) > B]).

cycles(Mf, Idx, B) ->
    T = tri3(Idx),
    length([1 || {I, J, K} <- T, Mf(I, J) > B, Mf(J, K) > B, Mf(K, I) > B])
        + length([1 || {I, J, K} <- T, Mf(I, K) > B, Mf(K, J) > B, Mf(J, I) > B]).

decisive(Mf, Idx, B) -> length([1 || {I, J} <- pairs(Idx), abs(Mf(I, J)) > B]).

stat(Ms, Idx, B) ->
    Ord = [ordered(mg(Mt), Idx, B) || Mt <- Ms],
    Cyc = [cycles(mg(Mt), Idx, B) || Mt <- Ms],
    Dec = [decisive(mg(Mt), Idx, B) || Mt <- Ms],
    [{ordered_median, median(Ord)}, {ordered_range, spread(Ord)},
     {cycles_median, median(Cyc)}, {cycles_range, spread(Cyc)},
     {decisive_median, median(Dec)}].

int_stat(Maps, Idx, M, B) ->
    Thr = round(B * M),
    Ord = [ordered(imf(Mp), Idx, Thr) || Mp <- Maps],
    Cyc = [cycles(imf(Mp), Idx, Thr) || Mp <- Maps],
    Dec = [decisive(imf(Mp), Idx, Thr) || Mp <- Maps],
    On = [length([1 || {I, J} <- pairs(Idx), abs(maps:get({I, J}, Mp)) =:= Thr]) || Mp <- Maps],
    [{ordered_median, median(Ord)}, {ordered_range, spread(Ord)},
     {cycles_median, median(Cyc)}, {cycles_range, spread(Cyc)},
     {decisive_median, median(Dec)}, {integer_threshold, Thr},
     {edges_exactly_on_band_median, median(On)}].

median([]) -> 0.0;
median(Xs) ->
    S = lists:sort(Xs),
    L = length(S),
    mid(S, L, L rem 2).

mid(S, L, 1) -> lists:nth(L div 2 + 1, S) * 1.0;
mid(S, L, 0) -> (lists:nth(L div 2, S) + lists:nth(L div 2 + 1, S)) / 2.0.

spread(Xs) -> {lists:min(Xs), lists:max(Xs)}.

%%%---------------------------------------------------------------------------
%%% CHECK 5. The three encodings, per K, both directions.
%%%---------------------------------------------------------------------------
check_encodings(M) ->
    Ks = lists:seq(0, M),
    Same = [K || K <- Ks, wv2(K, M) =:= av2(K, M)],
    Diff = [K || K <- Ks, hv2(K, M) =/= wv2(K, M)],
    io:format("~nCHECK 5: the three encodings, margin per K of 0..~p~n", [M]),
    io:format("  win-rate form equals the audit's (1+V)/2 form, all ~p values of K : ~s~n",
              [length(Ks), agree(length(Same) =:= length(Ks))]),
    io:format("  win-rate form differs BITWISE from the halved form on ~p of ~p K~n",
              [length(Diff), length(Ks)]),
    [enc_band(Ks, M, B) || B <- ?BANDS],
    length(Same) =:= length(Ks).

%% The two directions of one edge under each encoding. The reverse margin is the
%% negation, and the negation of a float is exact, so what differs between the
%% encodings is the magnitude they land on, per sign.
wv2(K, M) -> W = K / M, W - (1.0 - W).
av2(K, M) -> V = K * 2.0 / M - 1.0, (1.0 + V) / 2 - (1.0 - V) / 2.
hv2(K, M) -> V = K * 2.0 / M - 1.0, H = V / 2, H - (-H).

enc_band(Ks, M, B) ->
    Exact = [K || K <- Ks, abs(2 * K - M) =:= round(B * M)],
    Fwd = [K || K <- Ks, (wv2(K, M) > B) =/= (hv2(K, M) > B)],
    Rev = [K || K <- Ks, (-wv2(K, M) > B) =/= (-hv2(K, M) > B)],
    ExW = [K || K <- Exact, wv2(K, M) > B orelse -wv2(K, M) > B],
    ExH = [K || K <- Exact, hv2(K, M) > B orelse -hv2(K, M) > B],
    io:format("  band ~.2f : K with |2K-M| exactly ~w (a true tie) = ~w~n",
              [B, round(B * M), Exact]),
    io:format("            forward test disagrees at K = ~w, reverse test at K = ~w~n",
              [Fwd, Rev]),
    io:format("            of those ties, counted decisive by win-rate ~w, by halved ~w~n",
              [ExW, ExH]),
    io:format("            EXACT arithmetic counts NO tie as decisive, so at this band"
              " win-rate is ~s and halved is ~s~n",
              [right(ExW =:= []), right(ExH =:= [])]).

right(true) -> "RIGHT";
right(false) -> "WRONG".

agree(true) -> "AGREE";
agree(false) -> "DISAGREE".

verdict(true) ->
    "the record re-derives its own pair consistency, its own triple search and all\n"
    "six null columns, its champion rates equal the feed's as-run rung profiles, and\n"
    "the encoding disagreement is exactly where the record says it is. It is a\n"
    "record.";
verdict(false) ->
    "the record does NOT re-derive. Do not quote it until the disagreement is\n"
    "explained.".

status(true) -> 0;
status(false) -> 1.
