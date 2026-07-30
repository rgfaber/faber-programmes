#!/usr/bin/env escript
%%! -noshell
%%
%% INDEPENDENT VERIFICATION of the EXP-066 WITHIN-TIER RECOUNT.
%%
%% The recount record claims a set of counts for the kill mode tier alone. This
%% script recomputes every one of them from the persisted win-rate matrix with
%% code that shares nothing with the script that produced them. It was written
%% without reading scripts/exp066_within_tier_recount.escript.
%%
%% Two things are taken from the recount record as DATA, not as method:
%%   the tier seed lists (kill mode / near parity / alone), and
%%   the numbers that are to be checked.
%% Everything else is recomputed here.
%%
%% The counting conventions come from scripts/exp066_verify_crossplay.escript,
%% the pre-existing independent verifier of the matrix record:
%%   margin(A,B)          = W(A,B) - W(B,A)
%%   A beats B at band T  iff margin(A,B) > T          (strict)
%%   edge {A,B} decisive  iff abs(margin(A,B)) > T      (strict)
%%   ordered_exp057       = ordered (A,X,C), A < X, A =/= C, X =/= C,
%%                          A beats X, X beats C, C beats A
%% The unordered cycle counter here is deliberately a DIFFERENT algorithm from
%% that verifier's: a triple is cyclic iff all three of its within-triple
%% out-degrees equal 1. (Sum of out-degrees equals the number of decisive edges
%% in the triple, so all-ones already forces all three edges decisive.)
%%
%% No genome is loaded, no match is replayed, no arm is re-run. This is arithmetic
%% over two persisted text files.
%%
%%   scripts/exp066_verify_within_tier.escript [crossplay] [recount] [out]

-mode(compile).

-define(TOL_SHARE, 1.0e-12).
-define(TOL_RHO, 1.0e-9).
-define(TOL_TIE, 1.0e-12).
-define(NULL_DRAWS, 2000).
-define(NULL_HEAD, 200).
-define(RNG_ALG, exsss).
-define(RNG_STATE, {771, 5397, 10023}).

main(Args) ->
    {CrossPath, RecPath, OutPath} = paths(Args),
    {crossplay, CF} = term_after_marker(CrossPath),
    {within_tier_recount, RF} = term_after_marker(RecPath),
    Rows = [{S, list_to_tuple(Ws)} || {row, _I, S, Ws} <- keyget(matrix, CF)],
    Seeds = [S || {S, _} <- Rows],
    Mgs = margins(Rows, Seeds),
    Tiers = tier_map(RF),
    Sets = [{full, Seeds}, {kill, tier_seeds(Tiers, kill)},
            {near_parity, tier_seeds(Tiers, near_parity)},
            {alone, tier_seeds(Tiers, alone)}],
    Bands = keyget(bands, RF),
    Under = under_block(RF),
    Parts = [head(CrossPath, RecPath, OutPath, Seeds, Bands, Sets),
             sec_structure(Sets, Bands, Mgs, Under, CF),
             sec_full(Sets, Bands, Mgs, CF, Under),
             sec_tier(kill, Sets, Bands, Mgs, Under),
             sec_tier(near_parity, Sets, Bands, Mgs, Under),
             sec_closed_form(Sets, Bands, Mgs, Under),
             sec_own_null(Sets, Bands, Mgs, Under),
             sec_boundary(Sets, Bands, Mgs, Tiers, Under),
             sec_scale(Sets, Bands, Mgs, Under),
             sec_spearman(Sets, Rows, RF, Under),
             sec_ties(Sets, Bands, Mgs),
             sec_exact(Sets, Bands, Mgs, Rows, Seeds)],
    Oks = lists:append([O || {_L, O} <- Parts]),
    All = lists:all(fun({_T, B}) -> B end, Oks),
    Bad = [T || {T, false} <- Oks],
    Diffs = exact_diffs(Sets, Bands, Mgs, int_margins(Rows, Seeds)),
    Tail = [verdict_lines(Oks, Bad, All, Diffs),
            term_lines(Sets, Bands, Mgs, Oks, All, Diffs)],
    Text = [[L || {L, _O} <- Parts], Tail],
    io:put_chars(Text),
    ok = file:write_file(OutPath, Text),
    halt(status(All)).

paths([A, B, C | _]) -> {A, B, C};
paths(_) ->
    D = "programmes/p7_coevolution/exp066_competence_floor/",
    {D ++ "exp066_crossplay.txt", D ++ "exp066_within_tier_recount.txt",
     D ++ "exp066_within_tier_verify.txt"}.

%% ---------------------------------------------------------------- parsing ----

%% Each record is human-readable text with ONE Erlang term at the foot, after a
%% marker line. Everything before the marker is prose and is not parsed.
term_after_marker(Path) ->
    {ok, Bin} = file:read_file(Path),
    [_Prose, Rest] = string:split(binary_to_list(Bin), "== MACHINE-READABLE TERM"),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

keyget(K, Fields) -> element(2, lists:keyfind(K, 1, Fields)).

%% {tier,kill,Kvs} and {at_band,0.05,Kvs} are 3-tuples keyed on element 2.
tagget(Tag, Key, L) -> hd([Kvs || X <- L, element(1, X) =:= Tag,
                                 element(2, X) =:= Key, Kvs <- [element(3, X)]]).

under_block(RF) ->
    [{under, _Label, Block} | _] = keyget(runs, RF),
    Block.

tier_map(RF) ->
    maps:from_list([{S, keyget(tier, Kvs)} || {seed, S, Kvs} <- keyget(tier_table, RF)]).

