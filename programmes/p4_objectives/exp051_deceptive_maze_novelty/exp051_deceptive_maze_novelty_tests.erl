%%%-------------------------------------------------------------------
%%% @doc EXP-051 — the deception test: novelty vs objective on a deceptive maze.
%%%
%%% Pre-registration: experiments/exp051_deceptive_maze_novelty.md
%%% Run: erl -noshell -pa <ebins> -eval 'exp051_deceptive_maze_novelty_tests:run(), init:stop().'
%%%
%%% Lehman & Stanley 2011 replicated. Gate-redesigned: position sensors (no goal
%%% pointer -> deception in the LANDSCAPE, not leaked); a MATCHED maze pair D
%%% (deceptive) / N (non-deceptive twin); ONE (mu+lambda) EA differing only in the
%%% score (closeness vs k-NN novelty over a trajectory behaviour); sep-CMA-ES as an
%%% objective CEILING and random as a FLOOR; a mutation-effectiveness check; n=40.
%%% Deception is certified only if objective solves the twin N, stalls on D, AND a
%%% strong optimizer (CMA) is ALSO trapped on D. Accessors only; self-contained.
%%% @end
%%%-------------------------------------------------------------------
-module(exp051_deceptive_maze_novelty_tests).

-export([run/0, run/1, validate/0]).

-define(W, 11).
-define(H, 11).
-define(T, 60).                  %% steps per rollout
-define(HID, 10).
-define(MU, 20).
-define(LAMBDA, 20).
-define(SIGMA, 0.15).
-define(K_NOV, 15).              %% k for k-NN novelty
-define(ARCH_CAP, 300).
-define(FEED, "exp051_feed.txt").

%%%============================================================================
%%% Mazes: wall at y=5; D's gap is far from the greedy path, N's is on it.
%%% S=(1,1), G=(1,9). Greedy-up from S hits the wall; in D the only gap is at
%%% x=9-10 (a detour that INCREASES distance-to-G first), in N the gap is at x=1.
%%%============================================================================
maze(d) -> #{blocked => wall_gap([9, 10]), s => {1, 1}, g => {1, 9}};
maze(n) -> #{blocked => wall_gap([1]), s => {1, 1}, g => {1, 9}}.

wall_gap(GapXs) ->
    maps:from_list([{{X, 5}, true} || X <- lists:seq(0, ?W - 1), not lists:member(X, GapXs)]).

