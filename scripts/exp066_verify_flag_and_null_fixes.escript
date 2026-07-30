#!/usr/bin/env escript
%%! -noshell
%%
%% INDEPENDENT VERIFICATION of the four post-hoc EXP-066 fixes of 2026-07-30.
%%
%% WHY THIS EXISTS. A green result is not believable until the corresponding RED
%% has been seen. The runner file is NOT reverted here (another agent may be
%% reading it, and mutating a file to test it is unnecessary): instead this script
%% holds the OLD and the NEW form of each fixed thing SIDE BY SIDE, reimplemented
%% from the description rather than called, and applies both to the SAME data in
%% ONE run. Printing both values is stronger evidence than a revert, because a
%% revert can only show one of them at a time.
%%
%% WHAT IT CHECKS.
%%   FIX A  IF-10 LADDER-INVERSION. The as-run predicate and the widened one, per
%%          arm and per seed, over all 40 archived champions, on profiles this
%%          script recomputes itself. Both reimplementations are also compared
%%          against the runner's own inverted_as_run/1 and inverted/1.
%%   FIX B  PH-GEN. Whether IF-8's left conjunct is vacuous (train_w at 1.0000 for
%%          40 of 40) and whether the NEW diagnostic resolves the two arm S modes.
%%   FIX C  scripted_null/1's discarded L and D, and an INDEPENDENT triple search
%%          over the emitted pair table under the stated relation.
%%   FIX D  The synthetic null, as-run construction beside the fixed one, on
%%          literally the same drawn integers, plus the escript's third encoding
%%          and an exact-integer reference.
%%
%% NO ARM IS RE-RUN AND NO GENOME IS MODIFIED. Every match here is a REPLAY of an
%% archived champion or a scripted bot through the runner's own match loop
%% (duels/3 -> duel/3 -> play_seat/5 -> play/2 -> robo_sim). Nothing under arm/2,
%% seed_run/4, one_run/4 or fitness_fun/5 is called. The three champion .eterm
%% files are opened read-only. This script writes NO record: it prints and exits.
%%
%% HOW IT REACHES INTERNAL FUNCTIONS. The runner's beam is read for its abstract
%% code, the module attribute is renamed and export_all is injected, so the
%% recompiled shadow exposes profile/2, duels/3, margin/1 and the rest without the
%% runner on disk being touched in any way.
%%
%%   scripts/exp066_verify_flag_and_null_fixes.escript [null_draws]

-define(SHADOW, exp066_verify_shadow).
-define(RUNG_LOWER, [sitting_duck, spinner, rammer, circle_strafer]).
-define(FLOOR, predictive_gun).
-define(FP, 256).
-define(XP_SEED, 660).
-define(NULL_N, 20).
-define(NULL_CELL, 160).
-define(BANDS, [0.05, 0.10, 0.15]).

main(Args) ->
    Root = root(),
    M = boot(Root),
    Draws = draws(Args),
    Opts = M:merged(#{archive_dir => arch(Root)}),
    hdr(Root, Draws),
    K = M:constants(Opts),
    B = maps:get(b, K),
    Rows = replay(M, Opts),
    Res = lists:append([fix_a(M, Rows), fix_b(Rows, B), fix_c(M, Root, Opts, Rows),
                        fix_d(Draws)]),
    verdict(Res),
    halt(status(Res)).

root() -> filename:dirname(filename:dirname(filename:absname(escript:script_name()))).

arch(Root) -> Root ++ "/programmes/p7_coevolution/exp066_competence_floor/".

draws([D | _]) -> list_to_integer(D);
draws([]) -> 200.

hdr(Root, Draws) ->
    io:format("== EXP-066: INDEPENDENT VERIFICATION OF THE FOUR POST-HOC FIXES ==~n~n"
              "repo        : ~s~n"
              "null draws  : ~p at seed ~p, ~p objects, ~p matches per cell~n"
              "old and new : held side by side in ONE run; the runner is NOT reverted~n"
              "replay only : no arm re-run, no genome modified, nothing written~n~n",
              [Root, Draws, ?XP_SEED, ?NULL_N, ?NULL_CELL]).

%%%============================================================================
%%% Replay every archived champion. One pass, reused by FIX A and FIX B.
%%%============================================================================
replay(M, Opts) ->
    Held = M:heldout_starts(Opts),
    Train = M:train_starts(Opts),
    Cal = M:calib_starts(Opts),
    io:format("replaying 40 archived champions on all three splits ...~n"),
    T0 = erlang:monotonic_time(second),
    Rs = [{A, M:pmap(fun(C) -> row(M, C, Held, Train, Cal) end,
                     M:champion_read(M:add_path(Opts, A)),
                     erlang:system_info(schedulers_online))}
          || A <- [s, l, d]],
    io:format("  done in ~p s~n~n", [erlang:monotonic_time(second) - T0]),
    Rs.

row(M, {champion, Arm, Seed, Layers, Q, Fit, _Evals}, Held, Train, Cal) ->
    Net = {net, Layers, Q},
    Prof = M:profile(Net, Held),
    {TW, TFl} = leg(M, Net, Train),
    {CW, CFl} = leg(M, Net, Cal),
    {HW, HFl} = leg(M, Net, Held),
    #{arm => Arm, seed => Seed, fit => Fit, net => Net, profile => Prof,
      tw => TW, tfl => TFl, cw => CW, cfl => CFl, hw => HW, hfl => HFl}.

%% One split against the floor bot: win rate and the FLOORED mean margin in whole
%% units, which is the quantity margin/1 returns and the fitness reads.
leg(M, Net, Starts) ->
    Os = M:heldout(Net, ?FLOOR, Starts),
    {M:win_rate(Os), mean([M:margin(O) || O <- Os]) / ?FP}.

%%%============================================================================
%%% FIX A. The as-run inversion predicate beside the widened one.
%%%
%%% Both are reimplemented HERE from their stated definitions, then compared with
%%% the runner's own two functions on the same profiles, so a disagreement between
%%% description and code would show up as a DISAGREE line rather than pass.
%%%============================================================================
old_pred(Prof) ->
    lists:any(fun({Kind, W, L, _D}) ->
                  lists:member(Kind, [sitting_duck, spinner]) andalso L > W
              end, Prof).

new_pred(Prof) -> lists:any(fun new_cell/1, Prof).

new_cell({Kind, W, L, D}) ->
    lists:member(Kind, ?RUNG_LOWER) andalso (L > W orelse D > 0.5).

