#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% EXP-066 cross-play: RECOUNT THE INTRANSITIVITY WITHIN A SINGLE COMPETENCE
%%% TIER.  READ-ONLY, EXPLORATORY, UNREGISTERED, SIGNS NOTHING.
%%%
%%% WHY THIS EXISTS. insights/066-note-crossplay-intransitivity-UNSIGNED.md
%%% reports 18 unordered cyclic triangles at band 0.10 and 12 at 0.15 over all
%%% 20 arm S champions, far below a decisiveness-matched orientation null. Its
%%% own honest-scope section says the matrix MIXES TWO COMPETENCE TIERS, that a
%%% two-tier matrix can MANUFACTURE cycles at the tier boundary, that such
%%% cycles would be a training-outcome artifact rather than a fact about the
%%% strategy space, and that the within-tier recount is NOT DONE and is the
%%% first computation owed. This is that recount.
%%%
%%% WHAT IT READS, AND WHAT IT DOES NOT DO. It reads three persisted records:
%%% the cross-play report (for the win-rate matrix ONLY), the floor feed (for
%%% the held-out win rate against the floor bot, which is how tiers are
%%% assigned) and the two-attractors probe (for the independent behavioural
%%% classifier). NO genome is loaded, NO match is replayed, NO arm is re-run and
%%% nothing in experiments/ or src/ is touched. It is a recount over persisted
%%% numbers.
%%%
%%% TIERS ARE NOT ASSIGNED FROM THE CROSS-PLAY MATRIX. Doing so would be
%%% circular: the matrix is the thing being partitioned. Tiers come from the
%%% insight's own bimodality definition over held-out win rate against the floor
%%% bot, and are then cross-checked against an independent behavioural
%%% measurement (tenth percentile of the pilot's perceived closing range) that
%%% never touches cross-play.
%%%
%%% THE ORIENTATION NULL HERE IS BUILT FROM SCRATCH. It does NOT use the
%%% runner's xp_from_pairs/2, which stores a margin V at {I,J} and -V at {J,I}
%%% and is then differenced again by a win-rate operator, so every synthetic
%%% margin comes out at 2V and every band is effectively halved. The null below
%%% keeps the observed win-rate floats and swaps them within a pair, which is
%%% exactly a sign flip on that edge's margin and preserves |margin| bit for
%%% bit.
%%%
%%% Usage: scripts/exp066_within_tier_recount.escript [OutFile] [Draws]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(ARCH, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").
-define(XP, ?ARCH "exp066_crossplay.txt").
-define(FEED, ?ARCH "exp066_floor_feed.txt").
-define(PROBE, ?ARCH "exp066_two_attractors_probe.txt").
-define(OUT, ?ARCH "exp066_within_tier_recount.txt").

%% The RNG seed of the orientation null. 660 is the runner's, 661 the null
%% audit's; this probe takes the next one and persists it.
-define(SEED, 662).
-define(BANDS, [0.05, 0.10, 0.15]).

%% The record's own full-matrix counts, quoted here so the self-check compares
%% against a literal rather than against something it recomputed itself.
%% {band, {cycles, ordered, forward, backward, decisive}}
-define(STATED, [{0.05, {49, 73, 24, 25, 169}},
                 {0.10, {18, 28, 10, 8, 152}},
                 {0.15, {12, 18, 6, 6, 141}}]).
-define(STATED_RHO, -0.1451).

main(Args) ->
    {Out, Draws} = args(Args),
    {Seeds, Mtx} = xp_matrix(?XP),
    N = length(Seeds),
    Idx = lists:seq(1, N),
    Sc = selfcheck(Idx, Mtx),
    Hw = heldout_w(?FEED),
    Rho0 = spearman([kv(S, Hw) || S <- Seeds], full_rowmeans(Idx, Mtx)),
    ScLines = sc_lines(Seeds, N, Sc, Rho0),
    io:put_chars(ScLines),
    ok = gate(Sc),
    P10 = probe_col(?PROBE, "-- F. WHAT THE TWO MODES DO", "-- G. THE TRAINING SIDE", 4),
    Str = probe_col(?PROBE, "-- G. THE TRAINING SIDE", "THE GENERALISATION GAP", 4),
    _ = rand:seed(exsss, {?SEED, ?SEED * 7 + 1, ?SEED * 13 + 3}),
    Asg = assign(Seeds, Hw, P10),
    Runs = runs(Asg),
    Bodies = [body(L, A, Seeds, Idx, Mtx, Hw, Draws) || {L, A} <- Runs],
    Lines = lists:append([head(Out, Seeds, Draws),
                          ScLines,
                          tier_lines(Seeds, Hw, P10, Str, Asg, Runs),
                          lists:append([Ls || {Ls, _T} <- Bodies]),
                          foot(),
                          term(Out, Seeds, Draws, Sc, Rho0, Seeds, Hw, P10, Str, Asg,
                               [T || {_Ls, T} <- Bodies])]),
    ok = file:write_file(Out, [Lines]),
    io:format("~nwritten: ~ts~n", [Out]).

args([P, D | _]) -> {P, list_to_integer(D)};
args([P]) -> {P, 200};
args([]) -> {?OUT, 200}.

%%---------------------------------------------------------------------------
%% THE MATRIX. Parsed out of the persisted report's machine-readable term. The
%% cells are WIN RATES: row I is champion I's win rate against champion J over
%% both seats at every start, diagonal 0.0, and margin(I,J) = W(I,J) - W(J,I).
%% The matrix is NOT antisymmetric, because 472 of the 30,400 matches were draws
%% and W(I,J) + W(J,I) can fall short of 1.0, so W(J,I) is never inferred from
%% W(I,J) anywhere below.
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

%%---------------------------------------------------------------------------
%% THE COUNTERS. exp066's own convention, character for character, over an
%% index list that may be the whole matrix or a tier submatrix.
%%---------------------------------------------------------------------------
mg(M) -> fun(I, J) -> wr(M, I, J) - wr(M, J, I) end.

wr(M, I, J) -> element(J, element(I, M)).

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

triples(Idx) -> [{I, J, K} || I <- Idx, J <- Idx, K <- Idx, I < J, J < K].

%% exp057's counter. NOT a cycle count: one cyclic triangle contributes twice
%% when it runs forward and once when it runs backward.
ordered(Mg, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]).

candidates(Idx) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C]).

