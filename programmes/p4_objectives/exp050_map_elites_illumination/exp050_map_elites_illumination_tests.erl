%%%-------------------------------------------------------------------
%%% @doc EXP-050 — MAP-Elites illumination of the pole-balancer (P4 opener).
%%%
%%% Pre-registration: experiments/exp050_map_elites_illumination.md
%%% Run: erl -noshell -pa <ebins> -eval 'exp050_map_elites_illumination_tests:run(), init:stop().'
%%%
%%% MAP-Elites (Mouret & Clune 2015) fills an ARCHIVE of diverse balancers instead
%%% of one optimum. Gate-redesigned: reachable + fall-orthogonal descriptor (signed
%%% mean pole angle x mean cart position), a reachable-set pre-run (coverage is
%%% relative to what random search reaches), an OPERATOR-FAIR baseline (same Gaussian
%%% (1+lambda) hill-climb) as the free-lunch comparator with sep-CMA-ES only as a
%%% labelled ceiling, and a Spearman descriptor-validity gate. Single fixed start ->
%%% claims scoped to the single-start behavioural manifold. Accessors only.
%%% @end
%%%-------------------------------------------------------------------
-module(exp050_map_elites_illumination_tests).

-export([run/0, run/1, validate/0]).

-define(INPUTS, 4).
-define(HIDDEN, 8).
-define(OUTPUTS, 1).
-define(CAP, 500).               %% survival cap (goal steps)
-define(GRID, 25).               %% cells per axis
-define(SIGMA, 0.1).             %% Gaussian mutation / operator sigma
-define(LAMBDA, 15).             %% children per generation (operator-fair + cma budget match)
-define(MIN_SURV, 100).          %% a cell counts as a "balancer" cell at >= this survival
-define(BD1_LO, -1.0).           %% mean signed scaled pole angle in [-1,1]
-define(BD1_HI, 1.0).
-define(BD2_LO, -1.0).           %% mean scaled cart position in [-1,1]
-define(BD2_HI, 1.0).
-define(FEED, "exp050_feed.txt").
-define(ARCHIVE, "exp050_archive.eterm").

