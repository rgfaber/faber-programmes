%%%-------------------------------------------------------------------
%%% @doc EXP-047 — lifetime mechanism probe.
%%%
%%% Pre-registration: experiments/exp047_lifetime_mechanism_probe.md
%%% Run: scripts/run_experiment.sh exp047_lifetime_mechanism_probe_tests
%%%   (or, since eunit swallows io:format, directly:
%%%    erl -noshell -pa <ebins> -eval 'exp047..._tests:run_full(), init:stop().')
%%%
%%% Does 045's "integration low-passes per-step substrate differences" story
%%% survive DIRECT measurement, or is it a just-so narrative? Three fitness nulls
%%% (043-045) cannot tell "the substrates compute the same thing" from "different
%%% things that wash out at the action". This decodes the current good arm from
%%% each substrate's internal state and reports per-arm AUC + per-step disagreement.
%%%
%%% Uses only network_evaluator's PUBLIC accessors (the #network record is private
%%% to that module), so this runner never touches the record directly.
%%%
%%% Feed is written directly to a file (eunit swallows io:format for passing tests).
%%%
%%% Archived after signing. A permanent record of what was executed.
%%% @end
%%%-------------------------------------------------------------------
-module(exp047_lifetime_mechanism_probe_tests).

-include_lib("eunit/include/eunit.hrl").

-export([validate/0, run_full/0, run_full/1, run_phase2_from_file/0,
         run_phase2_from_file/1, arm_dim/1, build_net/2, eval_instance/3, evolve_arm/2]).

%%%============================================================================
%%% Config (the 043 fair-contest cell)
%%%============================================================================
-define(INPUTS, 3).
-define(HIDDEN, 10).
-define(OUTPUTS, 1).
-define(LIFETIME, 60).
-define(REVERSAL_AT, 30).
-define(PHI, 0.8).
-define(OPTIMAL_RATE, 0.6).          %% 2*PHI - 1
-define(N_RUNS, 10).                  %% independent evolutionary runs per arm
-define(MAX_GEN, 300).
-define(FITNESS_GOAL, 95.0).          %% high: arms run to plateau -> true champions
-define(ARMS, [fixed, cfc, nm_global, nm_pc]).
-define(ADAPTIVE, [cfc, nm_global, nm_pc]).
-define(LOGREG_ITERS, 400).
-define(LOGREG_LR, 0.5).
-define(FEED, "exp047_feed.txt").
-define(CHAMPS, "exp047_champions.eterm").

%% Instance sets. Evolver-facing (train) and probe-facing (holdout) flip_seeds are
%% DISJOINT (common-random-numbers hygiene). Each instance: {GoodArm, ReversalAt,
%% Lifetime, FlipSeed, Phi}.
train_instances() ->
    [{G, ?REVERSAL_AT, ?LIFETIME, Fs, ?PHI}
     || {G, Fs} <- [{0, 101}, {1, 102}, {0, 103}, {1, 104}, {0, 105}, {1, 106},
                    {0, 107}, {1, 108}, {0, 109}, {1, 110}, {0, 111}, {1, 112}]].

holdout_instances() ->
    [{G, ?REVERSAL_AT, ?LIFETIME, Fs, ?PHI}
     || {G, Fs} <- [{0, 901}, {1, 902}, {0, 903}, {1, 904}, {0, 905}, {1, 906},
                    {0, 907}, {1, 908}, {0, 909}, {1, 910}, {0, 911}, {1, 912},
                    {0, 913}, {1, 914}, {0, 915}, {1, 916}]].

%%%============================================================================
%%% Genome dims (the validation contract against the 043 feed)
%%%============================================================================
net_params() -> ?HIDDEN * ?INPUTS + ?HIDDEN + ?OUTPUTS * ?HIDDEN + ?OUTPUTS.
n_synapses() -> ?HIDDEN * ?INPUTS + ?OUTPUTS * ?HIDDEN.

arm_dim(fixed) -> net_params();
arm_dim(cfc) -> net_params() + ?HIDDEN;
arm_dim(nm_global) -> net_params() + 5;
arm_dim(nm_pc) -> net_params() + 4 * n_synapses() + 1.