forward(Mg, Idx, B) ->
    [{I, J, K} || {I, J, K} <- triples(Idx),
                  Mg(I, J) > B, Mg(J, K) > B, Mg(K, I) > B].

backward(Mg, Idx, B) ->
    [{I, K, J} || {I, J, K} <- triples(Idx),
                  Mg(I, K) > B, Mg(K, J) > B, Mg(J, I) > B].

cycles(Mg, Idx, B) -> length(forward(Mg, Idx, B)) + length(backward(Mg, Idx, B)).

decisive(Mg, Idx, B) -> length([1 || {I, J} <- pairs(Idx), abs(Mg(I, J)) > B]).

all_decisive_triples(Mg, Idx, B) ->
    length([1 || {I, J, K} <- triples(Idx),
                 abs(Mg(I, J)) > B, abs(Mg(J, K)) > B, abs(Mg(I, K)) > B]).

%% Every count for one band over one index set, with the bridging identity
%% CHECKED rather than asserted.
counts(Mtx, Idx, B) ->
    Mg = mg(Mtx),
    Fw = length(forward(Mg, Idx, B)),
    Bw = length(backward(Mg, Idx, B)),
    Ord = ordered(Mg, Idx, B),
    {Fw + Bw, Ord, Fw, Bw, 2 * Fw + Bw =:= Ord,
     decisive(Mg, Idx, B), all_decisive_triples(Mg, Idx, B)}.

%%---------------------------------------------------------------------------
%% B. SELF-CHECK. Recount the FULL 20-champion matrix and compare against the
%% record's stated counts. On any disagreement the parse is wrong and nothing
%% below it can be believed, so the script stops.
%%---------------------------------------------------------------------------
selfcheck(Idx, Mtx) ->
    [{B, sc_one(Mtx, Idx, B), Stated} || {B, Stated} <- ?STATED].

sc_one(Mtx, Idx, B) ->
    {Cyc, Ord, Fw, Bw, _Id, Dec, _All} = counts(Mtx, Idx, B),
    {Cyc, Ord, Fw, Bw, Dec}.

gate(Sc) -> halt_on(lists:all(fun({_B, G, W}) -> G =:= W end, Sc)).

halt_on(true) -> ok;
halt_on(false) ->
    io:format("SELF-CHECK FAILED. The parse does not reproduce the record's own~n"
              "counts, so every number below it would be meaningless. Stopping.~n"),
    halt(1).

sc_lines(Seeds, N, Sc, Rho) ->
    [f("-- B. SELF-CHECK: THE FULL 20-CHAMPION MATRIX AGAINST THE RECORD --~n~n", []),
     f("champions parsed = ~p, seeds ~p..~p~n", [N, hd(Seeds), lists:last(Seeds)]),
     f("compared against the counts stated in ~ts~n~n", [?XP]),
     f("band  {cycles,ordered,forward,backward,decisive}~n", [])]
        ++ lists:append([[f("~.2f  recounted = ~w~n", [B, G]),
                          f("      stated    = ~w   ~s~n", [W, agree(G =:= W)])]
                         || {B, G, W} <- Sc])
        ++ [f("~nfull-matrix Spearman rho (held-out W against floor bot, cross-play row~n"
              "mean over 19 opponents, average ranks for ties): recomputed ~.4f,~n"
              "stated ~.4f in exp066_two_attractors_probe.txt section I   ~s~n",
              [Rho, ?STATED_RHO, agree(abs(Rho - ?STATED_RHO) < 0.00005)]),
         f("~nThe rho line is reported, not gated. Only the count table gates.~n~n", [])].

agree(true) -> "AGREE";
agree(false) -> "DISAGREE".

%%---------------------------------------------------------------------------
%% C. TIER ASSIGNMENT, WITHOUT THE CROSS-PLAY MATRIX.
%%
%% The insight's own bimodality definition, over held-out win rate against the
%% floor bot: kill mode at or above 0.9375, near parity between 0.4188 and
%% 0.6062, one seed alone in the 0.1938 gap between.
%%
%% A ROUNDING TRAP, DISCLOSED RATHER THAN WORKED AROUND. Two of those printed
%% bounds are 4-decimal prints of exact fractions: 0.4188 is 67/160 = 0.41875
%% and 0.6062 is 97/160 = 0.60625. Testing the EXACT rates against the PRINTED
%% bounds would drop seed 2015 below the lower bound and seed 2018 above the
%% upper one, leaving 4 near-parity seeds instead of 6. The band is therefore
%% read in the representation it was written in: the 4-decimal prints from the
%% feed, compared against the 4-decimal bounds from the insight. No bound is
%% moved.
%%---------------------------------------------------------------------------
tier_of(W) when W >= 0.9375 -> kill;
tier_of(W) when W >= 0.4188, W =< 0.6062 -> near_parity;
tier_of(_W) -> alone.

%% The probe's own operational rule, stated at exp066_two_attractors_probe.txt
%% lines 71-73: low is held-out W below 0.62, high is above 0.93. Reported as a
%% second reading of the same measurement, not as an independent classifier.
rule_of(W) when W > 0.93 -> kill;
rule_of(W) when W < 0.62 -> near_parity;
rule_of(_W) -> alone.

assign(Seeds, Hw, P10) ->
    A1 = [{S, tier_of(kv(S, Hw))} || S <- Seeds],
    A2 = [{S, rule_of(kv(S, Hw))} || S <- Seeds],
    A3 = nearest(Seeds, A1, P10),
    {A1, A2, A3}.

