%%%-------------------------------------------------------------------
%%% @doc EXP-052 — the price of ignoring the objective: what does novelty search
%%% trade away where goal-chasing already wins?
%%%
%%% Pre-registration (design-gated): experiments/exp052_novelty_efficiency_tradeoff.md
%%% Run: erl -noshell -pa <ebins> -eval 'exp052_novelty_efficiency_tradeoff_tests:run(), init:stop().'
%%%
%%% Non-deceptive maze E (D's wall+gap, goal at {9,9}); objective solves it fast, a
%%% constant policy cannot (needs a turn), random init does not floor it. Three searches
%%% at matched operator+budget: objective-EA, novelty-EA[final-pos], random. Two metrics
%%% per run from one eval stream: EFG (1-based eval-order index of first solve, censored
%%% = +inf) and behavioural coverage (distinct VISITED cells, a curve at 2k/6k/15k).
%%% All-runs median with bootstrap CIs; final-cell coverage kept only as a manipulation
%%% check. Accessors only; self-contained.
%%% @end
%%%-------------------------------------------------------------------
-module(exp052_novelty_efficiency_tradeoff_tests).

-export([run/0, run/1, validate/0]).

-define(W, 11).
-define(H, 11).
-define(T, 60).
-define(HID, 10).
-define(MU, 20).
-define(LAMBDA, 20).
-define(SIGMA, 0.15).
-define(K_NOV, 15).
-define(BOOT, 2000).
-define(FEED, "exp052_feed.txt").

%% Non-deceptive maze E: same wall+gap as the 051 deceptive maze D, goal at {9,9}.
maze(e) -> #{blocked => wall_gap([9, 10]), s => {1, 1}, g => {9, 9}}.

wall_gap(GapXs) ->
    maps:from_list([{{X, 5}, true} || X <- lists:seq(0, ?W - 1), not lists:member(X, GapXs)]).

%%%============================================================================
%%% Entry
%%%============================================================================
run() -> run(#{n => 120, e => 15000}).
validate() -> run(#{n => 6, e => 3000}).

run(#{n := N, e := E}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    Checks = checkpoints(E),
    emit(Fd, "== EXP-052 efficiency tradeoff: what novelty trades where objective wins ==~n", []),
    emit(Fd, "config: maze=E(non-deceptive) grid=~px~p T=~p net=[6,~p,4] mu=~p lambda=~p "
             "sigma=~.2f E=~p n=~p checkpoints=~p~n",
         [?W, ?H, ?T, ?HID, ?MU, ?LAMBDA, ?SIGMA, E, N, Checks]),
    Obj = run_many(fun() -> search(maze(e), objective, E, Checks) end, N),
    Nov = run_many(fun() -> search(maze(e), novelty_fp, E, Checks) end, N),
    Rnd = run_many(fun() -> search(maze(e), random, E, Checks) end, N),
    report_efg(Fd, E, "objective-EA", Obj),
    report_efg(Fd, E, "novelty-EA[final-pos]", Nov),
    report_efg(Fd, E, "random", Rnd),
    report_cov(Fd, Checks, "objective-EA", Obj),
    report_cov(Fd, Checks, "novelty-EA[final-pos]", Nov),
    report_cov(Fd, Checks, "random", Rnd),
    verdict(Fd, E, Checks, Obj, Nov, Rnd),
    file:close(Fd),
    ok.

run_many(Fun, N) -> [Fun() || _ <- lists:seq(1, N)].

%% Coverage snapshot budgets: two intermediate + the full budget.
checkpoints(E) -> lists:usort([min(2000, E), min(6000, E), E]).

%%%============================================================================
%%% A search run -> #{efg => Idx|inf, cov => [{Budget,Count}], solved => bool}
%%% One eval stream feeds both metrics.
%%%============================================================================
search(Maze, random, E, Checks) ->
    M = lists:foldl(fun(_, Acc) ->
                        {_, A1} = eval_ind(Maze, rand_genome(), Acc),
                        A1
                    end, new_m(Checks), lists:seq(1, E)),
    finalize(M);
search(Maze, Mode, E, Checks) ->
    {Pop, M0} = eval_init(Maze, new_m(Checks)),
    M = ea_loop(Maze, Mode, E - ?MU, Pop, [], M0),
    finalize(M).

eval_init(Maze, M0) ->
    lists:foldl(fun(_, {Pop, M}) ->
                    {Ind, M1} = eval_ind(Maze, rand_genome(), M),
                    {[Ind | Pop], M1}
                end, {[], M0}, lists:seq(1, ?MU)).

ea_loop(_Maze, _Mode, Budget, _Pop, _Arch, M) when Budget =< 0 -> M;
ea_loop(Maze, Mode, Budget, Pop, Arch, M) ->
    {Off, M1} = lists:foldl(fun(_, {Acc, Mi}) ->
                                {Ind, Mi1} = eval_ind(Maze, mutate(g_of(pick(Pop))), Mi),
                                {[Ind | Acc], Mi1}
                            end, {[], M}, lists:seq(1, ?LAMBDA)),
    NewPop = top_mu(score_all(Mode, Pop ++ Off, Arch)),
    Arch1 = archive_update(Mode, Arch, Off),
    ea_loop(Maze, Mode, Budget - ?LAMBDA, NewPop, Arch1, M1).

%% Evaluate one genome: roll it out, fold its (visited, solved) into the metrics
%% accumulator, and return the individual (for selection) + updated accumulator.
eval_ind(Maze, G, M) ->
    {Final, Visited, Solved} = rollout(mk_net(G), Maze),
    Ind = #{g => G, fp => Final, close => closeness(Final, maps:get(g, Maze)), solved => Solved},
    {Ind, bump(M, Visited, Solved)}.

g_of(I) -> maps:get(g, I).
pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).

score_all(objective, Inds, _Arch) -> [{maps:get(close, I), I} || I <- Inds];
score_all(novelty_fp, Inds, Arch) ->
    All = [maps:get(fp, I) || I <- Inds] ++ Arch,
    [{novelty(maps:get(fp, I), All), I} || I <- Inds].

top_mu(Scored) ->
    [I || {_S, I} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].

archive_update(objective, Arch, _Off) -> Arch;
archive_update(novelty_fp, Arch, Off) ->
    Fps = [maps:get(fp, I) || I <- Off],
    Scored = [{novelty(F, Arch ++ Fps), F} || F <- Fps],
    {_, MostNovel} = lists:last(lists:keysort(1, Scored)),
    [MostNovel | Arch].

%% Final-position k-NN novelty (drop one self-distance, keep duplicate zeros).
novelty(_F, []) -> 0.0;
novelty(F, Others) ->
    Ds = drop_one_zero(lists:sort([manhattan(F, O) || O <- Others])),
    K = min(?K_NOV, length(Ds)),
    mean(lists:sublist(Ds, max(1, K))).

drop_one_zero([0 | T]) -> T;
drop_one_zero(Ds) -> Ds.

%%%============================================================================
%%% Metrics accumulator: {Idx, FirstSolve|inf, VisitedSet, Checks, Snaps}
%%%============================================================================
new_m(Checks) -> {0, inf, ordsets:new(), Checks, []}.

bump({Idx, First, Vis, Checks, Snaps}, Visited, Solved) ->
    Idx1 = Idx + 1,
    First1 = first_solve(First, Solved, Idx1),
    Vis1 = ordsets:union(Vis, Visited),
    Snaps1 = maybe_snap(Idx1, Vis1, Checks, Snaps),
    {Idx1, First1, Vis1, Checks, Snaps1}.

first_solve(inf, true, Idx) -> Idx;
first_solve(First, _Solved, _Idx) -> First.

maybe_snap(Idx, Vis, Checks, Snaps) ->
    maybe_snap_v(lists:member(Idx, Checks), Idx, Vis, Snaps).
maybe_snap_v(true, Idx, Vis, Snaps) -> [{Idx, ordsets:size(Vis)} | Snaps];
maybe_snap_v(false, _Idx, _Vis, Snaps) -> Snaps.

finalize({_Idx, First, _Vis, _Checks, Snaps}) ->
    #{efg => First, cov => lists:reverse(Snaps), solved => First =/= inf}.

%%%============================================================================
%%% Reporting: EFG (all-runs median with censored=+inf) + coverage curve
%%%============================================================================
report_efg(Fd, E, Label, Runs) ->
    Efgs = [maps:get(efg, R) || R <- Runs],
    N = length(Efgs),
    Solved = length([1 || X <- Efgs, X =/= inf]),
    Cens = N - Solved,
    Vals = [efg_num(X, E) || X <- Efgs],           %% censored -> 10*E sentinel
    {Lo, Hi} = boot_ci(Vals, fun median/1),
    Med = median(Vals),
    SolvedOnly = [X || X <- Efgs, X =/= inf],
    emit(Fd, "EFG ~s: solved ~p/~p (censored ~p); all-runs median EFG=~s 95%CI[~s,~s]; "
             "solved-only median=~s~n",
         [Label, Solved, N, Cens, efg_show(Med, E), efg_show(Lo, E), efg_show(Hi, E),
          efg_show(median(SolvedOnly), E)]).

report_cov(Fd, Checks, Label, Runs) ->
    Parts = [cov_at(B, Runs) || B <- Checks],
    emit(Fd, "COV ~s: ~s~n", [Label, string:join(Parts, "  ")]).

cov_at(B, Runs) ->
    Vals = [cov_lookup(B, maps:get(cov, R)) || R <- Runs],
    {Lo, Hi} = boot_ci(Vals, fun median/1),
    lists:flatten(io_lib:format("@~p=~.1f[~.1f,~.1f]", [B, median(Vals), Lo, Hi])).

cov_lookup(B, Cov) ->
    case lists:keyfind(B, 1, Cov) of
        {B, C} -> C;
        false -> 0
    end.

%%%============================================================================
%%% Verdict (all outcomes reachable; see the pre-registration decision rule)
%%%============================================================================
%% Two axes adjudicated INDEPENDENTLY (CLAIM-gate fix): coverage has its own floor
%% (nov > rnd) and never depends on the speed gate. Speed uses a TWO-SAMPLE test
%% (bootstrap CI on the median DIFFERENCE), not disjoint one-sample CIs.
verdict(Fd, E, _Checks, Obj, Nov, Rnd) ->
    Ef = fun(Runs) -> [efg_num(maps:get(efg, R), E) || R <- Runs] end,
    Cv = fun(Runs) -> [cov_lookup(E, maps:get(cov, R)) || R <- Runs] end,
    OeMed = median(Ef(Obj)), NeMed = median(Ef(Nov)), ReMed = median(Ef(Rnd)),
    ObjSolve = length([1 || R <- Obj, maps:get(solved, R)]) / length(Obj),

    %% Speed axis (two-sample median-difference CIs).
    {FLo, FHi} = boot_diff_ci(Ef(Obj), Ef(Rnd)),   %% obj - rnd ; < 0 => objective faster
    {SLo, SHi} = boot_diff_ci(Ef(Obj), Ef(Nov)),   %% obj - nov ; < 0 => objective faster (tax)
    Floor = FHi < 0.0,
    Margin = 0.25 * OeMed,
    Tax = SHi < 0.0,
    Reversal = SLo > 0.0,
    Equiv = (SLo > -Margin) andalso (SHi < Margin),
    SpeedValid = ObjSolve > 0.9 andalso Floor,

    %% Coverage axis (independent; its own floor: nov > rnd).
    {NcLo, _} = boot_ci(Cv(Nov), fun median/1),
    {_, OcHi} = boot_ci(Cv(Obj), fun median/1),
    {_, RcHi} = boot_ci(Cv(Rnd), fun median/1),
    CovGain = (NcLo > OcHi) andalso (NcLo > RcHi),

    emit(Fd, "~n-- Verdict (maze E, budget ~p, coverage at E; two-sample tests) --~n", [E]),
    emit(Fd, "objective solves E (rate>0.9): ~p (~.3f); EFG medians obj=~.1f nov=~.1f rnd=~.1f~n",
         [ObjSolve > 0.9, ObjSolve, OeMed, NeMed, ReMed]),
    emit(Fd, "floor gate median(obj-rnd)<0 (CI[~.1f,~.1f]): ~p~n", [FLo, FHi, Floor]),
    emit(Fd, "speed median(obj-nov) (CI[~.1f,~.1f]) tax=~p reversal=~p equiv(+/-~.1f)=~p~n",
         [SLo, SHi, Tax, Reversal, Margin, Equiv]),
    emit(Fd, "coverage nov>obj & nov>rnd (novLB=~.1f > objUB=~.1f, rndUB=~.1f): ~p~n",
         [NcLo, OcHi, RcHi, CovGain]),
    emit(Fd, "SPEED=~s~n", [speed_result(SpeedValid, Tax, Reversal, Equiv)]),
    emit(Fd, "COVERAGE=~s~n", [cov_result(CovGain)]).

speed_result(false, _, _, _) ->
    "INVALID (objective not reliably faster than random -> maze refloored or regression)";
speed_result(true, true, _, _) ->
    "TAX: objective reaches the goal in fewer evaluations than novelty (median diff CI < 0)";
speed_result(true, false, true, _) ->
    "REVERSAL: novelty reaches the goal in FEWER evaluations than objective (surprise)";
speed_result(true, false, false, true) ->
    "NO TAX: novelty is equivalent to objective within +/-25% (no efficiency penalty here)";
speed_result(true, false, false, false) ->
    "INCONCLUSIVE (unsigned): median-difference CI spans the equivalence margin -> underpowered".

cov_result(true) ->
    "NOVELTY WINS: distinct-visited-cell coverage exceeds objective AND random (disjoint CIs)";
cov_result(false) ->
    "NO GAIN: novelty coverage not separable from objective/random".

%%%============================================================================
%%% Rollout (from 051): argmax of 4 outputs; illegal moves are no-ops.
%%% Returns {FinalCell, VisitedOrdset, ReachedG}.
%%%============================================================================
rollout(Net, Maze) ->
    step(Net, Maze, maps:get(s, Maze), ?T, ordsets:from_list([maps:get(s, Maze)]),
         maps:get(s, Maze) =:= maps:get(g, Maze)).

step(_Net, _Maze, Pos, 0, Vis, Solved) -> {Pos, Vis, Solved};
step(_Net, _Maze, Pos, _T, Vis, true) -> {Pos, Vis, true};
step(Net, Maze, Pos, T, Vis, false) ->
    Next = move(Pos, argmax(network_evaluator:evaluate(Net, sense(Maze, Pos))), Maze),
    step(Net, Maze, Next, T - 1, ordsets:add_element(Next, Vis), Next =:= maps:get(g, Maze)).

sense(Maze, {X, Y} = P) ->
    [X / (?W - 1), Y / (?H - 1),
     legal_bit(Maze, move(P, 0, Maze)), legal_bit(Maze, move(P, 1, Maze)),
     legal_bit(Maze, move(P, 2, Maze)), legal_bit(Maze, move(P, 3, Maze))].

move({X, Y}, Dir, Maze) -> legal_or_stay(Maze, {X, Y}, delta({X, Y}, Dir)).
delta({X, Y}, 0) -> {X, Y + 1};
delta({X, Y}, 1) -> {X + 1, Y};
delta({X, Y}, 2) -> {X, Y - 1};
delta({X, Y}, 3) -> {X - 1, Y}.

legal_or_stay(Maze, From, To) -> legal_pick(legal(Maze, To), From, To).
legal_pick(true, _From, To) -> To;
legal_pick(false, From, _To) -> From.

legal(Maze, {X, Y}) ->
    X >= 0 andalso X < ?W andalso Y >= 0 andalso Y < ?H
        andalso not maps:is_key({X, Y}, maps:get(blocked, Maze)).

legal_bit(Maze, To) -> legal_bit_v(legal(Maze, To)).
legal_bit_v(true) -> 1.0;
legal_bit_v(false) -> 0.0.

closeness(Final, G) -> 1.0 / (1.0 + manhattan(Final, G)).
manhattan({X1, Y1}, {X2, Y2}) -> abs(X1 - X2) + abs(Y1 - Y2).

argmax([H | T]) -> argmax(T, 1, H, 0).
argmax([], _I, _Best, BestI) -> BestI;
argmax([H | T], I, Best, _BestI) when H > Best -> argmax(T, I + 1, H, I);
argmax([_H | T], I, Best, BestI) -> argmax(T, I + 1, Best, BestI).

%%%============================================================================
%%% Net + genome + numerics + stats
%%%============================================================================
net_params() -> ?HID * 6 + ?HID + 4 * ?HID + 4.
mk_net(G) ->
    network_evaluator:set_weights(
      network_evaluator:create_feedforward(6, [?HID], 4, tanh, tanh), G).
rand_genome() -> [rand:normal() || _ <- lists:seq(1, net_params())].
mutate(G) -> [X + ?SIGMA * rand:normal() || X <- G].

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

%% Censored EFG -> a sentinel above any finite EFG, so ordering/median are well-defined.
efg_num(inf, E) -> 10 * E;
efg_num(X, _E) -> X.

efg_show(V, E) when V >= 10 * E -> ">E";
efg_show(V, _E) when is_float(V) -> lists:flatten(io_lib:format("~.1f", [V]));
efg_show(V, _E) -> lists:flatten(io_lib:format("~p", [V])).

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L),
    N = length(S),
    median_pick(N rem 2, S, N).
median_pick(1, S, N) -> lists:nth(N div 2 + 1, S) * 1.0;
median_pick(0, S, N) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0.

%% Bootstrap 95% percentile CI of a statistic over runs.
boot_ci([], _Stat) -> {0.0, 0.0};
boot_ci(Vals, Stat) ->
    N = length(Vals),
    Reps = [Stat([lists:nth(rand:uniform(N), Vals) || _ <- lists:seq(1, N)])
            || _ <- lists:seq(1, ?BOOT)],
    Sorted = lists:sort(Reps),
    {pctile(Sorted, 0.025), pctile(Sorted, 0.975)}.

pctile(Sorted, P) ->
    N = length(Sorted),
    I = max(1, min(N, round(P * N))),
    lists:nth(I, Sorted) * 1.0.

%% Two-sample bootstrap 95% CI on the difference of medians (median(As) - median(Bs)).
boot_diff_ci([], _Bs) -> {0.0, 0.0};
boot_diff_ci(_As, []) -> {0.0, 0.0};
boot_diff_ci(As, Bs) ->
    Na = length(As), Nb = length(Bs),
    Reps = [median([lists:nth(rand:uniform(Na), As) || _ <- lists:seq(1, Na)])
            - median([lists:nth(rand:uniform(Nb), Bs) || _ <- lists:seq(1, Nb)])
            || _ <- lists:seq(1, ?BOOT)],
    Sorted = lists:sort(Reps),
    {pctile(Sorted, 0.025), pctile(Sorted, 0.975)}.

emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