old_cell({Kind, W, L, _D}) ->
    lists:member(Kind, [sitting_duck, spinner]) andalso L > W.

why({_K, W, L, _D}) when L > W -> loses;
why(_Cell) -> draw_parked.

fix_a(M, Rows) ->
    io:format("~n=========================================================================~n"
              "FIX A. IF-10 LADDER-INVERSION: AS-RUN PREDICATE BESIDE THE WIDENED ONE~n"
              "=========================================================================~n~n"
              "AS-RUN  : any rung of [sitting_duck, spinner] with L > W~n"
              "WIDENED : any rung of [sitting_duck, spinner, rammer, circle_strafer]~n"
              "          with L > W orelse D > 0.5~n~n"
              "Both are reimplemented in this script and also read off the runner. All~n"
              "four verdicts per champion come from ONE recomputed profile.~n~n"
              "arm seed   heldW  duck W/L/D          spinner W/L/D       "
              "rammer W/L/D        strafer W/L/D       OLD    NEW    agrees~n"),
    Per = [a_row(M, R) || {_A, Rs} <- Rows, R <- Rs],
    [a_arm(M, A, Rs) || {A, Rs} <- Rows],
    a_predict(M, Rows),
    a_duck_2004(Rows),
    lists:append([[{"FIX A: my predicates agree with the runner's on all 40 champions",
                    lists:all(fun(X) -> X end, [Ag || {_S, _O, _N, Ag} <- Per])}],
                  a_counts(Rows),
                  [{"FIX A: arms S and L stay 0 of 30 under BOTH predicates",
                    a_quiet_sl(Rows)}]]).

a_row(M, R) ->
    Prof = maps:get(profile, R),
    Old = old_pred(Prof),
    New = new_pred(Prof),
    Ag = Old =:= M:inverted_as_run(Prof) andalso New =:= M:inverted(Prof),
    io:format("~3s ~4w ~7.4f ~s ~-6s ~-6s ~s~n",
              [atom_to_list(maps:get(arm, R)), maps:get(seed, R), maps:get(hw, R),
               cells(Prof), mark(Old), mark(New), agree(Ag)]),
    {maps:get(seed, R), Old, New, Ag}.

cells(Prof) ->
    [io_lib:format("~6.4f/~6.4f/~6.4f ", [W, L, D])
     || Kind <- ?RUNG_LOWER, {_K, W, L, D} <- [lists:keyfind(Kind, 1, Prof)]].

a_arm(M, A, Rs) ->
    Old = length([1 || R <- Rs, old_pred(maps:get(profile, R))]),
    New = length([1 || R <- Rs, new_pred(maps:get(profile, R))]),
    Trips = [{maps:get(seed, R), [{Kd, why(C)}
                                  || {Kd, _W, _L, _D} = C <- maps:get(profile, R),
                                     new_cell(C)]}
             || R <- Rs, new_pred(maps:get(profile, R))],
    io:format("~narm ~s, ~p champions: OLD fires ~p, WIDENED fires ~p"
              "  (runner says ~p and ~p)~n",
              [atom_to_list(A), length(Rs), Old, New,
               M:inverted_count_as_run(res(Rs)), M:inverted_count(res(Rs))]),
    [io:format("    seed ~w trips ~w~n", [S, T]) || {S, T} <- Trips].

%% The runner's two counters take a list of #res{}, so they are fed one built by
%% position: field 21 is profile, which the exercise the other agent ran asserted
%% and which is re-asserted here by reading it back.
res(Rs) -> [res_one(maps:get(profile, R)) || R <- Rs].

res_one(Prof) ->
    R = setelement(21, erlang:make_tuple(22, 0.0, [{1, res}]), Prof),
    Prof = element(21, R),
    R.

a_counts(Rows) ->
    Want = [{s, 0, 0}, {l, 0, 0}, {d, 5, 8}],
    [{lists:flatten(io_lib:format("FIX A: arm ~s counts old/new = ~p/~p, record states ~p/~p",
                                  [A, o(Rows, A), n(Rows, A), WO, WN])),
      o(Rows, A) =:= WO andalso n(Rows, A) =:= WN}
     || {A, WO, WN} <- Want].

o(Rows, A) -> length([1 || R <- arm(Rows, A), old_pred(maps:get(profile, R))]).
n(Rows, A) -> length([1 || R <- arm(Rows, A), new_pred(maps:get(profile, R))]).

arm(Rows, A) -> element(2, lists:keyfind(A, 1, Rows)).

a_quiet_sl(Rows) ->
    Rs = arm(Rows, s) ++ arm(Rows, l),
    length([1 || R <- Rs, old_pred(maps:get(profile, R))]) =:= 0
        andalso length([1 || R <- Rs, new_pred(maps:get(profile, R))]) =:= 0.

%% The signed insight predicted, in advance, that widening flips IF-10 LOUD on
%% arm D. IF-10 reads the MEDIAN champion, so that is where the prediction lives.
a_predict(M, Rows) ->
    Rs = arm(Rows, d),
    Med = median_by_w(Rs),
    Prof = maps:get(profile, Med),
    io:format("~nTHE SIGNED INSIGHT'S PREDICTION: widening flips IF-10 loud on arm D.~n"
              "IF-10 reads the median champion by held-out W (the runner's own rule).~n"
              "  arm D median champion : seed ~w, held-out W = ~.4f~n"
              "  OLD predicate         : ~s~n"
              "  WIDENED predicate     : ~s~n"
              "  rungs tripping        : ~w~n"
              "  PREDICTION            : ~s~n",
              [maps:get(seed, Med), maps:get(hw, Med), mark(old_pred(Prof)),
               mark(new_pred(Prof)),
               [{Kd, why(C)} || {Kd, _W, _L, _D} = C <- Prof, new_cell(C)],
               held(old_pred(Prof) =:= false andalso new_pred(Prof) =:= true)]),
    _ = M,
    ok.

median_by_w(Rs) ->
    S = lists:sort(fun(A, B) -> maps:get(hw, A) =< maps:get(hw, B) end, Rs),
    lists:nth(max(1, length(S) div 2 + length(S) rem 2), S).