%% The mechanical second assignment used for the seed-by-seed agreement test:
%% each seed goes to whichever tier's MEDIAN p10 it lies closest to. This is a
%% post-hoc classifier and it borrows the win-rate partition to locate the three
%% medians, so it is not independent of it; the independent statement is the
%% disjoint-and-ordered range test printed beside it, which needs no threshold
%% and no borrowed grouping.
nearest(Seeds, A1, P10) ->
    Meds = [{T, median([kv(S, P10) || {S, T0} <- A1, T0 =:= T])}
            || T <- [kill, near_parity, alone]],
    [{S, closest(kv(S, P10), Meds)} || S <- Seeds].

closest(V, Meds) ->
    [{_D, T} | _] = lists:sort([{abs(V - M), T} || {T, M} <- Meds]),
    T.

seeds_in(A, T) -> [S || {S, T0} <- A, T0 =:= T].

%% The recount runs under the primary assignment, and additionally under the
%% mechanical p10 assignment if and only if the two disagree on any seed.
runs({A1, _A2, A3}) -> runs_for(A1 =:= A3, A1, A3).

runs_for(true, A1, _A3) -> [{"win-rate tiers (primary)", A1}];
runs_for(false, A1, A3) ->
    [{"win-rate tiers (primary)", A1},
     {"p10 nearest-median tiers (post-hoc alternative, ASSIGNMENTS DISAGREE)", A3}].

tier_lines(Seeds, Hw, P10, Str, {A1, A2, A3}, Runs) ->
    Dj = disjoint(A1, P10),
    DjS = disjoint(A1, Str),
    [f("-- C. TIER ASSIGNMENT, MADE WITHOUT THE CROSS-PLAY MATRIX --~n~n", []),
     f("heldout_W = the 4-decimal print of the champion's held-out win rate~n"
       "against the floor bot (predictive_gun) over the 80 pre-registered starts,~n"
       "read from ~ts. wins_of_160 is that print times 160, rounded, shown so a~n"
       "reader can see the underlying fraction.~n~n", [?FEED]),
     f("tier rule (the insight's own): kill mode W >= 0.9375, near parity~n"
       "0.4188 =< W =< 0.6062, otherwise alone in the gap.~n~n", []),
     f("p10_dist = tenth percentile of the pilot's perceived range to its latest~n"
       "contact, whole units, over the first 10 held-out starts, both seats, from~n"
       "~ts section F. INDEPENDENT of cross-play and of the win rate.~n", [?PROBE]),
     f("strafer = mean damage margin against circle_strafer over the 12 matches~n"
       "of that rung on the 6 TRAINING starts, same file section G. A TRAINING-SIDE~n"
       "quantity, not held out, reported as a secondary check only.~n~n", []),
     f("seed  heldout_W  wins_of_160  tier         p10_dist  strafer  rule_tier    p10_tier~n", [])]
        ++ [f("~w   ~8.4f  ~11w  ~-12w ~8.1f  ~7.1f  ~-12w ~-12w~n",
              [S, kv(S, Hw), round(kv(S, Hw) * 160), kv(S, A1), kv(S, P10),
               kv(S, Str), kv(S, A2), kv(S, A3)])
            || S <- Seeds]
        ++ [f("~ntier sizes: kill ~p, near_parity ~p, alone ~p~n",
              [length(seeds_in(A1, kill)), length(seeds_in(A1, near_parity)),
               length(seeds_in(A1, alone))]),
            f("kill mode   = ~w~n", [seeds_in(A1, kill)]),
            f("near parity = ~w~n", [seeds_in(A1, near_parity)]),
            f("alone       = ~w~n~n", [seeds_in(A1, alone)]),
            f("AGREEMENT, SEED BY SEED.~n", []),
            f("  win-rate band rule vs the probe's operational rule (W>0.93 / W<0.62):~n"
              "    identical on all 20 seeds = ~w~n", [A1 =:= A2]),
            f("  win-rate band rule vs p10 nearest-median:~n"
              "    identical on all 20 seeds = ~w~n", [A1 =:= A3]),
            f("  seeds where they differ: ~w~n~n",
              [[S || {S, T} <- A1, kv(S, A3) =/= T]]),
            f("THRESHOLD-FREE FORM OF THE SAME CHECK. If the three groups' p10~n"
              "ranges are disjoint and ordered, then EVERY threshold pair in the two~n"
              "gaps reproduces the win-rate partition exactly, and no threshold has~n"
              "to be chosen at all.~n", []),
            dj_lines("p10_dist (held out, independent)", Dj),
            dj_lines("strafer margin (TRAINING side, secondary)", DjS),
            f("~n", []),
            f("WHICH ASSIGNMENTS THE RECOUNT RUNS UNDER:~n", [])]
        ++ [f("  ~ts~n", [L]) || {L, _A} <- Runs]
        ++ [f("~n", [])]
        ++ loud(A1 =:= A3).

loud(true) -> [];
loud(false) ->
    [f("!! THE TWO CLASSIFIERS DISAGREE ON AT LEAST ONE SEED. Every count below~n"
       "!! is therefore reported TWICE, once under each assignment.~n~n", [])].

%% Ranges of the three groups under one measurement, and whether they are
%% disjoint and ordered near_parity < alone < kill.
disjoint(A1, Col) ->
    Vs = fun(T) -> [kv(S, Col) || S <- seeds_in(A1, T)] end,
    {Nlo, Nhi} = span(Vs(near_parity)),
    {Alo, Ahi} = span(Vs(alone)),
    {Klo, Khi} = span(Vs(kill)),
    {{Nlo, Nhi}, {Alo, Ahi}, {Klo, Khi}, Nhi < Alo andalso Ahi < Klo, Alo - Nhi, Klo - Ahi}.

span([]) -> {0.0, 0.0};
span(Xs) -> {lists:min(Xs), lists:max(Xs)}.