tier_seeds(Tiers, Kind) ->
    lists:sort([S || {S, T} <- maps:to_list(Tiers), T =:= Kind]).

set_seeds(Name, Sets) -> element(2, lists:keyfind(Name, 1, Sets)).

%% ---------------------------------------------------------------- counting ----

%% Every cell of the matrix is a win rate out of 160 matches, so every margin is
%% an exact multiple of 1/160 and every band is an exact multiple of 1/160 too
%% (0.05 = 8/160, 0.10 = 16/160, 0.15 = 24/160). Counting on the integer grid is
%% the SAME definition and the SAME bands with the binary rounding error removed.
%% Nothing is moved: only the arithmetic changes.
int_margins(Rows, Seeds) ->
    Cols = maps:from_list(lists:zip(Seeds, lists:seq(1, length(Seeds)))),
    W = maps:from_list(Rows),
    maps:from_list([{{A, B}, w160(A, B, W, Cols) - w160(B, A, W, Cols)}
                    || A <- Seeds, B <- Seeds, A =/= B]).

w160(A, B, W, Cols) -> round(cell(A, B, W, Cols) * 160).

%% Largest distance any cell sits from its integer numerator over 160. If this is
%% not tiny the grid assumption is wrong and the exact recount would be invalid.
grid_error(Rows, Seeds) ->
    Cols = maps:from_list(lists:zip(Seeds, lists:seq(1, length(Seeds)))),
    W = maps:from_list(Rows),
    lists:max([abs(cell(A, B, W, Cols) * 160 - w160(A, B, W, Cols))
               || A <- Seeds, B <- Seeds]).

margins(Rows, Seeds) ->
    Cols = maps:from_list(lists:zip(Seeds, lists:seq(1, length(Seeds)))),
    W = maps:from_list(Rows),
    maps:from_list([{{A, B}, cell(A, B, W, Cols) - cell(B, A, W, Cols)}
                    || A <- Seeds, B <- Seeds, A =/= B]).

cell(A, B, W, Cols) -> element(maps:get(B, Cols), maps:get(A, W)).

%% Mode gt is the record's convention, strict >, and is what every AGREES row
%% below is computed under. Mode ge exists only for the sensitivity disclosure in
%% section J, because edges DO land exactly on a band. No band is moved either way.
cmp(gt, X, T) -> X > T;
cmp(ge, X, T) -> X >= T.

beats(A, B, T, M, Mode) -> cmp(Mode, maps:get({A, B}, M), T).

decisive({A, B}, T, M, Mode) -> cmp(Mode, abs(maps:get({A, B}, M)), T).

tie({A, B}, T, M) -> abs(abs(maps:get({A, B}, M)) - T) < ?TOL_TIE.

exact_tie({A, B}, T, M) -> abs(maps:get({A, B}, M)) =:= T.

pairs_of(Set) -> [{A, B} || A <- Set, B <- Set, A < B].

triples_of(Set) -> [{A, B, C} || A <- Set, B <- Set, C <- Set, A < B, B < C].

outdeg(X, Others, T, M, Mode) ->
    length([Y || Y <- Others, beats(X, Y, T, M, Mode)]).

%% Cyclic by out-degree, which is a different route to the same object than the
%% "either of the two orientations holds" test used by the crossplay verifier.
cyclic(Tri, T, M) -> cyclic(Tri, T, M, gt).

cyclic({A, B, C}, T, M, Mode) ->
    outdeg(A, [B, C], T, M, Mode) =:= 1 andalso outdeg(B, [A, C], T, M, Mode) =:= 1
        andalso outdeg(C, [A, B], T, M, Mode) =:= 1.

forward(Tri, T, M) -> forward(Tri, T, M, gt).

forward({A, B, C}, T, M, Mode) ->
    beats(A, B, T, M, Mode) andalso beats(B, C, T, M, Mode)
        andalso beats(C, A, T, M, Mode).

backward(Tri, T, M) -> backward(Tri, T, M, gt).

backward({A, B, C}, T, M, Mode) ->
    beats(A, C, T, M, Mode) andalso beats(C, B, T, M, Mode)
        andalso beats(B, A, T, M, Mode).

cyclable({A, B, C}, T, M, Mode) ->
    decisive({A, B}, T, M, Mode) andalso decisive({B, C}, T, M, Mode)
        andalso decisive({A, C}, T, M, Mode).

counts(Set, T, M) -> counts(Set, T, M, gt).

counts(Set, T, M, Mode) ->
    Ps = pairs_of(Set),
    Ts = triples_of(Set),
    F = length([X || X <- Ts, forward(X, T, M, Mode)]),
    B = length([X || X <- Ts, backward(X, T, M, Mode)]),
    Cy = length([X || X <- Ts, cyclic(X, T, M, Mode)]),
    Ord = length([1 || A <- Set, X <- Set, C <- Set, A < X, A =/= C, X =/= C,
                       beats(A, X, T, M, Mode), beats(X, C, T, M, Mode),
                       beats(C, A, T, M, Mode)]),
    #{champions => length(Set), pairs => length(Ps), triples => length(Ts),
      ordered_candidates => length(Ps) * max(0, length(Set) - 2),
      decisive => length([P || P <- Ps, decisive(P, T, M, Mode)]),
      ties => length([P || P <- Ps, tie(P, T, M)]),
      exact_ties => length([P || P <- Ps, exact_tie(P, T, M)]),
      cyclable => length([X || X <- Ts, cyclable(X, T, M, Mode)]),
      cycles => Cy, forward => F, backward => B, ordered => Ord,
      identity => (2 * F + B) =:= Ord, cycles_eq_fb => (F + B) =:= Cy}.