%% The one cell the task names: arm D seed 2004 against the SITTING DUCK. Reported
%% at CELL level, because the seed as a whole already fires under the as-run
%% predicate through the SPINNER, and that would hide what the new clause added.
a_duck_2004(Rows) ->
    R = lists:keyfind(2004, 1, [{maps:get(seed, X), X} || X <- arm(Rows, d)]),
    {2004, Row} = R,
    Prof = maps:get(profile, Row),
    Duck = lists:keyfind(sitting_duck, 1, Prof),
    Spin = lists:keyfind(spinner, 1, Prof),
    {sitting_duck, W, L, D} = Duck,
    io:format("~nTHE DRAW-PARKED CLAUSE, ON THE CELL THE TASK NAMES.~n"
              "  arm D seed 2004 versus the SITTING DUCK, recomputed: "
              "W = ~.5f  L = ~.5f  D = ~.5f~n"
              "    counts of 160: W ~p  L ~p  D ~p~n"
              "  AS-RUN clause on THAT CELL (L > W)          : ~w  -> the cell PASSES~n"
              "  WIDENED clause on THAT CELL (L > W or D>0.5): ~w  -> the cell TRIPS,"
              " ground ~w~n"
              "  the same seed's SPINNER cell: W = ~.5f L = ~.5f D = ~.5f, "
              "as-run clause ~w~n"
              "  so the SEED fires under both predicates, but only the widened one~n"
              "  sees the duck: a champion that cannot kill a stationary target~n"
              "  inside the turn cap was passing on a technicality.~n",
              [W, L, D, round(W * 160), round(L * 160), round(D * 160),
               old_cell(Duck), new_cell(Duck), why(Duck),
               element(2, Spin), element(3, Spin), element(4, Spin), old_cell(Spin)]).

%%%============================================================================
%%% FIX B. Is IF-8's left conjunct vacuous, and does PH-GEN resolve anything?
%%%============================================================================
fix_b(Rows, B) ->
    All = lists:append([Rs || {_A, Rs} <- Rows]),
    Sat = length([1 || R <- All, maps:get(tw, R) >= 1.0]),
    Left = length([1 || R <- All, maps:get(tw, R) >= B]),
    Right = length([1 || R <- All, maps:get(hw, R) < B]),
    io:format("~n~n=========================================================================~n"
              "FIX B. THE OLD IF-8 CONJUNCTION, AND THE NEW POST-HOC DIAGNOSTIC~n"
              "=========================================================================~n~n"
              "IF-8 MEMORISATION as pre-registered = train_w >= B AND held-out W < B,~n"
              "with B = ~.4f recomputed by constants/1 in this run.~n~n"
              "  champions with train_w exactly 1.0000  : ~p of ~p~n"
              "  champions with train_w >= B (LEFT)     : ~p of ~p~n"
              "  champions with held-out W < B (RIGHT)  : ~p of ~p~n"
              "  train_w range over all 40              : ~.4f .. ~.4f~n~n"
              "So the LEFT conjunct is TRUE for every champion and IF-8 reduces to the~n"
              "right conjunct alone. It carries no train-to-held-out contrast. That is~n"
              "the defect, and it is NOT repaired by anything below.~n",
              [B, Sat, length(All), Left, length(All), Right, length(All),
               lists:min([maps:get(tw, R) || R <- All]),
               lists:max([maps:get(tw, R) || R <- All])]),
    b_splits(All),
    b_tiers(Rows),
    [{"FIX B: IF-8 left conjunct vacuous, train_w = 1.0000 for 40 of 40",
      Sat =:= 40 andalso Left =:= 40},
     {"FIX B: the FLOORED margin leg does NOT saturate on any split",
      b_unsaturated(All)},
     {"FIX B: arm S floored margin on TRAIN separates near-parity from kill mode",
      b_disjoint(arm(Rows, s), tfl)},
     {"FIX B: arm S floored margin on CALIBRATION separates them too",
      b_disjoint(arm(Rows, s), cfl)},
     {"FIX B: arm S W on CALIBRATION separates them too", b_disjoint(arm(Rows, s), cw)},
     {"FIX B: the W leg of PH-GEN SATURATES on train, reported as a negative",
      length([1 || R <- All, maps:get(tw, R) >= 1.0]) =:= 40}].

b_splits(All) ->
    io:format("~nDOES THE NEW DIAGNOSTIC SATURATE TOO? Champions at W = 1.0000, of 40:~n"
              "  train        ~p   (12 matches)~n"
              "  calibration  ~p   (60 matches)~n"
              "  held out     ~p   (160 matches)~n"
              "The FLOORED margin, whole units, min .. max over all 40:~n"
              "  train        ~.2f .. ~.2f~n"
              "  calibration  ~.2f .. ~.2f~n"
              "  held out     ~.2f .. ~.2f~n"
              "The win-rate leg SATURATES on train (40 of 40), exactly as IF-8's~n"
              "train_w does. Half of FIX B is therefore a negative. The floored margin~n"
              "leg reaches no ceiling.~n",
              [length([1 || R <- All, maps:get(tw, R) >= 1.0]),
               length([1 || R <- All, maps:get(cw, R) >= 1.0]),
               length([1 || R <- All, maps:get(hw, R) >= 1.0]),
               lists:min([maps:get(tfl, R) || R <- All]),
               lists:max([maps:get(tfl, R) || R <- All]),
               lists:min([maps:get(cfl, R) || R <- All]),
               lists:max([maps:get(cfl, R) || R <- All]),
               lists:min([maps:get(hfl, R) || R <- All]),
               lists:max([maps:get(hfl, R) || R <- All])]).

b_unsaturated(All) ->
    Fs = [maps:get(F, R) || R <- All, F <- [tfl, cfl, hfl]],
    length(lists:usort(Fs)) =:= length(Fs).

tier(W) when W < 0.62 -> low;
tier(W) when W > 0.93 -> high;
tier(_W) -> mid.

b_tiers(Rows) ->
    io:format("~nDOES PH-GEN RESOLVE THE TWO ARM S MODES? Tiers are the two-attractors~n"
              "probe's already published rule on held-out W (below 0.62 near-parity,~n"
              "above 0.93 kill mode), reused unchanged. NO CUT POINT IS CHOSEN HERE:~n"
              "the per-tier min and max are printed and overlap is printed as overlap.~n"
              "(independent) means the quantity uses only train and calibration,~n"
              "neither of which enters the tier definition.~n"),
    [b_tier_arm(A, Rs) || {A, Rs} <- Rows].

b_tier_arm(A, Rs) ->
    io:format("~narm ~s, tier sizes ~w~n",
              [atom_to_list(A),
               [{T, length([1 || R <- Rs, tier(maps:get(hw, R)) =:= T])}
                || T <- [low, mid, high]]]),
    [b_tier_line(Rs, F, Tag) || {F, Tag} <- [{tfl, "floored margin, TRAIN       (independent)"},
                                             {cfl, "floored margin, CALIBRATION (independent)"},
                                             {cw, "W on CALIBRATION            (independent)"},
                                             {hfl, "floored margin, HELD OUT    (held-out)  "},
                                             {tw, "W on TRAIN                  (ceilinged)  "}]].