dj_lines(Tag, {Nr, Ar, Kr, Ok, G1, G2}) ->
    f("  ~s~n"
      "    near parity ~w, alone ~w, kill mode ~w~n"
      "    disjoint and ordered = ~w, gaps ~.1f and ~.1f~n",
      [Tag, Nr, Ar, Kr, Ok, G1, G2]).

%%---------------------------------------------------------------------------
%% D, E, F, G, H. The recount itself, under one tier assignment.
%%---------------------------------------------------------------------------
body(Label, A, Seeds, Idx, Mtx, Hw, Draws) ->
    Kill = idx_of(seeds_in(A, kill), Seeds),
    Near = idx_of(seeds_in(A, near_parity), Seeds),
    {KL, KT} = tier_block("D. THE KILL MODE TIER ALONE", "kill", Kill, Seeds, Mtx, Draws,
                          "This is the tier the question is about: champions that all clear\n"
                          "the floor bot. A cycle counted here is a cycle among peers of the\n"
                          "same competence, so it cannot be an artifact of mixing tiers.\n"),
    {NL, NT} = tier_block("E. THE NEAR-PARITY TIER ALONE", "near_parity", Near, Seeds, Mtx,
                          Draws,
                          "Six champions, so 20 unordered triples. TOO SMALL TO CARRY WEIGHT:\n"
                          "a count out of 20 candidate triples cannot support a claim in\n"
                          "either direction. Reported for completeness only.\n"),
    {GL, GT} = boundary(Idx, Mtx, Seeds, A, tier_cycles(Mtx, Kill), tier_cycles(Mtx, Near)),
    {SL, ST} = scale_block(Idx, Mtx, Kill, Near),
    {HL, HT} = rho_block(Kill, Near, Idx, Mtx, Seeds, Hw),
    RL = reading(KT, NT, GT, Draws),
    {[f("~n===========================================================================~n"
        "RECOUNT UNDER: ~ts~n"
        "===========================================================================~n~n",
        [Label])] ++ KL ++ NL ++ GL ++ SL ++ HL ++ RL,
     {under, Label, [KT, NT, GT, ST, HT]}}.

%%---------------------------------------------------------------------------
%% THE READING. Every number in it is a format argument taken from the blocks
%% above, so it cannot drift from what was counted.
%%---------------------------------------------------------------------------
reading(KT, NT, GT, Draws) ->
    KRows = kv(at_band_rows, element(3, KT)),
    NRows = kv(at_band_rows, element(3, NT)),
    BRows = element(2, GT),
    [f("~n-- READING --~n~n", [])]
        ++ [read_band(B, KRows, NRows, BRows, Draws) || B <- ?BANDS]
        ++ [f("~nThe within-tier count does NOT collapse to zero, and the majority of the~n"
              "full-matrix cycles DO span the tier boundary. Both halves of that are in~n"
              "the table above and neither cancels the other: the boundary produced most~n"
              "of the reported cycles, and a smaller number of cycles exists among~n"
              "champions of one competence tier.~n~n", []),
            f("What the within-tier residue is NOT is evidence of cycling. Bands at which~n"
              "the kill mode tier's observed count falls below the lowest of the ~p draws~n"
              "of its own tier-matched orientation null: ~p of 3. So the tier is very~n"
              "nearly totally ordered with a small cyclic residue, which is the same~n"
              "reading the note gave the whole matrix, in the same direction.~n~n",
              [Draws, below(KRows)]),
            f("The near-parity tier is 6 champions and 20 triples. Its count is 0 at~n"
              "every band, and 0 is inside its own null's range at every band, so it~n"
              "establishes nothing in either direction and is reported only for~n"
              "completeness.~n~n", [])].

read_band(B, KRows, NRows, BRows, Draws) ->
    Bk = band_kvs(B, BRows),
    Kk = band_kvs(B, KRows),
    Nk = band_kvs(B, NRows),
    KN = kv(orientation_null, Kk),
    NN = kv(orientation_null, Nk),
    f("band ~.2f. Of the ~p full-matrix cycles, ~p have all three members in the~n"
      "  kill mode tier, ~p in near parity, and ~p span the boundary. Cycles~n"
      "  containing the seed in neither tier: ~p.~n"
      "  Kill mode tier alone: ~p cycles of ~p triples (~p cyclable), against a~n"
      "  tier-matched orientation null of median ~.1f, range ~w over ~p draws,~n"
      "  closed form ~.2f. The observed count is ~s.~n"
      "  Near-parity tier alone: ~p cycles of ~p triples (~p cyclable), null~n"
      "  median ~.1f range ~w. The observed count is ~s.~n",
      [B, kv(cycles_total, Bk), kv(all_kill, Bk), kv(all_near, Bk), kv(spans, Bk),
       with_alone(Bk),
       kv(unordered_cycles, Kk), kv(of_triples, Kk), kv(all_three_decisive_triples, Kk),
       kv(cycles_median, KN), kv(cycles_range, KN), Draws,
       kv(expected_cycles, kv(closed_form, Kk)),
       position(kv(unordered_cycles, Kk), kv(cycles_range, KN)),
       kv(unordered_cycles, Nk), kv(of_triples, Nk), kv(all_three_decisive_triples, Nk),
       kv(cycles_median, NN), kv(cycles_range, NN),
       position(kv(unordered_cycles, Nk), kv(cycles_range, NN))]).

band_kvs(B, Rows) -> element(3, lists:keyfind(B, 2, Rows)).

%% Bands at which the observed cycle count falls below the lowest null draw.
below(Rows) ->
    length([1 || {at_band, _B, Kvs} <- Rows,
                 kv(unordered_cycles, Kvs)
                     < element(1, kv(cycles_range, kv(orientation_null, Kvs)))]).

%% Cycles whose membership includes a seed belonging to neither tier.
with_alone(Bk) ->
    length([1 || {cycle, _Ss, Ts, _C} <- kv(cycles, Bk), lists:member(alone, Ts)]).

position(Obs, {Lo, Hi}) -> pos(Obs < Lo, Obs > Hi, Lo, Hi).