%%%============================================================================
%%% Entry
%%%============================================================================
run() -> run(#{e => 40000, prerun => 3000}).
validate() -> run(#{e => 2000, prerun => 500}).

run(#{e := E, prerun := PreN}) ->
    rand:seed(exsss, {50, 50, 50}),
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-050 MAP-Elites illumination of the pole-balancer (P4 opener) ==~n", []),
    emit(Fd, "config: E=~p prerun=~p grid=~px~p cap=~p sigma=~.2f min_surv=~p~n",
         [E, PreN, ?GRID, ?GRID, ?CAP, ?SIGMA, ?MIN_SURV]),
    emit(Fd, "BD1=mean signed scaled pole angle [-1,1]; BD2=mean scaled cart position [-1,1]~n"),
    prerun(Fd, PreN),
    Arch = map_elites(Fd, E),
    ok = file:write_file(?ARCHIVE, term_to_binary(Arch)),
    report_archive(Fd, Arch),
    FairBest = fair_baseline(Fd, E),
    MultiBest = multi_restart(Fd, E),
    {RandCells, RandMax} = random_baseline(Fd, E),
    CmaBest = cma_ceiling(Fd, E),
    verdict(Fd, Arch, FairBest, MultiBest, RandCells, RandMax, CmaBest),
    file:close(Fd),
    ok.

%%%============================================================================
%%% Controls the CLAIM gate required: pure random search + multi-restart, both
%%% at the SAME operator and budget. Random genomes already hit the cap (pre-run),
%%% so these are the fair comparators, not a single-start greedy hill-climb.
%%%============================================================================
random_baseline(Fd, E) ->
    Arch = lists:foldl(fun(_, A) -> place(A, rand_genome()) end, #{}, lists:seq(1, E)),
    Vals = maps:values(Arch),
    Cells = length([1 || {S, _, _, _} <- Vals, S >= ?MIN_SURV]),
    emit(Fd, "~n-- Pure random search (~p evals; fair coverage/peak comparator) --~n", [E]),
    emit(Fd, "EXP050 random_search balancer_cells=~p max_survival=~.1f~n",
         [Cells, lists:max([S || {S, _, _, _} <- Vals])]),
    {Cells, lists:max([S || {S, _, _, _} <- Vals])}.

multi_restart(Fd, E) ->
    K = 40,
    Per = max(?LAMBDA, E div K),
    Best = lists:max([one_hillclimb(Per) || _ <- lists:seq(1, K)]),
    emit(Fd, "~n-- Multi-restart (~p x (1+~p) hill-climb, ~p evals each) --~n", [K, ?LAMBDA, Per]),
    emit(Fd, "EXP050 multi_restart best_survival=~.1f~n", [Best]),
    Best.

one_hillclimb(Budget) ->
    {S0, _, _} = eval_genome(G0 = rand_genome(), ?CAP),
    hill(Budget - 1, S0, G0).

%%%============================================================================
%%% Pre-run: reachable set + calibration (random genomes)
%%%============================================================================
prerun(Fd, N) ->
    Rs = [eval_genome(rand_genome(), ?CAP) || _ <- lists:seq(1, N)],
    Survs = [S || {S, _, _} <- Rs],
    Balancers = [{S, B1, B2} || {S, B1, B2} <- Rs, S >= ?MIN_SURV],
    Cells = lists:usort([cell(B1, B2) || {_, B1, B2} <- Balancers]),
    emit(Fd, "~n-- Pre-run (~p random genomes) --~n", [N]),
    emit(Fd, "survival: median=~.1f max=~p frac>=min_surv=~.3f frac_at_cap=~.3f~n",
         [median(Survs), lists:max(Survs), frac_ge(Survs, ?MIN_SURV), frac_ge(Survs, ?CAP)]),
    emit(Fd, "random balancers: n=~p distinct cells R_random=~p; "
             "BD1 range=[~.2f,~.2f] BD2 range=[~.2f,~.2f]~n",
         [length(Balancers), length(Cells),
          minf([B1 || {_, B1, _} <- Balancers]), maxf([B1 || {_, B1, _} <- Balancers]),
          minf([B2 || {_, _, B2} <- Balancers]), maxf([B2 || {_, _, B2} <- Balancers])]),
    put(r_random, length(Cells)).

%%%============================================================================
%%% MAP-Elites
%%%============================================================================
map_elites(Fd, E) ->
    emit(Fd, "~n-- MAP-Elites: 100 random init + ~p mutation evals --~n", [E]),
    Arch0 = lists:foldl(fun(_, A) -> place(A, rand_genome()) end, #{}, lists:seq(1, 100)),
    me_loop(E, Arch0).

me_loop(0, Arch) -> Arch;
me_loop(E, Arch) -> me_loop(E - 1, place(Arch, mutate(sample_elite(Arch)))).

%% Evaluate a genome and keep it in its behavioural cell iff it beats the incumbent.
place(Arch, G) ->
    {S, B1, B2} = eval_genome(G, ?CAP),
    keep_better(Arch, cell(B1, B2), {S, B1, B2, G}).

sample_elite(Arch) ->
    {_S, _B1, _B2, G} = lists:nth(rand:uniform(maps:size(Arch)), maps:values(Arch)),
    G.

%%%============================================================================
%%% Operator-fair baseline: (1+lambda) Gaussian hill-climb on survival
%%%============================================================================
fair_baseline(Fd, E) ->
    {S0, _, _} = eval_genome(G0 = rand_genome(), ?CAP),
    Best = hill(E - 1, S0, G0),
    emit(Fd, "~n-- Operator-fair baseline ((1+~p) Gaussian sigma=~.2f hill-climb) --~n",
         [?LAMBDA, ?SIGMA]),
    emit(Fd, "EXP050 fair_baseline best_survival=~.1f~n", [Best]),
    Best.

hill(E, Best, _BestG) when E =< 0 -> Best;
hill(E, Best, BestG) ->
    Kids = [child_of(BestG) || _ <- lists:seq(1, ?LAMBDA)],
    {KS, KG} = lists:max(Kids),
    hill_step(KS > Best, E - ?LAMBDA, Best, BestG, KS, KG).

child_of(BestG) ->
    C = mutate(BestG),
    {surv(C), C}.

hill_step(true, E, _Best, _BestG, KS, KG) -> hill(E, KS, KG);
hill_step(false, E, Best, BestG, _KS, _KG) -> hill(E, Best, BestG).

%%%============================================================================
%%% sep-CMA-ES ceiling (labelled context, NOT the free-lunch comparator)
%%%============================================================================
cma_ceiling(Fd, E) ->
    Opts = #{max_generations => max(1, E div ?LAMBDA), lambda => ?LAMBDA,
             fitness_goal => ?CAP + 1, init_sigma => 1.0},
    R = sep_cma_es:evolve(fun(G) -> surv(G) end, net_params(), Opts),
    Best = maps:get(fitness, R),
    emit(Fd, "~n-- sep-CMA-ES ceiling (strong optimizer, context only) --~n"),
    emit(Fd, "EXP050 cma_ceiling best_survival=~.1f~n", [Best]),
    Best.

%%%============================================================================
%%% Archive report + descriptor-validity + verdict
%%%============================================================================
report_archive(Fd, Arch) ->
    Cells = maps:values(Arch),
    Surv = [C || {S, _, _, _} = C <- Cells, S >= ?MIN_SURV],
    Quals = [S || {S, _, _, _} <- Cells],
    B1s = [B1 || {_, B1, _, _} <- Surv],
    B2s = [B2 || {_, _, B2, _} <- Surv],
    emit(Fd, "~n-- Archive --~n"),
    emit(Fd, "filled cells=~p; balancer cells (>=~p)=~p "
             "(fair coverage vs random-search-at-budget is in the verdict; grid is mostly "
             "unreachable, so filled/625 is not a coverage measure)~n",
         [length(Cells), ?MIN_SURV, length(Surv)]),
    emit(Fd, "QD-score(sum survival over all cells)=~p; max_quality=~.1f~n",
         [round(lists:sum(Quals)), lists:max(Quals)]),
    emit(Fd, "balancer BD1 range=[~.2f,~.2f] BD2 range=[~.2f,~.2f]~n",
         [minf(B1s), maxf(B1s), minf(B2s), maxf(B2s)]).

verdict(Fd, Arch, FairBest, MultiBest, RandCells, RandMax, CmaBest) ->
    Cells = maps:values(Arch),
    AllQ = [S || {S, _, _, _} <- Cells],
    BalCells = length([1 || S <- AllQ, S >= ?MIN_SURV]),
    MaxQ = lists:max(AllQ),
    %% Descriptor validity over ALL filled cells (not range-restricted to balancers).
    Sp1 = spearman([B1 || {_, B1, _, _} <- Cells], AllQ),
    Sp2 = spearman([B2 || {_, _, B2, _} <- Cells], AllQ),
    emit(Fd, "~n-- Verdict --~n"),
    emit(Fd, "descriptor validity (over ALL ~p cells): |Sp(BD1,q)|=~.3f |Sp(BD2,q)|=~.3f (<0.3)~n",
         [length(Cells), abs(Sp1), abs(Sp2)]),
    emit(Fd, "coverage @ equal budget: MAP-Elites balancer_cells=~p vs random_search=~p~n",
         [BalCells, RandCells]),
    emit(Fd, "peak survival: mapelites=~.1f random=~.1f multi_restart=~.1f fair_greedy=~.1f "
             "cma=~.1f~n", [MaxQ, RandMax, MultiBest, FairBest, CmaBest]),
    emit(Fd, "~s~n", [classify(Sp1, Sp2, BalCells, RandCells, MaxQ, RandMax, MultiBest)]).

classify(Sp1, Sp2, _Bal, _Rand, _MaxQ, _RandMax, _Multi) when abs(Sp1) >= 0.3; abs(Sp2) >= 0.3 ->
    "RESULT=DESCRIPTOR INVALID (over all cells): a BD axis is a quality proxy (|Spearman|>=0.3); "
    "the illumination claim is void.";
classify(_Sp1, _Sp2, Bal, Rand, MaxQ, RandMax, Multi) ->
    coverage_verdict(Bal, Rand) ++ " " ++ advantage_verdict(MaxQ, RandMax, Multi).

coverage_verdict(Bal, Rand) when Bal > Rand * 1.2 ->
    "RESULT=ILLUMINATES: MAP-Elites fills more balancer cells than random search at equal budget ("
    ++ integer_to_list(Bal) ++ " vs " ++ integer_to_list(Rand) ++ ").";
coverage_verdict(Bal, Rand) ->
    "RESULT=NO COVERAGE ADVANTAGE: MAP-Elites=" ++ integer_to_list(Bal)
    ++ " ~= random search=" ++ integer_to_list(Rand) ++ " balancer cells at equal budget.".

advantage_verdict(MaxQ, RandMax, Multi) when RandMax >= MaxQ * 0.98; Multi >= MaxQ * 0.98 ->
    "NO PEAK ADVANTAGE: random and/or multi-restart reach the same peak -> task too easy for a "
    "QD-vs-objective claim (the earlier 'QD beats objective' was a single-greedy-baseline artifact).";
advantage_verdict(_MaxQ, _RandMax, _Multi) ->
    "PEAK ADVANTAGE: MAP-Elites peak exceeds BOTH random and multi-restart at equal budget.".

%%%============================================================================
%%% Genome eval on the pole -> {Survival, BD1, BD2}
%%%============================================================================
surv(G) -> element(1, eval_genome(G, ?CAP)).

eval_genome(G, Cap) ->
    Net = network_evaluator:set_weights(
            network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh), G),
    ep_loop(Net, pb_sim:init([]), Cap, 0, 0.0, 0.0).

%% Accumulate: Steps, sum of signed scaled pole angle (sensor 3), sum of scaled cart pos (sensor 1).
ep_loop(Net, S, Cap, T, AngAcc, CartAcc) ->
    {Inputs, S1} = pb_sim:sense(sensor, [?INPUTS], S),
    Output = network_evaluator:evaluate(Net, Inputs),
    {_F, Done, S2} = pb_sim:act(actuator, [without_damping, 0, Cap], Output, S1),
    ep_continue(Done, Net, S2, Cap, T + 1,
                AngAcc + lists:nth(3, Inputs), CartAcc + lists:nth(1, Inputs)).

ep_continue(0, Net, S, Cap, T, AngAcc, CartAcc) ->
    ep_loop(Net, S, Cap, T, AngAcc, CartAcc);
ep_continue(_Done, _Net, _S, _Cap, T, AngAcc, CartAcc) ->
    {float(T), safe_div(AngAcc, T), safe_div(CartAcc, T)}.

%%%============================================================================
%%% Archive placement + grid
%%%============================================================================
keep_better(Arch, Key, New) ->
    better(maps:get(Key, Arch, undefined), New, Arch, Key).

better(undefined, New, Arch, Key) -> maps:put(Key, New, Arch);
better({OldS, _, _, _}, {S, _, _, _} = New, Arch, Key) when S > OldS -> maps:put(Key, New, Arch);
better(_Old, _New, Arch, _Key) -> Arch.

cell(B1, B2) ->
    {bin(B1, ?BD1_LO, ?BD1_HI), bin(B2, ?BD2_LO, ?BD2_HI)}.

bin(V, Lo, Hi) ->
    I = trunc((V - Lo) / (Hi - Lo) * ?GRID),
    max(0, min(?GRID - 1, I)).

%%%============================================================================
%%% Genomes + numerics
%%%============================================================================
net_params() -> ?HIDDEN * ?INPUTS + ?HIDDEN + ?OUTPUTS * ?HIDDEN + ?OUTPUTS.

rand_genome() -> [rand:normal() || _ <- lists:seq(1, net_params())].

mutate(G) -> [X + ?SIGMA * rand:normal() || X <- G].

safe_div(_A, 0) -> 0.0;
safe_div(A, B) -> A / B.

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L),
    lists:nth(max(1, length(S) div 2), S).

frac_ge(L, T) -> length([1 || X <- L, X >= T]) / max(1, length(L)).

minf([]) -> 0.0;
minf(L) -> lists:min(L).
maxf([]) -> 0.0;
maxf(L) -> lists:max(L).

%% Spearman rank correlation (Pearson of ranks).
spearman(Xs, _Ys) when length(Xs) < 3 -> 0.0;
spearman(Xs, Ys) -> pearson(ranks(Xs), ranks(Ys)).

ranks(L) ->
    Sorted = lists:sort(lists:zip(L, lists:seq(1, length(L)))),
    Ranked = lists:zip(Sorted, lists:seq(1, length(Sorted))),
    Back = [{OrigIdx, Rank} || {{_V, OrigIdx}, Rank} <- Ranked],
    [R || {_I, R} <- lists:sort(Back)].

pearson(Xs, Ys) ->
    N = length(Xs),
    Mx = lists:sum(Xs) / N,
    My = lists:sum(Ys) / N,
    Cov = lists:sum([(X - Mx) * (Y - My) || {X, Y} <- lists:zip(Xs, Ys)]),
    Sx = math:sqrt(lists:sum([(X - Mx) * (X - Mx) || X <- Xs])),
    Sy = math:sqrt(lists:sum([(Y - My) * (Y - My) || Y <- Ys])),
    safe_div(Cov, Sx * Sy).

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