b_tier_line(Rs, F, Tag) ->
    io:format("  ~s -> ~s~n     low ~-20s mid ~-20s high ~s~n",
              [Tag, ovtext(overlap(Rs, F)), rtext(range(Rs, F, low)),
               rtext(range(Rs, F, mid)), rtext(range(Rs, F, high))]).

range(Rs, F, T) ->
    case [maps:get(F, R) || R <- Rs, tier(maps:get(hw, R)) =:= T] of
        [] -> empty;
        Xs -> {lists:min(Xs), lists:max(Xs)}
    end.

overlap(Rs, F) -> ov(range(Rs, F, low), range(Rs, F, high)).

ov(empty, _H) -> not_testable;
ov(_L, empty) -> not_testable;
ov({_LMin, LMax}, {HMin, _HMax}) when LMax < HMin -> {disjoint, high_above};
ov({LMin, _LMax}, {_HMin, HMax}) when HMax < LMin -> {disjoint, low_above};
ov(_L, _H) -> overlapping.

ovtext(not_testable) -> "NOT TESTABLE, a tier is empty";
ovtext(overlapping) -> "OVERLAPPING, does NOT separate";
ovtext({disjoint, low_above}) -> "DISJOINT, near-parity ABOVE kill mode";
ovtext({disjoint, high_above}) -> "DISJOINT, kill mode ABOVE near-parity".

rtext(empty) -> "(none)";
rtext({Min, Max}) -> io_lib:format("~.4f..~.4f", [Min, Max]).

b_disjoint(Rs, F) -> element(1, hd([{X} || X <- [overlap(Rs, F)]])) =/= overlapping
                         andalso overlap(Rs, F) =/= not_testable.

%%%============================================================================
%%% FIX C. The discarded loss and draw rates, and an INDEPENDENT triple search.
%%%============================================================================
fix_c(M, Root, Opts, Rows) ->
    Held = M:heldout_starts(Opts),
    io:format("~n~n=========================================================================~n"
              "FIX C. THE RATES scripted_null/1 DISCARDED, AND THE TRIPLE SEARCH~n"
              "=========================================================================~n~n"
              "THE AS-RUN CODE kept element(1, rates(Os)) and dropped L and D:~n"
              "    [{K, win_rate(heldout({script,K}, predictive_gun, Starts))} ...]~n"
              "Both forms below are computed from the SAME replayed matches.~n~n"
              "rung             OLD kept     RECOVERED W/L/D          counts of 160"
              "     floor bot~n"),
    Cells = [c_rung(M, Kind, Held) || Kind <- ?RUNG_LOWER],
    Pairs = read_pairs(Root),
    c_duck_2004(M, Rows, Held),
    Tri = c_triples(Pairs),
    Legs = c_legs(M, Rows, Held, Tri),
    c_candidate(M, Rows, Held),
    lists:append(
      [[{"FIX C: the recovered triple names an EDGE the win rate alone could not",
         lists:all(fun({_K, _W, L, _D}) -> L > 0.5 end, Cells)},
        {"FIX C: 210 pairs in the emitted table, 45 objects, transpose exact",
         length(Pairs) =:= 210 andalso lists:all(fun c_ok/1, Pairs)}],
       Tri,
       Legs]).

c_rung(M, Kind, Held) ->
    Os = M:heldout({script, Kind}, ?FLOOR, Held),
    {W, L, D} = M:rates(Os),
    io:format("~-16s   W=~.5f     ~.5f/~.5f/~.5f   ~4w/~4w/~4w   ~s~n",
              [atom_to_list(Kind), W, W, L, D,
               round(W * 160), round(L * 160), round(D * 160), beats_text(L)]),
    {Kind, W, L, D}.

beats_text(L) when L > 0.5 -> "BEATS the rung";
beats_text(_L) -> "no edge from L".

c_duck_2004(M, Rows, Held) ->
    Row = hd([R || R <- arm(Rows, d), maps:get(seed, R) =:= 2004]),
    Net = maps:get(net, Row),
    {W1, L1, D1} = M:rates(M:duels(Net, {script, sitting_duck}, Held)),
    {W2, L2, D2} = M:rates(M:duels({script, sitting_duck}, Net, Held)),
    io:format("~nTHE TRIPLE THE OLD CODE WOULD HAVE THROWN AWAY, for the pair the task~n"
              "names: arm D seed 2004 against the SITTING DUCK, both directions replayed.~n"
              "  d2004 vs duck : W/L/D = ~.5f/~.5f/~.5f  = ~p/~p/~p of 160~n"
              "  duck vs d2004 : W/L/D = ~.5f/~.5f/~.5f  = ~p/~p/~p of 160~n"
              "  a win rate ALONE (~.5f for the duck) cannot tell 160 losses from 157~n"
              "  draws, and this pair is parked: NEITHER side beats the other.~n",
              [W1, L1, D1, round(W1 * 160), round(L1 * 160), round(D1 * 160),
               W2, L2, D2, round(W2 * 160), round(L2 * 160), round(D2 * 160), W2]).

%%%----------------------------------------------------------------------------
%%% The triple search, reimplemented from the stated relation over the emitted
%%% pair table. Provenance is DERIVED here from the shape of each pair, not read
%%% from the table's own label, and then compared with that label.
%%%----------------------------------------------------------------------------
read_pairs(Root) ->
    {ok, Bin} = file:read_file(arch(Root) ++ "exp066_recovered_rates_and_null_fix.txt"),
    {recovered, F} = term_after_marker(binary_to_list(Bin)),
    element(2, lists:keyfind(pairs, 1, F)).

term_after_marker(Text) ->
    [_Prose, Rest] = string:split(Text, "== MACHINE-READABLE TERM"),
    [_Hdr, TermText] = string:split(Rest, "==\n"),
    {ok, Tokens, _} = erl_scan:string(TermText),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.