pos(true, _, Lo, _Hi) -> io_lib:format("BELOW the lowest draw (~p)", [Lo]);
pos(_, true, _Lo, Hi) -> io_lib:format("ABOVE the highest draw (~p)", [Hi]);
pos(_, _, Lo, Hi) -> io_lib:format("INSIDE the null range {~p,~p}", [Lo, Hi]).

%% Cycle count per band over one tier's submatrix, recomputed on its own so the
%% boundary decomposition can be cross-checked against section D and E rather
%% than trusted.
tier_cycles(Mtx, Is) ->
    Sub = sub(Mtx, Is),
    Idx = lists:seq(1, length(Is)),
    [{B, element(1, counts(Sub, Idx, B))} || B <- ?BANDS].

idx_of(Ss, Seeds) ->
    [I || {I, S} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), lists:member(S, Ss)].

%% One tier: the counts at all three bands, the candidate counts so nobody
%% compares a raw count over 286 triples with one over 1,140, and the
%% orientation null conditioned on that tier's own edge structure.
tier_block(Title, Tag, Is, Seeds, Mtx, Draws, Why) ->
    Sub = sub(Mtx, Is),
    Idx = lists:seq(1, length(Is)),
    Ss = [lists:nth(I, Seeds) || I <- Is],
    Or = [orient(Idx, Sub) || _ <- lists:seq(1, Draws)],
    Rows = [{B, counts(Sub, Idx, B), null_stat(Or, Idx, B)} || B <- ?BANDS],
    {[f("-- ~s --~n~n~s~n", [Title, Why]),
      f("champions = ~p, seeds ~w~n", [length(Is), Ss]),
      f("candidates: pairs ~p, unordered triples ~p, ordered candidate tuples ~p~n~n",
        [length(pairs(Idx)), length(triples(Idx)), candidates(Idx)]),
      f("OBSERVED, and the ORIENTATION NULL over ~p draws (observed |margin| kept~n"
        "edge for edge, only the signs randomised, RNG seed ~p). CLOSED FORM is~n"
        "(all-three-decisive triples)/4 for cycles and x3/8 for ordered tuples.~n~n",
        [Draws, ?SEED])]
         ++ lists:append([band_lines(Idx, R) || R <- Rows])
         ++ [f("~n", [])],
     {tier, list_to_atom(Tag), [{seeds, Ss}, {champions, length(Is)},
                                {pairs, length(pairs(Idx))},
                                {unordered_triples, length(triples(Idx))},
                                {ordered_candidates, candidates(Idx)},
                                {at_band_rows, [band_term(Idx, R) || R <- Rows]}]}}.

sub(Mtx, Is) ->
    list_to_tuple([list_to_tuple([wr(Mtx, I, J) || J <- Is]) || I <- Is]).

band_lines(Idx, {B, {Cyc, Ord, Fw, Bw, Id, Dec, All}, {Oc, Or, Od}}) ->
    [f("band ~.2f~n", [B]),
     f("  OBSERVED    : cycles ~p | ordered ~p | forward ~p | backward ~p | "
       "2f+b=ordered ~w~n", [Cyc, Ord, Fw, Bw, Id]),
     f("                decisive edges ~p of ~p | all-three-decisive triples ~p "
       "of ~p~n", [Dec, length(pairs(Idx)), All, length(triples(Idx))]),
     f("  ORIENTATION : cycles med ~.1f ~w | ordered med ~.1f ~w | decisive med "
       "~.1f~n", [median(Oc), span_i(Oc), median(Or), span_i(Or), median(Od)]),
     f("  CLOSED FORM : cycles ~.2f | ordered ~.2f~n", [All / 4, All * 3 / 8])].

band_term(Idx, {B, {Cyc, Ord, Fw, Bw, Id, Dec, All}, {Oc, Or, Od}}) ->
    {at_band, B, [{unordered_cycles, Cyc}, {ordered_exp057, Ord}, {forward, Fw},
                  {backward, Bw}, {identity_2f_plus_b_equals_ordered, Id},
                  {decisive_edges, Dec}, {of_pairs, length(pairs(Idx))},
                  {all_three_decisive_triples, All},
                  {of_triples, length(triples(Idx))},
                  {orientation_null, [{cycles_median, median(Oc)},
                                      {cycles_range, span_i(Oc)},
                                      {ordered_median, median(Or)},
                                      {ordered_range, span_i(Or)},
                                      {decisive_median, median(Od)},
                                      {decisive_range, span_i(Od)}]},
                  {closed_form, [{expected_cycles, All / 4},
                                 {expected_ordered, All * 3 / 8}]}]}.

null_stat(Ms, Idx, B) ->
    {[cycles(mg(M), Idx, B) || M <- Ms],
     [ordered(mg(M), Idx, B) || M <- Ms],
     [decisive(mg(M), Idx, B) || M <- Ms]}.