cyclic_triples(Set, T, M) -> [X || X <- triples_of(Set), cyclic(X, T, M)].

%% ------------------------------------------------------------- comparisons ----

row(Tag, Mine, Claimed) -> row_ok(Tag, Mine, Claimed, Mine =:= Claimed).

rowf(Tag, Mine, Claimed, Tol) ->
    row_ok(Tag, Mine, Claimed, abs(Mine - Claimed) =< Tol).

row_ok(Tag, Mine, Claimed, Ok) ->
    L = io_lib:format("  ~-42s mine ~-16s claimed ~-16s ~s~n",
                      [Tag, fmt(Mine), fmt(Claimed), verd(Ok)]),
    {L, {Tag, Ok}}.

note(Fmt, Args) -> {io_lib:format(Fmt, Args), []}.

fmt(V) -> lists:flatten(io_lib:format("~p", [V])).

verd(true) -> "AGREES";
verd(false) -> "DISAGREES".

status(true) -> 0;
status(false) -> 1.

%% Sections return {Lines, [{Tag,Bool}]}. gather/1 splices a list of them.
gather(Items) ->
    {[L || {L, _} <- Items], lists:append([oks(O) || {_L, O} <- Items])}.

oks([]) -> [];
oks({Tag, B}) -> [{Tag, B}];
oks(L) when is_list(L) -> L.

band_tag(Set, Band, Name) ->
    lists:flatten(io_lib:format("~s ~.2f ~s", [Set, Band, Name])).

tag(Set, Name) -> lists:flatten(io_lib:format("~s ~s", [Set, Name])).

%% ---------------------------------------------------------------- sections ----

head(CrossPath, RecPath, OutPath, Seeds, Bands, Sets) ->
    {io_lib:format(
       "== EXP-066 WITHIN-TIER RECOUNT: INDEPENDENT VERIFICATION ==~n~n"
       "date        = 2026-07-30~n"
       "status      = EXPLORATORY, POST HOC, NOT PRE-REGISTERED, SIGNS NOTHING~n"
       "engine_pin  = a5e8bcfc5646827e9be49a9629f8a6a9678c814b~n"
       "produced_by = scripts/exp066_verify_within_tier.escript~n"
       "written_to  = ~s~n"
       "matrix from = ~s~n"
       "claims from = ~s~n~n"
       "INDEPENDENCE. This script was written without reading~n"
       "scripts/exp066_within_tier_recount.escript and shares no code with it. It~n"
       "takes exactly two things from the recount record as DATA: the tier seed~n"
       "lists, and the numbers to be checked. Every count below is recomputed from~n"
       "the persisted win-rate matrix. No genome loaded, no match replayed, no arm~n"
       "re-run, no matrix rebuilt.~n~n"
       "CONVENTIONS (from scripts/exp066_verify_crossplay.escript, the pre-existing~n"
       "independent verifier of the matrix record, NOT from the recount script):~n"
       "  margin(A,B)         = W(A,B) - W(B,A)~n"
       "  A beats B at band T = margin(A,B) > T          (strict)~n"
       "  edge decisive at T  = abs(margin(A,B)) > T      (strict)~n"
       "  ordered_exp057      = ordered (A,X,C), A < X, A =/= C, X =/= C,~n"
       "                        A beats X, X beats C, C beats A~n"
       "  unordered cycle     = triple whose three within-triple out-degrees are~n"
       "                        all 1 (a DIFFERENT algorithm from the two-orientation~n"
       "                        test the crossplay verifier uses)~n"
       "  cyclable triple     = all three of its edges decisive at the band~n~n"
       "champions parsed = ~p, seeds ~p..~p~n"
       "bands            = ~p, taken from the record, not chosen here~n"
       "tier seed lists taken as given:~n"
       "  kill        = ~p~n"
       "  near parity = ~p~n"
       "  alone       = ~p~n~n",
       [OutPath, CrossPath, RecPath, length(Seeds), hd(Seeds), lists:last(Seeds),
        Bands, set_seeds(kill, Sets), set_seeds(near_parity, Sets),
        set_seeds(alone, Sets)]),
     []}.

sec_structure(Sets, Bands, Mgs, Under, CF) ->
    B = hd(Bands),
    FC = counts(set_seeds(full, Sets), B, Mgs),
    Items = [note("-- A. STRUCTURAL COUNTS --~n~n", []),
             note("  ~p champions in the kill tier, ~p in near parity, ~p alone.~n~n",
                  [length(set_seeds(kill, Sets)), length(set_seeds(near_parity, Sets)),
                   length(set_seeds(alone, Sets))])],
    Str = [struct_rows(N, Sets, B, Mgs, Under) || N <- [kill, near_parity]],
    Full = [row("full champions", maps:get(champions, FC), keyget(champions, CF)),
            row("full pairs", maps:get(pairs, FC), keyget(pairs, CF)),
            row("full unordered_triples", maps:get(triples, FC),
                keyget(unordered_triples, CF)),
            row("full ordered_candidates", maps:get(ordered_candidates, FC),
                keyget(ordered_candidates, CF))],
    gather(Items ++ lists:append(Str) ++ Full ++ [note("~n", [])]).

struct_rows(Name, Sets, B, Mgs, Under) ->
    Kvs = tagget(tier, Name, Under),
    Set = set_seeds(Name, Sets),
    C = counts(Set, B, Mgs),
    [row(tag(Name, "seeds"), Set, keyget(seeds, Kvs)),
     row(tag(Name, "champions"), maps:get(champions, C), keyget(champions, Kvs)),
     row(tag(Name, "pairs"), maps:get(pairs, C), keyget(pairs, Kvs)),
     row(tag(Name, "unordered_triples"), maps:get(triples, C),
         keyget(unordered_triples, Kvs)),
     row(tag(Name, "ordered_candidates"), maps:get(ordered_candidates, C),
         keyget(ordered_candidates, Kvs))].