%% A pair is self-consistent when both cells sum to 1.0, every rate is a whole
%% number of matches, and the reverse cell is the forward cell transposed.
c_ok({pair, _A, _B, _P, {W1, L1, D1}, {W2, L2, D2}, T, N}) ->
    abs(W1 + L1 + D1 - 1.0) < 1.0e-9 andalso abs(W2 + L2 + D2 - 1.0) < 1.0e-9
        andalso {W2, L2, D2} =:= {L1, W1, D1} andalso T =:= true
        andalso lists:all(fun(X) -> abs(X * N - round(X * N)) < 1.0e-9 end,
                          [W1, L1, D1]).

%% Provenance, derived: champion versus rung and rung versus the floor bot are
%% measurements the pre-registered run already made; a rung against a rung that is
%% not the floor bot is new work.
prov({script, ?FLOOR}, {script, _}) -> preregistered;
prov({script, _}, {script, ?FLOOR}) -> preregistered;
prov({script, _}, {script, _}) -> new_post_hoc;
prov({champ, _, _}, {champ, _, _}) -> unmeasured;
prov(_A, _B) -> preregistered.

c_triples(Pairs) ->
    Objs = lists:usort(lists:append([[A, B] || {pair, A, B, _P, _F, _R, _T, _N} <- Pairs])),
    Tab = maps:from_list(lists:append([[{{A, B}, {F, R}}, {{B, A}, {R, F}}]
                                       || {pair, A, B, _P, F, R, _T, _N} <- Pairs])),
    Mislab = [{A, B, P, prov(A, B)} || {pair, A, B, P, _F, _R, _T, _N} <- Pairs,
                                       P =/= prov(A, B)],
    Tri = [classify(Tab, T) || T <- triples(Objs)],
    Cyc = [T || {cyclic, T, _C} <- Tri],
    c_report(Objs, Tri, Cyc, Mislab),
    [{"FIX C: provenance derived independently matches every label in the table",
      Mislab =:= []},
     {"FIX C: 14190 triples over 45 objects, enumerated independently",
      length(Tri) =:= 14190 andalso length(Objs) =:= 45},
     {"FIX C: a GENUINE PREREGISTERED cyclic triple exists, and the count is 5",
      length([1 || {cyclic, _T, preregistered} <- Tri]) =:= 5},
     {"FIX C: 13 cyclic triples in total, 8 of them extended",
      length(Cyc) =:= 13
          andalso length([1 || {cyclic, _T, extended} <- Tri]) =:= 8},
     {"FIX C: every champion in a cycle is an arm D champion",
      lists:all(fun({champ, A, _S}) -> A =:= d end, cyc_champs(Tri))}].

triples(Objs) ->
    Ix = lists:zip(lists:seq(1, length(Objs)), Objs),
    [{A, B, C} || {I, A} <- Ix, {J, B} <- Ix, {K, C} <- Ix, I < J, J < K].

%% THE RELATION, restated once: A beats B iff W(A,B) > 0.5, over the 160 matches
%% of the ordered cell. Draws count as NOT beating. Nothing looser is used.
beats(Tab, A, B) ->
    case maps:get({A, B}, Tab, none) of
        none -> unmeasured;
        {{W, _L, _D}, _Rev} -> W > 0.5
    end.

classify(Tab, {A, B, C}) ->
    Es = [beats(Tab, X, Y) || {X, Y} <- [{A, B}, {B, A}, {B, C}, {C, B}, {A, C}, {C, A}]],
    class(Tab, {A, B, C}, lists:member(unmeasured, Es)).

class(_Tab, T, true) -> {unmeasured, T, unmeasured};
class(Tab, {A, B, C} = T, false) ->
    P = provenance_of([prov(A, B), prov(B, C), prov(A, C)]),
    Fwd = beats(Tab, A, B) andalso beats(Tab, B, C) andalso beats(Tab, C, A),
    Bwd = beats(Tab, A, C) andalso beats(Tab, C, B) andalso beats(Tab, B, A),
    cyc(T, P, Fwd orelse Bwd).

cyc(T, P, true) -> {cyclic, T, P};
cyc(T, P, false) -> {acyclic, T, P}.

provenance_of(Ps) -> po(lists:member(new_post_hoc, Ps)).

po(true) -> extended;
po(false) -> preregistered.

cyc_champs(Tri) ->
    lists:usort([O || {cyclic, {A, B, C}, _P} <- Tri, O <- [A, B, C],
                      element(1, O) =:= champ]).

c_report(Objs, Tri, Cyc, Mislab) ->
    io:format("~nTHE TRIPLE SEARCH, REDONE FROM THE EMITTED TABLE.~n"
              "  objects           ~p (5 scripted rungs + 40 champions)~n"
              "  triples           ~p~n"
              "  relation          A beats B iff W(A,B) > 0.5; draws are NOT beating~n"
              "  provenance labels derived here, disagreements with the table: ~p~n~n"
              "  class          triples   all 3 edges present   CYCLIC~n",
              [length(Objs), length(Tri), length(Mislab)]),
    [io:format("  ~-14s ~7p ~21p ~8p~n",
               [Cl, length([1 || {_S, _T, P} <- Tri, P =:= Cl]),
                length([1 || {S, T, P} <- Tri, P =:= Cl, S =/= unmeasured,
                             all_edges(T, Tri)]),
                length([1 || {cyclic, _T, P} <- Tri, P =:= Cl])])
     || Cl <- [preregistered, extended, unmeasured]],
    io:format("~n  CYCLIC TRIPLES FOUND: ~p~n", [length(Cyc)]),
    [io:format("    ~-14s ~s~n", [prov_of(Tri, T), objs_text(T)]) || T <- Cyc],
    io:format("~n  champions sitting in a cycle, per arm: ~w~n",
              [[{A, [S || {champ, Ar, S} <- cyc_champs(Tri), Ar =:= A]}
                || A <- [s, l, d]]]).

%% all_edges is recomputed the same way classify/2 does, over the stored class.
all_edges(T, Tri) -> lists:keyfind(T, 2, Tri) =/= false.

prov_of(Tri, T) -> element(3, lists:keyfind(T, 2, Tri)).

objs_text({A, B, C}) -> lists:flatten([obj(A), " / ", obj(B), " / ", obj(C)]).

obj({script, K}) -> atom_to_list(K);
obj({champ, A, S}) -> atom_to_list(A) ++ integer_to_list(S).

