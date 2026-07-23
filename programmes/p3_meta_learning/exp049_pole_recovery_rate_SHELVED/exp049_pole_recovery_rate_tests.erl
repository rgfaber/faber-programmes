%%%-------------------------------------------------------------------
%%% @doc EXP-049 — pole recovery rate (046 hardening, gate-redesigned).
%%%
%%% Pre-registration: experiments/exp049_pole_recovery_rate.md
%%% Run: erl -noshell -pa <ebins> -eval 'exp049_pole_recovery_rate_tests:run(), init:stop().'
%%%
%%% Does reward-modulated plasticity RECOVER a hidden motor reversal on a windy
%%% pole because of DEPLOYMENT-TIME adaptation, or is 046's claim an artifact of
%%% evolvability / a co-adapted null / a timing leak? Per the DESIGN gate:
%%%   - evolve on WIND-ONLY (no reversal); impose the reversal only at DEPLOYMENT
%%%   - deployment battery: K varied trials, reversal time hidden + randomised
%%%   - nm_clamp null: plasticity identical up to the reversal, then weights frozen
%%%     (paired with nm_live within the same champion and same trial)
%%%   - recovered = survives AND re-stabilises (angle returns under a band and holds)
%%%
%%% Accessors only; self-contained runner (permanent record).
%%% @end
%%%-------------------------------------------------------------------
-module(exp049_pole_recovery_rate_tests).

-export([run/0, run/1, validate/0]).

-define(INPUTS, 4).
-define(HIDDEN, 8).
-define(OUTPUTS, 1).
-define(GOAL, 400).
-define(WIND, 5.0).
-define(SHIFT_GAIN, -1.0).
-define(N_RUNS, 20).
-define(MAX_GEN, 100).
-define(FITNESS_GOAL, 400.0).
-define(M_EVOLVE, 5).            %% wind-only varied trials per fitness eval (no reversal)
-define(K_DEPLOY, 50).           %% deployment trials per champion (with reversal)
-define(REV_MIN, 80).
-define(REV_MAX, 200).
-define(ANGLE_MIN, 0.035).       %% ~2.0 deg
-define(ANGLE_MAX, 0.087).       %% ~5.0 deg
-define(CART_RANGE, 0.5).
-define(RESTAB_BAND, 0.35).      %% scaled |angle| ceiling in the tail window
-define(RESTAB_W, 80).           %% steps after the reversal before the tail window
-define(EVOLVED_ARMS, [fixed, cfc, nm]).
-define(FEED, "exp049_feed.txt").
-define(CHAMPS, "exp049_champions.eterm").