%%%============================================================================
%%% Network construction from a flat genome, per arm (accessors only)
%%%============================================================================
build_net(fixed, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, []} = lists:split(net_params(), G),
    {fixed, network_evaluator:set_weights(Base, W)};
build_net(cfc, G) ->
    Base = network_evaluator:create_cfc_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, Taus} = lists:split(net_params(), G),
    Net1 = network_evaluator:set_weights(Base, W),
    Meta = network_evaluator:get_neuron_meta(Net1),
    Net2 = network_evaluator:set_neuron_meta(Net1, set_taus(Meta, Taus)),
    {cfc, network_evaluator:reset_internal_state(Net2)};
build_net(nm_global, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, [A, B, C, D, Eta]} = lists:split(net_params(), G),
    {nm_global, {network_evaluator:set_weights(Base, W), {A, B, C, D, Eta}}};
build_net(nm_pc, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, Rest} = lists:split(net_params(), G),
    {Coeffs, [Eta]} = lists:split(4 * n_synapses(), Rest),
    {nm_pc, {network_evaluator:set_weights(Base, W), {pc, build_pc_coeffs(Coeffs), Eta}}}.

set_taus([HiddenMeta, OutputMeta], Taus) ->
    NewHidden = [M#{tau => clamp_tau(T)} || {M, T} <- lists:zip(HiddenMeta, Taus)],
    [NewHidden, OutputMeta].

clamp_tau(T) -> max(0.1, min(2.0, 0.1 + abs(T))).

build_pc_coeffs(Coeffs) ->
    {L1Flat, L2Flat} = lists:split(4 * ?HIDDEN * ?INPUTS, Coeffs),
    L1 = [tuples4(neuron_slice(L1Flat, N, ?INPUTS)) || N <- lists:seq(0, ?HIDDEN - 1)],
    [L1, [tuples4(L2Flat)]].

neuron_slice(Flat, N, Inputs) -> lists:sublist(Flat, N * Inputs * 4 + 1, Inputs * 4).

tuples4([A, B, C, D | Rest]) -> [{A, B, C, D} | tuples4(Rest)];
tuples4([]) -> [].

%%%============================================================================
%%% Episode evaluation (one champion on one instance) -> total reward
%%%============================================================================
eval_instance(Arm, Genome, Instance) ->
    Net = build_net(Arm, Genome),
    S0 = prob_reversal_bandit_sim:init(tuple_to_list(Instance)),
    episode_loop(Net, S0, 0.0).

episode_loop(Net, S, Acc) ->
    {Inputs, S1} = prob_reversal_bandit_sim:sense(sensor, [], S),
    {Output, Net1} = step(Net, Inputs),
    {Reward, Done, S2} = prob_reversal_bandit_sim:act(actuator, [], Output, S1),
    continue(Done, Net1, S2, Acc + Reward).

continue(done, _Net, _S, Acc) -> Acc;
continue(_, Net, S, Acc) -> episode_loop(Net, S, Acc).

%% Per-arm forward step. M (neuromodulator) is the last reward (sensor input 1).
step({fixed, Net}, Inputs) ->
    {network_evaluator:evaluate(Net, Inputs), {fixed, Net}};
step({cfc, Net}, Inputs) ->
    {Out, Net1} = network_evaluator:evaluate_with_state(Net, Inputs),
    {Out, {cfc, Net1}};
step({nm_global, {Net, Rule}}, Inputs) ->
    {Out, Net1} = network_evaluator:evaluate_with_neuromod(Net, Inputs, Rule, hd(Inputs)),
    {Out, {nm_global, {Net1, Rule}}};
step({nm_pc, {Net, Rule}}, Inputs) ->
    {Out, Net1} = network_evaluator:evaluate_with_neuromod(Net, Inputs, Rule, hd(Inputs)),
    {Out, {nm_pc, {Net1, Rule}}}.

%% The arm's internal-state vector AFTER a step (the substrate we decode from).
state_vec({fixed, Net}) -> network_evaluator:get_weights(Net);
state_vec({cfc, Net}) -> lists:flatten(network_evaluator:get_internal_state(Net));
state_vec({nm_global, {Net, _}}) -> network_evaluator:get_weights(Net);
state_vec({nm_pc, {Net, _}}) -> network_evaluator:get_weights(Net).

%%%============================================================================
%%% Fitness: mean reward over the instance set, normalised (chance=50, opt=100)
%%%============================================================================
fitness(Arm, Instances, Genome) ->
    Rewards = [eval_instance(Arm, Genome, I) || I <- Instances],
    MeanPerTrial = lists:sum(Rewards) / (length(Instances) * ?LIFETIME),
    50.0 * (1.0 + MeanPerTrial / ?OPTIMAL_RATE).

%%%============================================================================
%%% Phase 1: evolve one arm, N runs
%%%============================================================================
evolve_arm(Arm, NRuns) ->
    N = arm_dim(Arm),
    Train = train_instances(),
    F = fun(G) -> fitness(Arm, Train, G) end,
    [one_run(Arm, F, N, R) || R <- lists:seq(1, NRuns)].

one_run(Arm, F, N, R) ->
    Opts = #{max_generations => ?MAX_GEN, fitness_goal => ?FITNESS_GOAL, init_sigma => 1.0},
    Result = sep_cma_es:evolve(F, N, Opts),
    #{arm => Arm, run => R, fitness => maps:get(fitness, Result),
      reason => maps:get(reason, Result), evals => maps:get(evaluations, Result),
      genome => maps:get(best, Result)}.