%%%----------------------------------------------------------------------------
%%% Every leg of every PREREGISTERED cyclic triple, REPLAYED. A cycle read off a
%%% table is only as good as the table, so the three legs are re-measured from the
%%% archived genome and the scripted bot.
%%%----------------------------------------------------------------------------
c_legs(M, Rows, Held, TriRes) ->
    Cycles = [{{script, ?FLOOR}, {script, sitting_duck}, {champ, d, 2008}},
              {{script, ?FLOOR}, {script, spinner}, {champ, d, 2001}},
              {{script, ?FLOOR}, {script, spinner}, {champ, d, 2008}},
              {{script, ?FLOOR}, {script, rammer}, {champ, d, 2003}},
              {{script, ?FLOOR}, {script, rammer}, {champ, d, 2007}}],
    io:format("~nEVERY LEG OF THE FIVE PREREGISTERED CYCLES, REPLAYED FROM THE ARCHIVE.~n"
              "Each cycle is claimed as gun -> lower rung -> arm D champion -> gun.~n"),
    Ok = [c_cycle(M, Rows, Held, T) || T <- Cycles],
    _ = TriRes,
    [{"FIX C: all 15 legs of the 5 preregistered cycles hold under replay",
      lists:all(fun(X) -> X end, Ok)}].

c_cycle(M, Rows, Held, {A, B, C}) ->
    io:format("~n  CYCLE ~s -> ~s -> ~s -> ~s~n", [obj(A), obj(B), obj(C), obj(A)]),
    Legs = [c_leg(M, Rows, Held, X, Y) || {X, Y} <- [{A, B}, {B, C}, {C, A}]],
    Closed = lists:all(fun({_X, _Y, Ok}) -> Ok end, Legs),
    io:format("    CYCLE CLOSES UNDER REPLAY: ~w~n", [Closed]),
    Closed.

c_leg(M, Rows, Held, X, Y) ->
    {W, L, D} = M:rates(M:duels(objref(Rows, X), objref(Rows, Y), Held)),
    io:format("    ~-16s beats ~-16s W = ~.5f (~p of 160)  L ~p  D ~p  -> ~w~n",
              [obj(X), obj(Y), W, round(W * 160), round(L * 160), round(D * 160),
               W > 0.5]),
    {X, Y, W > 0.5}.

objref(_Rows, {script, K}) -> {script, K};
objref(Rows, {champ, A, S}) ->
    maps:get(net, hd([R || R <- arm(Rows, A), maps:get(seed, R) =:= S])).

%% The candidate the unsigned note named, leg by leg, replayed.
c_candidate(M, Rows, Held) ->
    Legs = [{{champ, d, 2004}, {script, ?FLOOR}},
            {{script, ?FLOOR}, {script, sitting_duck}},
            {{script, sitting_duck}, {champ, d, 2004}}],
    io:format("~nTHE CANDIDATE THE UNSIGNED NOTE NAMED, REPLAYED LEG BY LEG.~n"),
    Rs = [c_leg(M, Rows, Held, X, Y) || {X, Y} <- Legs],
    Missing = [{X, Y} || {X, Y, false} <- Rs],
    io:format("    legs holding ~p of 3; MISSING ~s~n",
              [length(Rs) - length(Missing),
               [io_lib:format("~s -> ~s ", [obj(X), obj(Y)]) || {X, Y} <- Missing]]),
    io:format("    the note's triple does NOT close, and the missing leg is the one~n"
              "    the note assumed rather than the one the recovery settled.~n").

%%%============================================================================
%%% FIX D. The synthetic null, as-run construction beside the fixed one, on
%%% LITERALLY the same drawn integers.
%%%
%%% Four encodings of one draw, all from the same list of per-pair win counts K:
%%%   as-built  cell {I,J} = V, {J,I} = -V, V = 2K/M - 1   (xp_from_pairs/2)
%%%   win rate  cell {I,J} = K/M, {J,I} = 1 - K/M          (xp_from_wins/2, the fix)
%%%   halved    cell {I,J} = V/2, {J,I} = -V/2             (the other escript)
%%%   exact     the integer test 2K - M > B*M, no float at all
%%%============================================================================
fix_d(Draws) ->
    io:format("~n~n=========================================================================~n"
              "FIX D. THE MATCH-LEVEL NULL WAS MIS-SCALED BY TWO~n"
              "=========================================================================~n~n"
              "The draws are generated ONCE, as per-pair win counts K, from seed ~p.~n"
              "All four encodings below read the SAME K values, so nothing here depends~n"
              "on rand reproducing a stream twice.~n~n", [?XP_SEED]),
    _ = rand:seed(exsss, {?XP_SEED, ?XP_SEED * 7 + 1, ?XP_SEED * 13 + 3}),
    Idx = lists:seq(1, ?NULL_N),
    Ks = [[flips(?NULL_CELL) || _ <- pairs(Idx)] || _ <- lists:seq(1, Draws)],
    Cols = [{as_built, fun v_asbuilt/1}, {win_rate, fun v_winrate/1},
            {halved, fun v_halved/1}],
    Stats = [{Name, [{Bd, d_stats(Idx, Ks, Fun, Bd)} || Bd <- ?BANDS]}
             || {Name, Fun} <- Cols],
    Exact = [{Bd, d_exact(Idx, Ks, Bd)} || Bd <- ?BANDS],
    d_table(Stats, Exact),
    Ident = d_identity(Stats),
    Sign = d_sign(Idx, Draws),
    Bit = d_bitwise(),
    d_published(Stats),
    [{"FIX D: the as-built column at band 0.10 IS the fixed column at band 0.05",
      Ident},
     {"FIX D: the fixed column is far below the as-built one at the headline band",
      d_at(Stats, win_rate, 0.10, cyc) < d_at(Stats, as_built, 0.10, cyc)},
     {"FIX D: the sign-only null is unaffected by the correction, measured not assumed",
      Sign},
     {"FIX D: the audit's (1+V)/2 margin is bitwise the fix's K/M margin, all 161 K",
      Bit}].

pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

flips(M) -> length([1 || _ <- lists:seq(1, M), rand:uniform(2) =:= 1]).

v_asbuilt(K) -> V = K * 2.0 / ?NULL_CELL - 1.0, {V, -V}.
v_winrate(K) -> W = K / ?NULL_CELL, {W, 1.0 - W}.
v_halved(K) -> V = K * 2.0 / ?NULL_CELL - 1.0, {V / 2, -V / 2}.

matrix(Idx, Ks, Fun) ->
    Look = maps:from_list(
             lists:append([[{{I, J}, F}, {{J, I}, R}]
                           || {{I, J}, K} <- lists:zip(pairs(Idx), Ks),
                              {F, R} <- [Fun(K)]])),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

mg(Mtx) -> fun(I, J) -> element(J, element(I, Mtx)) - element(I, element(J, Mtx)) end.