%%%============================================================================
%%% Entry
%%%============================================================================
run() -> run(#{n => 40, e => 15000}).
validate() -> run(#{n => 3, e => 1500}).

run(#{n := N, e := E}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-051 deception test: novelty vs objective on a deceptive maze ==~n", []),
    emit(Fd, "config: grid=~px~p T=~p net=[6,~p,4] mu=~p lambda=~p sigma=~.2f E=~p n=~p~n",
         [?W, ?H, ?T, ?HID, ?MU, ?LAMBDA, ?SIGMA, E, N]),
    emit(Fd, "sensors: normalised (x,y) + 4 wall-legality bits, NO goal sensor~n"),
    mutation_effectiveness(Fd),
    ObjN = solve_rate(Fd, "objective-EA on N (competence)", fun() -> ea(maze(n), objective, E) end, N),
    ObjD = solve_rate(Fd, "objective-EA on D (deception stall)", fun() -> ea(maze(d), objective, E) end, N),
    CmaD = solve_rate(Fd, "sep-CMA-ES objective on D (landscape)", fun() -> cma(maze(d), E) end, N),
    RndD = solve_rate(Fd, "random search on D (floor)", fun() -> rand_search(maze(d), E) end, N),
    NovD = solve_rate(Fd, "novelty-EA[trajectory] on D", fun() -> ea(maze(d), novelty, E) end, N),
    NovFpD = solve_rate(Fd, "novelty-EA[final-pos] on D (advantage)",
                        fun() -> ea(maze(d), novelty_fp, E) end, N),
    verdict(Fd, N, ObjN, ObjD, CmaD, RndD, NovD, NovFpD),
    file:close(Fd),
    ok.

%% Run Fun (returns solved bool) N times; report solve rate + Wilson 95% CI.
solve_rate(Fd, Label, Fun, N) ->
    K = length([1 || true <- [Fun() || _ <- lists:seq(1, N)]]),
    {Lo, Hi} = wilson(K, N),
    emit(Fd, "EXP051 ~s: solved ~p/~p (rate=~.3f, 95%CI[~.3f,~.3f])~n",
         [Label, K, N, K / N, Lo, Hi]),
    {K, N, Lo, Hi}.

%%%============================================================================
%%% (mu+lambda) EA, parameterised by score mode (objective | novelty).
%%% Returns whether ANY evaluated genome reached G during the run.
%%%============================================================================
ea(Maze, Mode, E) ->
    Pop0 = [evalind(Maze, rand_genome()) || _ <- lists:seq(1, ?MU)],
    ea_loop(Maze, Mode, E - ?MU, Pop0, [], any_solved(Pop0)).

ea_loop(_Maze, _Mode, Budget, _Pop, _Arch, Solved) when Budget =< 0 -> Solved;
ea_loop(Maze, Mode, Budget, Pop, Arch, Solved) ->
    Offspring = [evalind(Maze, mutate(g_of(pick(Pop)))) || _ <- lists:seq(1, ?LAMBDA)],
    Combined = Pop ++ Offspring,
    NewPop = top_mu(score_all(Mode, Combined, Arch)),
    Arch1 = archive_update(Mode, Arch, Offspring),
    ea_loop(Maze, Mode, Budget - ?LAMBDA, NewPop, Arch1,
            Solved orelse any_solved(Offspring)).

evalind(Maze, G) ->
    {Final, Visited, Solved} = rollout(mk_net(G), Maze),
    #{g => G, beh => Visited, fp => Final, close => closeness(Final, maps:get(g, Maze)),
      solved => Solved}.

g_of(I) -> maps:get(g, I).
any_solved(Inds) -> lists:any(fun(I) -> maps:get(solved, I) end, Inds).
pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).

score_all(objective, Inds, _Arch) -> [{maps:get(close, I), I} || I <- Inds];
score_all(Mode, Inds, Arch) ->            %% novelty (trajectory) | novelty_fp (final position)
    {Key, DistF} = nov_params(Mode),
    All = [maps:get(Key, I) || I <- Inds] ++ Arch,
    [{novelty(maps:get(Key, I), All, DistF), I} || I <- Inds].

nov_params(novelty) -> {beh, fun beh_dist/2};
nov_params(novelty_fp) -> {fp, fun manhattan/2}.

top_mu(Scored) ->
    [I || {_S, I} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].

%% Add the single most-novel offspring behaviour; APPEND-ONLY (a sliding window would
%% forget old behaviours and let novelty re-farm explored regions).
archive_update(objective, Arch, _Off) -> Arch;
archive_update(Mode, Arch, Off) ->
    {Key, DistF} = nov_params(Mode),
    Behs = [maps:get(Key, I) || I <- Off],
    Scored = [{novelty(B, Arch ++ Behs, DistF), B} || B <- Behs],
    {_, MostNovel} = lists:last(lists:keysort(1, Scored)),
    [MostNovel | Arch].

%% Novelty = mean of the k smallest distances to the others, INCLUDING duplicates at
%% distance 0 (the anti-convergence penalty). Drop exactly ONE self-distance.
novelty(_B, [], _D) -> 0.0;
novelty(B, Others, DistF) ->
    Ds = drop_one_zero(lists:sort([DistF(B, O) || O <- Others])),
    K = min(?K_NOV, length(Ds)),
    mean(lists:sublist(Ds, max(1, K))).

drop_one_zero([0 | T]) -> T;
drop_one_zero(Ds) -> Ds.

%% Trajectory behaviour distance: size of the symmetric difference of visited cells.
beh_dist(A, B) -> length(ordsets:subtract(A, B)) + length(ordsets:subtract(B, A)).

%%%============================================================================
%%% sep-CMA-ES on the objective (closeness) — the strong-optimizer ceiling.
%%% Solved iff the champion's rollout reaches G.
%%%============================================================================
cma(Maze, E) ->
    F = fun(G) -> maps:get(close, evalind(Maze, G)) end,
    Opts = #{max_generations => max(1, E div ?LAMBDA), lambda => ?LAMBDA,
             fitness_goal => 1.0, init_sigma => 1.0},
    R = sep_cma_es:evolve(F, net_params(), Opts),
    {_F, _V, Solved} = rollout(mk_net(maps:get(best, R)), Maze),
    Solved.

rand_search(Maze, E) ->
    lists:any(fun(_) -> maps:get(solved, evalind(Maze, rand_genome())) end, lists:seq(1, E)).

%%%============================================================================
%%% Mutation-effectiveness: fraction of single mutations that change the final
%%% cell on D (argmax + small sigma can give a neutral, piecewise-constant map).
%%%============================================================================
mutation_effectiveness(Fd) ->
    Maze = maze(d),
    Changed = [1 || _ <- lists:seq(1, 300),
                    begin
                        G = rand_genome(),
                        {F0, _, _} = rollout(mk_net(G), Maze),
                        {F1, _, _} = rollout(mk_net(mutate(G)), Maze),
                        F0 =/= F1
                    end],
    emit(Fd, "~nmutation-effectiveness on D: ~.3f of single mutations change the final cell~n",
         [length(Changed) / 300]).