sec_full(Sets, Bands, Mgs, CF, Under) ->
    Hdr = note("-- B. FULL 20-CHAMPION MATRIX, against the crossplay record --~n~n"
               "This validates my parser and my conventions against numbers that were~n"
               "persisted before the recount existed. cyclable comes from the recount~n"
               "record's scale_matched block.~n~n", []),
    Items = [full_rows(B, Sets, Mgs, CF, Under) || B <- Bands],
    gather([Hdr] ++ lists:append(Items) ++ [note("~n", [])]).

full_rows(B, Sets, Mgs, CF, Under) ->
    C = counts(set_seeds(full, Sets), B, Mgs),
    Kvs = tagget(at_band, B, keyget(counts, CF)),
    Sc = keyget(full, tagget(at_band, B, keyget(scale_matched, Under))),
    [row(band_tag(full, B, "decisive_edges"), maps:get(decisive, C),
         keyget(decisive_edges, Kvs)),
     row(band_tag(full, B, "unordered_cycles"), maps:get(cycles, C),
         keyget(unordered_cycles, Kvs)),
     row(band_tag(full, B, "ordered_exp057"), maps:get(ordered, C),
         keyget(ordered_exp057, Kvs)),
     row(band_tag(full, B, "forward"), maps:get(forward, C), keyget(forward, Kvs)),
     row(band_tag(full, B, "backward"), maps:get(backward, C), keyget(backward, Kvs)),
     row(band_tag(full, B, "identity 2f+b=ordered"), maps:get(identity, C),
         keyget(identity_2f_plus_b_equals_ordered, Kvs)),
     row(band_tag(full, B, "cyclable_triples"), maps:get(cyclable, C),
         keyget(cyclable_triples, Sc))].

sec_tier(Name, Sets, Bands, Mgs, Under) ->
    Hdr = note("-- ~s. THE ~s TIER ALONE, against the recount record --~n~n",
               [sec_letter(Name), string:uppercase(atom_to_list(Name))]),
    Items = [tier_rows(Name, B, Sets, Mgs, Under) || B <- Bands],
    gather([Hdr] ++ lists:append(Items) ++ [note("~n", [])]).

sec_letter(kill) -> "C";
sec_letter(near_parity) -> "D".

tier_rows(Name, B, Sets, Mgs, Under) ->
    C = counts(set_seeds(Name, Sets), B, Mgs),
    Kvs = tagget(at_band, B, keyget(at_band_rows, tagget(tier, Name, Under))),
    [row(band_tag(Name, B, "decisive_edges"), maps:get(decisive, C),
         keyget(decisive_edges, Kvs)),
     row(band_tag(Name, B, "of_pairs"), maps:get(pairs, C), keyget(of_pairs, Kvs)),
     row(band_tag(Name, B, "all_three_decisive_triples"), maps:get(cyclable, C),
         keyget(all_three_decisive_triples, Kvs)),
     row(band_tag(Name, B, "of_triples"), maps:get(triples, C), keyget(of_triples, Kvs)),
     row(band_tag(Name, B, "unordered_cycles"), maps:get(cycles, C),
         keyget(unordered_cycles, Kvs)),
     row(band_tag(Name, B, "ordered_exp057"), maps:get(ordered, C),
         keyget(ordered_exp057, Kvs)),
     row(band_tag(Name, B, "forward"), maps:get(forward, C), keyget(forward, Kvs)),
     row(band_tag(Name, B, "backward"), maps:get(backward, C), keyget(backward, Kvs)),
     row(band_tag(Name, B, "identity 2f+b=ordered"), maps:get(identity, C),
         keyget(identity_2f_plus_b_equals_ordered, Kvs)),
     row(band_tag(Name, B, "cycles=forward+backward"), maps:get(cycles_eq_fb, C), true)].

sec_closed_form(Sets, Bands, Mgs, Under) ->
    Hdr = note("-- E. THE ORIENTATION NULL'S CLOSED FORM, NO RNG NEEDED --~n~n"
               "Under the null the decisive set is fixed and each decisive edge's~n"
               "direction is a fair coin, so a cyclable triple is cyclic with~n"
               "probability 2/8 and contributes 2*P(fwd)+1*P(bwd) = 3/8 to the ordered~n"
               "count. Hence E[cycles] = C/4 and E[ordered] = 3C/8 with C the number of~n"
               "cyclable triples. Two triples share at most one edge, and conditioning~n"
               "on that edge's direction leaves each triple cyclic with probability 1/4~n"
               "either way, so the cycle indicators are pairwise uncorrelated and~n"
               "sd[cycles] = sqrt(3C/16) exactly.~n~n", []),
    Items = [cf_rows(N, B, Sets, Mgs, Under) || N <- [kill, near_parity], B <- Bands],
    gather([Hdr] ++ lists:append(Items) ++ [note("~n", [])]).