%%%============================================================================
%%% Phase 2: instrumented replay + decode
%%%============================================================================

%% Replay a champion on the holdout set. Returns rows {StateVec, SensorVec,
%% GoodArm, InstanceIdx, TrialIdx} -- one per trial.
replay(Arm, Genome) ->
    Instances = holdout_instances(),
    Indexed = lists:zip(lists:seq(1, length(Instances)), Instances),
    lists:append([replay_instance(Arm, Genome, Idx, I) || {Idx, I} <- Indexed]).

replay_instance(Arm, Genome, Idx, {GoodArm, RevAt, _Life, _Fs, _Phi} = Instance) ->
    Net = build_net(Arm, Genome),
    S0 = prob_reversal_bandit_sim:init(tuple_to_list(Instance)),
    replay_loop(Net, S0, GoodArm, RevAt, Idx, 0, []).

replay_loop(Net, S, GoodArm, RevAt, Idx, Trial, Acc) ->
    {Inputs, S1} = prob_reversal_bandit_sim:sense(sensor, [], S),
    {Output, Net1} = step(Net, Inputs),
    {_Reward, Done, S2} = prob_reversal_bandit_sim:act(actuator, [], Output, S1),
    Row = {state_vec(Net1), sensor_vec(Inputs), good_at(Trial, RevAt, GoodArm), Idx, Trial},
    replay_continue(Done, Net1, S2, GoodArm, RevAt, Idx, Trial + 1, [Row | Acc]).

replay_continue(done, _Net, _S, _GA, _R, _Idx, _Trial, Acc) -> lists:reverse(Acc);
replay_continue(_, Net, S, GA, R, Idx, Trial, Acc) ->
    replay_loop(Net, S, GA, R, Idx, Trial, Acc).

sensor_vec([LastReward, LastAction, _Bias]) -> [LastReward, LastAction].

good_at(Trial, RevAt, GoodArm) when Trial < RevAt -> GoodArm;
good_at(_Trial, _RevAt, GoodArm) -> 1 - GoodArm.

%% Decode good-arm from a champion's replay rows. Returns {StateAuc, SensorAuc, TimeAuc}.
decode_champion(Arm, Genome) ->
    {Train, Test} = split_balanced(decode_rows(replay(Arm, Genome))),
    {auc_for(fun state_of/1, Train, Test),
     auc_for(fun sensor_of/1, Train, Test),
     auc_for(fun time_of/1, Train, Test)}.