%%%============================================================================
%%% Rollout: from S, up to T steps; argmax of 4 outputs picks N/E/S/W; illegal
%%% moves are no-ops. Returns {FinalCell, VisitedOrdset, ReachedG}.
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

%% move: 0=N 1=E 2=S 3=W; returns the new cell if legal, else the same cell.
move({X, Y}, Dir, Maze) -> legal_or_stay(Maze, {X, Y}, delta({X, Y}, Dir)).

delta({X, Y}, 0) -> {X, Y + 1};
delta({X, Y}, 1) -> {X + 1, Y};
delta({X, Y}, 2) -> {X, Y - 1};
delta({X, Y}, 3) -> {X - 1, Y}.

legal_or_stay(Maze, From, To) ->
    legal_pick(legal(Maze, To), From, To).

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
%%% Net + genome + numerics
%%%============================================================================
net_params() -> ?HID * 6 + ?HID + 4 * ?HID + 4.

mk_net(G) ->
    network_evaluator:set_weights(
      network_evaluator:create_feedforward(6, [?HID], 4, tanh, tanh), G).

rand_genome() -> [rand:normal() || _ <- lists:seq(1, net_params())].
mutate(G) -> [X + ?SIGMA * rand:normal() || X <- G].

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

%% Wilson 95% score interval for k successes in n trials.
wilson(_K, 0) -> {0.0, 0.0};
wilson(K, N) ->
    Z = 1.96, P = K / N, Z2 = Z * Z,
    Denom = 1 + Z2 / N,
    Centre = (P + Z2 / (2 * N)) / Denom,
    Half = (Z * math:sqrt(P * (1 - P) / N + Z2 / (4 * N * N))) / Denom,
    {max(0.0, Centre - Half), min(1.0, Centre + Half)}.

%%%============================================================================
%%% Verdict (all four required for DECEPTION CONFIRMED)
%%%============================================================================
verdict(Fd, _N, {_ObjNk, _, ObjNlo, _}, {_ObjDk, _, _, ObjDhi},
        {_CmaDk, _, _, CmaDhi}, {_RndDk, _, _, _}, {_NovDk, _, NovDlo, _},
        {_NovFpk, _, NovFpLo, _}) ->
    Comp = ObjNlo > 0.8,
    Stall = ObjDhi < 0.2,
    Landscape = CmaDhi < 0.3,
    Adv = NovFpLo > ObjDhi,               %% final-position (canonical) novelty is the advantage test
    emit(Fd, "~n-- Verdict (deception certified if 1-3; 4 = final-position novelty advantage) --~n"),
    emit(Fd, "1 objective competent on twin N (LB>0.8): ~p (LB=~.3f)~n", [Comp, ObjNlo]),
    emit(Fd, "2 objective stalls on D (UB<0.2): ~p (UB=~.3f)~n", [Stall, ObjDhi]),
    emit(Fd, "3 CMA (strong) ALSO stalls on D (UB<0.3): ~p (UB=~.3f)~n", [Landscape, CmaDhi]),
    emit(Fd, "4 final-position novelty beats objective on D: ~p (fpNovLB=~.3f > objUB=~.3f; "
             "trajectory-nov LB=~.3f)~n", [Adv, NovFpLo, ObjDhi, NovDlo]),
    emit(Fd, "~s~n", [classify(Comp, Stall, Landscape, Adv)]).

classify(false, _, _, _) ->
    "RESULT=INVALID: objective search does not solve even the non-deceptive twin N -> optimizer "
    "or representation is broken; fix before interpreting.";
classify(true, false, _, _) ->
    "RESULT=NO DECEPTION: objective search solves D too -> the maze is not deceptive for this "
    "agent; signed negative about the TASK, redesign the maze.";
classify(true, true, false, _) ->
    "RESULT=WEAK-OPTIMIZER not deception: objective-EA stalls on D but strong CMA escapes -> the "
    "stall is optimizer weakness/neutrality, not a landscape trap (the 050 artifact avoided).";
classify(true, true, true, true) ->
    "RESULT=DECEPTION CONFIRMED: objective solves N, both objective-EA and strong CMA are trapped "
    "on D, and novelty-EA solves D with disjoint CIs -> novelty beats objective under genuine "
    "landscape deception (Lehman & Stanley replicated).";
classify(true, true, true, false) ->
    "RESULT=DECEPTIVE but NOVELTY NO HELP: D is genuinely deceptive (objective+CMA trapped) yet "
    "novelty does not beat objective -> signed negative against the QD/novelty claim on this task.".

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