cf_rows(Name, B, Sets, Mgs, Under) ->
    C = maps:get(cyclable, counts(set_seeds(Name, Sets), B, Mgs)),
    Kvs = tagget(at_band, B, keyget(at_band_rows, tagget(tier, Name, Under))),
    Cf = keyget(closed_form, Kvs),
    Nl = keyget(orientation_null, Kvs),
    Med = keyget(cycles_median, Nl),
    OMed = keyget(ordered_median, Nl),
    Sd = math:sqrt(3 * C / 16),
    [rowf(band_tag(Name, B, "closed form E[cycles]=C/4"), C / 4,
          keyget(expected_cycles, Cf), ?TOL_SHARE),
     rowf(band_tag(Name, B, "closed form E[ordered]=3C/8"), 3 * C / 8,
          keyget(expected_ordered, Cf), ?TOL_SHARE),
     note("    exact null sd[cycles] = sqrt(3C/16) = ~.4f ; the recount's simulated~n"
          "    median ~p lies ~.4f counts = ~.3f sd above the closed form; its ordered~n"
          "    median ~p lies ~.4f counts above 3C/8~n",
          [Sd, Med, Med - C / 4, (Med - C / 4) / Sd, OMed, OMed - 3 * C / 8])].

sec_own_null(Sets, Bands, Mgs, Under) ->
    Hdr = note("-- F. MY OWN ORIENTATION NULL (NEW, POST HOC, secondary) --~n~n"
               "This is NOT the recount's null re-run; it is a fresh independent draw~n"
               "of the same model, to see whether the recount's median is where a~n"
               "median of that model belongs. One fair coin per pair keeps or swaps~n"
               "that pair's two win rates, which flips the sign of the edge's margin~n"
               "and leaves abs(margin) bit for bit, so the decisive set is invariant by~n"
               "construction. Cycles per draw counted as forward+backward and ordered as~n"
               "2*forward+backward; both identities are checked directly on the observed~n"
               "data in sections B, C and D.~n"
               "  rng = rand ~p, seed state ~p, draws ~p (median also reported over the~n"
               "  first ~p draws of the same stream for a like-for-like count)~n~n",
               [?RNG_ALG, ?RNG_STATE, ?NULL_DRAWS, ?NULL_HEAD]),
    Set = set_seeds(kill, Sets),
    _ = rand:seed(?RNG_ALG, ?RNG_STATE),
    Draws = [null_draw(Set, Bands, Mgs) || _ <- lists:seq(1, ?NULL_DRAWS)],
    Items = [null_rows(B, Set, Mgs, Draws, Under) || B <- Bands],
    gather([Hdr] ++ Items ++ [note("~n", [])]).

null_draw(Set, Bands, Mgs) ->
    D = maps:from_list(lists:append([flip(P, Mgs) || P <- pairs_of(Set)])),
    Ts = triples_of(Set),
    [{B, tally(Ts, B, D)} || B <- Bands].

flip({A, B}, Mgs) ->
    S = 3 - 2 * rand:uniform(2),
    V = S * maps:get({A, B}, Mgs),
    [{{A, B}, V}, {{B, A}, -V}].

tally(Ts, B, D) ->
    F = length([X || X <- Ts, forward(X, B, D)]),
    Bw = length([X || X <- Ts, backward(X, B, D)]),
    {F + Bw, 2 * F + Bw}.

null_rows(B, Set, Mgs, Draws, Under) ->
    Cy = [element(1, keyget(B, Dr)) || Dr <- Draws],
    Od = [element(2, keyget(B, Dr)) || Dr <- Draws],
    Head = lists:sublist(Cy, ?NULL_HEAD),
    C = maps:get(cyclable, counts(Set, B, Mgs)),
    Kvs = tagget(at_band, B, keyget(at_band_rows, tagget(tier, kill, Under))),
    Nl = keyget(orientation_null, Kvs),
    Obs = maps:get(cycles, counts(Set, B, Mgs)),
    note("  kill ~.2f  my null cycles  median ~p range ~p (~p draws)~n"
         "            my null cycles  median ~p range ~p (first ~p draws)~n"
         "            my null ordered median ~p range ~p (~p draws)~n"
         "            closed form ~.4f | recount's median ~p range ~p~n"
         "            my null cycles  mean ~.4f vs closed form ~.4f~n"
         "            my null cycles  sd ~.4f vs exact sqrt(3C/16) ~.4f~n"
         "            observed ~p vs my null minimum ~p over ~p draws: ~s~n",
         [B, median(Cy), {lists:min(Cy), lists:max(Cy)}, ?NULL_DRAWS,
          median(Head), {lists:min(Head), lists:max(Head)}, ?NULL_HEAD,
          median(Od), {lists:min(Od), lists:max(Od)}, ?NULL_DRAWS,
          C / 4, keyget(cycles_median, Nl), keyget(cycles_range, Nl),
          mean(Cy), C / 4, sd(Cy), math:sqrt(3 * C / 16),
          Obs, lists:min(Cy), ?NULL_DRAWS, below(Obs < lists:min(Cy))]).

mean(L) -> lists:sum(L) / length(L).

sd(L) ->
    M = mean(L),
    math:sqrt(lists:sum([(X - M) * (X - M) || X <- L]) / (length(L) - 1)).

below(true) -> "below every draw";
below(false) -> "NOT below every draw".

sec_exact(Sets, Bands, Mgs, Rows, Seeds) ->
    Mi = int_margins(Rows, Seeds),
    Hdr = note("-- K. THE SAME RECOUNT IN EXACT ARITHMETIC (NEW, POST HOC) --~n~n"
               "Section J found pairs whose margin is mathematically ON a band. In IEEE~n"
               "doubles those margins come out a few times 1.0e-17 ABOVE the band, so~n"
               "strict > calls them decisive. On the exact grid strict > does not. Same~n"
               "definition, same bands, no threshold moved: win rates are integers out~n"
               "of 160 matches, bands are 8, 16 and 24 out of 160, and the comparison is~n"
               "still strict >. Only the binary rounding error is gone.~n"
               "  worst distance of any cell from its integer numerator over 160 = ~p~n~n",
               [grid_error(Rows, Seeds)]),
    Items = [exact_rows(N, B, Sets, Mgs, Mi) || N <- [full, kill, near_parity],
                                                B <- Bands],
    gather([Hdr] ++ Items ++ [note("~n", [])]).