%% Drop transition trials [RevAt, RevAt+2]: the reversal is epistemically invisible to
%% the substrate until it sees a post-reversal surprise, so there the label leads the state.
decode_rows(Rows) ->
    [R || {_, _, _, _, T} = R <- Rows, T < ?REVERSAL_AT orelse T > ?REVERSAL_AT + 2].

%% Balanced split: first 8 holdout instances (train) vs last 8 (test). Both halves carry
%% BOTH initial-arm polarities, so pure episode-time no longer predicts the label -- a state
%% must encode the ACTUAL current good arm (which flips sign with the instance's GoodArm) to
%% decode. (The old odd/even split put all GoodArm=0 in train, all GoodArm=1 in test, making
%% the training label identical to "trial>=30" and inverting it on test: a fatal confound.)
split_balanced(Rows) ->
    lists:partition(fun({_, _, _, Idx, _}) -> Idx =< 8 end, Rows).

state_of({St, _Se, Y, _I, _T}) -> {St, Y}.
sensor_of({_St, Se, Y, _I, _T}) -> {Se, Y}.
%% Time-only control: decode the label from trial index alone. Under the balanced split it
%% must sit ~0.5. It is the confound sentinel the constant-state fixed arm cannot be.
time_of({_St, _Se, Y, _I, T}) -> {[float(T)], Y}.

auc_for(Extract, Train, Test) ->
    TrX = [element(1, Extract(R)) || R <- Train],
    TrY = [element(2, Extract(R)) || R <- Train],
    TeX = [element(1, Extract(R)) || R <- Test],
    TeY = [element(2, Extract(R)) || R <- Test],
    {Mu, Sd} = standardiser(TrX),
    Model = train_logreg([standardise(X, Mu, Sd) || X <- TrX], TrY),
    Scores = [predict(Model, standardise(X, Mu, Sd)) || X <- TeX],
    auc(Scores, TeY).

%%%============================================================================
%%% Logistic regression (pure Erlang), standardisation, AUC
%%%============================================================================
standardiser(X) ->
    D = length(hd(X)),
    N = length(X),
    Cols = [[lists:nth(J, Xi) || Xi <- X] || J <- lists:seq(1, D)],
    Mu = [lists:sum(C) / N || C <- Cols],
    Sd = [col_sd(C, M, N) || {C, M} <- lists:zip(Cols, Mu)],
    {Mu, Sd}.

col_sd(C, M, N) ->
    V = lists:sum([(X - M) * (X - M) || X <- C]) / N,
    guard_sd(math:sqrt(V)).

guard_sd(S) when S < 1.0e-9 -> 1.0;
guard_sd(S) -> S.

standardise(X, Mu, Sd) ->
    [(Xi - M) / S || {Xi, M, S} <- lists:zip3(X, Mu, Sd)].

train_logreg(X, Y) ->
    D = length(hd(X)),
    Init = {lists:duplicate(D, 0.0), 0.0},
    lists:foldl(fun(_, Model) -> gd_step(X, Y, Model) end, Init, lists:seq(1, ?LOGREG_ITERS)).

gd_step(X, Y, {W, B}) ->
    N = length(X),
    Zero = lists:duplicate(length(W), 0.0),
    {GW, GB} = lists:foldl(step_grad(W, B), {Zero, 0.0}, lists:zip(X, Y)),
    {vsub(W, vscale(?LOGREG_LR / N, GW)), B - ?LOGREG_LR * GB / N}.

step_grad(W, B) ->
    fun({Xi, Yi}, {AccW, AccB}) ->
        E = sigmoid(dot(W, Xi) + B) - Yi,
        {vadd(AccW, vscale(E, Xi)), AccB + E}
    end.

predict({W, B}, X) -> sigmoid(dot(W, X) + B).

auc(Scores, Labels) ->
    Pairs = lists:zip(Scores, Labels),
    Pos = [S || {S, 1} <- Pairs],
    Neg = [S || {S, 0} <- Pairs],
    auc_ranked(Pos, Neg).

auc_ranked([], _) -> 0.5;
auc_ranked(_, []) -> 0.5;
auc_ranked(Pos, Neg) ->
    C = lists:sum([lists:sum([pair_score(P, Nv) || Nv <- Neg]) || P <- Pos]),
    C / (length(Pos) * length(Neg)).

pair_score(P, N) when P > N -> 1.0;
pair_score(P, N) when P == N -> 0.5;
pair_score(_, _) -> 0.0.

sigmoid(Z) when Z < -30.0 -> 0.0;
sigmoid(Z) when Z > 30.0 -> 1.0;
sigmoid(Z) -> 1.0 / (1.0 + math:exp(-Z)).

dot(A, B) -> lists:sum([X * Y || {X, Y} <- lists:zip(A, B)]).
vadd(A, B) -> [X + Y || {X, Y} <- lists:zip(A, B)].
vsub(A, B) -> [X - Y || {X, Y} <- lists:zip(A, B)].
vscale(S, A) -> [S * X || X <- A].

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

%% True sample sd for REPORTING (no divide-by-zero guard; 0.0 when degenerate).
sd_of([]) -> 0.0;
sd_of(L) ->
    M = mean(L),
    math:sqrt(mean([(X - M) * (X - M) || X <- L])).

%%%============================================================================
%%% Full run: Phase 1 (evolve + persist) then Phase 2 (decode), feed to file
%%%============================================================================
run_full() -> run_full(?N_RUNS).

run_full(NRuns) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-047 lifetime mechanism probe ==~n", []),
    emit(Fd, "config: cell=043-fair-contest phi=~.2f life=~p reversal_at=~p n_runs=~p~n",
         [?PHI, ?LIFETIME, ?REVERSAL_AT, NRuns]),
    emit(Fd, "dims: fixed=~p cfc=~p nm_global=~p nm_pc=~p (must match 043 feed 51/61/56/212)~n",
         [arm_dim(fixed), arm_dim(cfc), arm_dim(nm_global), arm_dim(nm_pc)]),
    Champions = phase1(Fd, NRuns),
    ok = file:write_file(?CHAMPS, term_to_binary(Champions)),
    emit(Fd, "~n[phase1] champions persisted -> ~s~n", [?CHAMPS]),
    phase2(Fd, Champions),
    file:close(Fd),
    ok.

%% Re-run Phase 2 ONLY from persisted champions (no re-evolution). The payoff of
%% persisting champions: a decoder fix costs a Phase-2 rerun, not 40 evolution runs.
run_phase2_from_file() -> run_phase2_from_file(?CHAMPS).

run_phase2_from_file(File) ->
    {ok, Bin} = file:read_file(File),
    Champions = binary_to_term(Bin),
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-047 lifetime mechanism probe (Phase 2 rerun, split fixed) ==~n", []),
    emit(Fd, "champions loaded from ~s (Phase 1 evolution unchanged)~n", [File]),
    emit(Fd, "dims: fixed=~p cfc=~p nm_global=~p nm_pc=~p~n",
         [arm_dim(fixed), arm_dim(cfc), arm_dim(nm_global), arm_dim(nm_pc)]),
    [phase1_summary(Fd, Arm, Champs) || {Arm, Champs} <- Champions],
    phase2(Fd, Champions),
    shifted_reversal(Fd, Champions),
    file:close(Fd),
    ok.

%%%============================================================================
%%% Phase 3: shifted-reversal control (clock vs genuine tracking)
%%%============================================================================
%% Champions evolved with the reversal fixed at trial 30. Replay them on holdout
%% instances with the reversal moved to 20/30/40. A substrate that TRACKS the
%% reversal from evidence performs well wherever it lands (FLAT fitness across R);
%% a substrate running an internal CLOCK tuned to the trained schedule performs
%% well only at R=30 (PEAKED). The fixed arm (no internal state -> cannot clock)
%% is the reactive-only reference for whatever asymmetry the schedule itself causes.
shifted_reversal(Fd, Champions) ->
    emit(Fd, "~n-- Phase 3: shifted-reversal control (clock vs tracking) --~n"),
    emit(Fd, "  evolved at reversal=30; replayed at 20/30/40. FLAT across R => tracks the~n"),
    emit(Fd, "  reversal; PEAKED at 30 => internal clock. fixed arm = reactive-only reference.~n~n"),
    Rows = [shift_arm(Fd, Arm, Champs) || {Arm, Champs} <- Champions],
    shift_verdict(Fd, Rows).

shift_arm(Fd, Arm, Champs) ->
    Fits = [{R, mean([fitness_at(Arm, maps:get(genome, C), R) || C <- Champs])}
            || R <- [20, 30, 40]],
    F20 = getf(20, Fits),
    F30 = getf(30, Fits),
    F40 = getf(40, Fits),
    Drop = F30 - (F20 + F40) / 2,
    emit(Fd, "EXP047 shift arm=~p fit@R20=~.1f fit@R30=~.1f fit@R40=~.1f clock_drop=~.2f~n",
         [Arm, F20, F30, F40, Drop]),
    {Arm, Drop}.

getf(R, Fits) -> element(2, lists:keyfind(R, 1, Fits)).

fitness_at(Arm, Genome, R) ->
    Instances = [{G, R, ?LIFETIME, Fs, ?PHI} || {G, _RA, _L, Fs, _P} <- holdout_instances()],
    Rewards = [eval_instance(Arm, Genome, I) || I <- Instances],
    50.0 * (1.0 + (lists:sum(Rewards) / (length(Instances) * ?LIFETIME)) / ?OPTIMAL_RATE).

shift_verdict(Fd, Rows) ->
    M = maps:from_list(Rows),
    FixedDrop = maps:get(fixed, M),
    AdaptiveDrops = [maps:get(A, M) || A <- ?ADAPTIVE],
    emit(Fd, "~nfixed(reactive-only) clock_drop=~.2f; adaptive clock_drops=~p~n",
         [FixedDrop, [round2(D) || D <- AdaptiveDrops]]),
    emit(Fd, "~s~n", [shift_classify(FixedDrop, lists:max(AdaptiveDrops))]).

%% Adaptive arms no more schedule-sensitive than the reactive-only fixed arm => they
%% track the reversal, not a clock. A materially larger drop => clock-dependence.
shift_classify(FixedDrop, MaxAdaptive) when MaxAdaptive =< FixedDrop + 2.0 ->
    "SHIFT=TRACKS: adaptive fitness is no more schedule-sensitive than the reactive-only "
    "fixed arm; the substrates adapt to the reversal wherever it lands, not via a clock.";
shift_classify(_FixedDrop, _MaxAdaptive) ->
    "SHIFT=CLOCK-DEPENDENT: adaptive fitness peaks at the trained reversal time and drops when "
    "it moves; at least one substrate relies on an internal clock, not evidence tracking.".

round2(X) -> round(X * 100) / 100.

phase1_summary(Fd, Arm, Champs) ->
    Fits = [maps:get(fitness, C) || C <- Champs],
    emit(Fd, "EXP047 arm=~p SUMMARY mean_fitness=~.2f sd=~.2f best=~.1f (persisted)~n",
         [Arm, mean(Fits), sd_of(Fits), lists:max(Fits)]).

phase1(Fd, NRuns) ->
    emit(Fd, "~n-- Phase 1: evolve ~p runs/arm (fitness_goal=~.1f max_gen=~p) --~n",
         [NRuns, ?FITNESS_GOAL, ?MAX_GEN]),
    [{Arm, phase1_arm(Fd, Arm, NRuns)} || Arm <- ?ARMS].

phase1_arm(Fd, Arm, NRuns) ->
    Champs = evolve_arm(Arm, NRuns),
    [emit(Fd, "EXP047 arm=~p dim=~p run=~p reason=~p fitness=~.1f evals=~p~n",
          [Arm, arm_dim(Arm), maps:get(run, C), maps:get(reason, C),
           maps:get(fitness, C), maps:get(evals, C)]) || C <- Champs],
    Fits = [maps:get(fitness, C) || C <- Champs],
    emit(Fd, "EXP047 arm=~p SUMMARY mean_fitness=~.2f sd=~.2f best=~.1f~n",
         [Arm, mean(Fits), sd_of(Fits), lists:max(Fits)]),
    Champs.

phase2(Fd, Champions) ->
    emit(Fd, "~n-- Phase 2: decode current-good-arm from internal state --~n"),
    emit(Fd, "  state_auc  = decode from the substrate's own internal state~n"),
    emit(Fd, "  sensor_auc = decode from [last_reward,last_action] -- ENDOGENOUS (last_action is~n"),
    emit(Fd, "               the arm's own output), reported as diagnostic, NOT a decision bar~n"),
    emit(Fd, "  time_ctrl  = decode from trial index; must be ~~0.5 or the split is time-confounded~n~n"),
    Decoded = [{Arm, decode_arm(Fd, Arm, Champs)} || {Arm, Champs} <- Champions],
    verdict(Fd, Decoded, disagreement(Champions)).

%% Per-step disagreement among the adaptive arms. For each arm, take the per-(instance,
%% trial) MAJORITY vote across its 10 champions (majority_preds/2), then count the fraction
%% of aligned held-out points where the three arms' majority predictions are NOT unanimous.
%% Balanced split (train instances 1-8, test 9-16), transition trials excluded.
disagreement(Champions) ->
    Maps = [majority_preds(Arm, Champs)
            || {Arm, Champs} <- Champions, lists:member(Arm, ?ADAPTIVE)],
    Keys = maps:keys(hd(Maps)),
    NotUnanimous = [K || K <- Keys, not unanimous([maps:get(K, M) || M <- Maps])],
    length(NotUnanimous) / max(1, length(Keys)).

%% Majority good-arm prediction per (instance,trial) across an arm's 10 champions.
majority_preds(Arm, Champs) ->
    PredMaps = [maps:from_list(arm_test_preds(Arm, maps:get(genome, C))) || C <- Champs],
    Keys = maps:keys(hd(PredMaps)),
    maps:from_list([{K, majority([maps:get(K, M) || M <- PredMaps])} || K <- Keys]).

majority(Preds) ->
    Ones = length([1 || P <- Preds, P =:= 1]),
    two_class(Ones * 2 >= length(Preds)).

two_class(true) -> 1;
two_class(false) -> 0.

arm_test_preds(Arm, Genome) ->
    {Train, Test} = split_balanced(decode_rows(replay(Arm, Genome))),
    TrX = [St || {St, _, _, _, _} <- Train],
    TrY = [Y || {_, _, Y, _, _} <- Train],
    {Mu, Sd} = standardiser(TrX),
    Model = train_logreg([standardise(X, Mu, Sd) || X <- TrX], TrY),
    [{{Idx, Trial}, thresh(predict(Model, standardise(St, Mu, Sd)))}
     || {St, _, _, Idx, Trial} <- Test].

thresh(P) when P >= 0.5 -> 1;
thresh(_) -> 0.

unanimous([H | T]) -> lists:all(fun(X) -> X =:= H end, T).

decode_arm(Fd, Arm, Champs) ->
    Results = [decode_champion(Arm, maps:get(genome, C)) || C <- Champs],
    StateAucs = [S || {S, _, _} <- Results],
    SensorAucs = [Se || {_, Se, _} <- Results],
    TimeAucs = [Ti || {_, _, Ti} <- Results],
    emit(Fd, "EXP047 arm=~p state_auc=~.3f(sd~.3f) | sensor_auc=~.3f (endogenous) | "
             "time_ctrl=~.3f~n",
         [Arm, mean(StateAucs), sd_of(StateAucs), mean(SensorAucs), mean(TimeAucs)]),
    #{state_auc => mean(StateAucs), sensor_auc => mean(SensorAucs),
      time_auc => mean(TimeAucs), state_sd => sd_of(StateAucs)}.