%%%============================================================================
%%% Entry
%%%============================================================================
run() -> run(#{n_runs => ?N_RUNS, k => ?K_DEPLOY}).

validate() -> run(#{n_runs => 3, k => 12}).

run(#{n_runs := NRuns, k := K}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-049 pole recovery rate (046 hardening, gate-redesigned) ==~n", []),
    emit(Fd, "evolve WIND-ONLY (no reversal); impose reversal only at deployment~n"),
    emit(Fd, "config: n_runs=~p K=~p rev_time[~p,~p] wind=~.1f goal=~p restab(band=~.2f,W=~p)~n",
         [NRuns, K, ?REV_MIN, ?REV_MAX, ?WIND, ?GOAL, ?RESTAB_BAND, ?RESTAB_W]),
    emit(Fd, "dims: fixed=~p cfc=~p nm=~p (must be 49/57/54)~n",
         [arm_dim(fixed), arm_dim(cfc), arm_dim(nm)]),
    Champs = phase1_evolve(Fd, NRuns),
    ok = file:write_file(?CHAMPS, term_to_binary(Champs)),
    DeployConds = gen_conditions(K, {999, 1}, reversal),
    phase2_deploy(Fd, Champs, DeployConds),
    file:close(Fd),
    ok.

%%%============================================================================
%%% Phase 1: evolve wind-only (varied init/cart/wind-sign, NO reversal)
%%%============================================================================
phase1_evolve(Fd, NRuns) ->
    emit(Fd, "~n-- Phase 1: evolve wind-only, ~p runs/arm (max_gen=~p) --~n", [NRuns, ?MAX_GEN]),
    [{Arm, [evolve_one(Fd, Arm, R) || R <- lists:seq(1, NRuns)]} || Arm <- ?EVOLVED_ARMS].

evolve_one(Fd, Arm, RunIdx) ->
    Conds = gen_conditions(?M_EVOLVE, {RunIdx, 42}, no_reversal),
    F = fun(G) -> mean([survival(deploy_mode(Arm), G, C) || C <- Conds]) end,
    Opts = #{max_generations => ?MAX_GEN, fitness_goal => ?FITNESS_GOAL, init_sigma => 1.0},
    Result = sep_cma_es:evolve(F, arm_dim(Arm), Opts),
    Fit = maps:get(fitness, Result),
    emit(Fd, "EXP049 evolve arm=~p run=~p wind_only_survival=~.1f reason=~p~n",
         [Arm, RunIdx, Fit, maps:get(reason, Result)]),
    #{arm => Arm, run => RunIdx, fitness => Fit, genome => maps:get(best, Result)}.

%% For evolution nm uses live plasticity; fixed/cfc as-is.
deploy_mode(fixed) -> fixed;
deploy_mode(cfc) -> cfc;
deploy_mode(nm) -> nm_live.

%%%============================================================================
%%% Phase 2: deployment battery (reversal imposed here, hidden + randomised)
%%%============================================================================
phase2_deploy(Fd, Champs, Conds) ->
    emit(Fd, "~n-- Phase 2: deployment battery (K=~p, reversal hidden) --~n", [length(Conds)]),
    emit(Fd, "  recovered = survives to goal AND |angle| tail-max <= ~.2f after reversal+~p~n~n",
         [?RESTAB_BAND, ?RESTAB_W]),
    Probs = arm_probs(Champs, Conds),
    report_arm(Fd, fixed, maps:get(fixed, Probs)),
    report_arm(Fd, cfc, maps:get(cfc, Probs)),
    report_arm(Fd, nm_live, maps:get(nm_live, Probs)),
    report_arm(Fd, nm_clamp, maps:get(nm_clamp, Probs)),
    verdict(Fd, Probs).

arm_probs(Champs, Conds) ->
    Fixed = [champion_prob(fixed, G, Conds) || G <- genomes(fixed, Champs)],
    Cfc = [champion_prob(cfc, G, Conds) || G <- genomes(cfc, Champs)],
    NmG = genomes(nm, Champs),
    Live = [champion_prob(nm_live, G, Conds) || G <- NmG],
    Clamp = [champion_prob(nm_clamp, G, Conds) || G <- NmG],
    #{fixed => Fixed, cfc => Cfc, nm_live => Live, nm_clamp => Clamp}.

genomes(Arm, Champs) ->
    {Arm, Cs} = lists:keyfind(Arm, 1, Champs),
    [maps:get(genome, C) || C <- Cs].

%% Per-champion {survival_prob, recovery_prob} over the K deployment conditions.
champion_prob(Mode, Genome, Conds) ->
    Outs = [outcome(Mode, Genome, C) || C <- Conds],
    N = length(Conds),
    {length([1 || {true, _} <- Outs]) / N, length([1 || {_, true} <- Outs]) / N}.

rec_probs(Pairs) -> [R || {_S, R} <- Pairs].
surv_probs(Pairs) -> [S || {S, _R} <- Pairs].

report_arm(Fd, Label, Pairs) ->
    Rec = rec_probs(Pairs),
    Surv = surv_probs(Pairs),
    emit(Fd, "EXP049 arm=~p survival_prob mean=~.3f | recovery_prob mean=~.3f sd=~.3f "
             "max=~.3f (n=~p)~n",
         [Label, mean(Surv), mean(Rec), sd_of(Rec), lists:max(Rec), length(Rec)]).

%%%============================================================================
%%% Verdict (paired nm_live vs nm_clamp is the headline; vs fixed secondary)
%%%============================================================================
verdict(Fd, Probs) ->
    Live = rec_probs(maps:get(nm_live, Probs)),
    Clamp = rec_probs(maps:get(nm_clamp, Probs)),
    Fixed = rec_probs(maps:get(fixed, Probs)),
    Diffs = [L - C || {L, C} <- lists:zip(Live, Clamp)],
    Pos = length([1 || D <- Diffs, D > 0]),
    {Lo, Hi} = bootstrap_ci(Diffs),
    Gap = mean(Diffs),
    FixedGap = mean(Live) - mean(Fixed),
    emit(Fd, "~n-- Verdict (paired nm_live vs nm_clamp) --~n"),
    emit(Fd, "nm_live-nm_clamp per-champion gap: mean=~.3f 99% CI=[~.3f,~.3f] positive=~p/~p~n",
         [Gap, Lo, Hi, Pos, length(Diffs)]),
    emit(Fd, "nm_live-fixed gap: ~.3f (nm_live ~.3f vs fixed ~.3f)~n",
         [FixedGap, mean(Live), mean(Fixed)]),
    emit(Fd, "~s~n", [classify(Gap, Lo, FixedGap)]).

classify(Gap, Lo, FixedGap) when Gap >= 0.25, Lo > 0.10, FixedGap >= 0.10 ->
    "RESULT=046 CONFIRMED: switching adaptation off (clamp) drops recovery by a paired mean "
    ">=0.25 (99% CI above 0.10), and nm_live beats the fixed null. Deployment-time adaptation "
    "causes the recovery.";
classify(Gap, _Lo, _FixedGap) when Gap < 0.10 ->
    "RESULT=046 OVERSTATED: clamping adaptation off barely changes recovery (paired gap <0.10); "
    "the evolved base policy, not deployment-time adaptation, does the work. Scope 046 down.";
classify(_Gap, _Lo, _FixedGap) ->
    "RESULT=PARTIAL: adaptation contributes but does not clear the pre-registered bars; report "
    "the gap and CI as the graded result, do not claim 'reliable'.".

%% Percentile bootstrap over champions (resample the paired diffs). Deterministic seed.
bootstrap_ci(Diffs) ->
    rand:seed(exsss, {4949, 1, 1}),
    N = length(Diffs),
    Means = lists:sort([mean([lists:nth(rand:uniform(N), Diffs) || _ <- lists:seq(1, N)])
                        || _ <- lists:seq(1, 2000)]),
    {pct(Means, 0.005), pct(Means, 0.995)}.

pct(Sorted, P) -> lists:nth(max(1, round(P * length(Sorted))), Sorted).

%%%============================================================================
%%% Recovery of one deployment trial: survives to goal AND re-stabilises
%%%============================================================================
outcome(Mode, Genome, {_A, _C, _W, RevTime} = Cond) ->
    {Steps, Angles, _WChange} = run_episode(Mode, Genome, Cond),
    Tail = [Tilt || {T, Tilt} <- Angles, T >= RevTime + ?RESTAB_W],
    Surv = survived(Steps),
    {Surv, Surv andalso restabilised(Tail)}.

survived(Steps) -> Steps >= ?GOAL.

restabilised([]) -> false;
restabilised(Tail) -> lists:max(Tail) =< ?RESTAB_BAND.

%%%============================================================================
%%% Episode: returns {Steps, [{T, |scaled angle|}], WeightChange}
%%%============================================================================
survival(Mode, Genome, Cond) ->
    {Steps, _Angles, _W} = run_episode(Mode, Genome, Cond),
    float(Steps).

run_episode(Mode, Genome, {Angle, Cart, WindSign, RevTime}) ->
    Net = build_net(base_arm(Mode), Genome),
    Ov = [{p1_angle, Angle}, {cpos, Cart}, {wind, WindSign * ?WIND},
          {shift_at, RevTime}, {shift_gain, ?SHIFT_GAIN}],
    ep_loop(Mode, Net, pb_sim:init(Ov), 0, RevTime, undefined, undefined, []).

ep_loop(Mode, Net, S, T, RevTime, PrevTilt, WSnap, Angles) ->
    {Inputs, S1} = pb_sim:sense(sensor, [?INPUTS], S),
    CurTilt = abs(lists:nth(3, Inputs)),
    {Output, Net1, WSnap1} = fwd(Mode, Net, Inputs, T, RevTime, PrevTilt, CurTilt, WSnap),
    {_F, Done, S2} = pb_sim:act(actuator, [without_damping, 0, ?GOAL], Output, S1),
    Angles1 = [{T, CurTilt} | Angles],
    ep_continue(Done, Mode, Net1, S2, T + 1, RevTime, CurTilt, WSnap1, Angles1).

ep_continue(0, Mode, Net, S, T, RevTime, PrevTilt, WSnap, Angles) ->
    ep_loop(Mode, Net, S, T, RevTime, PrevTilt, WSnap, Angles);
ep_continue(_Done, _Mode, Net, _S, T, _RevTime, _PT, WSnap, Angles) ->
    {T, lists:reverse(Angles), wchange(Net, WSnap)}.

%% Per-mode forward step; snapshot weights at the reversal step for nm arms.
fwd(fixed, Net, Inputs, _T, _Rev, _PT, _CT, WSnap) ->
    {network_evaluator:evaluate(Net, Inputs), Net, WSnap};
fwd(cfc, Net, Inputs, _T, _Rev, _PT, _CT, WSnap) ->
    {Out, Net1} = network_evaluator:evaluate_with_state(Net, Inputs),
    {Out, Net1, WSnap};
fwd(nm_live, {Net, Rule}, Inputs, T, Rev, PT, CT, WSnap) ->
    {Out, Net1} = network_evaluator:evaluate_with_neuromod(Net, Inputs, Rule, modulator(PT, CT)),
    {Out, {Net1, Rule}, snap(WSnap, Net, T, Rev)};
fwd(nm_clamp, {Net, Rule}, Inputs, T, Rev, PT, CT, WSnap) ->
    clamp_fwd(T < Rev, {Net, Rule}, Inputs, T, Rev, PT, CT, WSnap).

%% Before the reversal: plastic (identical to nm_live). At/after: weights frozen.
clamp_fwd(true, {Net, Rule}, Inputs, _T, _Rev, PT, CT, WSnap) ->
    {Out, Net1} = network_evaluator:evaluate_with_neuromod(Net, Inputs, Rule, modulator(PT, CT)),
    {Out, {Net1, Rule}, WSnap};
clamp_fwd(false, {Net, Rule}, Inputs, T, Rev, _PT, _CT, WSnap) ->
    {network_evaluator:evaluate(Net, Inputs), {Net, Rule}, snap(WSnap, Net, T, Rev)}.

modulator(undefined, _CurTilt) -> 0.0;
modulator(PrevTilt, CurTilt) -> math:tanh(5.0 * (PrevTilt - CurTilt)).

%% Snapshot the plastic weights once, at the first step >= the reversal (Net is a raw net).
snap(undefined, Net, T, Rev) when T >= Rev -> network_evaluator:get_weights(Net);
snap(WSnap, _Net, _T, _Rev) -> WSnap.

wchange(_Net, undefined) -> 0.0;
wchange({Net, _Rule}, WSnap) -> vnorm(vsub(network_evaluator:get_weights(Net), WSnap));
wchange(Net, WSnap) -> vnorm(vsub(network_evaluator:get_weights(Net), WSnap)).

base_arm(fixed) -> fixed;
base_arm(cfc) -> cfc;
base_arm(nm_live) -> nm;
base_arm(nm_clamp) -> nm.

%%%============================================================================
%%% Conditions: {Angle, Cart, WindSign, RevTime}. no_reversal -> RevTime huge.
%%%============================================================================
gen_conditions(N, Seed, Mode) ->
    rand:seed(exsss, seed_triple(Seed)),
    [one_condition(Mode) || _ <- lists:seq(1, N)].

seed_triple({A, B}) -> {A, B, 991}.

one_condition(Mode) ->
    Angle = ?ANGLE_MIN + rand:uniform() * (?ANGLE_MAX - ?ANGLE_MIN),
    Sign = sign_of(rand:uniform()),
    Cart = (rand:uniform() - 0.5) * 2 * ?CART_RANGE,
    Wind = sign_of(rand:uniform()),
    {Angle * Sign, Cart, Wind, rev_time(Mode)}.

sign_of(U) when U < 0.5 -> -1.0;
sign_of(_U) -> 1.0.

rev_time(no_reversal) -> 1000000000;
rev_time(reversal) -> ?REV_MIN + rand:uniform(?REV_MAX - ?REV_MIN + 1) - 1.

%%%============================================================================
%%% Network construction ([4,8,1]; accessors only)
%%%============================================================================
net_params() -> ?HIDDEN * ?INPUTS + ?HIDDEN + ?OUTPUTS * ?HIDDEN + ?OUTPUTS.

arm_dim(fixed) -> net_params();
arm_dim(cfc) -> net_params() + ?HIDDEN;
arm_dim(nm) -> net_params() + 5.

build_net(fixed, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, []} = lists:split(net_params(), G),
    network_evaluator:set_weights(Base, W);
build_net(cfc, G) ->
    Base = network_evaluator:create_cfc_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, Taus} = lists:split(net_params(), G),
    Net1 = network_evaluator:set_weights(Base, W),
    Meta = network_evaluator:get_neuron_meta(Net1),
    network_evaluator:set_neuron_meta(Net1, set_taus(Meta, Taus));
build_net(nm, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, [A, B, C, D, Eta]} = lists:split(net_params(), G),
    {network_evaluator:set_weights(Base, W), {A, B, C, D, Eta}}.

set_taus([HiddenMeta, OutputMeta], Taus) ->
    [[M#{tau => clamp_tau(T)} || {M, T} <- lists:zip(HiddenMeta, Taus)], OutputMeta].

clamp_tau(T) -> max(0.1, min(2.0, 0.1 + abs(T))).

%%%============================================================================
%%% Small numerics
%%%============================================================================
vsub(A, B) -> [X - Y || {X, Y} <- lists:zip(A, B)].
vnorm(A) -> math:sqrt(lists:sum([X * X || X <- A])).

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

sd_of([]) -> 0.0;
sd_of(L) ->
    M = mean(L),
    math:sqrt(mean([(X - M) * (X - M) || X <- L])).

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