exact_rows(Name, B, Sets, Mgs, Mi) ->
    Set = set_seeds(Name, Sets),
    F = counts(Set, B, Mgs),
    X = counts(Set, round(B * 160), Mi),
    Keys = [decisive, cyclable, cycles, ordered, forward, backward],
    Diff = [K || K <- Keys, maps:get(K, F) =/= maps:get(K, X)],
    note("  ~-12s ~.2f~n"
         "    float [~s]~n"
         "    exact [~s]~n"
         "    keys that change ......... ~p~n"
         "    on-band pairs, abs(margin) = the band EXACTLY on the 160 grid:~n~s"
         "    closed form E[cycles] = C/4 ... float ~.4f  exact ~.4f~n"
         "    share cycles/cyclable ........ float ~.6f  exact ~.6f~n",
         [Name, B, kv(Keys, F), kv(Keys, X), Diff,
          onband_lines(Set, B, Mgs, Mi),
          maps:get(cyclable, F) / 4, maps:get(cyclable, X) / 4,
          share(maps:get(cycles, F), maps:get(cyclable, F)),
          share(maps:get(cycles, X), maps:get(cyclable, X))]).

kv(Keys, M) ->
    lists:join(", ", [io_lib:format("~p ~p", [K, maps:get(K, M)]) || K <- Keys]).

onband_lines(Set, B, Mgs, Mi) ->
    T = round(B * 160),
    Ps = [P || P <- pairs_of(Set), abs(maps:get(P, Mi)) =:= T],
    onband_body(Ps, B, Mgs, Mi, T).

onband_body([], _B, _Mgs, _Mi, _T) -> "      none\n";
onband_body(Ps, B, Mgs, Mi, T) ->
    [io_lib:format("      ~p  abs int margin ~p/160 vs band ~p/160, float abs margin~n"
                   "        ~.20f, float strict > band = ~p, exact strict > band = false~n",
                   [P, abs(maps:get(P, Mi)), T, abs(maps:get(P, Mgs)),
                    abs(maps:get(P, Mgs)) > B])
     || P <- Ps].

median(L) ->
    S = lists:sort(L),
    N = length(S),
    med(S, N, N rem 2).

med(S, N, 1) -> float(lists:nth((N + 1) div 2, S));
med(S, N, 0) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.

sec_boundary(Sets, Bands, Mgs, Tiers, Under) ->
    Hdr = note("-- G. BOUNDARY DECOMPOSITION OF THE FULL-MATRIX CYCLES --~n~n"
               "Every cyclic triple of the 20-champion matrix, classified by the tiers~n"
               "of its three members. Cycle identity is compared as a SET of seeds, so~n"
               "the record's rotation order does not matter.~n~n", []),
    Items = [bnd_rows(B, Sets, Mgs, Tiers, Under) || B <- Bands],
    gather([Hdr] ++ lists:append(Items) ++ [note("~n", [])]).

bnd_rows(B, Sets, Mgs, Tiers, Under) ->
    Mine = lists:sort([lists:sort(tuple_to_list(T))
                       || T <- cyclic_triples(set_seeds(full, Sets), B, Mgs)]),
    Kvs = tagget(at_band, B, keyget(boundary_decomposition, Under)),
    Cl = lists:sort([lists:sort(Ss) || {cycle, Ss, _Ts, _K} <- keyget(cycles, Kvs)]),
    Sigs = [sig(T, Tiers) || T <- Mine],
    Classes = [class(S) || S <- Sigs],
    ClaimSig = keyget(signatures, Kvs),
    Alone = length([1 || {_K, _N, A} <- Sigs, A > 0]),
    ClaimAlone = lists:sum([N || {{_K, _Nn, A}, N} <- ClaimSig, A > 0]),
    [row(band_tag(full, B, "cycles_total"), length(Mine), keyget(cycles_total, Kvs)),
     row(band_tag(full, B, "cycle seed-sets equal record's"), Mine =:= Cl, true),
     note("    cycles I have that the record lacks: ~p~n"
          "    cycles the record has that I lack  : ~p~n",
          [Mine -- Cl, Cl -- Mine]),
     row(band_tag(full, B, "distinct cycles in record"), length(Mine),
         length(lists:usort(Cl))),
     row(band_tag(full, B, "all_kill"), length([X || X <- Classes, X =:= all_kill]),
         keyget(all_kill, Kvs)),
     row(band_tag(full, B, "all_near"), length([X || X <- Classes, X =:= all_near]),
         keyget(all_near, Kvs)),
     row(band_tag(full, B, "spans"), length([X || X <- Classes, X =:= spans]),
         keyget(spans, Kvs)),
     row(band_tag(full, B, "signatures"), tally_sigs(Sigs), lists:sort(ClaimSig)),
     row(band_tag(full, B, "cycles containing the alone seed"), Alone, ClaimAlone),
     row(band_tag(full, B, "all_kill = kill-tier submatrix cycles"),
         length([X || X <- Classes, X =:= all_kill]),
         maps:get(cycles, counts(set_seeds(kill, Sets), B, Mgs))),
     row(band_tag(full, B, "all_near = near-tier submatrix cycles"),
         length([X || X <- Classes, X =:= all_near]),
         maps:get(cycles, counts(set_seeds(near_parity, Sets), B, Mgs))),
     row(band_tag(full, B, "record's per-cycle tier labels"),
         labels_ok(keyget(cycles, Kvs), Tiers), true)].