%%%============================================================================
%%% Verdict against the pre-registered decision rule
%%%============================================================================
verdict(Fd, Decoded, Disagree) ->
    D = maps:from_list(Decoded),
    FixedAuc = maps:get(state_auc, maps:get(fixed, D)),
    TimeCtrl = mean([maps:get(time_auc, maps:get(A, D)) || A <- ?ARMS]),
    Adaptive = [maps:get(state_auc, maps:get(A, D)) || A <- ?ADAPTIVE],
    Spread = lists:max(Adaptive) - lists:min(Adaptive),
    emit(Fd, "~n-- Verdict (pre-registered; split fixed, sensor criterion dropped) --~n"),
    emit(Fd, "fixed sentinel state_auc=~.3f (must be ~~0.5; >0.6 => INVALID)~n", [FixedAuc]),
    emit(Fd, "time-control auc=~.3f (must be ~~0.5; >0.6 => split still time-confounded, INVALID)~n",
         [TimeCtrl]),
    emit(Fd, "adaptive state_aucs=~p spread=~.3f~n", [[round3(A) || A <- Adaptive], Spread]),
    emit(Fd, "per-step disagreement=~.3f (need >0.15 for SURVIVES)~n", [Disagree]),
    emit(Fd, "~s~n", [classify(FixedAuc, TimeCtrl, Adaptive, Spread, Disagree)]).