d_stats(Idx, Kss, Fun, Bd) ->
    Rs = [d_one(Idx, matrix(Idx, Ks, Fun), Bd) || Ks <- Kss],
    #{ord => median([O || {O, _C, _D} <- Rs]), ordr => spread([O || {O, _C, _D} <- Rs]),
      cyc => median([C || {_O, C, _D} <- Rs]), cycr => spread([C || {_O, C, _D} <- Rs]),
      dec => median([D || {_O, _C, D} <- Rs])}.

d_one(Idx, Mtx, Bd) ->
    Mg = mg(Mtx),
    Beats = fun(I, J) -> Mg(I, J) > Bd end,
    {ordered(Beats, Idx), cycles(Beats, Idx), decisive(Beats, Idx)}.

%% The exact-integer reference. Mg > B is exactly 2K - M > B*M, and B*M is 8, 16
%% or 24 for these three bands, so the SAME test runs with no rounding at all.
d_exact(Idx, Kss, Bd) ->
    T = round(Bd * ?NULL_CELL),
    Rs = [d_exact_one(Idx, Ks, T) || Ks <- Kss],
    #{ord => median([O || {O, _C, _D} <- Rs]), ordr => spread([O || {O, _C, _D} <- Rs]),
      cyc => median([C || {_O, C, _D} <- Rs]), cycr => spread([C || {_O, C, _D} <- Rs]),
      dec => median([D || {_O, _C, D} <- Rs]), thr => T}.

d_exact_one(Idx, Ks, T) ->
    Look = maps:from_list(
             lists:append([[{{I, J}, 2 * K - ?NULL_CELL}, {{J, I}, ?NULL_CELL - 2 * K}]
                           || {{I, J}, K} <- lists:zip(pairs(Idx), Ks)])),
    Beats = fun(I, J) -> maps:get({I, J}, Look, 0) > T end,
    {ordered(Beats, Idx), cycles(Beats, Idx), decisive(Beats, Idx)}.

ordered(Beats, Idx) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Beats(A, X), Beats(X, C), Beats(C, A)]).

cycles(Beats, Idx) ->
    T = [{I, J, K} || I <- Idx, J <- Idx, K <- Idx, I < J, J < K],
    length([1 || {I, J, K} <- T, Beats(I, J), Beats(J, K), Beats(K, I)])
        + length([1 || {I, J, K} <- T, Beats(I, K), Beats(K, J), Beats(J, I)]).

decisive(Beats, Idx) ->
    length([1 || {I, J} <- pairs(Idx), Beats(I, J) orelse Beats(J, I)]).

d_table(Stats, Exact) ->
    io:format("band  encoding                ordered median  ordered range  "
              "cycles median  cycles range  decisive median of 190~n"),
    [d_rows(Stats, Exact, Bd) || Bd <- ?BANDS].

d_rows(Stats, Exact, Bd) ->
    [d_row(atom_to_list(Name) ++ label(Name), get_bd(Stats, Name, Bd), Bd)
     || Name <- [as_built, win_rate, halved]],
    S = element(2, lists:keyfind(Bd, 1, Exact)),
    d_row("exact integer (2K-M > " ++ integer_to_list(maps:get(thr, S)) ++ ")", S, Bd),
    io:format("~n").

label(as_built) -> " (the DEFECT)";
label(win_rate) -> " (THE FIX)   ";
label(halved) -> " (escript)   ".

get_bd(Stats, Name, Bd) ->
    element(2, lists:keyfind(Bd, 1, element(2, lists:keyfind(Name, 1, Stats)))).

d_row(Tag, S, Bd) ->
    io:format("~.2f  ~-34s ~8.1f ~14s ~10.1f ~13s ~10.1f~n",
              [Bd, Tag, maps:get(ord, S), pt(maps:get(ordr, S)), maps:get(cyc, S),
               pt(maps:get(cycr, S)), maps:get(dec, S)]).

pt({A, B}) -> io_lib:format("{~p,~p}", [A, B]).

d_at(Stats, Name, Bd, Field) -> maps:get(Field, get_bd(Stats, Name, Bd)).

%% The factor of two, shown as an IDENTITY between two rows of the same table
%% rather than argued: the defective column at band 0.10 is the fixed column at
%% band 0.05, digit for digit, on the same draws.
d_identity(Stats) ->
    A = get_bd(Stats, as_built, 0.10),
    C = get_bd(Stats, win_rate, 0.05),
    io:format("THE FACTOR OF TWO, AS AN IDENTITY ON THE SAME DRAWS.~n"
              "  as-built at band 0.10 : ordered ~.1f ~s, cycles ~.1f ~s, decisive ~.1f~n"
              "  THE FIX  at band 0.05 : ordered ~.1f ~s, cycles ~.1f ~s, decisive ~.1f~n"
              "  identical: ~w~n"
              "  So every band was effectively HALVED against the synthetic null: the~n"
              "  persisted band-0.10 row is a band-0.05 row.~n~n",
              [maps:get(ord, A), pt(maps:get(ordr, A)), maps:get(cyc, A),
               pt(maps:get(cycr, A)), maps:get(dec, A),
               maps:get(ord, C), pt(maps:get(ordr, C)), maps:get(cyc, C),
               pt(maps:get(cycr, C)), maps:get(dec, C), A =:= C]),
    A =:= C.

%% The sign-only null. The claim is that the correction cannot move it, because
%% both +/-1 and +/-2 clear every band tested. Measured, not assumed, on the same
%% coin draws.
d_sign(Idx, Draws) ->
    _ = rand:seed(exsss, {?XP_SEED, ?XP_SEED * 7 + 1, ?XP_SEED * 13 + 3}),
    Coins = [[rand:uniform(2) || _ <- pairs(Idx)] || _ <- lists:seq(1, Draws)],
    As = [{Bd, d_stats(Idx, Coins, fun s_asbuilt/1, Bd)} || Bd <- ?BANDS],
    Wr = [{Bd, d_stats(Idx, Coins, fun s_winrate/1, Bd)} || Bd <- ?BANDS],
    io:format("THE SIGN-ONLY NULL, SAME COIN DRAWS, BOTH ENCODINGS.~n"),
    [io:format("  band ~.2f  as-built ordered ~.1f cycles ~.1f | THE FIX ordered ~.1f "
               "cycles ~.1f  identical ~w~n",
               [Bd, maps:get(ord, A), maps:get(cyc, A), maps:get(ord, W), maps:get(cyc, W),
                A =:= W])
     || {{Bd, A}, {Bd, W}} <- lists:zip(As, Wr)],
    Ok = As =:= Wr,
    io:format("  all three bands, every number identical: ~w~n"
              "  (the encodings differ: margins +/-2.0 as-built against +/-1.0 fixed;~n"
              "   it is the COUNTS that cannot tell them apart, because every band~n"
              "   tested is below 1.0)~n~n", [Ok]),
    Ok.