sig(Seeds, Tiers) ->
    Ts = [maps:get(S, Tiers) || S <- Seeds],
    {length([X || X <- Ts, X =:= kill]), length([X || X <- Ts, X =:= near_parity]),
     length([X || X <- Ts, X =:= alone])}.

class({3, 0, 0}) -> all_kill;
class({0, 3, 0}) -> all_near;
class(_) -> spans.

tally_sigs(Sigs) ->
    lists:sort([{S, length([X || X <- Sigs, X =:= S])} || S <- lists:usort(Sigs)]).

labels_ok(Cycles, Tiers) ->
    lists:all(fun(C) -> label_ok(C, Tiers) end, Cycles).

label_ok({cycle, Ss, Ts, K}, Tiers) ->
    Ts =:= [maps:get(S, Tiers) || S <- Ss] andalso K =:= class(sig(Ss, Tiers)).

sec_scale(Sets, Bands, Mgs, Under) ->
    Hdr = note("-- H. SCALE-MATCHED SHARES, cycles / cyclable triples --~n~n", []),
    Items = [scale_rows(N, B, Sets, Mgs, Under)
             || B <- Bands, N <- [full, kill, near_parity]],
    gather([Hdr] ++ lists:append(Items) ++ [note("~n", [])]).

scale_rows(Name, B, Sets, Mgs, Under) ->
    C = counts(set_seeds(Name, Sets), B, Mgs),
    Sc = keyget(Name, tagget(at_band, B, keyget(scale_matched, Under))),
    [row(band_tag(Name, B, "scale cycles"), maps:get(cycles, C), keyget(cycles, Sc)),
     row(band_tag(Name, B, "scale cyclable"), maps:get(cyclable, C),
         keyget(cyclable_triples, Sc)),
     row(band_tag(Name, B, "scale triples"), maps:get(triples, C), keyget(triples, Sc)),
     rowf(band_tag(Name, B, "share of cyclable"),
          share(maps:get(cycles, C), maps:get(cyclable, C)),
          keyget(share_of_cyclable, Sc), ?TOL_SHARE)].

share(_C, 0) -> 0.0;
share(C, Cy) -> C / Cy.

sec_spearman(Sets, Rows, RF, Under) ->
    Hdr = note("-- I. WITHIN-TIER SPEARMAN, held-out W against cross-play row mean --~n~n"
               "Held-out W per seed is the 4-decimal print in the recount record's tier~n"
               "table. Row mean excludes the diagonal. Average ranks for ties, then~n"
               "Pearson on the ranks.~n~n", []),
    Ws = maps:from_list([{S, keyget(heldout_w_print, Kvs)}
                         || {seed, S, Kvs} <- keyget(tier_table, RF)]),
    Sp = keyget(spearman, Under),
    Full = set_seeds(full, Sets),
    Items = [rowf("full rho (full-matrix row mean, 4dp)",
                  r4(rho(Full, Full, Ws, Rows)), keyget(full_matrix_stated, Sp),
                  ?TOL_SHARE)]
            ++ rho_rows(kill, Sets, Ws, Rows, Sp, kill_submatrix_rowmean,
                        kill_fullmatrix_rowmean)
            ++ rho_rows(near_parity, Sets, Ws, Rows, Sp, near_submatrix_rowmean,
                        near_fullmatrix_rowmean),
    gather([Hdr] ++ Items ++ [note("~n", [])]).

rho_rows(Name, Sets, Ws, Rows, Sp, SubKey, FullKey) ->
    Set = set_seeds(Name, Sets),
    Full = set_seeds(full, Sets),
    [rowf(tag(Name, "rho (submatrix row mean)"), rho(Set, Set, Ws, Rows),
          keyget(SubKey, Sp), ?TOL_RHO),
     rowf(tag(Name, "rho (full-matrix row mean)"), rho(Set, Full, Ws, Rows),
          keyget(FullKey, Sp), ?TOL_RHO)].

%% Xs = held-out W over Set; Ys = mean win rate of each Set row against Opp\{self}.
rho(Set, Opp, Ws, Rows) ->
    Xs = [maps:get(S, Ws) || S <- Set],
    Ys = [rowmean(S, Opp, Rows) || S <- Set],
    pearson(ranks(Xs), ranks(Ys)).

rowmean(S, Opp, Rows) ->
    Seeds = [X || {X, _} <- Rows],
    Cols = maps:from_list(lists:zip(Seeds, lists:seq(1, length(Seeds)))),
    W = maps:from_list(Rows),
    Vs = [cell(S, O, W, Cols) || O <- Opp, O =/= S],
    lists:sum(Vs) / length(Vs).

ranks(Vs) ->
    S = lists:sort(Vs),
    Z = lists:zip(lists:seq(1, length(S)), S),
    [avg_rank(V, Z) || V <- Vs].

avg_rank(V, Z) ->
    Is = [I || {I, X} <- Z, X =:= V],
    lists:sum(Is) / length(Is).

pearson(Xs, Ys) ->
    N = length(Xs),
    Mx = lists:sum(Xs) / N,
    My = lists:sum(Ys) / N,
    Dx = [X - Mx || X <- Xs],
    Dy = [Y - My || Y <- Ys],
    Num = lists:sum([A * B || {A, B} <- lists:zip(Dx, Dy)]),
    Den = math:sqrt(lists:sum([A * A || A <- Dx]) * lists:sum([B * B || B <- Dy])),
    Num / Den.

r4(X) -> round(X * 10000) / 10000.