classify(FixedAuc, _TimeCtrl, _Adaptive, _Spread, _Dis) when FixedAuc > 0.6 ->
    "RESULT=INVALID: fixed sentinel decodes above chance; decoder leaking, fix before signing.";
classify(_FixedAuc, TimeCtrl, _Adaptive, _Spread, _Dis) when TimeCtrl > 0.6 ->
    "RESULT=INVALID: time-control decodes above chance; split still confounded with episode time.";
classify(_FixedAuc, _TimeCtrl, Adaptive, Spread, Dis) ->
    AllTrack = lists:all(fun(A) -> A >= 0.75 end, Adaptive),
    branch(AllTrack, Spread, Dis).

branch(false, _Spread, _Dis) ->
    "RESULT=FALSIFIED: at least one substrate does NOT track (AUC<0.75); it solves via the "
    "reactive path, not its evolving state. The low-pass explanation does not apply to it.";
branch(true, Spread, _Dis) when Spread >= 0.10 ->
    "RESULT=FALSIFIED: substrates track but UNEQUALLY (spread>=0.10); action convergence was "
    "coincidence, not low-pass averaging. Retract 'mechanisms converge internally'.";
branch(true, _Spread, Dis) when Dis < 0.15 ->
    "RESULT=FALSIFIED: substrates track EQUALLY and per-step estimates AGREE (disagreement<0.15) "
    "-- nothing for integration to average away; 045's low-pass story explains nothing.";