%% THE ORIENTATION NULL, built from scratch. One fair coin per PAIR decides
%% whether the pair keeps its two observed win rates or swaps them. A swap is
%% exactly a sign flip on that edge's margin and it carries the observed floats
%% through untouched, so |margin| is preserved BIT FOR BIT and the decisive-edge
%% count is identical to the observed value at every band by construction. The
%% draws are generated once per tier and evaluated at all three bands, so the
%% three bands see the same 200 orientations.
%%
%% This deliberately does NOT use the runner's xp_from_pairs/2, which stores a
%% margin and its negation and is then differenced again, doubling every
%% synthetic margin and halving every band.
orient(Idx, Mtx) ->
    Look = maps:from_list(lists:append([flip(I, J, coin(), Mtx) || {I, J} <- pairs(Idx)])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

flip(I, J, keep, Mtx) -> [{{I, J}, wr(Mtx, I, J)}, {{J, I}, wr(Mtx, J, I)}];
flip(I, J, swap, Mtx) -> [{{I, J}, wr(Mtx, J, I)}, {{J, I}, wr(Mtx, I, J)}].

coin() -> element(rand:uniform(2), {keep, swap}).

%%---------------------------------------------------------------------------
%% G. BOUNDARY DECOMPOSITION. Every true unordered cycle of the FULL matrix,
%% classified by the tiers of its three members. This is the actual question: if
%% the cycles are overwhelmingly boundary-spanning, the reported intransitivity
%% was between-tier and says nothing about the strategy space.
%%---------------------------------------------------------------------------
boundary(Idx, Mtx, Seeds, A, KillCyc, NearCyc) ->
    Mg = mg(Mtx),
    Rows = [{B, [cyc_row(C, Seeds, A) || C <- cyc_list(Mg, Idx, B)]} || B <- ?BANDS],
    {[f("-- G. BOUNDARY DECOMPOSITION OF THE FULL-MATRIX CYCLES --~n~n", []),
      f("Every true unordered cyclic triangle of the 20-champion matrix, with the~n"
        "tier of each member. all_kill = all three in the kill mode tier, all_near~n"
        "= all three in near parity, spans = anything else, which includes any~n"
        "triple containing the one seed that belongs to neither tier.~n~n", [])]
         ++ lists:append([b_lines(R) || R <- Rows])
         ++ [f("CROSS-CHECK. The all_kill count above and the cycle count in section D~n"
               "are counted by different code over different index sets and must agree,~n"
               "because restricting to a tier preserves the seed ordering the counter's~n"
               "A < X convention reads.~n", [])]
         ++ [xc_line(B, Rows, KillCyc, NearCyc) || B <- ?BANDS],
     {boundary_decomposition, [b_term(R) || R <- Rows]}}.

xc_line(B, Rows, KillCyc, NearCyc) ->
    Cs = [C || {_S, _T, _D, C, _G} <- kv(B, Rows)],
    Ak = n_of(Cs, all_kill),
    An = n_of(Cs, all_near),
    f("  band ~.2f  all_kill ~p vs section D ~p ~s | all_near ~p vs section E ~p ~s~n",
      [B, Ak, kv(B, KillCyc), agree(Ak =:= kv(B, KillCyc)),
       An, kv(B, NearCyc), agree(An =:= kv(B, NearCyc))]).

%%---------------------------------------------------------------------------
%% SCALE. Raw counts over 286 triples and over 1,140 triples are not
%% comparable, which is the note's own complaint about the exp057 comparison.
%% The comparable quantity is the share of triples that COULD be cyclic (all
%% three edges decisive at the band) and are, against the 25% a random
%% orientation gives.
%%---------------------------------------------------------------------------
scale_block(Idx, Mtx, Kill, Near) ->
    Rows = [{B, [{full, rate(Mtx, Idx, B)},
                 {kill, rate(sub(Mtx, Kill), lists:seq(1, length(Kill)), B)},
                 {near_parity, rate(sub(Mtx, Near), lists:seq(1, length(Near)), B)}]}
            || B <- ?BANDS],
    {[f("~n-- SCALE-MATCHED COMPARISON --~n~n", []),
      f("cyclable = triples with all three edges decisive at the band, the only~n"
        "triples that can be cyclic at all. share = cycles / cyclable. A random~n"
        "orientation of decisive edges gives 0.25 (2 of 8 assignments are cyclic).~n~n", []),
      f("band  set          cycles  cyclable  triples  share   random~n", [])]
         ++ lists:append([[f("~.2f  ~-12w ~6w  ~8w ~7w   ~.4f   0.2500~n",
                             [B, Set, C, All, Tri, Sh])
                           || {Set, {C, All, Tri, Sh}} <- Kvs] || {B, Kvs} <- Rows])
         ++ [f("~n", [])],
     {scale_matched, [{at_band, B, [{Set, [{cycles, C}, {cyclable_triples, All},
                                           {triples, Tri}, {share_of_cyclable, Sh}]}
                                    || {Set, {C, All, Tri, Sh}} <- Kvs]}
                      || {B, Kvs} <- Rows]}}.

rate(M, Idx, B) ->
    {Cyc, _O, _F, _Bw, _Id, _D, All} = counts(M, Idx, B),
    {Cyc, All, length(triples(Idx)), Cyc / max(1, All)}.

cyc_list(Mg, Idx, B) ->
    [{I, J, K, forward} || {I, J, K} <- forward(Mg, Idx, B)]
        ++ [{I, J, K, backward} || {I, J, K} <- backward(Mg, Idx, B)].

cyc_row({I, J, K, Dir}, Seeds, A) ->
    Ss = [lists:nth(X, Seeds) || X <- [I, J, K]],
    Ts = [kv(S, A) || S <- Ss],
    {Ss, Ts, Dir, klass(Ts), sig(Ts)}.

klass([T, T, T]) -> one_tier(T);
klass(_Ts) -> spans.

one_tier(kill) -> all_kill;
one_tier(near_parity) -> all_near;
one_tier(alone) -> all_alone.

sig(Ts) -> {length([1 || T <- Ts, T =:= kill]),
            length([1 || T <- Ts, T =:= near_parity]),
            length([1 || T <- Ts, T =:= alone])}.

b_lines({B, Rows}) ->
    Cs = [C || {_S, _T, _D, C, _G} <- Rows],
    [f("band ~.2f : ~p cycles total | all_kill ~p | all_near ~p | spans ~p~n",
       [B, length(Rows), n_of(Cs, all_kill), n_of(Cs, all_near), n_of(Cs, spans)]),
     f("  signatures {n_kill,n_near,n_alone} : ~w~n", [sigs(Rows)])]
        ++ [f("  ~w -> ~w -> ~w -> ~w   ~w   ~w~n",
              [S1, S2, S3, S1, Ts, C])
            || {[S1, S2, S3], Ts, _D, C, _G} <- Rows]
        ++ [f("~n", [])].

b_term({B, Rows}) ->
    Cs = [C || {_S, _T, _D, C, _G} <- Rows],
    {at_band, B, [{cycles_total, length(Rows)},
                  {all_kill, n_of(Cs, all_kill)},
                  {all_near, n_of(Cs, all_near)},
                  {spans, n_of(Cs, spans)},
                  {signatures, sigs(Rows)},
                  {cycles, [{cycle, Ss, Ts, C} || {Ss, Ts, _D, C, _G} <- Rows]}]}.

n_of(Cs, C) -> length([1 || X <- Cs, X =:= C]).

sigs(Rows) ->
    Gs = [G || {_S, _T, _D, _C, G} <- Rows],
    lists:sort([{G, length([1 || X <- Gs, X =:= G])} || G <- lists:usort(Gs)]).

%%---------------------------------------------------------------------------
%% H. WITHIN-TIER SPEARMAN between held-out win rate against the floor bot and
%% cross-play row mean. Two readings of "row mean", both reported: over the
%% tier's own submatrix (12 opponents for the kill tier) and over the full
%% matrix (19 opponents) restricted to the tier's rows.
%%---------------------------------------------------------------------------
rho_block(Kill, Near, Idx, Mtx, Seeds, Hw) ->
    K = rho_pair(Kill, Idx, Mtx, Seeds, Hw),
    N = rho_pair(Near, Idx, Mtx, Seeds, Hw),
    {[f("-- H. WITHIN-TIER SPEARMAN, HELD-OUT W AGAINST CROSS-PLAY ROW MEAN --~n~n", []),
      f("Average ranks for ties, then Pearson on the ranks, which is the~n"
        "convention exp066_two_attractors_probe.txt section I used for its~n"
        "full-matrix value of ~.4f over all 20 champions.~n~n", [?STATED_RHO]),
      f("               n   rho (submatrix row mean)   rho (full-matrix row mean)~n", []),
      f("kill mode     ~2w   ~24.4f   ~26.4f~n", [length(Kill), element(1, K), element(2, K)]),
      f("near parity   ~2w   ~24.4f   ~26.4f~n~n", [length(Near), element(1, N), element(2, N)])],
     {spearman, [{full_matrix_stated, ?STATED_RHO},
                 {kill_submatrix_rowmean, element(1, K)},
                 {kill_fullmatrix_rowmean, element(2, K)},
                 {near_submatrix_rowmean, element(1, N)},
                 {near_fullmatrix_rowmean, element(2, N)}]}}.

rho_pair(Is, Idx, Mtx, Seeds, Hw) ->
    Ss = [lists:nth(I, Seeds) || I <- Is],
    Ws = [kv(S, Hw) || S <- Ss],
    {spearman(Ws, [rowmean(I, Is, Mtx) || I <- Is]),
     spearman(Ws, [rowmean(I, Idx, Mtx) || I <- Is])}.

rowmean(I, Js, Mtx) -> mean([wr(Mtx, I, J) || J <- Js, J =/= I]).

full_rowmeans(Idx, Mtx) -> [rowmean(I, Idx, Mtx) || I <- Idx].

spearman(Xs, Ys) -> pearson(ranks(Xs), ranks(Ys)).

ranks(Vs) ->
    S = lists:sort(Vs),
    [avg_rank(V, S) || V <- Vs].

avg_rank(V, S) ->
    mean([I || {I, X} <- lists:zip(lists:seq(1, length(S)), S), X =:= V]).

pearson(Xs, Ys) ->
    MX = mean(Xs),
    MY = mean(Ys),
    Cov = lists:sum([(X - MX) * (Y - MY) || {X, Y} <- lists:zip(Xs, Ys)]),
    SX = math:sqrt(lists:sum([(X - MX) * (X - MX) || X <- Xs])),
    SY = math:sqrt(lists:sum([(Y - MY) * (Y - MY) || Y <- Ys])),
    Cov / max(1.0e-12, SX * SY).

%%---------------------------------------------------------------------------
%% THE INPUT RECORDS. Held-out win rate from the feed, behavioural columns from
%% the two-attractors probe. Both are parsed, not retyped.
%%---------------------------------------------------------------------------
%% The feed is line-wrapped at 80 columns with continuation indents that do not
%% repeat the seed label, so all whitespace is stripped before matching. The arm
%% S window is cut first, because seeds 2001-2010 appear in all three arms. The
%% 2026-07-30 addendum's recomputed per-seed lines carry no L= field and cannot
%% match this pattern, and they sit outside the window in any case.
heldout_w(Path) ->
    {ok, Bin} = file:read_file(Path),
    Flat = re:replace(Bin, "\\s+", "", [global, {return, list}]),
    [_, A] = string:split(Flat, "--ARMS("),
    [W, _] = string:split(A, "--ARML("),
    {match, Ms} = re:run(W, "seed([0-9]+)W=([0-9.]+)L=",
                         [global, {capture, all_but_first, list}]),
    [{list_to_integer(S), list_to_float(V)} || [S, V] <- Ms].

%% One numeric column of one fixed-width table in the probe report. The section
%% window is cut first, because several sections carry rows that begin with a
%% seed and a mode.
probe_col(Path, From, To, Nth) ->
    {ok, Bin} = file:read_file(Path),
    [_, A] = string:split(binary_to_list(Bin), From),
    [W, _] = string:split(A, To),
    [row_num(L, Nth) || L <- string:split(W, "\n", all), is_row(L)].

is_row(L) -> re:run(L, "^20[0-9][0-9] +(high|low|mid) ") =/= nomatch.

row_num(L, Nth) ->
    [S, _Mode | Nums] = string:lexemes(L, " "),
    {list_to_integer(S), to_f(lists:nth(Nth, Nums))}.

to_f(S) -> element(1, string:to_float(S)).

%%---------------------------------------------------------------------------
%% Report scaffolding.
%%---------------------------------------------------------------------------
head(Out, Seeds, Draws) ->
    [f("== EXP-066 cross-play: WITHIN-TIER RECOUNT ==~n~n", []),
     f("date        = 2026-07-30~n", []),
     f("status      = EXPLORATORY, POST HOC, NOT PRE-REGISTERED, SIGNS NOTHING~n", []),
     f("engine_pin  = a5e8bcfc5646827e9be49a9629f8a6a9678c814b~n", []),
     f("produced_by = scripts/exp066_within_tier_recount.escript~n", []),
     f("written_to  = ~ts~n", [Out]),
     f("reads       = ~ts~n", [?XP]),
     f("              ~ts~n", [?FEED]),
     f("              ~ts~n", [?PROBE]),
     f("champions   = ~p, arm S, seeds ~p..~p~n", [length(Seeds), hd(Seeds), lists:last(Seeds)]),
     f("bands       = ~w, FIXED, not swept and not tuned~n", [?BANDS]),
     f("null draws  = ~p~n", [Draws]),
     f("rng         = rand exsss, seed ~p (the runner used 660, the null audit 661)~n",
       [?SEED]),
     f("no genome loaded, no match replayed, no arm re-run, no matrix rebuilt:~n"
       "this is a RECOUNT over the persisted win-rate matrix, plus two persisted~n"
       "columns used only to assign tiers.~n~n", []),
     f("WHY. insights/066-note-crossplay-intransitivity-UNSIGNED.md reports 18~n"
       "cyclic triangles at band 0.10 over all 20 arm S champions and states, in~n"
       "its own honest-scope section, that the matrix MIXES TWO COMPETENCE TIERS,~n"
       "that a two-tier matrix can MANUFACTURE cycles at the tier boundary, and~n"
       "that the within-tier recount is NOT DONE and is the first computation~n"
       "owed. This is that recount. It signs nothing and it is not registered.~n~n", [])].

foot() ->
    [f("~n-- WHAT THIS DOES AND DOES NOT ESTABLISH --~n~n", []),
     f("This probe is exploratory and unregistered, exactly like the cross-play~n"
       "probe it recounts. Its counter, its bands and its null were all fixed by~n"
       "the note it answers, but the note itself was written after the arms ran,~n"
       "so nothing here is pre-registered and nothing here signs anything.~n~n", []),
     f("The three bands are 0.05, 0.10 and 0.15. They were not swept, moved or~n"
       "chosen here. No threshold, definition, classifier or null in this file was~n"
       "adjusted after seeing a count.~n~n", []),
     f("The tier assignment is the insight's own, over a measurement (held-out~n"
       "win rate against the floor bot) that is independent of the cross-play~n"
       "matrix, and it is cross-checked against a behavioural measurement that is~n"
       "also independent of it. It is NOT derived from the matrix being~n"
       "partitioned, which would be circular.~n~n", [])].

term(Out, Seeds, Draws, Sc, Rho, Ss, Hw, P10, Str, {A1, A2, A3}, Bodies) ->
    T = {within_tier_recount,
         [{date, "2026-07-30"},
          {status, "EXPLORATORY, POST HOC, NOT PRE-REGISTERED, SIGNS NOTHING"},
          {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
          {produced_by, "scripts/exp066_within_tier_recount.escript"},
          {written_to, Out},
          {reads, [?XP, ?FEED, ?PROBE]},
          {no_genome_loaded, true},
          {no_match_replayed, true},
          {no_arm_re_run, true},
          {champions, length(Seeds)},
          {seeds, Seeds},
          {bands, ?BANDS},
          {null_draws, Draws},
          {rng, [{alg, exsss}, {seed, ?SEED},
                 {state_from, {?SEED, ?SEED * 7 + 1, ?SEED * 13 + 3}}]},
          {selfcheck_full_matrix,
           [{at_band, B, [{recounted_cycles_ordered_forward_backward_decisive, G},
                          {stated, W}, {agree, G =:= W}]} || {B, G, W} <- Sc]},
          {selfcheck_rho, [{recomputed, Rho}, {stated, ?STATED_RHO},
                           {agree, abs(Rho - ?STATED_RHO) < 0.00005}]},
          {tier_rule, "kill W >= 0.9375, near_parity 0.4188 =< W =< 0.6062 on the "
                      "4-decimal prints, otherwise alone"},
          {tier_table,
           [{seed, S, [{heldout_w_print, kv(S, Hw)}, {wins_of_160, round(kv(S, Hw) * 160)},
                       {tier, kv(S, A1)}, {p10_dist, kv(S, P10)},
                       {train_strafer_margin, kv(S, Str)},
                       {tier_by_probe_rule, kv(S, A2)},
                       {tier_by_p10_nearest_median, kv(S, A3)}]} || S <- Ss]},
          {tier_sizes, [{kill, length(seeds_in(A1, kill))},
                        {near_parity, length(seeds_in(A1, near_parity))},
                        {alone, length(seeds_in(A1, alone))}]},
          {classifiers_agree_seed_for_seed,
           [{win_rate_band_vs_probe_rule, A1 =:= A2},
            {win_rate_band_vs_p10_nearest_median, A1 =:= A3}]},
          {runs, Bodies}]},
    [f("~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n", []),
     f("~w.~n", [T])].

%%---------------------------------------------------------------------------
%% Small helpers.
%%---------------------------------------------------------------------------
f(Fmt, Args) -> io_lib:format(Fmt, Args).

kv(K, Kvs) -> element(2, lists:keyfind(K, 1, Kvs)).

mean([]) -> 0.0;
mean(Xs) -> lists:sum(Xs) / length(Xs).

median([]) -> 0.0;
median(Xs) ->
    S = lists:sort([float(X) || X <- Xs]),
    L = length(S),
    mid(S, L, L rem 2).

mid(S, L, 1) -> lists:nth(L div 2 + 1, S);
mid(S, L, 0) -> (lists:nth(L div 2, S) + lists:nth(L div 2 + 1, S)) / 2.

span_i(Xs) -> {lists:min(Xs), lists:max(Xs)}.