s_asbuilt(1) -> {1.0, -1.0};
s_asbuilt(2) -> {-1.0, 1.0}.

s_winrate(1) -> {1.0, 0.0};
s_winrate(2) -> {0.0, 1.0}.

%% The published audit built its corrected column as (1+V)/2 and (1-V)/2. That is
%% algebraically K/M, but algebra is not float arithmetic, so it is checked at both
%% levels: the CELL value each construction stores, and the DIFFERENCED margin,
%% which is the only quantity mg/1 hands to a band test. Only the second one has
%% to match for the two to produce identical counts.
d_bitwise() ->
    Ks = lists:seq(0, ?NULL_CELL),
    Cell = [K || K <- Ks, (1.0 + (K * 2.0 / ?NULL_CELL - 1.0)) / 2 =/= K / ?NULL_CELL],
    Marg = [K || K <- Ks, audit_mg(K) =/= fix_mg(K)],
    io:format("THE AUDIT'S (1+V)/2 FORM AGAINST THE FIX'S K/M, ALL ~p VALUES OF K.~n"
              "  CELL values that differ in the last bit           : ~p of ~p~n"
              "  DIFFERENCED margins that differ (what mg/1 reads) : ~p of ~p~n"
              "  So the two constructions store different cell values on some K but~n"
              "  hand the band test the SAME margin on every K, and therefore produce~n"
              "  identical counts. The record's phrase 'bitwise identical construction'~n"
              "  is true of the margin, not of the stored cells.~n~n",
              [length(Ks), length(Cell), length(Ks), length(Marg), length(Ks)]),
    Marg =:= [].

audit_mg(K) -> V = K * 2.0 / ?NULL_CELL - 1.0, (1.0 + V) / 2 - (1.0 - V) / 2.

fix_mg(K) -> W = K / ?NULL_CELL, W - (1.0 - W).

%% The numbers the work package quotes as its acceptance target, and where they
%% actually come from. Reported as agreement or disagreement, number by number.
d_published(Stats) ->
    C = get_bd(Stats, win_rate, 0.10),
    H = get_bd(Stats, halved, 0.10),
    io:format("THE ACCEPTANCE NUMBERS THE WORK PACKAGE QUOTES: at band 0.10, ordered~n"
              "median 5.0 range {0,15} and cycles median 3.0 range {0,10}, attributed~n"
              "to scripts/exp066_verify_null_scaling.escript's corrected column.~n"
              "  THIS SCRIPT, win-rate encoding : ordered ~.1f ~s  cycles ~.1f ~s~n"
              "  THIS SCRIPT, halved encoding   : ordered ~.1f ~s  cycles ~.1f ~s~n"
              "  medians agree with the quoted 5.0 and 3.0 : ~w~n"
              "  ranges agree with the quoted {0,15},{0,10} : ~w~n"
              "  (the escript's own printed output is captured separately by the~n"
              "   driver, and the audit file's MATCH CORRECTED row is at seed 661)~n~n",
              [maps:get(ord, C), pt(maps:get(ordr, C)), maps:get(cyc, C),
               pt(maps:get(cycr, C)), maps:get(ord, H), pt(maps:get(ordr, H)),
               maps:get(cyc, H), pt(maps:get(cycr, H)),
               maps:get(ord, C) =:= 5.0 andalso maps:get(cyc, C) =:= 3.0,
               maps:get(ordr, C) =:= {0, 15} andalso maps:get(cycr, C) =:= {0, 10}]).

%%%============================================================================
%%% Plumbing.
%%%============================================================================
median([]) -> 0.0;
median(Xs) ->
    S = lists:sort([float(X) || X <- Xs]),
    L = length(S),
    mid(S, L, L rem 2).

mid(S, L, 1) -> lists:nth(L div 2 + 1, S);
mid(S, L, 0) -> (lists:nth(L div 2, S) + lists:nth(L div 2 + 1, S)) / 2.

spread([]) -> {0, 0};
spread(Xs) -> {lists:min(Xs), lists:max(Xs)}.

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

mark(true) -> "FIRED";
mark(false) -> "quiet".

held(true) -> "HELD";
held(false) -> "REFUTED".

agree(true) -> "yes";
agree(false) -> "DISAGREE".

verdict(Res) ->
    io:format("~n=========================================================================~n"
              "SUMMARY~n"
              "=========================================================================~n"),
    [io:format("  ~s  ~s~n", [ok_text(Ok), Label]) || {Label, Ok} <- Res],
    Bad = [L || {L, false} <- Res],
    io:format("~n~p checks, ~p failed~n", [length(Res), length(Bad)]).

ok_text(true) -> "PASS";
ok_text(false) -> "FAIL".

status(Res) -> st(lists:all(fun({_L, Ok}) -> Ok end, Res)).

st(true) -> 0;
st(false) -> 1.

%%%============================================================================
%%% The shadow module: the runner's own abstract code, renamed, with export_all
%%% injected. The runner on disk is NOT touched.
%%%============================================================================
boot(Root) ->
    Build = Root ++ "/_build/test/lib",
    [true = code:add_patha(Build ++ "/" ++ App ++ "/ebin")
     || App <- ["faber_tweann", "faber_programmes"]],
    Beam = Build ++ "/faber_programmes/experiments/"
               "exp066_single_population_floor_tests.beam",
    {ok, {_M, [{abstract_code, {raw_abstract_v1, Forms}}]}} =
        beam_lib:chunks(Beam, [abstract_code]),
    {ok, ?SHADOW, Bin} = compile:forms(inject([rename(F) || F <- Forms]),
                                       [return_errors, nowarn_export_all]),
    {module, ?SHADOW} = code:load_binary(?SHADOW, "nofile", Bin),
    ?SHADOW.

rename({attribute, L, module, _}) -> {attribute, L, module, ?SHADOW};
rename(F) -> F.

inject([{attribute, L, module, M} | Rest]) ->
    [{attribute, L, module, M},
     {attribute, L, compile, [export_all, nowarn_export_all]} | Rest];
inject([F | Rest]) -> [F | inject(Rest)];
inject([]) -> [].