branch(true, _Spread, _Dis) ->
    "RESULT=SURVIVES: all substrates track (AUC>=0.75), track EQUALLY (spread<0.10), yet per-step "
    "estimates DIFFER (disagreement>0.15) -- exactly what the low-pass story predicts.".

round3(X) -> round(X * 1000) / 1000.

%%%============================================================================
%%% emit: write to feed file AND stdout (stdout shown under erl -noshell)
%%%============================================================================
emit(Fd, Fmt) -> emit(Fd, Fmt, []).

emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).

%%%============================================================================
%%% Validation entry point (cheap): dims + a 2-run convergence smoke per arm
%%%============================================================================
validate() ->
    io:format("~n== dim check (043 feed: fixed 51 nm_global 56 cfc 61 nm_pc 212) ==~n"),
    [io:format("  ~p dim=~p~n", [A, arm_dim(A)]) || A <- ?ARMS],
    io:format("~n== convergence smoke (2 runs/arm) ==~n"),
    [smoke(A) || A <- ?ARMS],
    ok.

smoke(Arm) ->
    Champs = evolve_arm(Arm, 2),
    Fits = [maps:get(fitness, C) || C <- Champs],
    io:format("  ~p mean_fitness=~.1f~n", [Arm, mean(Fits)]).

%%%============================================================================
%%% eunit entry
%%%============================================================================
probe_test_() ->
    {timeout, 14400, fun run_full/0}.