sec_ties(Sets, Bands, Mgs) ->
    Hdr = note("-- J. BAND BOUNDARY DISCLOSURE AND SENSITIVITY (NEW, POST HOC) --~n~n"
               "The margin step is 0.0125 and every band is an exact multiple of it, so~n"
               "an edge can land exactly ON a band, where > and >= disagree. Counted,~n"
               "not assumed. The record's convention is strict >, which is what every~n"
               "AGREES row above uses; it is documented in the crossplay verifier's code~n"
               "and NOT in either record's prose. No band is moved anywhere in this file:~n"
               "the ge column below is the same bands read inclusively.~n~n"
               "  set/band  on-band pairs (exact float equality in brackets)~n"
               "            decisive  gt -> ge | cycles gt -> ge | ordered gt -> ge~n~n",
               []),
    Items = [tie_rows(N, B, Sets, Mgs) || N <- [full, kill, near_parity], B <- Bands],
    gather([Hdr] ++ Items ++ [note("~n", [])]).

tie_rows(Name, B, Sets, Mgs) ->
    Set = set_seeds(Name, Sets),
    G = counts(Set, B, Mgs, gt),
    E = counts(Set, B, Mgs, ge),
    On = [P || P <- pairs_of(Set), tie(P, B, Mgs)],
    note("  ~-12s ~.2f  on-band ~p ~p [exact ~p]~n"
         "                   decisive ~p -> ~p | cycles ~p -> ~p | ordered ~p -> ~p~n",
         [Name, B, maps:get(ties, G), On, maps:get(exact_ties, G),
          maps:get(decisive, G), maps:get(decisive, E), maps:get(cycles, G),
          maps:get(cycles, E), maps:get(ordered, G), maps:get(ordered, E)]).

%% Every count that differs between IEEE double arithmetic and exact arithmetic on
%% the 160-match grid, under the record's own strict > rule and the record's own
%% bands. This is not a disagreement with the recount, which reproduces exactly;
%% it is a defect INHERITED from the counter both scripts use.
exact_diffs(Sets, Bands, Mgs, Mi) ->
    Keys = [decisive, cyclable, cycles, ordered, forward, backward],
    [{N, B, K, maps:get(K, counts(set_seeds(N, Sets), B, Mgs)),
      maps:get(K, counts(set_seeds(N, Sets), round(B * 160), Mi))}
     || N <- [full, kill, near_parity], B <- Bands, K <- Keys,
        maps:get(K, counts(set_seeds(N, Sets), B, Mgs))
            =/= maps:get(K, counts(set_seeds(N, Sets), round(B * 160), Mi))].

verdict_lines(Oks, Bad, All, Diffs) ->
    io_lib:format("-- VERDICT --~n~n"
                  "numbers compared = ~p~n"
                  "AGREES           = ~p~n"
                  "DISAGREES        = ~p~n"
                  "disagreeing tags = ~p~n~n~s~n~n"
                  "SEPARATELY, and NOT a disagreement with the recount: ~p counts change~n"
                  "when the same rule and the same bands are applied in exact arithmetic~n"
                  "instead of IEEE doubles (section K). Format {set,band,key,float,exact}:~n"
                  "~s~n"
                  "No cycle count, ordered count, forward or backward count, cycle seed~n"
                  "set, boundary signature or rho is among them, so no reading of the~n"
                  "recount changes. The cause is in the counter both scripts inherit, not~n"
                  "in the recount.~n~n",
                  [length(Oks), length([1 || {_T, true} <- Oks]), length(Bad), Bad,
                   verdict_text(All), length(Diffs), diff_lines(Diffs)]).

diff_lines([]) -> "  none\n";
diff_lines(Diffs) -> [io_lib:format("  ~p~n", [D]) || D <- Diffs].

verdict_text(true) ->
    "Every number the recount record states for the kill mode tier, and every\n"
    "number it states around them, is reproduced by code that shares nothing with\n"
    "the script that produced them. As a recount of the persisted matrix under the\n"
    "counter's own conventions it is sound. What it does NOT do is turn an\n"
    "exploratory unregistered probe into a signed result, and this verification\n"
    "does not either.";
verdict_text(false) ->
    "At least one number does NOT reproduce. The recount record must not be quoted\n"
    "until the disagreement is resolved. See the DISAGREES rows above.".

term_lines(Sets, Bands, Mgs, Oks, All, Diffs) ->
    T = {within_tier_verification,
         [{date, "2026-07-30"},
          {status, "EXPLORATORY VERIFICATION, POST HOC, NOT PRE-REGISTERED, SIGNS NOTHING"},
          {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
          {produced_by, "scripts/exp066_verify_within_tier.escript"},
          {shares_code_with_recount_script, false},
          {no_genome_loaded, true}, {no_match_replayed, true}, {no_arm_re_run, true},
          {rng, [{alg, ?RNG_ALG}, {state_from, ?RNG_STATE}, {draws, ?NULL_DRAWS}]},
          {bands, Bands},
          {recounted, [{Name, [{at_band, B, maps:to_list(counts(set_seeds(Name, Sets),
                                                                B, Mgs))}
                               || B <- Bands]}
                       || Name <- [full, kill, near_parity]]},
          {comparisons, [{length(Oks), agrees, length([1 || {_T, true} <- Oks])},
                         {disagrees, [T2 || {T2, false} <- Oks]}]},
          {all_agree, All},
          {float_vs_exact_arithmetic,
           [{note, "same strict > rule, same bands, arithmetic on the 160 grid"},
            {differing, [{S, B, K, Fl, Ex} || {S, B, K, Fl, Ex} <- Diffs]}]}]},
    io_lib:format("== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n"
                  "~w.~n", [T]).
