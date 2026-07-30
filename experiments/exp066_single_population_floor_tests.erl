%%%-------------------------------------------------------------------
%%% @doc EXP-066 -- Robo Rumble phase 0: the COMPETENCE FLOOR gate.
%%%
%%% Pre-registration (DESIGN-gated, BUILD_WITH_CHANGES, amendments applied):
%%% exp066_single_population_floor.md. That document is binding; this runner
%%% implements it and invents nothing.
%%%
%%% THE QUESTION, asked symmetrically. Does single-population evolution against
%%% the scripted gauntlet produce a controller that reliably beats the floor bot
%%% predictive_gun, or does it fail to, and by what pre-registered measurement
%%% would we tell the two apart from an instrument that never asked the
%%% question? Only CLEARED unlocks phase 1. PARTIAL, INCONCLUSIVE, FAILED and
%%% UNGRADEABLE all stop the front and prescribe different next moves.
%%%
%%% WHY THE GATE EXISTS. PLAN_ROBO_RUMBLE.md section 2: absence of cycling is
%%% uninterpretable below a competence floor, because at low competence a tank
%%% arena is transitive, so a null there is a statement about the OPTIMISER and
%%% not about the SUBSTRATE. That is the search under-convergence confound the
%%% closed Flatland programme left open.
%%%
%%% WHAT THIS FILE OWNS
%%%   1. The evolved controller (the pilot): 17 integer channels in, 5 outputs
%%%      onto an intent record, driven through robo_net's integer forward pass.
%%%   2. The deterministic 120-start generator and its train / held-out /
%%%      calibration split.
%%%   3. The match loop, which pins the perception contract.
%%%   4. The lazy ladder fitness, graded on damage MARGIN in arena fixed point,
%%%      never on energy and never on survival time.
%%%   5. The arms, the frozen constants, the decision rule and the twelve
%%%      instrument-failure codes.
%%%
%%% WHAT THIS FILE DOES NOT TOUCH. robo_sim, robo_net, robo_gauntlet and
%%% robo_match are consumed, never modified, so robo_match_tests' golden match
%%% vector still holds; gate 1 below asserts it by recomputation.
%%%
%%% DEVIATION FROM THE PRE-REGISTRATION, recorded rather than hidden. The
%%% pre-registration places the controller in a new faber-tweann module named
%%% robo_pilot and names the runner exp066_competence_floor_tests. No such
%%% engine module exists at the pinned commit and the engine pin is the
%%% provenance, so the controller lives here, in ONE module, with the perception
%%% boundary enforced by the same code shape robo_gauntlet:act/4 uses. Moving it
%%% into the engine later is a pin bump plus a file move, and nothing about the
%%% measurement changes. The runner name follows the task instruction.
%%%
%%% THE PERCEPTION BOUNDARY IS A SHAPE, NOT A COMMENT. pilot_act/4 destructures
%%% the arena to its scans field and to nothing else, then filters those scans to
%%% the acting tank's own observer id. The tanks and bullets lists are therefore
%%% NOT IN SCOPE below that line, so an opponent's tank record cannot be read
%%% from pilot_decide/3 even by accident. This is stated here because the task
%%% asked for it to be stated, but the defence is the destructuring, not this
%%% paragraph.
%%%
%%% DETERMINISM. The match path is integer only: no float, no libm, no clock, no
%%% rand, no process and no ETS below pilot_act/4. robo_net:quantize/1 is the ONE
%%% float boundary and it runs at phenotype build time, inside the fitness and
%%% outside the match. Everything hashed is flattened to tuples and lists,
%%% because term_to_binary is not canonical for maps and that has already bitten
%%% this front once.
%%%
%%% THE SCORING TRAP, ALREADY MEASURED. robo_gauntlet budgets every gun so a bot
%%% that is MISSING decays toward its fire floor while a bot that NEVER FIRES
%%% keeps a full bar, so ANY energy-derived fitness structurally rewards not
%%% shooting. The fitness here never reads energy and never reads survival time.
%%% @end
%%%-------------------------------------------------------------------
-module(exp066_single_population_floor_tests).

%% Kill gates and cheap instrument checks. Exported separately from the study so
%% they can be run BEFORE any compute is committed.
-export([crossplay/0, crossplay/1]).
%% The post-hoc addendum: the dropped won_opp_shots column and arm C's attempt
%% accounting, recomputed from the archive and APPENDED to the feed.
-export([addendum/0, addendum/1]).
%% The two flag fixes: IF-10 widened, and PH-GEN, a NEW post-hoc generalisation
%% diagnostic that is NOT a repair of IF-8. Both recomputed from the archive.
-export([flag_fixes/0, flag_fixes/1]).
%% The rates scripted_null/1 threw away, recovered, plus the search for an
%% intransitivity anchor built only from pre-registered measurements, plus the
%% corrected match-level null beside the as-built one.
-export([recovered/0, recovered/1]).
-export([gates/0, gates/1]).
%% Protocol step 2: the frozen constants. Scripted bots only, no pilot involved.
-export([constants/0, constants/1]).
%% Kill gate 0b: the hand-CONSTRUCTED weight vector driven through the pilot.
-export([arm_c/0, arm_c/1, arm_c_gains/0, arm_c_weights/1]).
%% The study.
-export([run/0, run/1, pilot/0, defaults/0, pilot_opts/0]).
%% The start generator and the archive format, exposed for later phases.
-export([inputs/0, starts/0, split/1, champion_id/1, champion_write/2]).
%% THE OWED EQUIVALENCE REPLAY, and the ONLY reason this line exists. robo_pilot
%% claims to be this runner's controller moved into the engine library, character
%% for character. Testing that claim requires running THIS runner's own pilot
%% beside the extracted one, and a test that instead re-copied these bodies into a
%% third file would be comparing a copy against a copy and would prove nothing.
%% exp066_pilot_extraction_equivalence_tests is the only caller.
%%
%% AN EXPORT LIST CANNOT CHANGE BEHAVIOUR. No body below is touched, no constant
%% moves, and every number this runner has already produced stands. The addition
%% is recorded in exp066_pilot_extraction_equivalence.txt rather than left for a
%% reader to notice in a diff.
-export([pilot_init/0, pilot_act/4, channels/2, heldout/3, rates/1, win_rate/1]).

-include_lib("faber_tweann/include/robo_sim.hrl").

%%%============================================================================
%%% Engine constants, mirrored. Every one of these is a robo_sim value that
%%% robo_sim does not export; each is named here once so no magic number appears
%%% in the channel encodings below.
%%%============================================================================
-define(INPUTS, 17).
%% The ONE topology arm_c_weights/1 can build. It emits one bias plus 17 weights
%% per output neuron, so it is [17,5] by construction and nothing else.
-define(C_LAYERS, [17, 5]).
-define(FP, 256).                %% arena fixed-point scale
-define(SIN_SCALE, 32768).       %% the engine's sine scale
-define(TANK_R, 4608).           %% 18 whole units
-define(BAR, 25600).             %% robo_sim START_ENERGY: the death floor
-define(ORBIT, 51200).           %% 200 whole units, the gauntlet's own orbit range
-define(WALL_SPAN, 32768).       %% 128 whole units of clearance reads danger 0
-define(W_CLAMP, 2048).          %% robo_net:weight_limit(), restated for IF-4

%% The five rungs, lowest first, exactly robo_gauntlet:kinds/0.
-define(FLOOR, predictive_gun).

%% Determinism of the harness itself (not the match path).
-define(BOOT_SEED, 66).
-define(BOOT_N, 10000).
-define(NEG_INF, -1.0e308).
%% The cross-play probe's synthetic nulls and its subsampling are the only places
%% in this runner where a REPORTED number comes off rand, so the seed is fixed and
%% named: the probe's report must be reproducible from the archived champions.
-define(XP_SEED, 660).

%% robo_match_tests' golden match vector, restated so this runner asserts by
%% RECOMPUTATION that the engine is untouched rather than trusting that it is.
-define(GOLDEN_MATCH,
        <<"DFCD8106EDC9AE214F6AE99BB5F4988FE441243284A6D3769634D778B3895E88">>).

%%%============================================================================
%%% Records. Records, never maps, for anything that is threaded through a match
%%% or hashed.
%%%============================================================================

%% What the pilot remembers between turns. All integer, carried by value exactly
%% as robo_gauntlet's own bot record is.
%%
%% Two contacts are kept, not one, because a velocity estimate is a difference of
%% successive positions and there is nothing else in this substrate to
%% difference. The tick of each is stored so the GAP is known: scans arrive only
%% when the radar sweeps, so successive sightings are not one turn apart and
%% dividing by a presumed gap of one reports a velocity several times too large.
-record(pilot, {
    tick = 0 :: non_neg_integer(),
    seen = 0 :: 0..2,                %% 0 none, 1 position, 2 also velocity
    age = 0 :: non_neg_integer(),    %% turns since the latest contact
    dist = 0 :: integer(),           %% range at the latest contact, fixed point
    ex = 0 :: integer(),             %% latest contact position, absolute
    ey = 0 :: integer(),
    etick = 0 :: non_neg_integer(),
    px = 0 :: integer(),             %% previous contact position, absolute
    py = 0 :: integer(),
    ptick = 0 :: non_neg_integer(),
    prev_e = ?BAR :: integer(),      %% own energy last turn
    d_e = 0 :: integer(),            %% own energy change since last turn
    target = none :: term()
}).

%% One match in flight. probe is off, or an accumulator for the channel-range
%% diagnostic; it is the only branch in the loop and it is a function clause.
-record(mrun, {
    pid = a :: term(),               %% the SUBJECT's seat; outcomes report from it
    ctl = [] :: list(),
    pulls = 0 :: non_neg_integer(),  %% commanded fire greater than zero
    shots = 0 :: non_neg_integer(),  %% gun_heat zero-to-nonzero: shots the engine took
    opp_shots = 0 :: non_neg_integer(),
    probe = off :: off | list()
}).

%% The per-run collector's state. mu_lambda_es exposes no trace, so wrapping the
%% fitness covers both optimiser arms uniformly.
-record(col, {
    lambda = 1 :: pos_integer(),
    checks = [] :: [pos_integer()],
    n = 0 :: non_neg_integer(),
    best = {none, ?NEG_INF} :: {none | [integer()], float()},
    marks = [] :: list(),
    block = [] :: list(),
    distinct = [] :: [non_neg_integer()],
    clamp = [] :: [float()]
}).

%% One seed's result. Every field goes into the raw feed: the exp064 gate found
%% the prior feed had kept 12 summary numbers and discarded the 72 per-run
%% values, leaving nothing re-analysable. That does not happen again.
-record(res, {
    arm, seed, layers, dim, evals, fit, q,
    w = 0.0, l = 0.0, d = 0.0,           %% held-out win / loss / draw rates
    margin = 0.0,                        %% mean held-out damage margin, whole units
    caps = 0.0,                          %% fraction of held-out matches at the turn cap
    shots = 0.0, pulls = 0.0,            %% per match, held-out
    won_opp_shots = 0.0,                 %% floor bot's shots in the champion's WON matches
    train_w = 0.0,                       %% train-split win rate, for IF-8
    distinct_last = 0,                   %% distinct quantised phenotypes, last generation
    clamp_last = 0.0,                    %% mean clamped-coordinate fraction, last generation
    clamp_frac = 0.0,                    %% the CHAMPION's coordinates at the clamp: IF-4
    profile = [],                        %% [{Kind, W, L, D}] over all five rungs
    marks = []                           %% [{Evaluations, HeldOutWinRate}]
}).

%%%============================================================================
%%% THE PILOT. One module, and the perception boundary is its shape.
%%%============================================================================

%% How many sensor channels the pilot emits. The runner ASSERTS a topology's
%% first width equals this, because robo_net:fit/2 silently pads or truncates and
%% a mismatch would never fail a test.
-spec inputs() -> pos_integer().
inputs() -> ?INPUTS.

pilot_init() -> #pilot{}.

%% THE PERCEPTION BOUNDARY. The arena is destructured to its scans field and to
%% NOTHING ELSE, so #arena.tanks and #arena.bullets are not in scope below this
%% line and an opponent's #tank{} record cannot be reached from pilot_decide/3.
%% The scans are then narrowed to the entries this tank observed. Identical in
%% shape to robo_gauntlet:act/4, deliberately: a comment would not survive
%% review, a shape the compiler can check does.
pilot_act(Net, State, #tank{id = Id} = Me, #arena{scans = Scans}) ->
    Mine = [S || {Observer, _T, _D, _V} = S <- Scans, Observer =:= Id],
    Next = pilot_observe(State, Me, Mine),
    {pilot_decide(Net, Next, Me), Next}.

%% Fold this turn's scans into memory. A silent turn ages the track, which is the
%% whole cost of pointing a radar at the wrong part of the arena.
pilot_observe(#pilot{tick = T, age = A} = S, Me, []) ->
    own_energy(S#pilot{tick = T + 1, age = A + 1}, Me);
pilot_observe(#pilot{tick = T} = S, #tank{x = MX, y = MY} = Me, Scans) ->
    {_O, Target, D, {DX, DY}} = nearest(Scans),
    own_energy(latch(S#pilot{tick = T + 1, age = 0, dist = D},
                     MX + DX, MY + DY, T, Target), Me).

%% Channel 4's source, and the ONLY proprioception of incoming fire that exists.
own_energy(#pilot{prev_e = P} = S, #tank{energy = E}) ->
    S#pilot{prev_e = E, d_e = E - P}.

%% Absolute contact position is own position plus the scan delta: a derivation
%% from two permitted facts, not a peek at the opponent's record. Switching
%% target id resets to a single sighting, so a velocity estimate can never
%% difference two DIFFERENT opponents.
latch(#pilot{target = Target} = S, X, Y, T, Target) ->
    #pilot{ex = EX, ey = EY, etick = ET, seen = N} = S,
    S#pilot{px = EX, py = EY, ptick = ET, ex = X, ey = Y, etick = T,
            seen = min(2, N + 1)};
latch(S, X, Y, T, Target) ->
    S#pilot{px = X, py = Y, ptick = T, ex = X, ey = Y, etick = T,
            seen = 1, target = Target}.

%% Nearest contact, strictly closer so ties keep list order, which the engine
%% fixes.
nearest([H | Rest]) -> lists:foldl(fun closer/2, H, Rest).

closer({_O, _T, D, _V} = C, {_BO, _BT, Best, _BV}) when D < Best -> C;
closer(_C, Best) -> Best.

%% Contact velocity per turn, by differencing the two latched positions.
%% Dividing by the GAP is arithmetic, not strategy, and it is mandatory. There is
%% NO trust window and NO gating, unlike robo_gauntlet:enemy_vel/1: a stale
%% estimate attenuates because the gap divides it, and channel 8 tells the net
%% how much to believe the track. That call belongs to evolution.
contact_vel(#pilot{seen = N}) when N < 2 -> {0, 0};
contact_vel(#pilot{ex = X, ey = Y, px = PX, py = PY, etick = T, ptick = P}) ->
    Gap = max(1, T - P),
    {(X - PX) div Gap, (Y - PY) div Gap}.

%%%----------------------------------------------------------------------------
%%% The 17 channels. Arena scale 256, every channel inside -256 to 256.
%%%----------------------------------------------------------------------------
channels(S, Me) -> own(S, Me) ++ place(Me) ++ contact(S, Me).

%% 1 own_speed, 2 own_energy, 3 gun_heat, 4 energy_delta.
%%
%% Engine velocity is always along the heading, so one scalar is all of own
%% motion. MAX_VEL 2048 maps to 256 exactly; START_ENERGY 25600 maps to 256; the
%% hottest reachable gun (power 30) reads 204, so channel 3's clamp never bites.
%% Channel 4 conflates being shot, hitting a wall, being rammed, paying to fire
%% and being paid for a hit: irreducible, since separating the causes needs
%% engine internals the boundary forbids.
own(#pilot{d_e = DE}, #tank{vel = V, energy = E, gun_heat = GH}) ->
    [V div 8, min(256, E div 100), min(256, GH div 2), clamp(DE div 16, 256)].

%% 5 pos_fwd, 6 pos_port, 7 wall_danger.
%%
%% Arena size is a rule of the game, not opponent state, so consulting it breaks
%% no perception rule (robo_gauntlet:wall_push/1 already does). Position is given
%% in BODY frame because acting on a world-frame position requires a rotation,
%% and a rotation is a product of activations that a fixed-topology MLP cannot
%% form. wall_danger is DANGER rather than clearance so the channel is SILENT in
%% the common case and does not perturb an untrained baseline.
place(#tank{x = X, y = Y, heading = H}) ->
    {W, A} = robo_sim:arena_size(),
    {FX, FY} = rotate(X - W div 2, Y - A div 2, H),
    [FX div 512, FY div 512, wall_danger(X, Y, W, A)].

wall_danger(X, Y, W, H) ->
    C = lists:min([X - ?TANK_R, W - ?TANK_R - X, Y - ?TANK_R, H - ?TANK_R - Y]),
    256 - min(256, max(0, C) * 256 div ?WALL_SPAN).

%% 8 contact_fresh, 9-14 the three bearing frames, 15 contact_prox,
%% 16 target_lateral, 17 target_range_rate.
%%
%% ALL EXACTLY ZERO when no contact has ever been seen, which combined with
%% robo_net's per-neuron bias makes "behave sensibly while blind" a learnable
%% bias term rather than a special case.
%%
%% THREE FRAMES, DELIBERATELY REDUNDANT. Recovering one frame from another is a
%% rotation, a rotation is a product of activations, and a fixed-topology MLP
%% cannot form products. Spending two channels to remove a multiplication the
%% architecture cannot perform is the correct trade every time: aiming, orbiting
%% and radar tracking each collapse to a single weight.
contact(#pilot{seen = 0}, _Me) -> lists:duplicate(10, 0);
contact(#pilot{age = A, dist = D} = S, #tank{heading = H, gun = G, radar = R} = Me) ->
    {UX, UY} = sight(S, Me),
    {BC, BS} = unit(UX, UY, H),
    {GC, GS} = unit(UX, UY, G),
    {RC, RS} = unit(UX, UY, R),
    {WC, WS} = unit(UX, UY, 0),
    {VX, VY} = contact_vel(S),
    [fresh(A), BC, BS, GC, GS, RC, RS,
     (256 * ?ORBIT) div (?ORBIT + D),
     clamp((WC * VY - WS * VX) div 2048, 256),
     clamp((WC * VX + WS * VY) div 2048, 256)].

%% 256 on a scan turn, 128 at eight turns, floor 1 at the cap. Exactly 0 if never
%% seen, and that zero is a structural sentinel, which is why this is only ever
%% reached from the seen-nonzero clause above.
fresh(A) -> 2048 div (8 + min(A, 1024)).

%% DEAD RECKONING IS IN, PREDICTION IS OUT. The bearing channels report the
%% contact's ESTIMATED POSITION NOW: latched position plus estimated velocity
%% times age, clamped to arena bounds. Keeping the sensor's meaning constant
%% across turns is what makes a radar track a track rather than a snapshot.
%% Solving flight time is strategy and is withheld; channels 16 and 17 let the
%% net learn the lead itself. This VOIDS any future claim that the controller
%% "learned to track" or "learned to handle intermittent observation".
sight(#pilot{ex = EX, ey = EY, age = A} = S, #tank{x = MX, y = MY}) ->
    {VX, VY} = contact_vel(S),
    {PX, PY} = inside(EX + VX * A, EY + VY * A),
    {PX - MX, PY - MY}.

inside(X, Y) ->
    {W, H} = robo_sim:arena_size(),
    {min(max(X, 0), W), min(max(Y, 0), H)}.

%% THE BEARING TRICK. No atan2 and none added: a scan carries a vector, never a
%% bearing. The delta is rotated into a part's frame against robo_sim's own sine
%% table, then BOTH components are divided by the octagonal norm OF THE ROTATED
%% VECTOR, recomputed rather than reused from the scan's Distance field, because
%% the octagonal metric is not rotation invariant. Max component is exactly 256,
%% so axis-aligned deltas sit exactly ON robo_net's contract edge rather than
%% inside it; the pair norm wobbles between 0.9318 and 1.0275, which is a bounded
%% deterministic gain modulation identical for every controller, not a direction
%% error. The scan's own Distance is used for channel 15, so the range the net
%% sees is the number the engine reported.
unit(UX, UY, A) ->
    {RX, RY} = rotate(UX, UY, A),
    scale_pair(RX, RY, robo_sim:dist({0, 0}, {RX, RY})).

scale_pair(_RX, _RY, 0) -> {0, 0};
scale_pair(RX, RY, N) -> {RX * 256 div N, RY * 256 div N}.

%% A world vector into a part's frame. Positive Y is to the LEFT of the part,
%% matching the engine's counter-clockwise-positive rotations.
rotate(DX, DY, A) ->
    C = robo_sim:cos(A),
    S = robo_sim:sin(A),
    {(DX * C + DY * S) div ?SIN_SCALE, (DY * C - DX * S) div ?SIN_SCALE}.

%%%----------------------------------------------------------------------------
%%% The 5 outputs
%%%
%%% From robo_net:eval_q12/3 so the last four bits are not thrown away, each
%%% through robo_net:to_range/2 with THE ENGINE'S OWN CLAMP as Max, so the
%%% network's reachable set is exactly the legal set and no output is wasted on
%%% values the engine will refuse.
%%%
%%% FIRING IS ONE CONTINUOUS OUTPUT AND THE THRESHOLD IS THE ENGINE'S.
%%% robo_sim:clamp_power/1 already reads anything at or below zero as hold and
%%% anything above as a power in tenths, so to_range(A, 30) covers hold and every
%%% power on one monotone axis with NO hand-chosen constant and no second output.
%%% Do NOT add a hold-biased encoding or a separate fire-decision output: the
%%% recorded hazard on this front runs the other way, "never fire" is the strong
%%% local optimum, and a neutral untrained prior is a mild counterweight.
%%%----------------------------------------------------------------------------
pilot_decide({Layers, Ws}, S, Me) ->
    intent(robo_net:eval_q12(Layers, Ws, channels(S, Me))).

intent([A, B, C, D, E | _]) ->
    #intent{turn_body = robo_net:to_range(A, 7),
            turn_gun = robo_net:to_range(B, 14),
            turn_radar = robo_net:to_range(C, 32),
            accel = robo_net:to_range(D, 512),
            fire = robo_net:to_range(E, 30)};
intent(_Short) -> #intent{}.

clamp(V, Max) -> max(-Max, min(Max, V)).

%%%============================================================================
%%% THE START GENERATOR. One deterministic generator, integer only, no rand and
%%% no libm.
%%%
%%% THE HEADING OFFSET IS THE CORRECTION THAT MATTERS AND IT WAS MEASURED, NOT
%%% REASONED. Under an all-mutually-facing generator, predictive_gun against its
%%% own clone draws 106 of 160 with 70 percent of matches hitting the turn cap.
%%% With the per-index offset the same 80 geometries give 67 wins / 67 losses /
%%% 26 draws. The all-facing rule was manufacturing stalemates by starting the
%%% mirror match perfectly symmetric, and it would have left the primary endpoint
%%% 70 percent censored. The offset also kills a second degeneracy: with at least
%%% 8 angle units of offset on every start, no tank is ever bore-sighted at turn
%%% 1, so "fire straight ahead immediately" cannot clear rung 1 by itself.
%%% Because the offset is ONE RULE applied to all 120 indices, train and held-out
%%% remain exchangeable draws from a single distribution.
%%%============================================================================
-spec starts() -> [tuple()].
starts() -> [start(I) || I <- lists:seq(1, 120)].

start(I) ->
    AX = 60 + (I * 137) rem 681,
    AY = 60 + (I * 191) rem 481,
    {BX, BY} = separate(I, AX, AY, 0),
    Face = robo_gauntlet:angle_of({BX - AX, BY - AY}),
    {AX, AY, robo_sim:wrap(Face + off(I)),
     BX, BY, robo_sim:wrap(Face + 128 + off(I div 8 + 3))}.

%% B is walked by a fixed stride until the pair is at least 150 whole units
%% apart, so no match opens inside ram range (2 * TANK_R = 36). K IS BOUNDED, with
%% a deterministic reflection fallback, so the walk cannot fail to terminate.
separate(_I, AX, AY, K) when K > 64 -> {800 - AX, 600 - AY};
separate(I, AX, AY, K) ->
    BX = 60 + ((I * 251) + K * 97) rem 681,
    BY = 60 + ((I * 313) + K * 89) rem 481,
    far_enough(I, AX, AY, K, BX, BY, robo_sim:dist({AX, AY}, {BX, BY}) >= 150).

far_enough(_I, _AX, _AY, _K, BX, BY, true) -> {BX, BY};
far_enough(I, AX, AY, K, _BX, _BY, false) -> separate(I, AX, AY, K + 1).

off(I) -> element(1 + (I rem 8), {-96, -64, -32, -8, 8, 32, 64, 96}).

%% TRAIN 1..6, HELD-OUT 7..86 (THE GATE LIVES HERE), CALIBRATION 87..116 (used to
%% BUILD AND TUNE arm C and for nothing else), 117..120 generated and
%% deliberately unused.
-spec split(train | heldout | calibration) -> [tuple()].
split(train) -> lists:sublist(starts(), 1, 6);
split(heldout) -> lists:sublist(starts(), 7, 80);
split(calibration) -> lists:sublist(starts(), 87, 30).

take(L, N) -> lists:sublist(L, N).

train_starts(O) -> take(split(train), maps:get(train, O)).
heldout_starts(O) -> take(split(heldout), maps:get(heldout, O)).
calib_starts(O) -> take(split(calibration), maps:get(calibration, O)).

%%%============================================================================
%%% THE MATCH LOOP. The runner owns its own loop; robo_match:run/4 is
%%% gauntlet-only and is NOT modified.
%%%
%%% THE PERCEPTION CONTRACT, as robo_match pins it: act on the CURRENT arena,
%%% whose scans came from the step that produced these tanks, and only THEN step.
%%% A runner that steps first hands every controller a one-turn-stale world,
%%% silently, and nothing fails. Encoder state is threaded by value exactly as
%%% robo_gauntlet's bot record is. Only live tanks act. The runner reads RAW
%%% #tank.damage_dealt, never robo_match's whole-unit division, because a power
%%% 0.1 pellet does 0.4 damage and whole units report that as 0, and that dead
%%% zone sits exactly where cheap exploratory shooting lives.
%%%============================================================================

%% Both seats at one start, which is what a fair pairing means when the start
%% geometry is not symmetric. BOTH SEATS ALWAYS: robo_sim folds fire_all/2 and
%% first_hit/2 in tank list order, and 27 of 80 held-out starts show
%% circle_strafer versus predictive_gun differing by seat.
duel(Subject, Opp, Start) ->
    [play_seat(Subject, Opp, Start, a, off),
     play_seat(Subject, Opp, Start, b, off)].

play_seat(Subject, Opp, {AX, AY, AH, BX, BY, BH}, Seat, Probe) ->
    Arena = robo_sim:new([{a, AX, AY, AH}, {b, BX, BY, BH}]),
    play(Arena, #mrun{pid = Seat, ctl = seats(Seat, Subject, Opp), probe = Probe}).

seats(a, Subject, Opp) -> [{a, mk(Subject)}, {b, mk(Opp)}];
seats(b, Subject, Opp) -> [{a, mk(Opp)}, {b, mk(Subject)}].

mk({net, Layers, Ws}) -> {pilot, {Layers, Ws}, pilot_init()};
mk({script, Kind}) -> {script, Kind, robo_gauntlet:init(Kind)}.

play(Arena, R) -> play_step(Arena, R, robo_sim:finished(Arena)).

play_step(Arena, R, true) -> report(Arena, R);
play_step(Arena, R, false) ->
    Acted = [act_one(T, R#mrun.ctl, Arena) || T <- robo_sim:alive(Arena)],
    Next = robo_sim:step(Arena, [{Id, I} || {Id, I, _C} <- Acted]),
    play(Next, tick(R, Arena, Next, Acted)).

act_one(#tank{id = Id} = T, Ctl, Arena) ->
    {Id, C} = lists:keyfind(Id, 1, Ctl),
    {I, C2} = drive(C, T, Arena),
    {Id, I, C2}.

drive({script, Kind, S}, T, Arena) ->
    {I, S2} = robo_gauntlet:act(Kind, S, T, Arena),
    {I, {script, Kind, S2}};
drive({pilot, Net, S}, T, Arena) ->
    {I, S2} = pilot_act(Net, S, T, Arena),
    {I, {pilot, Net, S2}}.

tick(R, Arena, Next, Acted) ->
    Ctl = lists:foldl(fun({Id, _I, C}, Acc) -> lists:keystore(Id, 1, Acc, {Id, C}) end,
                      R#mrun.ctl, Acted),
    probe_acc(count_shots(count_pulls(R#mrun{ctl = Ctl}, Acted), Arena, Next),
              Arena, Acted).

count_pulls(R, Acted) -> pulls(R, lists:keyfind(R#mrun.pid, 1, Acted)).

pulls(R, {_Id, #intent{fire = F}, _C}) when F > 0 -> R#mrun{pulls = R#mrun.pulls + 1};
pulls(R, _Other) -> R.

%% SHOTS ACTUALLY FIRED, not trigger pulls: a gun_heat zero-to-nonzero
%% transition, since the engine refuses a hot or unaffordable shot.
count_shots(R, Before, After) ->
    R#mrun{shots = R#mrun.shots + fired(R#mrun.pid, Before, After),
           opp_shots = R#mrun.opp_shots + fired(other(R#mrun.pid), Before, After)}.

fired(Id, #arena{tanks = B}, #arena{tanks = A}) ->
    heat_step(lists:keyfind(Id, #tank.id, B), lists:keyfind(Id, #tank.id, A)).

heat_step(#tank{gun_heat = 0}, #tank{gun_heat = H}) when H > 0 -> 1;
heat_step(_B, _A) -> 0.

other(a) -> b;
other(b) -> a.

probe_acc(#mrun{probe = off} = R, _Arena, _Acted) -> R;
probe_acc(R, Arena, Acted) ->
    probe_one(R, Arena, lists:keyfind(R#mrun.pid, 1, Acted)).

probe_one(R, #arena{tanks = Ts}, {Id, _I, {pilot, _Net, S}}) ->
    R#mrun{probe = [{lists:keyfind(Id, #tank.id, Ts), S} | R#mrun.probe]};
probe_one(R, _Arena, _Other) -> R.

report(#arena{turn = Turn, tanks = Ts}, R) ->
    Me = lists:keyfind(R#mrun.pid, #tank.id, Ts),
    Opp = lists:keyfind(other(R#mrun.pid), #tank.id, Ts),
    #{dealt => Me#tank.damage_dealt,
      taken => Opp#tank.damage_dealt,
      alive => not Me#tank.dead,
      opp_alive => not Opp#tank.dead,
      turns => Turn,
      pulls => R#mrun.pulls,
      shots => R#mrun.shots,
      opp_shots => R#mrun.opp_shots,
      probe => R#mrun.probe}.

%%%============================================================================
%%% THE FITNESS: a ladder over the scripted gauntlet, graded on damage MARGIN,
%%% walked lazily. IT NEVER READS ENERGY AND IT NEVER READS SURVIVAL TIME.
%%%
%%% taken is the OPPONENT's damage_dealt, which in a duel is exactly the bullet
%%% damage the learner absorbed, so no engine counter is needed. robo_sim credits
%%% damage_dealt on bullet hits ONLY, never on rams or walls, so ram farming is
%%% impossible under this rule.
%%%
%%% WHY THE DEATH FLOOR IS NOT A TUNING KNOB. Raw margin pays a losing controller
%%% to end the match early, because dying truncates the damage the opponent can
%%% still inflict: a wall suicide takes 100 turns and concedes about half a bar,
%%% against the 1.04 bars that surviving and losing to the floor bot concedes.
%%% Flooring the loss at one bar makes dying weakly worse than surviving with the
%%% same damage taken, at every turn. The constant is the tank's own starting
%%% energy, not a chosen number.
%%%============================================================================
margin(#{dealt := D, taken := T, alive := true}) -> D - T;
margin(#{dealt := D, taken := T, alive := false}) -> D - max(T, ?BAR).

%% F = (rungs cleared, walking from the bottom) + squash(mean margin on the
%% frontier rung).
%%
%% cleared(Rung) iff EVERY match of that rung has margin greater than zero: a
%% sign test, no invented threshold. all for clearing and mean for the frontier
%% is deliberate, because a rung cleared on average is a rung with a geometry the
%% controller cannot handle, while the mean grades partial progress so the rung
%% is never a plateau.
%%
%% WALK FROM THE BOTTOM, STOP AT THE FIRST UNCLEARED RUNG. Two consequences.
%% Compute: nothing above the frontier is read, so nothing above it is simulated,
%% and this is EXACT, not an approximation. Anti-forgetting, which matters more:
%% a rung once cleared must STAY cleared or the count drops, so rung 5's "circle
%% and never fire" attractor cannot eat the marksmanship learned on the gunless
%% rungs. The never-fire optimum is fenced off, not argued away.
%%
%% NO SHAPING. No term for scans held, radar coverage, gun alignment, near
%% misses, shots fired or hits counted. The floor is defined by PREDICTION, and
%% every cheap intermediate signal available here is precisely what
%% circle_strafer does, which is measured at 0 wins in 160 against the floor bot.
%% A per-scan reward would be worse than useless: a radar sweeping at maximum
%% rate acquires MORE distinct contacts than a radar that locks.
ladder(Subject, Rungs, Starts) -> ladder(Subject, Rungs, Starts, 0, []).

ladder(_Subject, [], _Starts, N, []) -> N * 1.0;
%% Once the whole ladder is cleared the frontier becomes the WEAKEST rung by
%% mean, so a champion keeps being pushed on its worst opponent, not its best.
ladder(_Subject, [], _Starts, N, Means) -> N + squash(lists:min(Means));
ladder(Subject, [K | Rest], Starts, N, Means) ->
    Ms = [margin(O) || Start <- Starts, O <- duel(Subject, {script, K}, Start)],
    rung(lists:all(fun(M) -> M > 0 end, Ms), Subject, Rest, Starts, N, mean(Ms), Means).

rung(true, Subject, Rest, Starts, N, Mean, Means) ->
    ladder(Subject, Rest, Starts, N + 1, [Mean | Means]);
rung(false, _Subject, _Rest, _Starts, N, Mean, _Means) ->
    N + squash(Mean).

%% THE TAIL TERM IS AN ORDERING, NOT AN EXCHANGE RATE. Confined below 1.0, so
%% clearing a rung outranks every possible margin gain on it. This is sound ONLY
%% because both optimisers select by RANK: mu_lambda_es sorts and keeps the best
%% mu, sep_cma_es sorts and recombines the best mu, and neither reads a
%% magnitude. An optimiser that read magnitudes would silently turn this into a
%% weighted sum with weights nobody chose.
squash(M) -> (clampf(M, 2.0 * ?BAR) + 2.0 * ?BAR) / (4.0 * ?BAR + 1).

clampf(V, Max) -> max(-Max, min(Max, V)).

%% Arm D's fitness: rung 5 only, so F degenerates to plain margin and the
%% curriculum is removed entirely.
rungs(d) -> [?FLOOR];
rungs(_Arm) -> robo_gauntlet:kinds().

%%%============================================================================
%%% THE COLLECTOR. Checkpoints and the per-generation diagnostics, captured by
%%% wrapping the fitness with one send to a per-run process. mu_lambda_es exposes
%%% no trace, so the wrapper covers both arms uniformly.
%%%
%%% DISTINCT QUANTISED PHENOTYPES is recorded from the first run, not added after
%%% a null. quantize/1 puts the search on a finite integer lattice at scale 256
%%% with a hard clamp at plus or minus 2048, so once sep-CMA's per-coordinate
%%% sigma falls below about 1/256 every offspring collapses to the SAME
%%% phenotype, fitness goes constant, the selection differential vanishes and the
%%% covariance keeps contracting. A run ending that way looks exactly like a
%%% converged negative and is not one (IF-5).
%%%============================================================================
col_start(Lambda, Checks) ->
    spawn_link(fun() -> col_loop(#col{lambda = Lambda, checks = Checks}) end).

col_loop(C) ->
    receive
        {eval, Q, F} -> col_loop(col_eval(C, Q, F));
        {stop, From} -> From ! {col, col_final(C)}
    end.

col_eval(C, Q, F) ->
    N = C#col.n + 1,
    C2 = C#col{n = N, best = better(C#col.best, Q, F), block = [Q | C#col.block]},
    col_block(col_mark(C2, N), N).

better({BQ, BF}, _Q, F) when F =< BF -> {BQ, BF};
better(_Best, Q, F) -> {Q, F}.

col_mark(C, N) -> mark(C, N, lists:member(N, C#col.checks)).

mark(C, N, true) -> C#col{marks = [{N, C#col.best} | C#col.marks]};
mark(C, _N, false) -> C.

col_block(C, N) -> close_block(C, N rem C#col.lambda =:= 0).

close_block(C, false) -> C;
close_block(C, true) ->
    B = C#col.block,
    C#col{block = [],
          distinct = [length(lists:usort(B)) | C#col.distinct],
          clamp = [mean([clamp_frac(Q) || Q <- B]) | C#col.clamp]}.

%% IF-4's raw material. sep_cma_es can emit 1.0e308-scale values from a diverging
%% covariance, which quantize/1 clamps silently.
clamp_frac(Q) -> length([1 || W <- Q, abs(W) >= ?W_CLAMP]) / max(1, length(Q)).

%% A TUPLE, never a map: term_to_binary is not canonical for maps.
col_final(C) ->
    {C#col.n, C#col.best, lists:reverse(C#col.marks),
     lists:reverse(C#col.distinct), lists:reverse(C#col.clamp)}.

%%%============================================================================
%%% ONE RUN. Seeded and reproducible: rand state is per process, so parallelism
%%% is deterministic.
%%%============================================================================
one_run(Arm, Seed, Layers, Opts) ->
    Dim = robo_net:weight_count(Layers),
    Lambda = lambda_for(Arm, Dim, Opts),
    Budget = maps:get(budget, Opts),
    %% DEFECT FIX (D3). Generations round UP, so every arm reaches at least the
    %% budget and therefore every checkpoint survives. Rounding DOWN dropped the
    %% 50,000 mark for any arm whose lambda does not divide the budget: lambda 17
    %% gave 49,997 evaluations and lambda 70 gave 49,980, so arms L and M silently
    %% kept two checkpoints of three while S and D kept all three. IF-9 then
    %% differenced 25k against 10k for two arms and 50k against 25k for the other
    %% two, comparing arms on different budget windows with nothing in the feed
    %% saying so. The overshoot is at most lambda-1 evaluations past the final
    %% checkpoint and cannot affect a reading taken AT a checkpoint.
    Gens = max(1, (Budget + Lambda - 1) div Lambda),
    Checks = [C || C <- maps:get(checkpoints, Opts), C =< Gens * Lambda],
    _ = rand:seed(exsss, {Seed, Seed * 7 + 1, Seed * 13 + 3}),
    Tab = ets:new(exp066_cache, [set, private]),
    Col = col_start(Lambda, Checks),
    Fit = fitness_fun(Layers, rungs(Arm), train_starts(Opts), Col, Tab),
    Res = optimise(Arm, Fit, Dim, Lambda, Gens),
    Col ! {stop, self()},
    Final = receive {col, X} -> X end,
    true = ets:delete(Tab),
    {Res, Final}.

%% INITIALISATION. sep_cma_es defaults x0 to the ZERO VECTOR, and a zero weight
%% vector makes every neuron activate(0) = 0, so every intent field is zero and
%% the initial mean IS LITERALLY A SITTING DUCK. x0 is therefore set explicitly
%% to a per-seed N(0,1) draw from the run's own seeded stream. mu_lambda_es has
%% no x0 option and already draws N(0,1) parents, so the two arms start from the
%% same distribution.
optimise(m, Fit, Dim, Lambda, Gens) ->
    mu_lambda_es:evolve(Fit, Dim, #{mu => 10, lambda => Lambda,
                                    max_generations => Gens, init_sigma => 1.0});
optimise(_Arm, Fit, Dim, Lambda, Gens) ->
    X0 = [rand:normal() || _ <- lists:seq(1, Dim)],
    sep_cma_es:evolve(Fit, Dim, #{lambda => Lambda, max_generations => Gens,
                                  init_sigma => 1.0, x0 => X0}).

%% BUDGET is in UNIQUE evaluations. Both optimisers evaluate only offspring
%% (mu_lambda_es uses comma selection, sep_cma_es samples lambda fresh points),
%% so evaluations equal lambda times generations with NO parent re-scoring. That
%% is the accounting defect the exp064 and exp065 gates found in the hand-rolled
%% EA, and it is absent here.
lambda_for(m, _Dim, Opts) -> maps:get(lambda_m, Opts);
lambda_for(_Arm, Dim, Opts) -> resolve_lambda(maps:get(lambda, Opts), Dim).

resolve_lambda(auto, Dim) -> cma_lambda(Dim);
resolve_lambda(L, _Dim) -> L.

%% sep_cma_es's own default, restated so the runner and the optimiser agree on
%% the generation count. Dim 281 gives 20, Dim 90 gives 17.
cma_lambda(N) -> 4 + trunc(3.0 * math:log(N)).

%% THE ONE FLOAT BOUNDARY, at phenotype build time, inside the fitness and
%% OUTSIDE the match.
%%
%% The cache is keyed on a canonical digest of the quantised integer weight list
%% rather than on the list itself, for memory: 50000 entries of 281 integers is
%% about 340 MB per run and 20 runs are meant to be parallel. The key is derived
%% from a LIST of integers with the deterministic option set, never a map.
fitness_fun(Layers, Rungs, Starts, Col, Tab) ->
    Net = fun(Q) -> ladder({net, Layers, Q}, Rungs, Starts) end,
    fun(Xs) ->
        Q = robo_net:quantize(Xs),
        F = cached(Tab, Q, Net),
        Col ! {eval, Q, F},
        F
    end.

cached(Tab, Q, Net) ->
    K = genome_key(Q),
    hit(Tab, K, Q, Net, ets:lookup(Tab, K)).

hit(_Tab, _K, _Q, _Net, [{_K2, F}]) -> F;
hit(Tab, K, Q, Net, []) ->
    F = Net(Q),
    true = ets:insert(Tab, {K, F}),
    F.

genome_key(Q) ->
    crypto:hash(sha256, term_to_binary(Q, [deterministic, {minor_version, 2}])).

%%%============================================================================
%%% THE PRIMARY ENDPOINT. Per-seed held-out win rate over 160 matches, where a
%%% WIN requires the predictive_gun tank DEAD and the champion tank ALIVE at
%%% match end.
%%%
%%% Draws (turn cap with both alive, or mutual death) count as NOT beating. This
%%% is chosen over any W + D/2 rule for a specific reason: a pure evader that
%%% never fires would score exactly the parity value under such a rule, which
%%% readmits the pre-measured never-fire local optimum through the scoring door.
%%%============================================================================
heldout(Subject, Kind, Starts) ->
    [O || Start <- Starts, O <- duel(Subject, {script, Kind}, Start)].

rates(Os) ->
    N = max(1, length(Os)),
    W = length([1 || #{alive := true, opp_alive := false} <- Os]),
    L = length([1 || #{alive := false, opp_alive := true} <- Os]),
    {W / N, L / N, (N - W - L) / N}.

win_rate(Os) -> element(1, rates(Os)).

%% Mean per-match damage margin in WHOLE units. THE MARGIN IS NOT A COMPETENCE
%% ORDERING AND MAY NOT BE USED AS ONE: measured on the held-out 80, the RAMMER
%% out-damages the CIRCLE_STRAFER while both lose almost everything. It is a
%% CENSORING DIAGNOSTIC and nothing more.
mean_margin(Os) -> mean([(maps:get(dealt, O) - maps:get(taken, O)) / ?FP || O <- Os]).

cap_share(Os) -> mean([b(maps:get(turns, O) >= 2000) || O <- Os]).

%% IF-12's raw material: the floor bot's shots in the champion's WON matches. A
%% controller that stays out of the radar beam faces an opponent that holds fire
%% unless the track is from this turn. That is legitimate exploitation of the
%% partial observability this substrate was chosen for, but it is a DIFFERENT
%% finding from out-shooting the floor bot.
won_opp_shots(Os) ->
    mean([maps:get(opp_shots, O) || #{alive := true, opp_alive := false} = O <- Os]).

profile(Subject, Starts) ->
    [begin
         Os = heldout(Subject, K, Starts),
         {W, L, D} = rates(Os),
         {K, W, L, D}
     end || K <- robo_gauntlet:kinds()].

%%%============================================================================
%%% THE FROZEN CONSTANTS. All measured on the FINAL generator, at the engine pin,
%%% BEFORE any evolution arm runs, with SCRIPTED BOTS ONLY.
%%%
%%% k = 4 IS THE ONE CHOSEN CONSTANT IN THE DESIGN AND IT IS NAMED AS SUCH. Four
%%% standard errors above parity puts CLEARED beyond any reading of
%%% "statistically indistinguishable from the floor bot's own clone", and it does
%%% not move with the constructor's skill in either direction. The gate killed the
%%% original gap-closing form B = P + 0.60 * (W_0b - P), under which the person
%%% who built arm C set the difficulty of the gate they then wanted evolution to
%%% clear.
%%%============================================================================
constants() -> constants(defaults()).

constants(Opts0) ->
    Opts = merged(Opts0),
    Starts = heldout_starts(Opts),
    %% P: predictive_gun against its own CLONE. Both seats are played through the
    %% same instrument the champions face, so the reference and the endpoint are
    %% the same measurement rather than two similar ones.
    Os = heldout({script, ?FLOOR}, ?FLOOR, Starts),
    {P, _PL, _PD} = rates(Os),
    Boot = bootstrap_se(Os),
    Binom = math:sqrt(max(0.0, P * (1 - P)) / max(1, length(Os))),
    SE = max(Boot, Binom),
    #{p => P,
      se => SE,
      se_bootstrap => Boot,
      se_binomial => Binom,
      s_par => mean([maps:get(opp_shots, O) || O <- Os]),
      cap_share => cap_share(Os),
      b => P + 4 * SE,
      r_line => P + 2 * SE,
      d_min => 2 * SE,
      n_scripted => scripted_null(Starts),
      matches => length(Os)}.

%% START-LEVEL bootstrap, both seats of a resampled start kept TOGETHER, floored
%% at the binomial value by the caller. The original design derived its noise
%% scale as half the spread of P over "four disjoint 40-start subsets"; they were
%% NOT disjoint (first/last and odd/even are two OVERLAPPING partitions of the
%% same 160 matches), which understated the SE by roughly threefold and would
%% have CLEARED a champion statistically indistinguishable from the floor bot's
%% own clone.
%%
%% THE GATE'S OWN FALSIFIER, recorded so its critique is not immune either: the
%% band critique is falsified if this bootstrap returns an SE at or below about
%% 0.020, in which case the original constants were adequately separated. It is
%% run and reported whatever it returns.
bootstrap_se(Os) ->
    Ps = list_to_tuple(pairs(Os)),
    N = tuple_size(Ps),
    _ = rand:seed(exsss, {?BOOT_SEED, ?BOOT_SEED * 7 + 1, ?BOOT_SEED * 13 + 3}),
    Rs = [boot_one(Ps, N) || _ <- lists:seq(1, ?BOOT_N)],
    M = mean(Rs),
    math:sqrt(mean([(X - M) * (X - M) || X <- Rs])).

pairs([A, B | Rest]) -> [{A, B} | pairs(Rest)];
pairs(_Short) -> [].

boot_one(Ps, N) ->
    Samp = [element(rand:uniform(N), Ps) || _ <- lists:seq(1, N)],
    win_rate(lists:append([[A, B] || {A, B} <- Samp])).

%% N: the scripted-ladder null against the floor bot on the same 160 matches.
%% Measured at authoring at or below 0.0125 (sitting_duck 0/160, spinner 0/160,
%% rammer 2/160, circle_strafer 0/160).
%%
%% FIXED 2026-07-30: THE FULL TRIPLE, NOT THE WIN RATE ALONE. This kept only
%% element 1 of rates/1 and threw the LOSS and DRAW rates away, so N could not
%% distinguish a rung the floor bot BEATS from a rung it merely never loses to. A
%% W of 0.0 is consistent with 160 losses and with 160 draws, and those are
%% different facts about the ladder: the first is an EDGE from the floor bot to
%% that rung, the second is no edge at all. The discarded L is what decides it,
%% which is why one of the three legs of any candidate intransitive triple through
%% the floor bot was unreadable in the as-run record. recovered/1 uses this.
%%
%% THE AS-RUN FEED IS NOT AMENDED. Its N line carries four win rates and that is
%% what the run of 2026-07-29 computed; a FUTURE run's line carries four
%% {Kind, W, L, D} tuples instead.
scripted_null(Starts) ->
    [rc_rung_cell(K, Starts) || K <- robo_gauntlet:kinds(), K =/= ?FLOOR].

%% One scripted rung against the floor bot, from the RUNG's side, all three rates.
rc_rung_cell(K, Starts) ->
    {W, L, D} = rates(heldout({script, K}, ?FLOOR, Starts)),
    {K, W, L, D}.

%% R: the best-of-30 random-genome held-out win rate, at the frozen encoding.
%%
%% FAILED IS DELIBERATELY NEAR-UNREACHABLE AND THE EXPECTED FORM OF A NEGATIVE IS
%% INCONCLUSIVE. R is a best-of-K ORDER STATISTIC and therefore inflated relative
%% to a mean random net; that conservatism is acceptable for a claim as strong as
%% "no better than random", but it means the FAILED branch will almost never fire
%% and its non-firing carries no information.
random_null(Layers, Starts, K) ->
    lists:max([win_rate(heldout({net, Layers, Q}, ?FLOOR, Starts))
               || Q <- random_genomes(Layers, K)]).

%% IF-2's reference: the best TRAINING fitness of K random vectors from the same
%% init distribution.
inert_null(Arm, Layers, Starts, K) ->
    lists:max([ladder({net, Layers, Q}, rungs(Arm), Starts)
               || Q <- random_genomes(Layers, K)]).

%% Calibration and null seeds 1..K, DISJOINT from the measurement seeds.
random_genomes(Layers, K) ->
    Dim = robo_net:weight_count(Layers),
    [begin
         _ = rand:seed(exsss, {I, I * 7 + 1, I * 13 + 3}),
         robo_net:quantize([rand:normal() || _ <- lists:seq(1, Dim)])
     end || I <- lists:seq(1, K)].

%%%============================================================================
%%% THE DECISION RULE. Pre-committed, computed on held-out ONLY, all outcomes
%%% reachable. The three CLEARED conditions do distinct work: typical strength,
%%% reliability across runs, and DIRECTION. The third is not decorative: at
%%% parity wins equal losses exactly, so "more wins than losses by at least
%%% D_min" is a genuine directional test.
%%%============================================================================
verdict(Rs, K) ->
    Ws = [R#res.w || R <- Rs],
    Ls = [R#res.l || R <- Rs],
    N = length(Ws),
    B = maps:get(b, K),
    Rel = length([1 || W <- Ws, W >= maps:get(r_line, K)]),
    Dir = length([1 || {W, L} <- lists:zip(Ws, Ls), W - L >= maps:get(d_min, K)]),
    Part = length([1 || {W, L} <- lists:zip(Ws, Ls),
                        W >= B, W - L >= maps:get(d_min, K)]),
    Med = median(Ws),
    decide(Med >= B andalso Rel >= ceil_frac(3, 4, N) andalso Dir >= ceil_frac(3, 4, N),
           Med =< maps:get(r, K, 0.0),
           Part >= ceil_frac(1, 4, N)).

decide(true, _Failed, _Partial) -> cleared;
decide(false, true, _Partial) -> failed;
decide(false, false, true) -> partial;
decide(false, false, false) -> inconclusive.

%% 15 of 20 and 5 of 20 scale to 8 of 10 and 3 of 10 on the same fractions.
ceil_frac(Num, Den, N) -> (Num * N + Den - 1) div Den.

%%%============================================================================
%%% INSTRUMENT FAILURE, distinguished from a real negative. Each is
%%% pre-committed. IF-1 through IF-6 void or replace a verdict; IF-7, IF-8 and
%%% IF-12 are MODIFIERS that LABEL a verdict; IF-9 through IF-11 are observables
%%% that constrain a reading.
%%%============================================================================
flags(Rs, K, Inert) ->
    Med = median_res(Rs),
    Ws = [R#res.w || R <- Rs],
    B = maps:get(b, K),
    [{'IF-2 SEARCH-INERT', median([R#res.fit || R <- Rs]) =< Inert,
      "the fitness supplies no usable gradient; NOT 'evolution cannot reach the floor'"},
     {'IF-3 DEGENERATE-NON-FIRING', Med#res.shots =< 0.0,
      "the pre-measured never-fire optimum was selected; the floor question was never asked"},
     {'IF-4 SEARCH-DIVERGED', Med#res.clamp_frac > 0.5,
      "a diverging covariance emitted values quantize/1 clamped silently"},
     {'IF-5 LATTICE-COLLAPSE', Med#res.distinct_last =< 1,
      "the run collapsed onto a lattice point; it has not answered the question"},
     {'IF-7 CAP-DOMINATED', Med#res.caps > 0.40,
      "2.5x the measured parity cap share; the verdict is cap-conditional and must be LABELLED so"},
     {'IF-8 MEMORISATION', Med#res.train_w >= B andalso Med#res.w < B,
      "MODIFIER; pre-registered next rung is the stochastic-start variant, NOT more budget"},
     {'IF-9 BUDGET-LIMITED', budget_gain(Rs) >= 0.05,
      "read ONLY on a FAILED or INCONCLUSIVE verdict: the negative is budget-limited"},
     {'IF-10 LADDER-INVERSION', inverted(Med#res.profile),
      "an OBSERVABLE. NOT claimed as intransitivity; that is phase 1's question"},
     %% IF-10 reads ONE seed and an arm is not its median champion: on arm D five
     %% of ten champions tripped even the as-run predicate while the median draw
     %% landed on one that did not. Both counts are emitted, over the whole arm, so
     %% the widening is visible in the feed instead of only in a probe.
     {'note IF-10 seeds inverted, WIDENED predicate', inverted_count(Rs),
      "four lower rungs, draw-parked counted as not beaten; count over the ARM"},
     {'note IF-10 seeds inverted, AS-RUN predicate', inverted_count_as_run(Rs),
      "duck-or-spinner and draw-blind, the predicate the 2026-07-29 run used"},
     %% Read ONLY when there is a won match to read it on: with no wins the mean
     %% is UNDEFINED, not zero, and a modifier that fires on every zero-win arm
     %% would label exactly the verdicts it says nothing about.
     {'IF-12 RADAR-STARVED', if12(Med, K),
      "MODIFIER; the champion won by staying out of the beam, a DIFFERENT finding"},
     {'note median W_s', median(Ws), "the primary endpoint"}].

%% IF-12's predicate, named ONCE. The post-hoc addendum re-evaluates this flag from
%% the archive because the original per-seed emit dropped the column it reads, and
%% the flag must not be restated there in a second copy that could drift from this
%% one.
if12(Med, K) ->
    Med#res.w > 0.0 andalso Med#res.won_opp_shots < 0.25 * maps:get(s_par, K).

if12_threshold(K) -> 0.25 * maps:get(s_par, K).

%% Median W_s at the last checkpoint minus the median at the one before it.
budget_gain(Rs) ->
    Marks = [R#res.marks || R <- Rs],
    gain([M || M <- Marks, length(M) >= 2]).

gain([]) -> 0.0;
gain(Ms) ->
    Last = median([element(2, lists:last(M)) || M <- Ms]),
    Prev = median([element(2, lists:nth(length(M) - 1, M)) || M <- Ms]),
    Last - Prev.

%% IF-10's predicate, WIDENED 2026-07-30. The signed insight calls the as-run
%% narrowness a DEFECT rather than a scoping note, and this is that fix. Three
%% changes, and NOT ONE OF THEM MOVES A THRESHOLD:
%%
%%   1. THE FOUR LOWER RUNGS, not two. The as-run list held sitting_duck and
%%      spinner only, so it never looked at the rammer or the circle_strafer, and
%%      arm D's median champion, seed 2007, loses the RAMMER 0.36875 to 0.63125
%%      while the flag stays quiet.
%%   2. DRAW-PARKED COUNTS AS NOT BEATEN. L > W alone is draw-blind: arm D seed
%%      2004 goes 0.0125 W / 0.00625 L / 0.98125 D against the SITTING DUCK, a
%%      champion that cannot kill a stationary target inside the turn cap, and
%%      passes on a technicality. THE THRESHOLD IS D > 0.5 AND IT IS NOT A
%%      TUNABLE: it is the definition of "the majority outcome of this rung is a
%%      draw" on a fixed 160 matches, the same reading the insight's prose uses,
%%      and there is no value to fit because half is what majority means.
%%   3. REPORTED PER SEED WITH A COUNT, in flags/3, as well as on the median
%%      champion, because the median champion is ONE seed of ten.
%%
%% THE FEED OF 2026-07-29 IS NOT AMENDED BY THIS. IF-10 quiet on all three arms
%% is what that run reported and it stands; what changes is what a FUTURE run
%% reports, and the recomputation over the archive lives in flag_fixes/1.
inverted(Profile) -> lists:any(fun lower_unbeaten/1, Profile).

%% One rung cell of a profile: a LOWER rung the champion has not beaten, either
%% because it loses more than it wins or because the rung is parked in draws.
lower_unbeaten({K, W, L, D}) ->
    lists:member(K, [sitting_duck, spinner, rammer, circle_strafer])
        andalso (L > W orelse D > 0.5).

%% The AS-RUN predicate, kept VERBATIM. It is no longer what IF-10 reads; it is
%% here so old and new can be printed side by side over the same profiles, which
%% is the only way a reader can see what the widening changed rather than take it.
inverted_as_run(Profile) ->
    lists:any(fun({K, W, L, _D}) ->
                  lists:member(K, [sitting_duck, spinner]) andalso L > W
              end, Profile).

%% Which lower rungs trip the widened predicate, and on which of its two grounds.
%% A cell can satisfy both; loses is reported first because losing is the stronger
%% statement.
unbeaten_rungs(Profile) ->
    [{K, unbeaten_why(C)} || {K, _W, _L, _D} = C <- Profile, lower_unbeaten(C)].

unbeaten_why({_K, W, L, _D}) when L > W -> loses;
unbeaten_why(_Cell) -> draw_parked.

inverted_count(Rs) -> length([1 || R <- Rs, inverted(R#res.profile)]).

inverted_count_as_run(Rs) -> length([1 || R <- Rs, inverted_as_run(R#res.profile)]).

%% The MEDIAN CHAMPION, by held-out win rate. Every IF code above that speaks of
%% "the median champion" reads this one seed, not a pooled average.
median_res(Rs) ->
    S = lists:sort(fun(A, B) -> A#res.w =< B#res.w end, Rs),
    lists:nth(max(1, length(S) div 2 + length(S) rem 2), S).

%%%============================================================================
%%% ARM C: KILL GATE 0b, EXPRESSIBILITY.
%%%
%%% A hand-CONSTRUCTED WEIGHT VECTOR driven through the pilot, NOT hand-written
%%% Erlang. Kill gate 0b must prove the NETWORK CLASS expresses the capability; a
%%% bespoke Erlang bot that beats predictive_gun proves nothing about it.
%%%
%%% Built and tuned on CALIBRATION starts ONLY, so its held-out number is an
%%% honest generalisation read with no in-sample advantage. It FREEZES THE
%%% ENCODING at the instant its held-out rate is measured. It does NOT set the
%%% bar: the bar is absolute, and the precondition is that arm C itself clears
%%% it, which proves the bar reachable BY CONSTRUCTION while leaving it
%%% independent of constructor skill in both directions.
%%%
%%% STOP RULE, PRE-REGISTERED. An ATTEMPT is one edit to the gains below, or one
%%% topology change, followed by one full evaluation on the 30 calibration
%%% starts. Construction stops when either the calibration win rate reaches B and
%%% 5 consecutive further attempts fail to raise it, or 40 attempts total (20 per
%%% topology) have been made without reaching B, in which case UNGRADEABLE fires.
%%% The attempt count and the full calibration trajectory go into the raw feed.
%%%
%%% REPRESENTABILITY OF THE TRIGGER, AND IT SETS THE TOPOLOGY FALLBACK.
%%% Fire-when-aligned is an EVEN function of aim error. Channel 12 is odd and
%%% cannot supply it; channel 11 is the even one, so a positive weight on channel
%%% 11 plus a negative bias thresholds on alignment. Sharpness is bounded by the
%%% weight cap: weights cap at 8.0 and tanh saturates at 4.875 in Q12, so a
%%% linear unit can threshold at roughly cos at or above 0.9, about plus or minus
%%% 25 degrees, against the floor bot's AIM_TOL of about 2.8 degrees. That is the
%%% sharpest known representability limit of the linear arm and it is stated in
%%% advance. If [17,5] cannot clear the precondition for this reason, the
%%% pre-registered move is [17,12,5], where a hidden layer builds a sharper
%%% conjunction from channels 11 and 12, and the fact is recorded as the reason.
%%%============================================================================

%% ATTEMPT 1. Every value below is a gain on ONE channel, and every one of them
%% is capped at plus or minus 8.0 by quantize/1: THE BIAS IS CAPPED TOO, which is
%% what fixes the trigger threshold at about cos 0.92 rather than anywhere
%% sharper.
arm_c_gains() ->
    #{orbit => 4.0,        %% turn_body  gets -orbit * bear_body_cos: equilibrium
                           %%            at cos 0, that is the contact held at
                           %%            ninety degrees, which is orbiting
      centre => 0.5,       %% turn_body  gets -centre * pos_port: turn toward the
                           %%            arena centre, since wall contact costs a
                           %%            full unit of energy per turn
      body_bias => 0.3,    %% turn_body  bias: the blind slow curve, matching
                           %%            robo_gauntlet:hunt/1's turn_body of 2
      aim => 2.0,          %% turn_gun   gets +aim * bear_gun_sin, THE AIM ERROR:
                           %%            the signed quantity a positive turn_gun
                           %%            reduces. Aim is ONE positive weight.
      lead => 3.0,         %% turn_gun   gets +lead * target_lateral: lead angle
                           %%            is lateral speed over bullet speed and
                           %%            is range-independent to first order, so
                           %%            ONE weight is a working lead
      lock => 3.0,         %% turn_radar gets +lock * bear_radar_sin, THE LOCK
                           %%            ERROR. Radar tracking is one weight.
      sweep => 5.0,        %% turn_radar bias: sweep while blind
      sweep_off => 5.0,    %% turn_radar gets -sweep_off * contact_fresh, so the
                           %%            sweep bias is cancelled by a fresh track
                           %%            and restored as the track ages
      throttle => 8.0,     %% accel      bias: full throttle. Coasting beats
                           %%            braking here, measured: the engine has
                           %%            no drag, so a sustained negative command
                           %%            drives the tank backwards into the wall
                           %%            it was fleeing.
      trigger => 8.0,      %% fire       gets +trigger * bear_gun_cos, the EVEN
                           %%            alignment channel
      fresh => 0.5,        %% fire       gets +fresh * contact_fresh
      close => 0.3,        %% fire       gets +close * contact_prox
      hold => -8.0}.       %% fire       bias, at the cap: blind reads -8.0, tanh
                           %%            saturates, to_range gives -30 and
                           %%            clamp_power reads that as HOLD

%% The flat genome, in robo_net's layout: layers in order, neurons within a layer
%% in order, and FOR EACH NEURON ITS BIAS FIRST followed by one weight per input
%% in input order. Output order is turn_body, turn_gun, turn_radar, accel, fire.
-spec arm_c_weights(map()) -> [float()].
arm_c_weights(G) ->
    neuron([{9, -gain(orbit, G)}, {6, -gain(centre, G)}], gain(body_bias, G))
        ++ neuron([{12, gain(aim, G)}, {16, gain(lead, G)}], 0.0)
        ++ neuron([{14, gain(lock, G)}, {8, -gain(sweep_off, G)}], gain(sweep, G))
        ++ neuron([], gain(throttle, G))
        ++ neuron([{11, gain(trigger, G)}, {8, gain(fresh, G)},
                   {15, gain(close, G)}], gain(hold, G)).

neuron(Pairs, Bias) -> [Bias | [weight_at(I, Pairs) || I <- lists:seq(1, ?INPUTS)]].

weight_at(I, Pairs) -> pair_val(lists:keyfind(I, 1, Pairs)).

pair_val(false) -> 0.0;
pair_val({_I, V}) -> V.

gain(K, G) -> maps:get(K, G, 0.0).

arm_c() -> arm_c(#{}).

%% Reports the calibration rate (the tuning surface), the held-out rate W_0b (the
%% precondition), the shots per match (the only source of a firing-rate scale for
%% IF-3) and the FULL LADDER PROFILE, which exists for IF-11: an arm C that
%% clears the precondition while LOSING to a lower rung is the signature of a
%% construction that beats predictive_gun by exploiting its perception rather
%% than out-fighting it.
arm_c(Opts0) ->
    Opts = merged(Opts0),
    Layers = maps:get(c_layers, Opts),
    ?INPUTS = hd(Layers),
    %% DEFECT FIX (D1). arm_c_weights/1 emits exactly one bias plus 17 weights per
    %% output neuron, which is the [17,5] layout and no other. Passing [17,12,5]
    %% used to hand a 90-parameter genome to a 281-parameter network; robo_net
    %% zero-fills the remainder, so the construction was silently destroyed and
    %% measured as losing every match to rammer, circle_strafer and the floor bot.
    %% A hand construction that cannot be built must say so rather than produce a
    %% number. See the D9 note on arm_c_role/0 for why no hidden-layer fallback
    %% was written instead.
    Layers =:= ?C_LAYERS orelse
        error({arm_c_topology_unsupported, [{given, Layers}, {supported, ?C_LAYERS}]}),
    Q = robo_net:quantize(arm_c_weights(maps:get(gains, Opts))),
    Net = {net, Layers, Q},
    Cal = heldout(Net, ?FLOOR, calib_starts(Opts)),
    Held = heldout(Net, ?FLOOR, heldout_starts(Opts)),
    #{layers => Layers,
      dim => robo_net:weight_count(Layers),
      calibration => win_rate(Cal),
      w_0b => win_rate(Held),
      margin => mean_margin(Held),
      shots => mean([maps:get(shots, O) || O <- Held]),
      caps => cap_share(Held),
      profile => profile(Net, heldout_starts(Opts)),
      genome => Q}.

%%%============================================================================
%%% CHAMPION ARCHIVING. The champion is the ES-returned best-by-TRAINING-fitness
%%% vector, NEVER re-picked on held-out; held-out is never fed back and never
%%% used for early stopping.
%%%
%%% The archived form is a TUPLE of tuples, lists, integers and atoms, so
%%% term_to_binary is canonical over it and the digest is stable across VMs. A
%%% map here would reproduce the exact accident that made robo_match's first
%%% golden vector differ between eunit and a plain erl.
%%%============================================================================
champion(Arm, Seed, Layers, Q, Fit, Evals) ->
    {champion, Arm, Seed, Layers, Q, Fit, Evals}.

-spec champion_id(tuple()) -> binary().
champion_id({champion, Arm, Seed, Layers, Q, _Fit, _Evals}) ->
    binary:encode_hex(
      crypto:hash(sha256,
                  term_to_binary({Arm, Seed, Layers, Q},
                                 [deterministic, {minor_version, 2}]))).

%% One Erlang term per line, so file:consult/1 reads the archive back.
-spec champion_write(string(), [tuple()]) -> ok.
champion_write(Path, Champs) ->
    {ok, Fd} = file:open(Path, [write]),
    [io:format(Fd, "~w.~n", [C]) || C <- Champs],
    file:close(Fd).

champion_read(Path) ->
    {ok, Terms} = file:consult(Path),
    Terms.

%%%============================================================================
%%% EXPLORATORY CROSS-PLAY PROBE. NOT pre-registered, and it SIGNS NOTHING.
%%%
%%% Everything in EXP-066 scored champions against SCRIPTED opponents. Phase 1
%%% scores champions against EACH OTHER, which is a different landscape, and
%%% clearing the floor says nothing about whether that landscape is rich enough
%%% for counter-strategies to exist. Arm L clearing at 0.94 with no hidden layer
%%% sharpens the worry: a strategy space a linear policy nearly saturates may
%%% simply be transitive, and a transitive space cannot cycle.
%%%
%%% This plays the champions already on disk against one another and counts
%%% intransitive triples with the SAME margin-and-band arithmetic exp057 used, so
%%% the reading is comparable to the bare-grid result rather than a new ruler.
%%% Hours, not the two weeks a designed phase 1 costs, using champions that cost
%%% nothing more.
%%%
%%% A transitive matrix here is a REASON TO REDESIGN phase 1, not a phase-1
%%% verdict: 20 champions of one arm at one budget is not a coevolutionary
%%% population, and cycling could still appear once opponents co-adapt. A matrix
%%% with loops in it is the encouraging case and still proves nothing on its own.
%%%============================================================================
%%% WHAT THE FIRST PASS OF THIS PROBE GOT WRONG, and it was found by a CLAIM
%%% gate, not by reading. Six defects, all of them in the RECORD rather than in
%%% the arithmetic:
%%%
%%%   1. IT PERSISTED NOTHING. crossplay/1 returned a map to a shell and wrote no
%%%      file, so the numbers a draft insight quoted existed on no disk anywhere.
%%%      In this corpus the signed insight PLUS the persisted feed IS the record,
%%%      so that made the headline unsignable however true it was. Everything
%%%      below is written to xp_out.
%%%   2. THE RUN CONFIGURATION WAS UNRECOVERABLE. The default was 12 held-out
%%%      starts, a draft said 6, and nothing on disk said which. xp_starts now
%%%      defaults to ALL 80 and the count is written into the report.
%%%   3. THE EDGES WERE ONE FLIPPED MATCH WIDE. At 6 starts a cell holds 12
%%%      matches, so a margin moves in steps of 2/12 = 0.167 and a single flipped
%%%      match jumps clean across the 0.10 band the counter reads. At 80 starts a
%%%      cell holds 160 matches and one flip moves a margin by 0.0125, which is
%%%      an eighth of the band. The granularity is now computed and reported so a
%%%      reader can see it rather than derive it.
%%%   4. "100 TRIPLES" WAS NOT 100 CYCLES. exp057's counter is over ORDERED
%%%      tuples and counts one cyclic triangle TWICE or ONCE depending on the
%%%      cycle's orientation against index order. Both counts are now reported,
%%%      with the identity that bridges them CHECKED rather than asserted.
%%%   5. THE RANDOM NULL WAS ONE SYNTHETIC SEED where an exact number exists.
%%%      The analytic expectation is now derived, and two empirical nulls are run
%%%      over many seeds: a sign-only one (every edge decisive) and a
%%%      MATCH-LEVEL one at this cell size, which are different references and
%%%      were being conflated.
%%%   6. THE exp057 COMPARISON WAS NOT LIKE FOR LIKE. Its zero is a median over
%%%      runs of a count over 10 GENERATIONAL CHECKPOINTS OF ONE RUN, an object
%%%      set pre-ordered by monotone progress and therefore transitivity-biased
%%%      BY CONSTRUCTION, over 45 pairs and 360 ordered candidates. This probe
%%%      has 20 INDEPENDENT equal-budget peers, 190 pairs and 3,420 ordered
%%%      candidates: 9.5x the candidate count. An n-MATCHED subsample
%%%      distribution is now reported, which is the only count comparable to it,
%%%      and the substrate difference is still not separable from the object-set
%%%      difference by this probe.
%%%
%%% THE DRAW SHARE was measured on a 4-champion 4-start corner of the matrix and
%%% quoted as if it covered the matrix. It is now the true share over every match
%%% played.
crossplay() -> crossplay(#{}).

crossplay(Opts0) ->
    Opts = merged(Opts0),
    Champs = champion_read(maps:get(xp_champions, Opts)),
    Starts = lists:sublist(heldout_starts(Opts), maps:get(xp_starts, Opts)),
    Seeds = [S || {champion, _A, S, _L, _Q, _F, _E} <- Champs],
    G = list_to_tuple([{net, L, Q} || {champion, _A, _S, L, Q, _F, _E} <- Champs]),
    N = tuple_size(G),
    %% The seat-symmetry self-check runs FIRST, on three pairs, because the whole
    %% matrix is derived from the I<J half and a wrong derivation would make every
    %% number below wrong after minutes of compute rather than seconds.
    Sym = xp_symmetry(G, Starts),
    Cells = pmap(fun({I, J}) -> xp_cell(G, Starts, I, J) end,
                 xp_pairs(lists:seq(1, N)), maps:get(workers, Opts)),
    Mtx = xp_matrix(N, Cells),
    Repro = xp_repro(G, Opts, maps:get(xp_repro_starts, Opts)),
    Report = xp_report(Opts, N, Seeds, Starts, Sym, Cells, Mtx, Repro),
    ok = xp_write(maps:get(xp_out, Opts), Report),
    Report.

%%% THE FIRST PASS'S NUMBER, REPRODUCED, because a number whose configuration is
%%% unknown is worse than no number. The draft insight quoted 100 intransitive
%%% triples at band 0.10 and 170 decisive edges of 190, and said the probe ran 6
%%% held-out starts, while the runner's default was 12; nothing was written to disk,
%%% so the record could not settle it. Replaying the archived champions at 6 starts
%%% returns exactly 100 and exactly 170, so THE FIRST PASS RAN 6 STARTS, 12 matches
%%% per cell. Recovered by reproduction, since it could not be recovered by reading.
%%%
%%% It also shows what that cell size did to the band sweep, which is the reason
%%% exp057 sweeps three bands at all: at 12 matches per cell a margin is a multiple
%%% of 1/12, so NO representable margin lies between 0.10 and 0.15 and those two
%%% bands are the SAME TEST. Two of the three bands were not independent readings.
xp_repro(_G, _Opts, none) -> {as_run_reproduction, [{ran, none}]};
xp_repro(G, Opts, S) ->
    N = tuple_size(G),
    Starts = lists:sublist(heldout_starts(Opts), S),
    Cells = pmap(fun({I, J}) -> xp_cell(G, Starts, I, J) end,
                 xp_pairs(lists:seq(1, N)), maps:get(workers, Opts)),
    Mtx = xp_matrix(N, Cells),
    {as_run_reproduction,
     [{starts, S},
      {why, "the first pass persisted nothing; this identifies the configuration "
            "behind the 100 triples and 170 decisive edges a draft quoted"},
      xp_grain(element(7, hd(Cells))),
      xp_draws(Cells),
      {counts, [xp_band(xp_mg(Mtx), lists:seq(1, N), B) || B <- xp_bands()]}]}.

duels(A, B, Starts) -> [O || St <- Starts, O <- duel(A, B, St)].

xp_pairs(Idx) -> [{I, J} || I <- Idx, J <- Idx, I < J].

xp_triples(Idx) -> [{I, J, K} || I <- Idx, J <- Idx, K <- Idx, I < J, J < K].

%% Score(I,J) = I's win rate against J over BOTH SEATS at every start, so seat
%% advantage cancels. One cell yields the reverse cell too: duel/3 plays seat a and
%% seat b, the engine is deterministic, so the two games behind cell {J,I} are
%% BYTE-IDENTICAL to the two behind {I,J} and differ only in which side reports.
%% W(J,I) is therefore L(I,J) exactly, which halves the matches from 60,800 to
%% 30,400. xp_symmetry/2 proves it rather than assuming it.
xp_cell(G, Starts, I, J) ->
    Os = duels(element(I, G), element(J, G), Starts),
    {W, L, D} = rates(Os),
    {cell, I, J, W, L, D, length(Os)}.

xp_symmetry(G, Starts) ->
    Probe = lists:sublist(xp_pairs(lists:seq(1, tuple_size(G))), 3),
    Checks = [xp_symmetry_one(G, Starts, P) || P <- Probe],
    lists:all(fun({sym, _I, _J, Ok}) -> Ok end, Checks)
        orelse error({seat_symmetry_broken, Checks}),
    Checks.

xp_symmetry_one(G, Starts, {I, J}) ->
    {cell, I, J, W, L, D, _M} = xp_cell(G, Starts, I, J),
    {cell, J, I, RW, RL, RD, _RM} = xp_cell(G, Starts, J, I),
    {sym, I, J, {RW, RL, RD} =:= {L, W, D}}.

%% Tuples, not a map: this matrix is written to disk and read back, and
%% term_to_binary is not canonical over maps.
xp_matrix(N, Cells) ->
    Idx = lists:seq(1, N),
    list_to_tuple([list_to_tuple([xp_at(Cells, I, J) || J <- Idx]) || I <- Idx]).

xp_at(_Cells, I, I) -> 0.0;
xp_at(Cells, I, J) when I < J -> element(4, lists:keyfind(J, 3, xp_row(Cells, I)));
xp_at(Cells, I, J) -> element(5, lists:keyfind(I, 3, xp_row(Cells, J))).

xp_row(Cells, I) -> [C || C <- Cells, element(2, C) =:= I].

wr(M, I, J) -> element(J, element(I, M)).

xp_mg(M) -> fun(I, J) -> wr(M, I, J) - wr(M, J, I) end.

%%% THE TWO COUNTS, and why both are needed.
%%%
%%% xp_ordered/3 is exp057's counter, character for character, so this probe is
%%% comparable to the bare-grid zero rather than measured with a new ruler. It
%%% counts ORDERED tuples (A,X,C) with A<X, and one cyclic triangle p<q<r
%%% therefore contributes TWICE when the cycle runs p->q->r->p (rotations (p,q,r)
%%% and (q,r,p) both satisfy A<X) and ONCE when it runs p->r->q->p (only (p,r,q)
%%% does). The count is 2*forward + backward and is NOT a cycle count.
%%%
%%% xp_cycles/3 counts unordered cyclic TRIANGLES, which is what "there is a
%%% rock-paper-scissors pocket here" means. Margins are antisymmetric, so for any
%%% band at or above zero "beats by more than the band" is an asymmetric relation
%%% and a triangle on three distinct vertices is cyclic in exactly one of two
%%% orientations: the two clauses below are mutually exclusive by construction, so
%%% their sum is the cycle count and no division by a guessed factor is involved.
xp_ordered(Mg, Idx, B) ->
    length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                 Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]).

xp_cycles(Mg, Idx, B) ->
    Tri = xp_triples(Idx),
    Fwd = length([1 || {I, J, K} <- Tri, Mg(I, J) > B, Mg(J, K) > B, Mg(K, I) > B]),
    Bwd = length([1 || {I, J, K} <- Tri, Mg(I, K) > B, Mg(K, J) > B, Mg(J, I) > B]),
    {Fwd, Bwd}.

%% Reported per band with the bridge between the two counters CHECKED, because an
%% arithmetic claim in a record should be recomputed rather than argued.
xp_band(Mg, Idx, B) ->
    {Fwd, Bwd} = xp_cycles(Mg, Idx, B),
    Ord = xp_ordered(Mg, Idx, B),
    Dec = length([1 || {I, J} <- xp_pairs(Idx), abs(Mg(I, J)) > B]),
    {at_band, B, [{ordered_exp057, Ord}, {unordered_cycles, Fwd + Bwd},
               {forward, Fwd}, {backward, Bwd},
               {identity_2f_plus_b_equals_ordered, 2 * Fwd + Bwd =:= Ord},
               {decisive_edges, Dec}, {of_pairs, length(xp_pairs(Idx))}]}.

xp_bands() -> [0.05, 0.10, 0.15].

%%% THE NULLS. Three references, and they are NOT interchangeable; the first pass
%%% quoted one number for all three.
%%%
%%% ANALYTIC. For a tournament whose every edge is decisive and independently
%%% oriented by a fair coin, an unordered triple is cyclic with probability 2/8,
%%% so E[cycles] = C(N,3)/4, and forward and backward orientations are equally
%%% likely, so E[ordered] = C(N,3) * (2 + 1) / 8 = 3*C(N,3)/8. At N=20 that is
%%% 285.0 cycles and 427.5 ordered tuples, exactly, at every band the edges clear.
%%%
%%% SIGN-ONLY, empirical. The same model sampled, to confirm the analytic value
%%% and give its spread. This is the reference the draft's single "452" belongs to.
%%%
%%% MATCH-LEVEL, empirical, AT THIS CELL SIZE. Coin-flip play over the real number
%%% of matches per cell, so a margin is 2K/M - 1 for K wins of M and most edges
%%% are NOT decisive at a 0.10 band. This is the honest coin-flip reference for a
%%% BANDED count and it is far below the sign-only one; conflating them
%%% understates how intransitive a banded count of 100-odd actually is.
xp_null_analytic(N) ->
    C3 = N * (N - 1) * (N - 2) / 6,
    {null_analytic, [{model, "fair coin per edge, every edge decisive"},
                     {c_n_3, C3},
                     {expected_unordered_cycles, C3 / 4},
                     {expected_ordered_exp057, 3 * C3 / 8}]}.

xp_null_sign(N, Draws) ->
    Idx = lists:seq(1, N),
    Ms = [xp_from_wins(N, [{I, J, xp_coin_w()} || {I, J} <- xp_pairs(Idx)])
          || _ <- lists:seq(1, Draws)],
    {null_sign_only, [{model, "fair coin per edge, winner takes the whole cell, "
                              "margin +/-1.0, all edges decisive"},
                      {draws, Draws} | xp_null_stats(Ms, Idx)]}.

xp_null_match(N, Draws, M) ->
    Idx = lists:seq(1, N),
    Ms = [xp_from_wins(N, [{I, J, xp_flips(M) / M} || {I, J} <- xp_pairs(Idx)])
          || _ <- lists:seq(1, Draws)],
    {null_match_level, [{model, "fair coin per MATCH, " ++ integer_to_list(M) ++ " per cell"},
                        {draws, Draws} | xp_null_stats(Ms, Idx)]}.

xp_null_stats(Ms, Idx) ->
    [{at_band, B, [{ordered_median, median([xp_ordered(xp_mg(M), Idx, B) || M <- Ms])},
                {ordered_range, spread([xp_ordered(xp_mg(M), Idx, B) || M <- Ms])},
                {cycles_median, median([xp_cyc_n(M, Idx, B) || M <- Ms])},
                {cycles_range, spread([xp_cyc_n(M, Idx, B) || M <- Ms])}]}
     || B <- xp_bands()].

xp_cyc_n(M, Idx, B) ->
    {F, Bw} = xp_cycles(xp_mg(M), Idx, B),
    F + Bw.

%% THE AS-RUN COIN, in MARGIN units. Used only by recovered/1's side-by-side null
%% table, never to build a reported null. Kept because a defect that is described
%% but not computed cannot be checked.
xp_coin() -> element(rand:uniform(2), {-1.0, 1.0}).

%% The sign-only coin in WIN-RATE units: the winner takes the whole cell. ONE
%% rand:uniform(2) call, exactly as xp_coin/0, so the two draw the same stream and
%% a comparison between them is a comparison of encodings and not of samples.
xp_coin_w() -> element(rand:uniform(2), {0.0, 1.0}).

xp_flips(M) -> length([1 || _ <- lists:seq(1, M), rand:uniform(2) =:= 1]).

%%% THE SYNTHETIC MATRIX. FIXED 2026-07-30, AT THE SOURCE.
%%%
%%% WHAT WAS WRONG. xp_from_pairs/2 stored a MARGIN V at {I,J} and -V at {J,I},
%%% and xp_mg/1 is a WIN-RATE differencing operator, so it returned
%%% V - (-V) = 2V. Every synthetic margin was DOUBLE the margin it represented and
%%% every band was therefore effectively HALVED against the synthetic nulls: the
%%% record's band-0.10 match-level row is really a band-0.05 row. The OBSERVED
%%% matrix holds win rates and is differenced correctly, so only the two synthetic
%%% nulls were affected, and only the match-level one moves numerically, because
%%% |2 * (+/-1)| clears every band either way.
%%%
%%% THE FIX IS THE UNITS, NOT A FACTOR AT THE CALL SITE. A synthetic cell now
%%% stores the two WIN RATES of that cell, which is exactly what xp_matrix/2
%%% stores for the observed matrix, so ONE differencing operator is correct for
%%% both and a band means the same thing on both. Antisymmetry is still by
%%% construction: the two cells of a pair sum to 1.0, so no synthetic tournament
%%% can be built with two winners on one edge, and there are no synthetic draws.
xp_from_wins(N, Vals) ->
    Look = maps:from_list(lists:append([[{{I, J}, W}, {{J, I}, 1.0 - W}]
                                        || {I, J, W} <- Vals])),
    Idx = lists:seq(1, N),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

%% THE AS-RUN CONSTRUCTION, KEPT VERBATIM AND RENAMED. It no longer builds any
%% reported null; recovered/1 calls it to put the as-built column beside the
%% corrected one on the SAME draws. DO NOT BUILD A NULL WITH THIS: it stores a
%% margin where the counter expects a win rate.
xp_from_pairs_as_run(N, Vals) ->
    Look = maps:from_list(lists:append([[{{I, J}, V}, {{J, I}, -V}] || {I, J, V} <- Vals])),
    Idx = lists:seq(1, N),
    list_to_tuple([list_to_tuple([maps:get({I, J}, Look, 0.0) || J <- Idx]) || I <- Idx]).

%%% THE n-MATCHED COMPARISON. exp057's zero was counted over 10 objects and 45
%%% pairs; this matrix has 20 objects and 190 pairs, and a count over 3,420
%%% ordered candidates cannot be set beside a count over 360. Random 10-champion
%%% subsamples of THIS matrix give the distribution of the same counter at the same
%%% n, which is the only number comparable to it. What that comparison still
%%% cannot separate is the SUBSTRATE from the OBJECT SET: exp057's ten objects were
%%% successive generations of one coevolutionary run, pre-ordered by monotone
%%% progress and so biased toward transitivity before any arithmetic ran.
xp_subsample(Mtx, N, Sub, Draws) ->
    Mg = xp_mg(Mtx),
    Sets = [xp_pick(N, Sub) || _ <- lists:seq(1, Draws)],
    {subsample, [{n, Sub}, {draws, Draws},
                 {pairs, length(xp_pairs(lists:seq(1, Sub)))},
                 {exp057_object_count, 10}, {exp057_pairs, 45}
                 | [{at_band, B, [{ordered_median, median([xp_ordered(Mg, S, B) || S <- Sets])},
                               {ordered_range, spread([xp_ordered(Mg, S, B) || S <- Sets])},
                               {ordered_zero_draws,
                                length([1 || S <- Sets, xp_ordered(Mg, S, B) =:= 0])},
                               {cycles_median, median([xp_sub_cyc(Mg, S, B) || S <- Sets])},
                               {cycles_range, spread([xp_sub_cyc(Mg, S, B) || S <- Sets])}]}
                    || B <- xp_bands()]]}.

xp_sub_cyc(Mg, S, B) ->
    {F, Bw} = xp_cycles(Mg, S, B),
    F + Bw.

xp_pick(N, Sub) ->
    lists:sort(lists:sublist([X || {_K, X} <- lists:sort([{rand:uniform(), I}
                                                          || I <- lists:seq(1, N)])], Sub)).

spread([]) -> {0.0, 0.0};
spread(Xs) -> {lists:min(Xs), lists:max(Xs)}.

%% The draw share over EVERY match played, not a corner of the matrix. Draws are
%% symmetric, so counting each unordered pair once is the whole matrix.
xp_draws(Cells) ->
    Total = lists:sum([element(7, C) || C <- Cells]),
    Drawn = lists:sum([element(6, C) * element(7, C) || C <- Cells]),
    {draws, [{matches, Total}, {count, round(Drawn)},
             {share, Drawn / max(1, Total)}]}.

%% Granularity: what one flipped match does to a margin, against the band the
%% counter reads. This is the number that decides whether an edge can be an
%% artifact, and the first pass never computed it.
xp_grain(M) ->
    {granularity, [{matches_per_cell, M}, {win_rate_step, 1.0 / M},
                   {one_flipped_match_moves_margin_by, 2.0 / M},
                   {narrowest_band, 0.05}, {headline_band, 0.10},
                   {flips_to_cross_headline_band, ceil(0.10 * M / 2.0)}]}.

xp_edges(Mg, Idx) ->
    As = [abs(Mg(I, J)) || {I, J} <- xp_pairs(Idx)],
    {edges, [{min_abs_margin, lists:min(As)}, {max_abs_margin, lists:max(As)},
             {median_abs_margin, median(As)},
             {signed_spread, spread([Mg(I, J) || {I, J} <- xp_pairs(Idx)])},
             {hist_abs_margin,
              [{'0.000-0.050', length([1 || A <- As, A =< 0.05])},
               {'0.050-0.100', length([1 || A <- As, A > 0.05, A =< 0.10])},
               {'0.100-0.150', length([1 || A <- As, A > 0.10, A =< 0.15])},
               {'0.150-1.000', length([1 || A <- As, A > 0.15])}]}]}.

xp_report(Opts, N, Seeds, Starts, Sym, Cells, Mtx, Repro) ->
    Idx = lists:seq(1, N),
    Mg = xp_mg(Mtx),
    M = element(7, hd(Cells)),
    %% Bound in sequence, not inside the literal below: they share one rand state
    %% and Erlang does not promise an evaluation order for list elements, so the
    %% report would not be reproducible if the order were left to the compiler.
    _ = rand:seed(exsss, {?XP_SEED, ?XP_SEED * 7 + 1, ?XP_SEED * 13 + 3}),
    Sign = xp_null_sign(N, maps:get(xp_null_draws, Opts)),
    Match = xp_null_match(N, maps:get(xp_null_draws, Opts), M),
    Sub = xp_subsample(Mtx, N, maps:get(xp_sub_n, Opts), maps:get(xp_sub_draws, Opts)),
    {crossplay,
     [{date, "2026-07-30"},
      {status, "EXPLORATORY, NOT pre-registered, SIGNS NOTHING on its own"},
      {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
      %% Named, because the as-run runner archived beside this file does NOT contain
      %% this probe: the version that produced the arms' numbers on 2026-07-29 held
      %% the first pass, which persisted nothing. The arms are untouched by the
      %% amendment; only the probe and one dropped emit field changed.
      {produced_by, "experiments/exp066_single_population_floor_tests.erl, AMENDED "
                    "2026-07-30 after a CLAIM gate; same engine pin, arms not re-run"},
      {champions_file, maps:get(xp_champions, Opts)},
      {champions, N}, {seeds, Seeds},
      {starts, length(Starts)}, {pairs, length(xp_pairs(Idx))},
      {ordered_candidates, length(xp_pairs(Idx)) * (N - 2)},
      {unordered_triples, length(xp_triples(Idx))},
      {total_matches, lists:sum([element(7, C) || C <- Cells])},
      {seat_symmetry_selfcheck, Sym},
      xp_grain(M),
      xp_draws(Cells),
      xp_edges(Mg, Idx),
      {counts, [xp_band(Mg, Idx, B) || B <- xp_bands()]},
      xp_null_analytic(N), Sign, Match, Sub, Repro,
      {matrix_note, "row I = champion I's win rate against champion J, both seats, "
                    "all starts; diagonal 0.0; margin(I,J) = W(I,J) - W(J,I)"},
      {matrix, [{row, I, lists:nth(I, Seeds),
                 [wr(Mtx, I, J) || J <- Idx]} || I <- Idx]}]}.

%%% THE PROBE IS NOW A RECORD. Human-readable, tuples and lists only, no maps
%%% anywhere in it, written where the archive keeps the rest of EXP-066.
xp_write(Path, {crossplay, Fields}) ->
    {ok, Fd} = file:open(Path, [write]),
    io:format(Fd, "== EXP-066 exploratory CROSS-PLAY probe: the 20 arm-S champions "
                  "against one another ==~n~n", []),
    [xp_line(Fd, F) || F <- Fields],
    io:format(Fd, "~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) =="
                  "~n~w.~n", [{crossplay, Fields}]),
    file:close(Fd).

xp_line(Fd, {matrix, Rows}) ->
    io:format(Fd, "~nmatrix (win rate of ROW against COLUMN):~n", []),
    [io:format(Fd, "  seed ~p : ~s~n", [S, xp_nums(Ws)]) || {row, _I, S, Ws} <- Rows],
    io:format(Fd, "~n", []);
xp_line(Fd, {at_band, B, Kvs}) ->
    io:format(Fd, "    band ~.2f : ~p~n", [B, Kvs]);
xp_line(Fd, {Key, [H | _] = Kvs}) when is_tuple(H) ->
    io:format(Fd, "~n~p:~n", [Key]),
    [xp_sub(Fd, Kv) || Kv <- Kvs];
xp_line(Fd, {Key, V}) ->
    io:format(Fd, "~p = ~p~n", [Key, V]).

xp_sub(Fd, {at_band, B, Kvs}) -> xp_line(Fd, {at_band, B, Kvs});
xp_sub(Fd, {K, [H | _] = Kvs}) when is_tuple(H) ->
    io:format(Fd, "    ~p:~n", [K]),
    [xp_deep(Fd, Kv) || Kv <- Kvs];
xp_sub(Fd, {K, V}) -> io:format(Fd, "    ~p = ~p~n", [K, V]);
xp_sub(Fd, Other) -> io:format(Fd, "    ~p~n", [Other]).

xp_deep(Fd, {at_band, B, Kvs}) -> io:format(Fd, "        band ~.2f : ~p~n", [B, Kvs]);
xp_deep(Fd, {K, V}) -> io:format(Fd, "        ~p = ~p~n", [K, V]).

xp_nums(Ws) -> lists:join(" ", [io_lib:format("~.4f", [W]) || W <- Ws]).

%%%============================================================================
%%% THE POST-HOC ADDENDUM. Two things the feed does not contain, appended to it
%%% rather than argued around.
%%%
%%% A. THE DROPPED COLUMN. seed_run/4 computes won_opp_shots, IF-12 reads it, and
%%%    the per-seed emit dropped it, so the feed carried IF-12's verdict with its
%%%    evidence absent: nothing on disk could show whether the floor bot ever
%%%    fired in the champion's won matches. "No modifier" is load-bearing in the
%%%    headline claim, so this is recomputed from the archived genomes.
%%%
%%% B. ARM C's ATTEMPT ACCOUNTING. The pre-registration requires "the attempt
%%%    count and the full calibration trajectory" in the raw feed. The feed has
%%%    one line, because the runner holds ONE fixed gains map and no attempt loop.
%%%    That is stated here as the fact it is. NO further attempts are run: arm C
%%%    gates nothing after defect fix D9, and tuning it now, knowing the arms
%%%    cleared, would be calibration after the fact.
%%%
%%% RECOMPUTED IS NOT CAPTURED, and the distinction is marked in the text. This
%%% replays archived champions through the same measurement at the same engine
%%% pin; it is a re-execution, and the recomputed held-out W is printed beside the
%%% feed's own value so that agreement is visible rather than assumed.
%%%============================================================================
addendum() -> addendum(#{}).

addendum(Opts0) ->
    Opts = merged(Opts0),
    K = constants(Opts),
    Arms = [add_arm(Opts, K, A) || A <- maps:get(addendum_arms, Opts)],
    C = arm_c(Opts),
    Lines = add_lines(Opts, K, Arms, C),
    [ok = add_append(P, Lines) || P <- maps:get(addendum_feeds, Opts)],
    io:format("~s", [Lines]),
    {addendum, [{feeds, maps:get(addendum_feeds, Opts)},
                {arms, [{A, W, if12(Med, K)} || {arm, A, _Rs, Med, W} <- Arms]}]}.

add_append(Path, Lines) ->
    {ok, Fd} = file:open(Path, [append]),
    io:format(Fd, "~s", [Lines]),
    file:close(Fd).

add_path(Opts, Arm) ->
    maps:get(archive_dir, Opts) ++ "exp066_champions_" ++ atom_to_list(Arm) ++ ".eterm".

add_arm(Opts, K, Arm) ->
    Held = heldout_starts(Opts),
    Rows = pmap(fun(Ch) -> add_row(Ch, Held) end,
                champion_read(add_path(Opts, Arm)), maps:get(workers, Opts)),
    Med = median_res([R || {arow, R, _Won} <- Rows]),
    {arm, Arm, Rows, Med, if12(Med, K)}.

add_row({champion, Arm, Seed, Layers, Q, Fit, Evals}, Held) ->
    Net = {net, Layers, Q},
    Os = heldout(Net, ?FLOOR, Held),
    {W, L, D} = rates(Os),
    Won = [O || #{alive := true, opp_alive := false} = O <- Os],
    {arow,
     #res{arm = Arm, seed = Seed, layers = Layers, evals = Evals, fit = Fit, q = Q,
          w = W, l = L, d = D, margin = mean_margin(Os), caps = cap_share(Os),
          shots = mean([maps:get(shots, O) || O <- Os]),
          won_opp_shots = won_opp_shots(Os)},
     length(Won)}.

add_lines(Opts, K, Arms, C) ->
    [add_head(Opts),
     add_part_a(K, Arms),
     add_part_b(K, C),
     add_tail()].

add_head(Opts) ->
    io_lib:format(
      "~n~n== ADDENDUM, appended 2026-07-30, POST HOC, recomputed from the champion "
      "archive ==~n~n"
      "WHAT THIS IS. Everything ABOVE this line was written by run/1 during the run of "
      "2026-07-29 and NOTHING above it is changed or re-run. Everything below was "
      "produced afterwards by addendum/1 from the archived champion genomes only, at "
      "engine pin a5e8bcfc5646827e9be49a9629f8a6a9678c814b, on the same 80 held-out "
      "starts, and appended because a CLAIM gate on the draft insight found two things "
      "this feed did not contain.~n~n"
      "Produced by: experiments/exp066_single_population_floor_tests.erl, AMENDED "
      "2026-07-30. The as-run copy archived beside the champions does NOT contain "
      "addendum/1; the amendment adds it, rewrites the cross-play probe so it writes "
      "a file, and emits the dropped column named in section A. NO ARM WAS RE-RUN and "
      "the arms' code path is unchanged apart from that one emit.~n"
      "Archive read: ~s~n"
      "Recomputation is a RE-EXECUTION of the same measurement, not the captured "
      "original. Where a number below can be checked against one above, both are "
      "printed.~n",
      [maps:get(archive_dir, Opts)]).

add_part_a(K, Arms) ->
    [io_lib:format(
       "~n-- A. THE DROPPED won_opp_shots COLUMN, IF-12's raw material --~n~n"
       "WHY IT IS ABSENT ABOVE. seed_run/4 computes won_opp_shots for every seed and "
       "the per-seed emit in arm_report/4 did not print it. Every IF-12 line above "
       "therefore reports a verdict whose evidence is in no record: the feed cannot "
       "show whether the floor bot ever fired in the champion's WON matches, and "
       "'the verdict carries no modifier' rests on exactly that. The runner's emit is "
       "fixed (defect D10) so a future run cannot drop it; these values are recovered.~n~n"
       "S_par (predictive_gun's shots per match against its own CLONE, recomputed) = ~.2f~n"
       "IF-12 threshold = 0.25 * S_par = ~.4f shots. IF-12 reads the MEDIAN champion "
       "by held-out W, by median_res/1, NOT the arm's mean.~n"
       "won_matches is the support of the mean: won_opp_shots is a mean over the "
       "champion's won matches ONLY, and is UNDEFINED, not zero, at zero wins.~n",
       [maps:get(s_par, K), if12_threshold(K)]),
     [add_arm_lines(K, A) || A <- Arms]].

add_arm_lines(K, {arm, Arm, Rows, Med, Fired}) ->
    Ws = [R#res.won_opp_shots || {arow, R, _Won} <- Rows],
    [io_lib:format("~narm ~s, ~p archived champions, recomputed. Compare each W with the "
                   "same seed's W in the arm ~s block above: agreement is evidence the "
                   "archived genome IS the champion the feed measured, and the recomputed "
                   "column beside it is therefore that champion's.~n",
                   [string:uppercase(atom_to_list(Arm)), length(Rows),
                    string:uppercase(atom_to_list(Arm))]),
     [io_lib:format("  seed ~p  W=~.4f  won_opp_shots=~.2f  won_matches=~p  "
                    "shots=~.2f  margin=~.2f~n",
                    [R#res.seed, R#res.w, R#res.won_opp_shots, Won, R#res.shots,
                     R#res.margin])
      || {arow, R, Won} <- Rows],
     io_lib:format("  won_opp_shots over the arm: min=~.2f median=~.2f max=~.2f ; "
                   "seeds individually below the threshold = ~p of ~p~n",
                   [lists:min(Ws), median(Ws), lists:max(Ws),
                    length([1 || X <- Ws, X < if12_threshold(K)]), length(Ws)]),
     io_lib:format("  MEDIAN CHAMPION = seed ~p, W=~.4f, won_opp_shots=~.2f against a "
                   "threshold of ~.4f~n",
                   [Med#res.seed, Med#res.w, Med#res.won_opp_shots, if12_threshold(K)]),
     io_lib:format("  IF-12 RADAR-STARVED, recomputed by if12/2, the same predicate the "
                   "run used = ~s~n", [add_flag(Fired)])].

add_flag(true) -> "FIRED";
add_flag(false) -> "quiet".

add_part_b(K, C) ->
    io_lib:format(
      "~n-- B. ARM C: THE ATTEMPT ACCOUNTING THE PRE-REGISTRATION REQUIRES --~n~n"
      "The pre-registration's stop rule says: an ATTEMPT is one edit to the gains or "
      "one topology change followed by one full evaluation on the 30 calibration "
      "starts; construction stops either when the calibration rate reaches B and 5 "
      "consecutive further attempts fail to raise it, or at 40 attempts (20 per "
      "topology) without reaching B, in which case UNGRADEABLE fires; and THE ATTEMPT "
      "COUNT AND THE FULL CALIBRATION TRAJECTORY GO INTO THE RAW FEED.~n~n"
      "THE HONEST ACCOUNTING:~n"
      "  attempts made                = 1 (the single fixed gains map labelled "
      "ATTEMPT 1 in the runner; arm_c/1 holds no attempt loop, so a second attempt "
      "would have been a source edit)~n"
      "  calibration trajectory       = ONE POINT, ~.4f on the 30 calibration starts. "
      "There is no trajectory. None is invented here.~n"
      "  held-out W_0b                = ~.4f (recomputed; the feed above reports the "
      "same value)~n"
      "  topologies tried             = 1 of the 2 the rule allows, [17,5] only. The "
      "pre-registered fallback to [17,12,5] was never taken, and after defect fix D1 "
      "arm_c_weights/1 REFUSES that topology rather than silently zero-filling it, so "
      "taking the fallback would itself have needed a source edit.~n"
      "  stop rule exercised          = NO. Neither branch was reached: the "
      "calibration rate never reached B=~.4f, so the first branch could not fire, and "
      "1 attempt is not 40, so the second could not either. Construction stopped "
      "because the experimenter stopped, not because the rule stopped it.~n"
      "  attempts run for this addendum = 0, DELIBERATELY. After defect fix D9 arm C "
      "gates nothing, and iterating a construction now, with the evolution arms "
      "already CLEARED at 0.9750, would be calibration after the fact against a known "
      "outcome. The 0.0000 stands as a fact about ONE construction and is not a "
      "measured bound on hand construction in general.~n"
      "  what this costs the front    = nothing that the arms did not already settle. "
      "Expressibility is a property of the network class and an evolved champion "
      "beating the floor bot establishes it a fortiori. What is LOST is the ability to "
      "say anything about how hard the encoding is to hand-build, and that claim is "
      "not made anywhere.~n",
      [maps:get(calibration, C), maps:get(w_0b, C), maps:get(b, K)]).

add_tail() ->
    "\n-- WHAT IS STILL NOT IN THIS RECORD --\n\n"
    "The cross-play probe is NOT in this feed and does not belong in it: it is "
    "exploratory, it was not pre-registered, and it signs nothing. It has its own "
    "record at programmes/p7_coevolution/exp066_competence_floor/exp066_crossplay.txt, "
    "which is where its numbers must be read from. The first pass of that probe "
    "persisted nothing at all, which is the defect this addendum's sibling fixes.\n"
    "== END ADDENDUM ==\n".

%%%============================================================================
%%% THE TWO FLAG FIXES. POST HOC, 2026-07-30, recomputed from the champion
%%% archive. NO ARM IS RE-RUN and no genome is modified.
%%%
%%% FIX A, IF-10. inverted/1 above is now the WIDENED predicate and
%%% inverted_as_run/1 holds the as-run one verbatim, so both are computed over the
%%% same profiles and printed side by side. The reasons are on inverted/1 itself.
%%% The feed of 2026-07-29 is NOT amended: IF-10 quiet on all three arms is what
%%% that run reported and it stands. What changes is what a FUTURE run reports.
%%%
%%% FIX B, PH-GEN, AND IT IS NOT A REPAIR OF IF-8. IF-8 as pre-registered reads
%%% train_w >= B AND held-out < B. train_w is 1.0000 for 40 of 40 champions, and
%%% not by accident: the train split is 6 starts times 2 seats = 12 matches, and
%%% ladder/3 clears a rung only when EVERY match of that rung has a positive
%%% margin, over exactly those same 12 matches, so any champion whose archived
%%% fitness cleared the gun rung had 12 positive margins there. The left conjunct
%%% is vacuously true everywhere and IF-8 collapses to the negation of half the
%%% CLEARED test. THAT IS PERMANENT AND IT IS NOT REPAIRED HERE. IF-8 was
%%% untestable with this instrument, its quiet state carries no information about
%%% memorisation, and nothing below changes that.
%%%
%%% PH-GEN is a NEW, POST-HOC diagnostic. The name is deliberately not an IF code
%%% and must never be written as one. It does not restore IF-8, it does not
%%% license reading IF-8's quiet state as a result, and it was not pre-registered.
%%%
%%% WHAT PH-GEN READS. The honest THREE-WAY split. split/1 cuts one deterministic
%%% 120-start generator into train 1..6, held-out 7..86 and calibration 87..116,
%%% disjoint by index construction and asserted by gate_starts/0. The 30
%%% calibration starts were used to build and tune arm C and to measure NO
%%% champion, so they are a genuine third set. Per champion, against the floor
%%% bot: 12, 60 and 160 matches; the win rate on each; and the mean of margin/1 in
%%% whole units on each. The margin is the FLOORED one the fitness itself reads,
%%% because the death floor has to be applied on both sides for two splits to be
%%% comparable at all. The feed's own margin column does NOT floor, so it is not
%%% comparable across splits and appears here only to tie a row back to the feed.
%%%
%%% EVALUATING AN ARCHIVED CHAMPION ON THE CALIBRATION STARTS IS A MATCH REPLAY,
%%% NOT AN ARM RE-RUN. The path is heldout/3 -> duel/3 -> play_seat/5 -> play/2 ->
%%% robo_sim, with pilot_act/4 and robo_gauntlet:act/4 as the two controllers.
%%% Nothing under arm/2, seed_run/4, one_run/4, fitness_fun/5 or the col_*
%%% collector is called, so no optimiser runs. ladder/3 IS called, on the train
%%% starts only, to recompute each champion's archived FITNESS as a provenance
%%% check: ladder/3 is the fitness FUNCTION, not the optimiser.
%%%============================================================================

%% One archived champion, remeasured on all three splits. A record, so an emit
%% cannot silently take the wrong column.
-record(fx, {
    arm, seed, layers, fit,
    profile = [],                    %% [{Kind, W, L, D}] on the HELD-OUT 80
    old = false,                     %% IF-10 under the as-run predicate
    new = false,                     %% IF-10 under the widened predicate
    trips = [],                      %% [{Kind, loses | draw_parked}]
    fit_recomputed = 0.0,            %% ladder/3 on the train starts
    tw = 0.0, tfl = 0.0, tdm = 0.0,  %% train: W, floored margin, raw margin
    cw = 0.0, cfl = 0.0, cdm = 0.0,  %% calibration: the same three
    hw = 0.0, hfl = 0.0, hdm = 0.0   %% held out: the same three
}).

flag_fixes() -> flag_fixes(#{}).

flag_fixes(Opts0) ->
    Opts = merged(Opts0),
    K = constants(Opts),
    Arms = [fx_arm(Opts, A) || A <- maps:get(addendum_arms, Opts)],
    ok = file:write_file(maps:get(fx_out, Opts), [fx_record(Opts, K, Arms)]),
    Note = fx_feed_note(Opts, Arms),
    [ok = add_append(P, Note) || P <- maps:get(addendum_feeds, Opts)],
    io:format("~s", [Note]),
    {flag_fixes,
     [{record, maps:get(fx_out, Opts)},
      {feeds, maps:get(addendum_feeds, Opts)},
      {if10, [{A, length(Rows), fx_old(Rows), fx_new(Rows)} || {arm, A, Rows} <- Arms]}]}.

fx_arm(Opts, Arm) ->
    Rows = pmap(fun(Ch) -> fx_row(Ch, Opts) end,
                champion_read(add_path(Opts, Arm)), maps:get(workers, Opts)),
    {arm, Arm, Rows}.

fx_row({champion, Arm, Seed, Layers, Q, Fit, _Evals}, Opts) ->
    Net = {net, Layers, Q},
    Prof = profile(Net, heldout_starts(Opts)),
    {TW, TFl, TDm} = fx_split(Net, train_starts(Opts)),
    {CW, CFl, CDm} = fx_split(Net, calib_starts(Opts)),
    {HW, HFl, HDm} = fx_split(Net, heldout_starts(Opts)),
    #fx{arm = Arm, seed = Seed, layers = Layers, fit = Fit, profile = Prof,
        old = inverted_as_run(Prof), new = inverted(Prof),
        trips = unbeaten_rungs(Prof),
        fit_recomputed = ladder(Net, rungs(Arm), train_starts(Opts)),
        tw = TW, tfl = TFl, tdm = TDm,
        cw = CW, cfl = CFl, cdm = CDm,
        hw = HW, hfl = HFl, hdm = HDm}.

%% One split against the floor bot: win rate, the FLOORED mean margin in whole
%% units, and the raw dealt-minus-taken mean the feed's margin column carries.
fx_split(Net, Starts) ->
    Os = heldout(Net, ?FLOOR, Starts),
    {win_rate(Os), mean([margin(O) || O <- Os]) / ?FP, mean_margin(Os)}.

fx_old(Rows) -> length([1 || R <- Rows, R#fx.old]).
fx_new(Rows) -> length([1 || R <- Rows, R#fx.new]).

%% The median champion by the run's OWN rule, median_res/1, reused rather than
%% restated so the two cannot drift. The champion list is in ascending seed order,
%% which is the order arm/2 produced, so the lower median lands on the same seed.
fx_median(Rows) ->
    Med = median_res([#res{seed = R#fx.seed, w = R#fx.hw} || R <- Rows]),
    lists:keyfind(Med#res.seed, #fx.seed, Rows).

%% THE TIER LABELS ARE NOT NEW AND NOTHING HERE CHOOSES THEM. This is the
%% operational rule the two-attractors probe already published (held-out W below
%% 0.62 is the near-parity mode, above 0.93 the kill mode), which reproduces the
%% signed insight's 13 / 1 / 6 partition of arm S seed for seed. It is applied
%% UNCHANGED to arms L and D, where no partition was published, and a champion
%% between the two is reported as mid rather than pushed into a tier.
tier(W) when W < 0.62 -> low;
tier(W) when W > 0.93 -> high;
tier(_W) -> mid.

fx_cell(Profile, K) ->
    {K, W, _L, D} = lists:keyfind(K, 1, Profile),
    {W, D}.

%%%----------------------------------------------------------------------------
%%% The record file.
%%%----------------------------------------------------------------------------
fx_record(Opts, K, Arms) ->
    [fx_head(Opts, K), fx_sec_a(Arms), fx_sec_b(K, Arms), fx_sec_c(Arms), fx_sec_d(),
     fx_term(Opts, Arms)].

fx_head(Opts, K) ->
    io_lib:format(
      "== EXP-066 FLAG FIXES: IF-10 WIDENED, PLUS ONE NEW POST-HOC GENERALISATION~n"
      "   DIAGNOSTIC, BOTH RECOMPUTED FROM THE CHAMPION ARCHIVE ==~n~n"
      "Date: 2026-07-30. Engine pin a5e8bcfc5646827e9be49a9629f8a6a9678c814b.~n"
      "Produced by: experiments/exp066_single_population_floor_tests.erl, flag_fixes/1,~n"
      "  driven by scripts/exp066_flag_fixes.sh. Archive read: ~s~n"
      "  (exp066_champions_s.eterm 20, _l.eterm 10, _d.eterm 10; 40 champions).~n~n"
      "NO ARM WAS RE-RUN AND NO GENOME WAS MODIFIED. Every number below comes from~n"
      "replaying archived champions through matches at the engine pin. The call path~n"
      "is heldout/3 -> duel/3 -> play_seat/5 -> play/2 -> robo_sim; ladder/3 is also~n"
      "called, on the 6 train starts only, to recompute each champion's archived~n"
      "FITNESS as a provenance check. ladder/3 is the fitness function, not the~n"
      "optimiser: nothing under arm/2, seed_run/4, one_run/4, fitness_fun/5 or the~n"
      "col_* collector is called anywhere in this record.~n~n"
      "WHAT THIS RECORD IS. Two things the signed insight~n"
      "066-evolution-clears-the-robo-rumble-competence-floor.md names as owed work in~n"
      "its final section, item 4.~n~n"
      "  FIX A  IF-10 LADDER-INVERSION. A defect fix to a PRE-REGISTERED predicate:~n"
      "         it read two of the four lower rungs and was draw-blind. Both~n"
      "         predicates are computed over the same profiles and printed side by~n"
      "         side. The as-run feed is NOT amended and IF-10's quiet state there~n"
      "         stands as what the run of 2026-07-29 reported.~n~n"
      "  FIX B  PH-GEN, a NEW POST-HOC three-split generalisation diagnostic. IT IS~n"
      "         NOT A REPAIR OF IF-8 and PH-GEN is NOT an IF code. IF-8 was~n"
      "         untestable with this instrument, that fact is permanent, and nothing~n"
      "         here restores it or licenses reading its quiet state as a result.~n~n"
      "WHAT THIS RECORD IS NOT. It is not pre-registered, it signs nothing, and no~n"
      "threshold in it was chosen to produce a result. The one threshold FIX A adds~n"
      "is D > 0.5, which is the definition of a majority on a fixed 160 matches.~n"
      "The tier labels are the two-attractors probe's already published rule, reused~n"
      "unchanged. Where a computation separates nothing, this record says so.~n~n"
      "REPRODUCIBILITY, AND THE ONE RANDOM NUMBER. Every match here is a deterministic~n"
      "integer simulation on a deterministic start set, so no measurement in this~n"
      "record comes off rand. The ONE quantity that does is B, quoted in section B: it~n"
      "comes from constants/1's START-LEVEL BOOTSTRAP over predictive_gun against its~n"
      "own clone, seeded from BOOT_SEED = 66 with 10,000 resamples, both fixed in the~n"
      "runner's source, so B = ~.4f is reproducible and is the same B the run of~n"
      "2026-07-29 froze. Two independent executions of flag_fixes/1 produced~n"
      "byte-identical copies of this file.~n~n"
      "THIS FILE IS REGENERABLE, THE FEED NOTE IS NOT. flag_fixes/1 overwrites this~n"
      "record, so it can be re-run at will (scripts/exp066_flag_fixes.sh record). The~n"
      "note it appends to the two feed copies is APPEND-ONLY and was written once, on~n"
      "2026-07-30; re-running the appending mode would add a second copy of it.~n",
      [maps:get(archive_dir, Opts), maps:get(b, K)]).

%%%----------------------------------------------------------------------------
%%% FIX A.
%%%----------------------------------------------------------------------------
fx_sec_a(Arms) ->
    [io_lib:format(
       "~n~n-- A. FIX A: IF-10 LADDER-INVERSION, AS-RUN PREDICATE BESIDE THE WIDENED ONE --~n~n"
       "AS-RUN (what the run of 2026-07-29 computed), inverted_as_run/1:~n"
       "  any rung K of [sitting_duck, spinner] with L > W~n~n"
       "WIDENED (what a future run computes), inverted/1:~n"
       "  any rung K of [sitting_duck, spinner, rammer, circle_strafer]~n"
       "  with L > W orelse D > 0.5~n~n"
       "THE THREE CHANGES, AND WHY NONE OF THEM IS A THRESHOLD MOVE.~n"
       "  1. FOUR LOWER RUNGS, not two. The as-run list never looked at the rammer or~n"
       "     the circle_strafer. Arm D's median champion, seed 2007, loses the RAMMER,~n"
       "     and IF-10 stayed quiet. Nothing was reweighted: two rungs that were~n"
       "     already in every profile were simply read.~n"
       "  2. DRAW-PARKED COUNTS AS NOT BEATEN. L > W alone is draw-blind. The~n"
       "     threshold is D > 0.5 and it is NOT a tunable: it is what 'the majority~n"
       "     outcome of this rung is a draw' means on a fixed 160 matches. Half is~n"
       "     not a fitted value. No other value was tried.~n"
       "  3. PER SEED WITH A COUNT, not only on the median champion. flags/3 now~n"
       "     emits both counts over the whole arm. The median champion is one seed.~n"
       "     The two counts in the table below are computed by inverted/1 and~n"
       "     inverted_as_run/1, which are the same two functions flags/3's new note~n"
       "     lines call, over the same held-out profiles, so a future run's feed will~n"
       "     carry these same numbers rather than numbers of a second kind.~n~n"
       "All profiles below are RECOMPUTED from the archived genome on the same 80~n"
       "held-out starts, all five rungs, 160 matches per rung. L is omitted from the~n"
       "table because rates/1 makes W + L + D exactly 1.0, so W and D determine it.~n~n"
       "arm  champions  as-run FIRES  widened FIRES  median champ  as-run  widened~n", []),
     [fx_a_arm(A) || A <- Arms],
     io_lib:format(
       "~nPER SEED. W/D per lower rung on the held-out 80. tier is the two-attractors~n"
       "probe's published rule on held-out W against the floor bot (below 0.62 low,~n"
       "above 0.93 high, else mid), reused unchanged.~n~n"
       "arm seed tier    duck W/D    spinner W/D    rammer W/D   strafer W/D"
       "    as-run widened~n", []),
     [[fx_a_row(R) || R <- Rows] || {arm, _A, Rows} <- Arms],
     io_lib:format(
       "~nWHICH RUNGS TRIP THE WIDENED PREDICATE, AND ON WHICH GROUND. loses means~n"
       "L > W on that rung; draw_parked means D > 0.5. A cell can satisfy both and~n"
       "loses is reported first because losing is the stronger statement. Champions~n"
       "that trip nothing are absent from this list.~n~n", []),
     [[fx_a_trip(R) || R <- Rows, R#fx.new] || {arm, _A, Rows} <- Arms],
     fx_a_prediction(Arms)].

fx_a_arm({arm, A, Rows}) ->
    Med = fx_median(Rows),
    io_lib:format("~3s ~10w ~13w ~14w ~13w ~7s ~8s~n",
                  [atom_to_list(A), length(Rows), fx_old(Rows), fx_new(Rows),
                   Med#fx.seed, add_flag(Med#fx.old), add_flag(Med#fx.new)]).

fx_a_row(R) ->
    {DW, DD} = fx_cell(R#fx.profile, sitting_duck),
    {SW, SD} = fx_cell(R#fx.profile, spinner),
    {RW, RD} = fx_cell(R#fx.profile, rammer),
    {CW, CD} = fx_cell(R#fx.profile, circle_strafer),
    io_lib:format("~3s ~4w ~-5s ~6.4f/~6.4f ~6.4f/~6.4f ~6.4f/~6.4f ~6.4f/~6.4f "
                  " ~-6s ~s~n",
                  [atom_to_list(R#fx.arm), R#fx.seed, atom_to_list(tier(R#fx.hw)),
                   DW, DD, SW, SD, RW, RD, CW, CD,
                   add_flag(R#fx.old), add_flag(R#fx.new)]).

fx_a_trip(R) ->
    io_lib:format("  arm ~s seed ~w  W=~.4f  trips ~w~n",
                  [atom_to_list(R#fx.arm), R#fx.seed, R#fx.hw, R#fx.trips]).

%% The insight predicted, IN ADVANCE of this recomputation, that widening the
%% member list "flips IF-10 loud on arm D with no change of criterion, no new
%% threshold and no re-run". IF-10 reads the median champion, so that is where the
%% prediction is tested. It is reported as it comes out.
fx_a_prediction(Arms) -> fx_a_pred(lists:keyfind(d, 2, Arms)).

fx_a_pred(false) ->
    "\nTHE INSIGHT'S PREDICTION IS NOT TESTED HERE: arm D was not measured in this\n"
    "configuration.\n";
fx_a_pred({arm, d, Rows}) ->
    Med = fx_median(Rows),
    io_lib:format(
      "~nTHE INSIGHT'S PREDICTION, TESTED. It predicted that widening the member list~n"
      "flips IF-10 LOUD on arm D with no change of criterion and no re-run. IF-10~n"
      "reads the median champion, so that is where it is tested.~n"
      "  arm D median champion  = seed ~w, held-out W = ~.4f~n"
      "  IF-10 as-run           = ~s~n"
      "  IF-10 widened          = ~s~n"
      "  rungs tripping         = ~w~n"
      "  PREDICTION HELD        = ~w~n",
      [Med#fx.seed, Med#fx.hw, add_flag(Med#fx.old), add_flag(Med#fx.new),
       Med#fx.trips, Med#fx.old =:= false andalso Med#fx.new =:= true]).

%%%----------------------------------------------------------------------------
%%% FIX B.
%%%----------------------------------------------------------------------------
fx_sec_b(K, Arms) ->
    [io_lib:format(
       "~n~n-- B. FIX B: PH-GEN, A NEW POST-HOC THREE-SPLIT GENERALISATION DIAGNOSTIC --~n~n"
       "PH-GEN IS NOT AN IF CODE AND IS NOT A REPAIR OF IF-8. Read this first.~n~n"
       "WHAT IF-8 WAS. 'IF-8 MEMORISATION' fires when train_w >= B and held-out W <~n"
       "B, with B = ~.4f. train_w reads 1.0000 for 40 of 40 champions, and that is~n"
       "forced by the design rather than observed: the train split is 6 starts times~n"
       "2 seats = 12 matches, one step is 1/12 = 0.0833, and ladder/3 clears a rung~n"
       "only when EVERY match of it has a positive margin over exactly those same 12~n"
       "matches. Any champion whose archived fitness cleared the gun rung therefore~n"
       "had 12 positive margins there, and in every case 12 wins. The left conjunct~n"
       "is vacuously true everywhere, so IF-8 collapses to 'the median champion is~n"
       "below B', which is the negation of half the CLEARED test and carries no~n"
       "train-to-held-out contrast at all.~n~n"
       "THAT STANDS. IF-8 was untestable with this instrument, its quiet state in the~n"
       "feed says nothing about memorisation, and PH-GEN does not change that. IF-8 is~n"
       "not modified, not rescored and not reinterpreted anywhere in this record.~n~n"
       "WHAT PH-GEN IS. A NEW diagnostic, post hoc, unregistered, first computed~n"
       "2026-07-30. It reads the honest three-way split of one deterministic 120-start~n"
       "generator:~n"
       "  train        starts   1..6    6 starts, 12 matches   the optimiser saw these~n"
       "  held out     starts   7..86  80 starts, 160 matches  the gate lives here~n"
       "  calibration  starts  87..116 30 starts, 60 matches   built arm C, measured~n"
       "                                                       NO champion~n"
       "Disjoint by index construction and asserted by gate_starts/0. Starts 117..120~n"
       "are generated and deliberately unused.~n~n"
       "HOW CLEAN THE THIRD SET ACTUALLY IS, stated exactly. During the RUN the~n"
       "calibration starts scored arm C and nothing else: no evolution arm and no~n"
       "champion was ever measured on them, and nothing was ever selected using them.~n"
       "They have since been READ ONCE, post hoc: exp066_two_attractors_probe.txt~n"
       "section K reports the calibration win rate of all 20 arm S champions, and the~n"
       "calW column below reproduces it. So for arm S this is a re-read of an already~n"
       "published post-hoc measurement, not a first look, and it is not a held-back~n"
       "test set in the strict sense any more. For arms L and D it is a first look.~n"
       "Either way nothing was selected on it, which is the property that matters.~n~n"
       "TWO QUANTITIES PER SPLIT, both against the floor bot. (a) the win rate, the~n"
       "same rule the gate uses, draws counting as not beating. (b) the mean of~n"
       "margin/1 in whole units: the FLOORED margin, which applies the one-bar death~n"
       "floor on both sides. Floored is what makes two splits comparable and is also~n"
       "exactly what the fitness reads. THE FEED'S OWN margin COLUMN DOES NOT FLOOR,~n"
       "so it is not comparable across splits; it appears in section C only, to tie~n"
       "each row back to the feed.~n~n"
       "REPLAY, NOT A RE-RUN. Scoring an archived champion on the calibration starts~n"
       "is heldout/3 -> duel/3 -> play_seat/5 -> play/2 -> robo_sim. No optimiser is~n"
       "reachable from that path. Confirmed by reading the code, and stated here.~n~n"
       "WHAT IS NEW HERE AND WHAT IS NOT, per column.~n"
       "  train_fl, held_fl, ARM S    NOT NEW. exp066_two_attractors_probe.txt~n"
       "                              section G carries them as train_gun, heldout_gun~n"
       "                              and gap, computed by a different script from the~n"
       "                              same archive. They must agree digit for digit,~n"
       "                              and that agreement is this table's cross-check.~n"
       "  calW, ARM S                 NOT NEW. Section K of the same probe carries it.~n"
       "                              Same cross-check.~n"
       "  cal_fl, EVERY ARM           NEW. No record carried a floored margin on the~n"
       "                              calibration starts for any champion.~n"
       "  every column, ARMS L and D  NEW. No floored margin on any split, and no~n"
       "                              calibration measurement, existed for those 20.~n",
       [maps:get(b, K)]),
     io_lib:format(
       "~n~nB1. WIN RATE ON EACH SPLIT, AND THE GAPS.~n~n"
       "t-c is train minus calibration, t-h train minus held out, c-h calibration~n"
       "minus held out. A positive gap is a champion doing better on the split the~n"
       "optimiser saw.~n~n"
       "arm seed tier   trainW    calW   heldW      t-c      t-h      c-h~n", []),
     [[fx_b1_row(R) || R <- Rows] || {arm, _A, Rows} <- Arms],
     io_lib:format(
       "~n~nB2. FLOORED MARGIN ON EACH SPLIT, WHOLE UNITS, AND THE GAPS.~n~n"
       "The gun rung only, which is the rung the gate is defined on. Same three~n"
       "splits, same gap convention.~n~n"
       "arm seed tier  train_fl   cal_fl  held_fl      t-c      t-h      c-h~n", []),
     [[fx_b2_row(R) || R <- Rows] || {arm, _A, Rows} <- Arms],
     fx_b_resolution(Arms),
     fx_b_saturation(Arms)].

fx_b1_row(R) ->
    io_lib:format("~3s ~4w ~-5s ~7.4f ~7.4f ~7.4f  ~7.4f  ~7.4f  ~7.4f~n",
                  [atom_to_list(R#fx.arm), R#fx.seed, atom_to_list(tier(R#fx.hw)),
                   R#fx.tw, R#fx.cw, R#fx.hw,
                   R#fx.tw - R#fx.cw, R#fx.tw - R#fx.hw, R#fx.cw - R#fx.hw]).

fx_b2_row(R) ->
    io_lib:format("~3s ~4w ~-5s ~9.2f ~8.2f ~8.2f  ~7.2f  ~7.2f  ~7.2f~n",
                  [atom_to_list(R#fx.arm), R#fx.seed, atom_to_list(tier(R#fx.hw)),
                   R#fx.tfl, R#fx.cfl, R#fx.hfl,
                   R#fx.tfl - R#fx.cfl, R#fx.tfl - R#fx.hfl, R#fx.cfl - R#fx.hfl]).

%%%----------------------------------------------------------------------------
%%% Does PH-GEN have any resolution? Reported as it comes out. The ranges are a
%%% description of numbers that already exist: no cut point is chosen anywhere
%%% below, and an overlap is printed as an overlap.
%%%----------------------------------------------------------------------------
fx_b_resolution(Arms) ->
    Rows = lists:append([Rs || {arm, _A, Rs} <- Arms]),
    [io_lib:format(
       "~n~nB3. DOES PH-GEN SEPARATE THE TWO MODES? THE RANGES, PER ARM, PER TIER.~n~n"
       "The question the ceilinged flag could not answer: is the split visible in a~n"
       "train-to-held-out contrast at all? Below, for each arm and each tier, the min~n"
       "and max of one quantity WITHIN that tier, then whether the low and high tiers'~n"
       "ranges overlap. NO CUT POINT IS CHOSEN HERE, nothing is fitted, and a quantity~n"
       "that does not separate is printed as not separating. Ranges carry four~n"
       "decimals; the same margins appear to two decimals in B2.~n~n"
       "READ THE (circular) TAG FIRST. THE TIERS ARE DEFINED BY HELD-OUT W, so any~n"
       "quantity computed on the held-out split is not independent of the labels it is~n"
       "being asked to separate, and a clean split of such a quantity is close to a~n"
       "restatement of the definition. The W gap is the worst case and is marked so:~n"
       "train W is exactly 1.0000 for ~w of ~w champions, so train-minus-held-out W is~n"
       "1.0000 minus held-out W identically, and its tier separation is a TAUTOLOGY~n"
       "and no evidence of anything. Lines marked (independent) use only the train and~n"
       "calibration splits, neither of which enters the tier definition; those are the~n"
       "lines that carry information.~n~n",
       [fx_ceil(Rows, fun(R) -> R#fx.tw end), length(Rows)]),
     [fx_res_arm(A) || A <- Arms]].

fx_res_arm({arm, A, Rows}) ->
    [io_lib:format("arm ~s, ~w champions, tier sizes ~w~n",
                   [atom_to_list(A), length(Rows), fx_sizes(Rows)]),
     fx_res_line("FLOORED margin, TRAIN only    (independent)",
                 fx_ranges(Rows, fun(R) -> R#fx.tfl end)),
     fx_res_line("FLOORED margin, CALIBRATION   (independent)",
                 fx_ranges(Rows, fun(R) -> R#fx.cfl end)),
     fx_res_line("W on CALIBRATION              (independent)",
                 fx_ranges(Rows, fun(R) -> R#fx.cw end)),
     fx_res_line("FLOORED gap, train minus held (held-out)  ",
                 fx_ranges(Rows, fun(R) -> R#fx.tfl - R#fx.hfl end)),
     fx_res_line("FLOORED margin, HELD OUT      (held-out)  ",
                 fx_ranges(Rows, fun(R) -> R#fx.hfl end)),
     fx_res_line("W gap, train minus held out   (circular)  ",
                 fx_ranges(Rows, fun(R) -> R#fx.tw - R#fx.hw end)),
     io_lib:format("~n", [])].

fx_res_line(Label, Ranges) ->
    io_lib:format("  ~s -> ~s~n"
                  "     low ~-19s mid ~-19s high ~s~n",
                  [Label, fx_ovtext(fx_overlap(Ranges)),
                   fx_rtext(lists:keyfind(low, 1, Ranges)),
                   fx_rtext(lists:keyfind(mid, 1, Ranges)),
                   fx_rtext(lists:keyfind(high, 1, Ranges))]).

fx_ranges(Rows, Fun) ->
    [{T, fx_range([Fun(R) || R <- Rows, tier(R#fx.hw) =:= T])} || T <- [low, mid, high]].

fx_range([]) -> empty;
fx_range(Vs) -> {lists:min(Vs), lists:max(Vs)}.

fx_rtext({_T, empty}) -> "(none)";
fx_rtext({_T, {Min, Max}}) -> io_lib:format("~.4f..~.4f", [Min, Max]).

fx_overlap(Ranges) ->
    fx_ov(element(2, lists:keyfind(low, 1, Ranges)),
          element(2, lists:keyfind(high, 1, Ranges))).

fx_ov(empty, _High) -> not_testable;
fx_ov(_Low, empty) -> not_testable;
fx_ov({_LMin, LMax}, {HMin, _HMax}) when LMax < HMin -> {disjoint, high_above};
fx_ov({LMin, _LMax}, {_HMin, HMax}) when HMax < LMin -> {disjoint, low_above};
fx_ov(_Low, _High) -> overlapping.

fx_ovtext(not_testable) -> "NOT TESTABLE, one tier is empty here";
fx_ovtext(overlapping) -> "OVERLAPPING, does NOT separate the tiers";
fx_ovtext({disjoint, low_above}) -> "DISJOINT, near-parity ABOVE kill mode";
fx_ovtext({disjoint, high_above}) -> "DISJOINT, kill mode ABOVE near-parity".

fx_sizes(Rows) ->
    [{T, length([1 || R <- Rows, tier(R#fx.hw) =:= T])} || T <- [low, mid, high]].

%%%----------------------------------------------------------------------------
%%% Does PH-GEN saturate too? Asked because the flag it stands beside did.
%%%----------------------------------------------------------------------------
fx_b_saturation(Arms) ->
    Rows = lists:append([Rs || {arm, _A, Rs} <- Arms]),
    io_lib:format(
      "~n~nB4. DOES PH-GEN SATURATE TOO? IF-8 FAILED BECAUSE ITS INSTRUMENT SAT AT A~n"
      "CEILING, SO THE SAME QUESTION IS ASKED OF PH-GEN.~n~n"
      "Champions at a win rate of exactly 1.0000, out of ~w:~n"
      "  train        ~w of ~w  (12 matches; the ceiling IS the fitness rule, see above)~n"
      "  calibration  ~w of ~w  (60 matches)~n"
      "  held out     ~w of ~w  (160 matches)~n~n"
      "The FLOORED margin has no ceiling and reaches none. Over all ~w champions:~n"
      "  train        min ~.2f  max ~.2f~n"
      "  calibration  min ~.2f  max ~.2f~n"
      "  held out     min ~.2f  max ~.2f~n~n"
      "READING, AND IT IS HALF A NEGATIVE. The WIN RATE leg of PH-GEN SATURATES on the~n"
      "train split exactly as IF-8's train_w does and for exactly the same reason, so~n"
      "one of PH-GEN's two legs inherits the defect it was built beside. It is~n"
      "reported rather than dropped, and it partially saturates on the other two~n"
      "splits as well. The FLOORED MARGIN leg does not saturate on any split and it is~n"
      "the leg that carries the diagnostic. Whether either leg RESOLVES anything is~n"
      "section B3's question, and the answer is whatever B3 printed, including where~n"
      "B3 marks a separation circular.~n",
      [length(Rows),
       fx_ceil(Rows, fun(R) -> R#fx.tw end), length(Rows),
       fx_ceil(Rows, fun(R) -> R#fx.cw end), length(Rows),
       fx_ceil(Rows, fun(R) -> R#fx.hw end), length(Rows),
       length(Rows),
       lists:min([R#fx.tfl || R <- Rows]), lists:max([R#fx.tfl || R <- Rows]),
       lists:min([R#fx.cfl || R <- Rows]), lists:max([R#fx.cfl || R <- Rows]),
       lists:min([R#fx.hfl || R <- Rows]), lists:max([R#fx.hfl || R <- Rows])]).

fx_ceil(Rows, Fun) -> length([1 || R <- Rows, Fun(R) >= 1.0]).

%%%----------------------------------------------------------------------------
%%% Provenance.
%%%----------------------------------------------------------------------------
fx_sec_c(Arms) ->
    Rows = lists:append([Rs || {arm, _A, Rs} <- Arms]),
    Ds = [abs(R#fx.fit - R#fx.fit_recomputed) || R <- Rows],
    [io_lib:format(
       "~n~n-- C. PROVENANCE: IS THE ARCHIVED GENOME THE CHAMPION THE FEED MEASURED? --~n~n"
       "Two checks, both mechanical.~n~n"
       "CHECK 1, THE FITNESS. ladder/3 is re-run on the 6 train starts with the arm's~n"
       "own rung list (all five for S and L, the gun rung alone for D) and compared~n"
       "with the Fit field stored in the archive. Champions whose recomputed fitness~n"
       "is EXACTLY the archived float: ~w of ~w. Largest absolute difference: ~e.~n~n"
       "CHECK 2, THE HELD-OUT COLUMNS. The recomputed held-out W and the recomputed~n"
       "raw (UNFLOORED) held-out margin are printed below beside nothing, because the~n"
       "value they must equal lives in the feed rather than in this file. Compare~n"
       "each row with the same seed's W= and margin= fields in the feed's arm block:~n"
       "  arm S seeds 2001..2020  exp066_floor_feed.txt lines 35..74~n"
       "  arm L seeds 2001..2010  lines 251..270~n"
       "  arm D seeds 2001..2010  lines 367..386~n"
       "and with the rung profiles at lines 135..234 (S), 301..350 (L), 417..466 (D).~n"
       "scripts/exp066_verify_flag_fixes.escript does that comparison mechanically,~n"
       "parsing both the feed and this record's machine-readable term.~n~n"
       "arm seed  fit_archive  fit_recomputed        heldW  held_margin_raw~n",
       [length([1 || R <- Rows, R#fx.fit =:= R#fx.fit_recomputed]),
        length(Rows), lists:max(Ds)]),
     [[fx_c_row(R) || R <- Rows2] || {arm, _A, Rows2} <- Arms],
     io_lib:format(
       "~nThe raw margin column is the feed's own convention, dealt minus taken with~n"
       "NO death floor, and it is NOT comparable with section B2's floored columns.~n"
       "It is here for one purpose: to tie each row to the feed.~n", [])].

fx_c_row(R) ->
    io_lib:format("~3s ~4w ~12.4f ~15.4f ~12.4f ~16.2f~n",
                  [atom_to_list(R#fx.arm), R#fx.seed, R#fx.fit, R#fx.fit_recomputed,
                   R#fx.hw, R#fx.hdm]).

fx_sec_d() ->
    "\n\n-- D. WHAT THIS RECORD DOES NOT DO --\n\n"
    "It does not amend the feed above its own appended note. The as-run feed of\n"
    "2026-07-29 reports IF-10 quiet on all three arms and that is what the run\n"
    "reported; the widened predicate is what a FUTURE run will report, and both are\n"
    "printed here so the difference is visible.\n\n"
    "It does not repair IF-8, claim IF-8 now works, or re-read IF-8's quiet state as\n"
    "evidence about memorisation. IF-8 was untestable with this instrument.\n\n"
    "It does not touch the signed insight. A pointer there is a separate act.\n\n"
    "It does not claim intransitivity. A champion that beats the floor bot while\n"
    "leaving a lower rung unbeaten is an OBSERVABLE, which is what IF-10 was always\n"
    "declared to be. Whether that is intransitivity is phase 1's question and needs\n"
    "the third leg of the triple, which is not measured here.\n\n"
    "It does not re-run an arm, modify a genome, or move a pre-registered threshold.\n"
    "The pre-registered constants B, R_line and D_min are untouched.\n"
    "It does not sign anything.\n".

%%%----------------------------------------------------------------------------
%%% One machine-readable term at the foot, tuples and lists only.
%%%----------------------------------------------------------------------------
fx_term(Opts, Arms) ->
    io_lib:format(
      "~n~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n~w.~n",
      [{flag_fixes,
        [{date, "2026-07-30"},
         {status, "POST HOC. FIX A is a defect fix to a pre-registered predicate. "
                  "FIX B is a NEW post-hoc diagnostic and is NOT a repair of IF-8."},
         {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
         {produced_by, "exp066_single_population_floor_tests:flag_fixes/1"},
         {archive_dir, maps:get(archive_dir, Opts)},
         {splits, [{train, 6, 12}, {calibration, 30, 60}, {heldout, 80, 160}]},
         {if10_as_run, [{rungs, [sitting_duck, spinner]}, {test, "L > W"}]},
         {if10_widened,
          [{rungs, [sitting_duck, spinner, rammer, circle_strafer]},
           {test, "L > W orelse D > 0.5"}]},
         {tier_rule, "held-out W below 0.62 low, above 0.93 high, else mid; the "
                     "two-attractors probe's published rule, reused unchanged"},
         {row_shape,
          {row, seed, tier, if10_as_run, if10_widened, trips,
           train_w, calib_w, heldout_w,
           train_floored, calib_floored, heldout_floored,
           train_raw, calib_raw, heldout_raw,
           fit_archive, fit_recomputed, heldout_profile}},
         {arms, [fx_term_arm(A) || A <- Arms]}]}]).

fx_term_arm({arm, A, Rows}) ->
    Med = fx_median(Rows),
    {arm, A,
     [{champions, length(Rows)},
      {if10_as_run_fires, fx_old(Rows)},
      {if10_widened_fires, fx_new(Rows)},
      {median_champion, Med#fx.seed, Med#fx.old, Med#fx.new},
      {tier_sizes, fx_sizes(Rows)},
      {rows, [fx_term_row(R) || R <- Rows]}]}.

fx_term_row(R) ->
    {row, R#fx.seed, tier(R#fx.hw), R#fx.old, R#fx.new, R#fx.trips,
     R#fx.tw, R#fx.cw, R#fx.hw, R#fx.tfl, R#fx.cfl, R#fx.hfl,
     R#fx.tdm, R#fx.cdm, R#fx.hdm, R#fx.fit, R#fx.fit_recomputed, R#fx.profile}.

%%%----------------------------------------------------------------------------
%%% The append-only note that goes into BOTH copies of the feed. Short: the feed
%%% is not the place for 40 rows of a post-hoc recomputation, and the record is.
%%%----------------------------------------------------------------------------
fx_feed_note(Opts, Arms) ->
    [io_lib:format(
       "~n~n== ADDENDUM 2, appended 2026-07-30, POST HOC: THE TWO FLAG FIXES ==~n~n"
       "WHAT THIS IS. Everything above the first addendum was written by run/1 on~n"
       "2026-07-29 and nothing above this line is changed or re-run. This note~n"
       "records two changes to the RUNNER's flag machinery, both recomputed from the~n"
       "archived champion genomes at engine pin~n"
       "a5e8bcfc5646827e9be49a9629f8a6a9678c814b. NO ARM WAS RE-RUN and no genome was~n"
       "modified: archived champions were replayed through matches, which is the same~n"
       "thing the first addendum did.~n~n"
       "THE NUMBERS ARE NOT HERE. They are in~n"
       "  ~s~n"
       "per seed, per arm, as-run predicate beside widened, plus the three-way split~n"
       "table. That file is the record for both fixes; this note is a pointer with~n"
       "the headline counts.~n~n"
       "FIX A, IF-10 LADDER-INVERSION, a defect fix to a pre-registered predicate.~n"
       "The as-run predicate read [sitting_duck, spinner] and tested L > W, so it~n"
       "never looked at the rammer or the circle_strafer and could not see a rung~n"
       "parked in draws. inverted/1 now reads all four lower rungs and counts a rung~n"
       "as not beaten when L > W or when D > 0.5, which is the definition of a~n"
       "majority on 160 matches and not a fitted value. flags/3 now also emits the~n"
       "count over the whole arm, under BOTH predicates, because IF-10 reads one~n"
       "median champion.~n~n"
       "  arm  champions  as-run FIRES  widened FIRES  median champ as-run / widened~n",
       [maps:get(fx_out, Opts)]),
     [fx_note_arm(A) || A <- Arms],
     [fx_note_seeds(A) || A <- Arms],
     io_lib:format(
       "~nEVERY IF-10 LINE ABOVE THIS ADDENDUM STANDS AS WRITTEN. Those lines report~n"
       "what the run of 2026-07-29 computed. A future run computes the widened~n"
       "predicate and its IF-10 lines will differ from the ones above; that is the~n"
       "point of the fix and it is recorded here so the difference is not a surprise.~n~n"
       "FIX B, AND IT IS NOT A REPAIR OF IF-8. IF-8 MEMORISATION reads trainW >= B~n"
       "and held-out < B. trainW is 1.0000 for 40 of 40 champions above, and that is~n"
       "forced by the design: the train split is 12 matches and ladder/3 clears a~n"
       "rung only when all 12 of its margins are positive, so any champion that~n"
       "cleared the gun rung had 12 wins there. The left conjunct is vacuously true~n"
       "and IF-8 collapses to the negation of half the CLEARED test. IF-8 WAS~n"
       "UNTESTABLE WITH THIS INSTRUMENT AND THAT FACT STANDS PERMANENTLY. It is not~n"
       "repaired, rescored or reinterpreted.~n~n"
       "What was built instead is PH-GEN, a NEW POST-HOC diagnostic with a name that~n"
       "is deliberately not an IF code. It reports, per champion, the win rate and~n"
       "the FLOORED margin (margin/1, whole units) on all three splits: train 12~n"
       "matches, calibration 60, held out 160, plus the gaps. The 30 calibration~n"
       "starts scored arm C during the run and no champion, so nothing was ever~n"
       "selected on them; for arm S they have since been read once, post hoc, by~n"
       "exp066_two_attractors_probe.txt section K, so this is a re-read there and a~n"
       "first look for arms L and D. PH-GEN is unregistered, signs nothing, and does~n"
       "not license any reading of IF-8's quiet state.~n", []),
     fx_note_found(Arms),
     io_lib:format(
       "~nPRODUCED BY. experiments/exp066_single_population_floor_tests.erl,~n"
       "flag_fixes/1, added 2026-07-30, driven by scripts/exp066_flag_fixes.sh. The~n"
       "same amendment widens inverted/1 and adds the two per-arm IF-10 counts to~n"
       "flags/3. The as-run copy archived beside the champions contains none of this.~n"
       "== END ADDENDUM 2 ==~n",
       [])].

fx_note_arm({arm, A, Rows}) ->
    Med = fx_median(Rows),
    io_lib:format("  ~3s ~10w ~13w ~14w  seed ~w: ~s / ~s~n",
                  [atom_to_list(A), length(Rows), fx_old(Rows), fx_new(Rows),
                   Med#fx.seed, add_flag(Med#fx.old), add_flag(Med#fx.new)]).

%% The identities, not only the counts: a count without seeds cannot be checked
%% against the per-seed profiles printed above this addendum.
fx_note_seeds({arm, A, Rows}) ->
    io_lib:format("  arm ~s seeds firing, as-run  : ~w~n"
                  "  arm ~s seeds firing, widened : ~w~n",
                  [atom_to_list(A), [R#fx.seed || R <- Rows, R#fx.old],
                   atom_to_list(A), [R#fx.seed || R <- Rows, R#fx.new]]).

%% PH-GEN's result, in the feed, because a pointer that carries only a definition
%% leaves the reader unable to tell whether the new diagnostic did anything.
fx_note_found(Arms) ->
    Rows = lists:append([Rs || {arm, _A, Rs} <- Arms]),
    [io_lib:format(
       "~nWHAT PH-GEN FOUND, AND HALF OF IT IS A NEGATIVE.~n"
       "  (a) THE WIN-RATE LEG SATURATES, exactly as IF-8's trainW does and for the~n"
       "      same reason: train W is 1.0000 for ~w of ~w champions, so~n"
       "      train-minus-held-out W is 1.0000 minus held-out W identically and~n"
       "      separates nothing that held-out W does not already separate. That leg~n"
       "      inherits the defect it was built beside. It is reported, not dropped.~n"
       "  (b) THE FLOORED-MARGIN LEG DOES NOT SATURATE on any split, and where the~n"
       "      question is testable it separates the two modes on the splits that do~n"
       "      NOT define them. Three quantities, in order: the floored margin on~n"
       "      train, the floored margin on calibration, the win rate on calibration.~n"
       "      Whether the near-parity and kill-mode tiers' ranges overlap, per arm:~n~n"
       "      arm  floored@train  floored@calib        W@calib~n",
       [fx_ceil(Rows, fun(R) -> R#fx.tw end), length(Rows)]),
     [fx_note_sep(A) || A <- Arms],
     io_lib:format("~n", []),
     io_lib:format(
       "      Tiers are the two-attractors probe's published rule on held-out W~n"
       "      (below 0.62 near-parity, above 0.93 kill mode), reused unchanged. Arm D~n"
       "      has NO near-parity champion, so the question is not testable there and~n"
       "      is reported as not testable rather than answered.~n"
       "  (c) CROSS-CHECK, AND WHAT IS ACTUALLY NEW. Arm S's train and held-out~n"
       "      floored gun margins already existed in exp066_two_attractors_probe.txt~n"
       "      section G, and its calibration win rates in section K, both computed by~n"
       "      a different script from the same archive. They agree digit for digit.~n"
       "      NEW here: the floored margin on the CALIBRATION starts, for every arm,~n"
       "      and every column for arms L and D, which had no floored margin on any~n"
       "      split and no calibration measurement at all.~n"
       "      The calibration starts scored arm C during the run and no champion, so~n"
       "      nothing was ever selected on them; for arm S they have since been read~n"
       "      once, by that probe, so this is a re-read rather than a first look.~n"
       "  (d) PROVENANCE. ladder/3 re-run on the 6 train starts reproduces the~n"
       "      archived fitness EXACTLY, as a float, for ~w of ~w champions.~n"
       "      scripts/exp066_verify_flag_fixes.escript checks the recomputed rung~n"
       "      profiles against the as-run profiles printed above this addendum.~n",
       [length([1 || R <- Rows, R#fx.fit =:= R#fx.fit_recomputed]), length(Rows)])].

fx_note_sep({arm, A, Rows}) ->
    io_lib:format("      ~3s ~14s ~14s ~14s~n",
                  [atom_to_list(A),
                   fx_short(fx_overlap(fx_ranges(Rows, fun(R) -> R#fx.tfl end))),
                   fx_short(fx_overlap(fx_ranges(Rows, fun(R) -> R#fx.cfl end))),
                   fx_short(fx_overlap(fx_ranges(Rows, fun(R) -> R#fx.cw end)))]).

fx_short(not_testable) -> "NOT TESTABLE";
fx_short(overlapping) -> "OVERLAPS";
fx_short({disjoint, _Dir}) -> "DISJOINT".

%%%============================================================================
%%% FIX C AND FIX D, both recomputed from the champion archive, 2026-07-30.
%%%
%%% FIX C. scripted_null/1 kept element 1 of rates/1 and discarded the LOSS and
%%% DRAW rates. That is not a cosmetic loss. A win rate of 0.0 is consistent with
%%% 160 losses and with 160 draws, and those are different facts: the first is an
%%% EDGE from the floor bot to that rung, the second is no edge at all. So the
%%% as-run record could not say whether the floor bot BEATS the lower rungs, and
%%% one leg of every candidate intransitive triple running through the floor bot
%%% was unreadable. The number is recovered here and used.
%%%
%%% WHAT IS MEASURED. Every scripted opponent against every one of the 40
%%% archived champions, BOTH DIRECTIONS MEASURED SEPARATELY, on the 80
%%% PRE-REGISTERED held-out starts, both seats, 160 matches per ordered cell. Both
%%% directions of a pair are two independent calls into the match loop and the
%%% transpose identity between them is CHECKED per pair rather than assumed, which
%%% is what xp_symmetry_one/3 does for the cross-play matrix. Plus the full 5 x 5
%%% scripted round robin, so triples of one champion and two rungs are testable.
%%%
%%% THE RELATION IS STATED ONCE AND NOT MOVED. A beats B iff W(A,B) > 0.5, where
%%% W(A,B) is A's win rate over the 160 matches of that ordered cell and a win
%%% requires B dead and A alive. DRAWS COUNT AS NOT BEATING, which is exp066's
%%% convention for the primary endpoint throughout: a draw is not a win, so it
%%% does not help A beat B any more than a loss does. This is the STRICTER of the
%%% two readings a reader might reach for, because W > 0.5 implies W > L while the
%%% reverse does not, so nothing below is obtained by loosening the relation. NO
%%% SECOND RELATION IS INTRODUCED ANYWHERE IN THIS RECORD.
%%%
%%% FIX D. The match-level null was mis-scaled by two. That is fixed in
%%% xp_from_wins/2, at the source, and the as-run construction is kept verbatim as
%%% xp_from_pairs_as_run/2 so the two columns can be computed from the SAME draws.
%%% exp066_crossplay.txt is NOT re-emitted: its null_match_level block is as-built
%%% and the audit beside it quotes those numbers.
%%%
%%% NO ARM IS RE-RUN AND NO GENOME IS MODIFIED. Archived champions are replayed
%%% through matches, which is what the first addendum and the cross-play probe
%%% already did. The call path is duels/3 -> duel/3 -> play_seat/5 -> play/2 ->
%%% robo_sim. Nothing under arm/2, seed_run/4, one_run/4, fitness_fun/5 or the
%%% col_* collector is reachable from it.
%%%============================================================================

recovered() -> recovered(#{}).

recovered(Opts0) ->
    Opts = merged(Opts0),
    Starts = heldout_starts(Opts),
    K = constants(Opts),
    Objs = rc_objects(Opts),
    Pairs = rc_cells(Opts, Objs, Starts),
    Tris = rc_search(Objs, Pairs),
    Nulls = rc_nulls(Opts),
    ok = file:write_file(maps:get(rc_out, Opts),
                         [rc_record(Opts, K, Objs, Starts, Pairs, Tris, Nulls)]),
    Note = rc_feed_note(Opts, Pairs, Tris, Nulls),
    [ok = add_append(P, Note) || P <- maps:get(addendum_feeds, Opts)],
    io:format("~s", [Note]),
    {recovered,
     [{record, maps:get(rc_out, Opts)},
      {feeds, maps:get(addendum_feeds, Opts)},
      {objects, length(Objs)},
      {pairs_measured, length(Pairs)},
      {transpose_exact, length([1 || {pair, _A, _B, _C, _F, _R, true, _M} <- Pairs])},
      {cyclic_triples, length([1 || {tri, _Ids, _T, _O, true, _F, _Cl} <- Tris])},
      {cyclic_preregistered,
       length([1 || {tri, _Ids, _T, _O, true, _F, preregistered} <- Tris])}]}.

%%%----------------------------------------------------------------------------
%%% The objects. Five scripted bots and the 40 archived champions. An object's ID
%%% carries no genome, so it is safe to print and to compare; the SUBJECT beside
%%% it is what goes into the match loop.
%%%----------------------------------------------------------------------------
rc_objects(Opts) ->
    [{obj, {script, Kind}, {script, Kind}} || Kind <- robo_gauntlet:kinds()]
        ++ [{obj, {champ, A, S}, {net, L, Q}}
            || Arm <- maps:get(addendum_arms, Opts),
               {champion, A, S, L, Q, _F, _E} <- champion_read(add_path(Opts, Arm))].

rc_subject(Objs, Id) -> element(3, lists:keyfind(Id, 2, Objs)).

rc_label({script, K}) -> atom_to_list(K);
rc_label({champ, A, S}) -> atom_to_list(A) ++ integer_to_list(S).

%% A rate back to the exact match count it came from. Every rate here is k/160, so
%% the integer is the reproducible number and the float is the readable one.
rc_n(R, M) -> round(R * M).

%%%----------------------------------------------------------------------------
%%% Which pairs are measured, and the PROVENANCE of each.
%%%
%%%   preregistered  both directions of this pair are a measurement the
%%%                  pre-registered run already made on the pre-registered starts:
%%%                  champion against rung is profile/2, which the feed prints per
%%%                  seed, and rung against the floor bot is N, which the feed
%%%                  prints in the frozen-constants block.
%%%   new_post_hoc   a rung against a rung other than the floor bot. The as-run N
%%%                  only played each rung against the floor bot, so these six
%%%                  pairs are NEW and are labelled NEW wherever they are used.
%%%   unmeasured     champion against champion. Not measured here. Cross-play
%%%                  exists for arm S only and lives in an UNREGISTERED probe, so
%%%                  it cannot enter a registered anchor; triples needing it are
%%%                  reported as untestable rather than filled in.
%%%----------------------------------------------------------------------------
rc_pair_class({script, ?FLOOR}, {script, _K}) -> preregistered;
rc_pair_class({script, _K}, {script, ?FLOOR}) -> preregistered;
rc_pair_class({script, _K1}, {script, _K2}) -> new_post_hoc;
rc_pair_class({script, _K}, {champ, _A, _S}) -> preregistered;
rc_pair_class({champ, _A, _S}, {script, _K}) -> preregistered;
rc_pair_class({champ, _A1, _S1}, {champ, _A2, _S2}) -> unmeasured.

rc_ids(Objs) -> [Id || {obj, Id, _S} <- Objs].

rc_pairs(Objs) ->
    Ids = rc_ids(Objs),
    [{A, B} || A <- Ids, B <- Ids, A < B, rc_pair_class(A, B) =/= unmeasured].

rc_cells(Opts, Objs, Starts) ->
    pmap(fun(P) -> rc_pair(Objs, Starts, P) end, rc_pairs(Objs), maps:get(workers, Opts)).

%% BOTH DIRECTIONS MEASURED, not one derived from the other. duel/3 plays seat a
%% and seat b at every start, and the engine is deterministic, so the two games
%% behind the reverse cell are the same two simulations read from the other side
%% and the reverse rates must be the forward rates with W and L exchanged. That is
%% a check worth 160 extra matches per pair, not an assumption.
rc_pair(Objs, Starts, {A, B}) ->
    {W, L, D} = rates(duels(rc_subject(Objs, A), rc_subject(Objs, B), Starts)),
    {RW, RL, RD} = rates(duels(rc_subject(Objs, B), rc_subject(Objs, A), Starts)),
    {pair, A, B, rc_pair_class(A, B), {W, L, D}, {RW, RL, RD},
     {RW, RL, RD} =:= {L, W, D}, 2 * length(Starts)}.

%%%----------------------------------------------------------------------------
%%% THE RELATION AND THE TRIPLE SEARCH.
%%%
%%% beats(A,B) iff W(A,B) > 0.5. Exactly one of beats(A,B) and beats(B,A) can hold,
%%% since W(A,B) + W(B,A) =< 1, so a pair is either oriented one way or carries no
%%% edge at all. A pair with no edge is the honest outcome of a pair parked in
%%% draws, and it is counted rather than broken.
%%%
%%% A triple is CYCLIC iff its three edges all exist and form a 3-cycle. The two
%%% orientations are mutually exclusive on three distinct vertices, which is the
%%% same argument xp_cycles/3 rests on.
%%%----------------------------------------------------------------------------
rc_search(Objs, Pairs) ->
    Wm = rc_wmap(Pairs),
    Cm = rc_cmap(Pairs),
    [rc_tri(Wm, Cm, T) || T <- rc_triples(rc_ids(Objs))].

rc_wmap(Pairs) ->
    maps:from_list(
      lists:append([[{{A, B}, W}, {{B, A}, RW}]
                    || {pair, A, B, _C, {W, _L, _D}, {RW, _RL, _RD}, _Ok, _M} <- Pairs])).

rc_cmap(Pairs) -> maps:from_list([{{A, B}, C} || {pair, A, B, C, _F, _R, _Ok, _M} <- Pairs]).

rc_triples(Ids) -> [{A, B, C} || A <- Ids, B <- Ids, C <- Ids, A < B, B < C].

rc_w(Wm, A, B) -> maps:get({A, B}, Wm, 0.0).

rc_beats(Wm, A, B) -> rc_w(Wm, A, B) > 0.5.

rc_oriented(Wm, A, B) -> rc_beats(Wm, A, B) orelse rc_beats(Wm, B, A).

rc_measured(Wm, A, B) -> maps:is_key({A, B}, Wm) andalso maps:is_key({B, A}, Wm).

rc_tri(Wm, Cm, {A, B, C}) ->
    Meas = rc_measured(Wm, A, B) andalso rc_measured(Wm, B, C) andalso rc_measured(Wm, A, C),
    Or = rc_oriented(Wm, A, B) andalso rc_oriented(Wm, B, C) andalso rc_oriented(Wm, A, C),
    Fwd = rc_beats(Wm, A, B) andalso rc_beats(Wm, B, C) andalso rc_beats(Wm, C, A),
    Bwd = rc_beats(Wm, A, C) andalso rc_beats(Wm, C, B) andalso rc_beats(Wm, B, A),
    {tri, {A, B, C}, Meas, Or, Fwd orelse Bwd, Fwd, rc_tclass(Cm, {A, B, C})}.

rc_tclass(Cm, {A, B, C}) ->
    rc_tclass_of([rc_pclass(Cm, A, B), rc_pclass(Cm, B, C), rc_pclass(Cm, A, C)]).

rc_pclass(Cm, A, B) -> maps:get({A, B}, Cm, unmeasured).

rc_tclass_of(Cs) ->
    rc_tc(lists:member(unmeasured, Cs), lists:member(new_post_hoc, Cs)).

rc_tc(true, _New) -> unmeasured;
rc_tc(false, true) -> extended;
rc_tc(false, false) -> preregistered.

%% The three edges of a cyclic triple in cycle order, so the record prints a path
%% and a reader can check each leg against the tables above it.
rc_path({A, B, C}, true) -> [{A, B}, {B, C}, {C, A}];
rc_path({A, B, C}, false) -> [{A, C}, {C, B}, {B, A}].

%%%----------------------------------------------------------------------------
%%% FIX D's tables. Four sample sets, each from a FRESHLY seeded generator, so the
%%% as-built and corrected columns of a given null are the same draws under two
%%% encodings and the comparison is of encodings, not of samples. The seed is
%%% XP_SEED, the same constant the cross-play probe fixes, so these columns are
%%% directly comparable with scripts/exp066_verify_null_scaling.escript, which
%%% seeds from 660 as well.
%%%----------------------------------------------------------------------------
rc_nulls(Opts) ->
    N = maps:get(rc_null_n, Opts),
    M = maps:get(rc_null_cell, Opts),
    Draws = maps:get(xp_null_draws, Opts),
    Idx = lists:seq(1, N),
    S0 = rc_draw(fun() -> rc_sign_as_run(N, Draws) end),
    S1 = rc_draw(fun() -> rc_sign_fixed(N, Draws) end),
    M0 = rc_draw(fun() -> rc_match_as_run(N, Draws, M) end),
    M1 = rc_draw(fun() -> rc_match_fixed(N, Draws, M) end),
    M2 = rc_draw(fun() -> rc_match_half(N, Draws, M) end),
    M3 = rc_draw(fun() -> rc_int_draws(N, Draws, M) end),
    {nulls,
     [{champions, N}, {matches_per_cell, M}, {draws, Draws}, {seed, ?XP_SEED},
      {sign_as_built, rc_stats(S0, Idx)},
      {sign_corrected, rc_stats(S1, Idx)},
      {match_as_built, rc_stats(M0, Idx)},
      {match_corrected, rc_stats(M1, Idx)},
      {match_corrected_half_encoding, rc_stats(M2, Idx)},
      {match_corrected_exact_integer, rc_int_stats(M3, Idx, M)},
      {abs_margin_span,
       [{sign_as_built, rc_absmg(S0, Idx)}, {sign_corrected, rc_absmg(S1, Idx)},
        {match_as_built, rc_absmg(M0, Idx)}, {match_corrected, rc_absmg(M1, Idx)}]},
      {sign_identical,
       rc_stats(S0, Idx) =:= rc_stats(S1, Idx)},
      {match_identical,
       rc_stats(M0, Idx) =:= rc_stats(M1, Idx)},
      {corrected_encodings_identical,
       rc_stats(M1, Idx) =:= rc_stats(M2, Idx)}]}.

rc_draw(F) ->
    _ = rand:seed(exsss, {?XP_SEED, ?XP_SEED * 7 + 1, ?XP_SEED * 13 + 3}),
    F().

rc_sign_as_run(N, Draws) ->
    Idx = lists:seq(1, N),
    [xp_from_pairs_as_run(N, [{I, J, xp_coin()} || {I, J} <- xp_pairs(Idx)])
     || _ <- lists:seq(1, Draws)].

rc_sign_fixed(N, Draws) ->
    Idx = lists:seq(1, N),
    [xp_from_wins(N, [{I, J, xp_coin_w()} || {I, J} <- xp_pairs(Idx)])
     || _ <- lists:seq(1, Draws)].

rc_match_as_run(N, Draws, M) ->
    Idx = lists:seq(1, N),
    [xp_from_pairs_as_run(N, [{I, J, xp_flips(M) * 2.0 / M - 1.0} || {I, J} <- xp_pairs(Idx)])
     || _ <- lists:seq(1, Draws)].

rc_match_fixed(N, Draws, M) ->
    Idx = lists:seq(1, N),
    [xp_from_wins(N, [{I, J, xp_flips(M) / M} || {I, J} <- xp_pairs(Idx)])
     || _ <- lists:seq(1, Draws)].

%% THE THIRD ENCODING, the one scripts/exp066_verify_null_scaling.escript uses for
%% its corrected column: halve the margin and store plus and minus half. Included
%% because it does NOT agree with xp_from_wins/2 at every band, and the record has
%% to say so and say why rather than pick whichever matched.
rc_match_half(N, Draws, M) ->
    Idx = lists:seq(1, N),
    [xp_from_pairs_as_run(N, [{I, J, (xp_flips(M) * 2.0 / M - 1.0) / 2}
                              || {I, J} <- xp_pairs(Idx)])
     || _ <- lists:seq(1, Draws)].

%%% THE SAME BAND TEST WITH NO FLOAT IN IT. A NEW POST-HOC DIAGNOSTIC.
%%%
%%% WHY IT EXISTS. Every synthetic margin is (2K - M)/M for an integer K, and all
%%% three pre-registered bands are exact multiples of the margin quantum 2/M: at
%%% M = 160, 0.05 is 8/160, 0.10 is 16/160 and 0.15 is 24/160. So EVERY draw
%%% contains edges whose margin equals the band exactly, where "margin > band" is
%%% mathematically FALSE, and whose float rendering decides the answer instead. The
%%% two float encodings round those edges in OPPOSITE directions and therefore
%%% disagree, which is why this column is here.
%%%
%%% Mg > B is exactly 2K - M > B * M, and B * M is 8, 16 and 24, integers. The
%%% counters are xp_ordered/3 and xp_cycles/3 unchanged, called with an integer
%%% margin and an integer threshold. THE BAND IS NOT MOVED: the same test is
%%% computed without rounding error. This is NEW, post hoc, unregistered, and it
%%% does not replace the float columns; it stands beside them.
rc_int_draws(N, Draws, M) ->
    Idx = lists:seq(1, N),
    [rc_int_one(Idx, M) || _ <- lists:seq(1, Draws)].

rc_int_one(Idx, M) ->
    maps:from_list(lists:append([rc_int_cell(M, P) || P <- xp_pairs(Idx)])).

rc_int_cell(M, {I, J}) ->
    K = xp_flips(M),
    [{{I, J}, 2 * K - M}, {{J, I}, M - 2 * K}].

rc_int_mg(Map) -> fun(I, J) -> maps:get({I, J}, Map, 0) end.

rc_int_stats(Maps, Idx, M) -> [rc_int_stat(Maps, Idx, M, B) || B <- xp_bands()].

rc_int_stat(Maps, Idx, M, B) ->
    Thr = round(B * M),
    Ord = [xp_ordered(rc_int_mg(Mp), Idx, Thr) || Mp <- Maps],
    Cyc = [rc_int_cyc(Mp, Idx, Thr) || Mp <- Maps],
    Dec = [rc_dec(rc_int_mg(Mp), Idx, Thr) || Mp <- Maps],
    On = [rc_int_on(Mp, Idx, Thr) || Mp <- Maps],
    {at_band, B, [{integer_threshold, Thr}, {threshold_exact, abs(B * M - Thr) < 1.0e-9},
               {ordered_median, median(Ord)}, {ordered_range, spread(Ord)},
               {cycles_median, median(Cyc)}, {cycles_range, spread(Cyc)},
               {decisive_median, median(Dec)},
               {edges_exactly_on_band_median, median(On)},
               {of_pairs, length(xp_pairs(Idx))}]}.

rc_int_cyc(Mp, Idx, Thr) ->
    {F, Bw} = xp_cycles(rc_int_mg(Mp), Idx, Thr),
    F + Bw.

rc_int_on(Mp, Idx, Thr) ->
    length([1 || {I, J} <- xp_pairs(Idx), abs(maps:get({I, J}, Mp)) =:= Thr]).

rc_stats(Ms, Idx) -> [rc_stat(Ms, Idx, B) || B <- xp_bands()].

rc_stat(Ms, Idx, B) ->
    Ord = [xp_ordered(xp_mg(M), Idx, B) || M <- Ms],
    Cyc = [xp_cyc_n(M, Idx, B) || M <- Ms],
    Dec = [rc_dec(xp_mg(M), Idx, B) || M <- Ms],
    {at_band, B, [{ordered_median, median(Ord)}, {ordered_range, spread(Ord)},
               {cycles_median, median(Cyc)}, {cycles_range, spread(Cyc)},
               {decisive_median, median(Dec)}, {of_pairs, length(xp_pairs(Idx))}]}.

rc_dec(Mg, Idx, B) -> length([1 || {I, J} <- xp_pairs(Idx), abs(Mg(I, J)) > B]).

%% The direct evidence of the doubling: the span of |margin| over every pair of
%% every draw. The as-built sign-only column reads 2.0 where the model it claims to
%% sample has margins of 1.0.
rc_absmg(Ms, Idx) ->
    As = lists:append([[abs((xp_mg(M))(I, J)) || {I, J} <- xp_pairs(Idx)] || M <- Ms]),
    spread(As).

%%%----------------------------------------------------------------------------
%%% The record.
%%%----------------------------------------------------------------------------
rc_record(Opts, K, Objs, Starts, Pairs, Tris, Nulls) ->
    Rm = rc_rmap(Pairs),
    Wm = rc_wmap(Pairs),
    %% The matches per ordered cell, taken from the start set actually used rather
    %% than written as a literal, so a reduced configuration cannot print a rate
    %% back as a count out of a match total it never played.
    M = 2 * length(Starts),
    [rc_head(Opts, Objs, Starts, Pairs),
     rc_sec_a(K, Rm, M),
     rc_sec_b(Objs, Pairs, Rm, M),
     rc_sec_c(Rm, M),
     rc_sec_d(Pairs, Rm, M),
     rc_sec_e(Objs, Wm, Rm, Tris, M),
     rc_sec_f(Nulls),
     rc_sec_g(),
     rc_term(Opts, Pairs, Tris, Nulls)].

rc_rmap(Pairs) ->
    maps:from_list(
      lists:append([[{{A, B}, F}, {{B, A}, R}]
                    || {pair, A, B, _C, F, R, _Ok, _M} <- Pairs])).

rc_okmap(Pairs) -> maps:from_list([{{A, B}, Ok} || {pair, A, B, _C, _F, _R, Ok, _M} <- Pairs]).

rc_key(A, B) when A < B -> {A, B};
rc_key(A, B) -> {B, A}.

rc_rates(Rm, A, B) -> maps:get({A, B}, Rm).

rc_champ_ids(Objs) -> [Id || {obj, {champ, _A, _S} = Id, _Sub} <- Objs].

rc_head(Opts, Objs, Starts, Pairs) ->
    io_lib:format(
      "== EXP-066: THE RATES scripted_null/1 THREW AWAY, RECOVERED; AND THE~n"
      "   MATCH-LEVEL NULL'S SCALE, FIXED AT THE SOURCE ==~n~n"
      "Date: 2026-07-30. Engine pin a5e8bcfc5646827e9be49a9629f8a6a9678c814b.~n"
      "Produced by: experiments/exp066_single_population_floor_tests.erl,~n"
      "  recovered/1, driven by scripts/exp066_recovered.sh. Archive read: ~s~n"
      "  (exp066_champions_s.eterm 20, _l.eterm 10, _d.eterm 10; 40 champions).~n~n"
      "NO ARM WAS RE-RUN AND NO GENOME WAS MODIFIED. Every rate below comes from~n"
      "replaying archived champions and scripted bots through matches at the engine~n"
      "pin. The call path is duels/3 -> duel/3 -> play_seat/5 -> play/2 -> robo_sim.~n"
      "Nothing under arm/2, seed_run/4, one_run/4, fitness_fun/5 or the col_*~n"
      "collector is reachable from it, so no optimiser runs anywhere in this record.~n~n"
      "TWO FIXES, ONE RECORD.~n~n"
      "  FIX C  scripted_null/1 kept element 1 of rates/1 and discarded the LOSS and~n"
      "         DRAW rates. A win rate of 0.0 is consistent with 160 losses and with~n"
      "         160 draws, and those are different facts about the ladder, so the~n"
      "         as-run record could not say whether the floor bot BEATS a lower rung~n"
      "         or merely never loses to it. Recovered here, in full, for every~n"
      "         scripted opponent against every champion and against every other~n"
      "         scripted opponent, and then used to ask whether a genuine~n"
      "         intransitive triple exists inside the pre-registered arms.~n~n"
      "  FIX D  the synthetic nulls were mis-scaled by a factor of two. Fixed in~n"
      "         xp_from_wins/2; the as-run construction is kept verbatim as~n"
      "         xp_from_pairs_as_run/2 so both columns come off the SAME draws.~n~n"
      "WHAT IS MEASURED, EXACTLY. ~w objects: 5 scripted bots and ~w archived~n"
      "champions. ~w pairs, ~w ORDERED CELLS, ~w matches per ordered cell (~w~n"
      "PRE-REGISTERED held-out starts, both seats), ~w matches in total. Both~n"
      "directions of every pair are measured by two separate calls into the match~n"
      "loop and the transpose identity between them is CHECKED per pair.~n~n"
      "WHAT IS NOT MEASURED. Champion against champion. That play exists for arm S~n"
      "only and lives in an UNREGISTERED probe (exp066_crossplay.txt), so it cannot~n"
      "enter an anchor that is meant to rest on pre-registered measurement. Triples~n"
      "needing such a pair are reported as UNTESTABLE, not filled in.~n~n"
      "REPRODUCIBILITY AND THE SEEDS. Every match here is a deterministic integer~n"
      "simulation on a deterministic start set, so no rate in this record comes off~n"
      "rand. Two quantities do. (1) The frozen constant B quoted in section A comes~n"
      "from constants/1's start-level bootstrap, seeded from BOOT_SEED = 66 with~n"
      "10,000 resamples, both fixed in the runner's source. (2) Every number in~n"
      "section F is drawn from rand seeded at XP_SEED = ~w, freshly per column, 200~n"
      "draws, which is the same seed and draw count~n"
      "scripts/exp066_verify_null_scaling.escript uses.~n~n"
      "THIS FILE IS REGENERABLE, THE FEED NOTE IS NOT. recovered/1 overwrites this~n"
      "record, so it can be re-run at will (scripts/exp066_recovered.sh record). Two~n"
      "independent executions produced byte-identical copies of it. The note it~n"
      "appends to the two feed copies is APPEND-ONLY and was written once, on~n"
      "2026-07-30; re-running the appending mode would add a second copy of it.~n",
      [maps:get(archive_dir, Opts), length(Objs), length(rc_champ_ids(Objs)),
       length(Pairs), 2 * length(Pairs), 2 * length(Starts), length(Starts),
       2 * length(Pairs) * 2 * length(Starts), ?XP_SEED]).

%%%----------------------------------------------------------------------------
%%% A. The recovered number itself.
%%%----------------------------------------------------------------------------
rc_sec_a(K, Rm, M) ->
    [io_lib:format(
       "~n~n-- A. FIX C: THE NUMBER scripted_null/1 DISCARDED --~n~n"
       "THE AS-RUN CODE.~n"
       "    scripted_null(Starts) ->~n"
       "        [{K, win_rate(heldout({script, K}, ?FLOOR, Starts))}~n"
       "         || K <- robo_gauntlet:kinds(), K =/= ?FLOOR].~n~n"
       "win_rate/1 is element(1, rates(Os)) and rates/1 returns {W, L, D}. So the~n"
       "loss rate and the draw rate were computed and then thrown away on the same~n"
       "line. The feed's N line (exp066_floor_feed.txt lines 16..19) carries four win~n"
       "rates and nothing else.~n~n"
       "WHY THAT IS NOT COSMETIC. W = 0.0 is consistent with 160 losses and with 160~n"
       "draws. The first says the floor bot BEATS that rung, which is an EDGE. The~n"
       "second says the pair is parked and there is NO edge. One leg of every~n"
       "candidate intransitive triple that runs through the floor bot is exactly that~n"
       "distinction, so the as-run record could not close such a triple even when the~n"
       "other two legs were sitting in it.~n~n"
       "THE FIXED CODE returns {K, W, L, D}, taken straight from rates/1. What~n"
       "constants/1 now reports, verbatim, on the pre-registered held-out starts~n"
       "(~w matches per rung, subject = the RUNG, opponent = predictive_gun):~n~n"
       "  ~p~n~n"
       "AND THE SAME PAIRS READ AS A TABLE, with the reverse direction measured~n"
       "separately. Counts are exact match counts out of ~w; every rate here is~n"
       "k/~w.~n~n"
       "  rung             rung vs gun W/L/D   gun vs rung W/L/D   the as-run N said   RECOVERED: the floor bot~n",
       [M, maps:get(n_scripted, K), M, M]),
     [rc_a_row(Rm, M, Kind) || Kind <- robo_gauntlet:kinds(), Kind =/= ?FLOOR],
     io_lib:format(
       "~nB = ~.4f, the pre-registered bar, is quoted here only because section E~n"
       "refers to it. It is untouched.~n",
       [maps:get(b, K)])].

rc_a_row(Rm, M, Kind) ->
    Rung = {script, Kind},
    Gun = {script, ?FLOOR},
    {W, L, D} = rc_rates(Rm, Rung, Gun),
    {GW, GL, GD} = rc_rates(Rm, Gun, Rung),
    io_lib:format("  ~-15s ~4w/~4w/~4w      ~4w/~4w/~4w        W = ~.5f only    ~s~n",
                  [atom_to_list(Kind), rc_n(W, M), rc_n(L, M), rc_n(D, M),
                   rc_n(GW, M), rc_n(GL, M), rc_n(GD, M), W,
                   rc_beat_text(GW, GD, M)]).

rc_beat_text(W, _D, M) when W > 0.5 ->
    io_lib:format("BEATS it, ~w of ~w", [rc_n(W, M), M]);
rc_beat_text(_W, D, M) when D > 0.5 ->
    io_lib:format("does NOT beat it; parked in draws, ~w of ~w", [rc_n(D, M), M]);
rc_beat_text(W, _D, M) ->
    io_lib:format("does NOT beat it, only ~w of ~w", [rc_n(W, M), M]).

%%%----------------------------------------------------------------------------
%%% B. The full table.
%%%----------------------------------------------------------------------------
rc_sec_b(Objs, Pairs, Rm, M) ->
    Om = rc_okmap(Pairs),
    [io_lib:format(
       "~n~n-- B. THE FULL W/L/D TABLE: EVERY SCRIPTED OPPONENT AGAINST EVERY ONE OF~n"
       "      THE ~w CHAMPIONS, BOTH DIRECTIONS --~n~n"
       "Pre-registered held-out starts, both seats, ~w matches per ordered cell.~n"
       "Counts are exact and integer; the two rate columns are the same numbers as~n"
       "k/~w. champ W/L/D is the CHAMPION's side, rung W/L/D is the RUNG's side, and~n"
       "each is a separate call into the match loop rather than a transpose of the~n"
       "other. tr is the transpose identity {RW,RL,RD} =:= {L,W,D}: ok means the two~n"
       "independent measurements agree exactly, which they must, since duel/3 plays~n"
       "both seats and the engine is deterministic.~n~n"
       "The champ W/L/D column of the predictive_gun row is the arms' own primary~n"
       "endpoint and the whole row set is profile/2, so every number in this table~n"
       "except the rung side of it is a recomputation of something the feed already~n"
       "prints per seed (lines 135..234 for arm S, 301..350 for L, 417..466 for D).~n~n"
       "arm seed rung             champ W/L/D of ~w     rung W/L/D of ~w    champ W    rung W  tr~n",
       [length(rc_champ_ids(Objs)), M, M, M, M]),
     [[rc_b_row(Rm, Om, M, Ch, Kind) || Kind <- robo_gauntlet:kinds()]
      || Ch <- rc_champ_ids(Objs)]].

rc_b_row(Rm, Om, M, {champ, A, S} = Ch, Kind) ->
    Rung = {script, Kind},
    {W, L, D} = rc_rates(Rm, Ch, Rung),
    {RW, RL, RD} = rc_rates(Rm, Rung, Ch),
    io_lib:format("~3s ~4w ~-16s ~4w/~4w/~4w      ~4w/~4w/~4w    ~7.5f  ~7.5f  ~s~n",
                  [atom_to_list(A), S, atom_to_list(Kind),
                   rc_n(W, M), rc_n(L, M), rc_n(D, M),
                   rc_n(RW, M), rc_n(RL, M), rc_n(RD, M), W, RW,
                   rc_ok_text(maps:get(rc_key(Ch, Rung), Om))]).

rc_ok_text(true) -> "ok";
rc_ok_text(false) -> "MISMATCH".

%%%----------------------------------------------------------------------------
%%% C. The scripted round robin.
%%%----------------------------------------------------------------------------
rc_sec_c(Rm, M) ->
    Kinds = robo_gauntlet:kinds(),
    [io_lib:format(
       "~n~n-- C. THE SCRIPTED ROUND ROBIN, ALL FIVE RUNGS AGAINST ONE ANOTHER --~n~n"
       "Same held-out starts, same ~w matches per ordered cell, both directions~n"
       "measured. PROVENANCE IS NOT UNIFORM HERE AND IS LABELLED PER ROW.~n"
       "  preregistered  the four pairs involving predictive_gun. These ARE N, the~n"
       "                 frozen scripted-ladder null, with the discarded L and D~n"
       "                 restored. Nothing new is measured; a number is recovered.~n"
       "  NEW post hoc   the six pairs that do not involve predictive_gun. The as-run~n"
       "                 N played each rung against the floor bot ONLY, so these six~n"
       "                 pairs were never measured and are new work, added here~n"
       "                 because triples of one champion and two rungs need them.~n~n"
       "A vs B W/L/D is A's side, counts out of ~w. beats is under the relation~n"
       "stated in section D.~n~n"
       "A                B                  A vs B W/L/D      B vs A W/L/D   provenance     edge~n",
       [M, M]),
     [[rc_c_row(Rm, M, K1, K2) || K2 <- Kinds, K2 > K1] || K1 <- Kinds]].

rc_c_row(Rm, M, K1, K2) ->
    A = {script, K1},
    B = {script, K2},
    {W, L, D} = rc_rates(Rm, A, B),
    {RW, RL, RD} = rc_rates(Rm, B, A),
    io_lib:format("~-16s ~-16s ~4w/~4w/~4w   ~4w/~4w/~4w   ~-14s ~s~n",
                  [atom_to_list(K1), atom_to_list(K2),
                   rc_n(W, M), rc_n(L, M), rc_n(D, M),
                   rc_n(RW, M), rc_n(RL, M), rc_n(RD, M),
                   rc_prov_text(rc_pair_class(A, B)), rc_edge_text(A, B, W, RW)]).

rc_prov_text(preregistered) -> "preregistered";
rc_prov_text(new_post_hoc) -> "NEW post hoc".

rc_edge_text(A, _B, W, _RW) when W > 0.5 -> rc_label(A) ++ " beats it";
rc_edge_text(_A, B, _W, RW) when RW > 0.5 -> rc_label(B) ++ " beats it";
rc_edge_text(_A, _B, _W, _RW) -> "NO EDGE".

%%%----------------------------------------------------------------------------
%%% D. The relation, and the census of edges it produces.
%%%----------------------------------------------------------------------------
rc_sec_d(Pairs, Rm, M) ->
    Ok = length([1 || {pair, _A, _B, _C, _F, _R, true, _M} <- Pairs]),
    Or = [P || P <- Pairs, rc_pair_oriented(P)],
    No = [P || P <- Pairs, not rc_pair_oriented(P)],
    [io_lib:format(
       "~n~n-- D. THE RELATION, STATED ONCE, AND THE EDGES IT PRODUCES --~n~n"
       "THE RELATION.~n~n"
       "    A beats B  iff  W(A,B) > 0.5~n~n"
       "where W(A,B) is A's win rate over the ~w matches of the ordered cell (A,B),~n"
       "and a WIN requires B dead and A alive at match end. DRAWS COUNT AS NOT~n"
       "BEATING. That is exp066's convention for its primary endpoint throughout: a~n"
       "draw is not a win, so it cannot help A beat B any more than a loss can. A~n"
       "turn cap with both tanks alive, and a mutual death, are both draws.~n~n"
       "WHY THIS READING AND NOT A LOOSER ONE. Because W(A,B) > 0.5 implies~n"
       "W(A,B) > L(A,B) while the reverse does not, this is the STRICTER of the two~n"
       "readings available, so nothing found below is an artifact of a permissive~n"
       "relation. At most one direction of a pair can satisfy it, since~n"
       "W(A,B) + W(B,A) =< 1. A pair where neither direction satisfies it carries NO~n"
       "EDGE, which is the honest reading of a pair parked in draws. NO SECOND~n"
       "RELATION IS DEFINED ANYWHERE IN THIS RECORD.~n~n"
       "THE CENSUS.~n"
       "  pairs measured                      ~w~n"
       "  ordered cells measured              ~w~n"
       "  transpose identity exact            ~w of ~w~n"
       "  pairs carrying an edge              ~w~n"
       "  pairs carrying NO edge              ~w~n~n"
       "EVERY PAIR WITH NO EDGE, LISTED. These are the pairs where the relation is~n"
       "silent, and they are the reason a triple can be testable and still not~n"
       "closable. maxD is the larger of the two draw rates.~n~n"
       "A                B                  A vs B W/L/D      B vs A W/L/D      maxD~n",
       [M, length(Pairs), 2 * length(Pairs), Ok, length(Pairs), length(Or), length(No)]),
     [rc_d_row(Rm, M, P) || P <- No]].

rc_pair_oriented({pair, _A, _B, _C, {W, _L, _D}, {RW, _RL, _RD}, _Ok, _M}) ->
    W > 0.5 orelse RW > 0.5.

rc_d_row(Rm, M, {pair, A, B, _C, _F, _R, _Ok, _M}) ->
    {W, L, D} = rc_rates(Rm, A, B),
    {RW, RL, RD} = rc_rates(Rm, B, A),
    io_lib:format("~-16s ~-16s ~4w/~4w/~4w   ~4w/~4w/~4w   ~7.5f~n",
                  [rc_label(A), rc_label(B),
                   rc_n(W, M), rc_n(L, M), rc_n(D, M),
                   rc_n(RW, M), rc_n(RL, M), rc_n(RD, M), max(D, RD)]).

%%%----------------------------------------------------------------------------
%%% E. The triple search.
%%%----------------------------------------------------------------------------
rc_sec_e(Objs, Wm, Rm, Tris, M) ->
    Cyc = [T || {tri, _I, _Me, _O, true, _F, _Cl} = T <- Tris],
    Pre = [T || {tri, _I, _Me, _O, true, _F, preregistered} = T <- Tris],
    Ext = [T || {tri, _I, _Me, _O, true, _F, extended} = T <- Tris],
    [io_lib:format(
       "~n~n-- E. IS THERE A GENUINE INTRANSITIVE TRIPLE INSIDE THE PRE-REGISTERED~n"
       "      ARMS? --~n~n"
       "A triple is CYCLIC iff all three of its edges exist under section D's~n"
       "relation and they form a 3-cycle. The two possible cyclic orientations of~n"
       "three distinct vertices are mutually exclusive, which is the same argument~n"
       "xp_cycles/3 rests on, so no factor is guessed anywhere.~n~n"
       "EVERY triple of the ~w objects is enumerated, ~w of them, and classified by~n"
       "the PROVENANCE of its three pairs:~n"
       "  preregistered  all three pairs are measurements the pre-registered run~n"
       "                 already made. This is the only class that can carry a~n"
       "                 REGISTERED anchor.~n"
       "  extended       all three pairs measured, but at least one is a rung-versus~n"
       "                 -rung pair that the as-run N never played. NEW post hoc.~n"
       "  unmeasured     at least one pair is champion versus champion, which is not~n"
       "                 measured here. UNTESTABLE, and reported as untestable.~n~n"
       "  class          triples   all 3 pairs measured   all 3 edges present   CYCLIC~n"
       "~s"
       "~nRESULT: ~w cyclic triples in total, ~w of them PREREGISTERED.~n",
       [length(rc_ids(Objs)), length(Tris), rc_e_classes(Tris),
        length(Cyc), length(Pre)]),
     rc_e_named(Rm, rc_ids(Objs), M),
     rc_e_pre(Wm, Pre, M),
     rc_e_ext(Ext),
     rc_e_arms(Objs, Pre ++ Ext)].

rc_e_classes(Tris) ->
    [rc_e_class_row(Tris, C) || C <- [preregistered, extended, unmeasured]].

rc_e_class_row(Tris, C) ->
    In = [T || {tri, _I, _Me, _O, _Cy, _F, Cl} = T <- Tris, Cl =:= C],
    io_lib:format("  ~-14s ~7w ~22w ~21w ~8w~n",
                  [atom_to_list(C), length(In),
                   length([1 || {tri, _I, true, _O, _Cy, _F, _Cl} <- In]),
                   length([1 || {tri, _I, _Me, true, _Cy, _F, _Cl} <- In]),
                   length([1 || {tri, _I, _Me, _O, true, _F, _Cl} <- In])]).

%%% THE CANDIDATE THE UNSIGNED NOTE NAMED. It is tested first, on its own, because
%%% it is the triple the work package was framed around and because the answer is
%%% not the one the framing expected.
rc_e_named(Rm, Ids, M) ->
    rc_e_named_1(Rm, lists:member({champ, d, 2004}, Ids), M).

rc_e_named_1(_Rm, false, _M) ->
    "\nTHE CANDIDATE THE NOTE NAMED IS NOT TESTABLE IN THIS CONFIGURATION: arm D\n"
    "seed 2004 is not among the objects measured.\n";
rc_e_named_1(Rm, true, M) ->
    C = {champ, d, 2004},
    G = {script, ?FLOOR},
    Duck = {script, sitting_duck},
    [io_lib:format(
       "~nE1. THE CANDIDATE THE UNSIGNED NOTE NAMED, TESTED LEG BY LEG.~n~n"
       "The note proposed: arm D seed 2004 beats predictive_gun at 0.9625 while going~n"
       "0.0125 W and 0.98125 D against the sitting duck, so the third leg of a triple~n"
       "is already inside the pre-registered arms. The three legs, measured:~n~n", []),
     rc_e_leg(Rm, M, C, G),
     rc_e_leg(Rm, M, G, Duck),
     rc_e_leg(Rm, M, Duck, C),
     rc_e_named_verdict(Rm, M, C, G, Duck)].

rc_e_leg(Rm, M, A, B) ->
    {W, L, D} = rc_rates(Rm, A, B),
    io_lib:format("  ~-16s vs ~-16s W/L/D = ~4w/~4w/~4w of ~w,  W = ~7.5f  -> ~s~n",
                  [rc_label(A), rc_label(B), rc_n(W, M), rc_n(L, M), rc_n(D, M), M, W,
                   rc_leg_text(rc_label(A), rc_label(B), W, D)]).

rc_leg_text(La, Lb, W, _D) when W > 0.5 -> La ++ " BEATS " ++ Lb;
rc_leg_text(La, Lb, _W, D) when D > 0.5 ->
    La ++ " does NOT beat " ++ Lb ++ ", the pair is parked in draws";
rc_leg_text(La, Lb, _W, _D) -> La ++ " does NOT beat " ++ Lb.

rc_e_named_verdict(Rm, M, C, G, Duck) ->
    Legs = [{C, G}, {G, Duck}, {Duck, C}],
    Miss = [{A, B} || {A, B} <- Legs, element(1, rc_rates(Rm, A, B)) =< 0.5],
    rc_e_miss(Rm, M, Miss).

rc_e_miss(_Rm, _M, []) ->
    "\n  ALL THREE LEGS PRESENT: this triple is cyclic under the stated relation.\n";
rc_e_miss(Rm, M, Miss) ->
    {DW, _DL, DD} = rc_rates(Rm, {script, sitting_duck}, {champ, d, 2004}),
    [io_lib:format(
       "~n  THE TRIPLE IS NOT CLOSED. ~w of the three legs is missing:~n", [length(Miss)]),
     [rc_e_miss_row(Rm, M, L) || L <- Miss],
     io_lib:format(
       "~n  WHY IT IS MISSING, AND IT IS NOT A THRESHOLD PROBLEM. The pair is not~n"
       "  close to the bar: the sitting duck wins ~w of ~w against arm D seed 2004~n"
       "  and DRAWS ~w of ~w. The duck neither beats the champion nor loses to it;~n"
       "  the pair is parked. To turn that into an edge the relation would have to~n"
       "  read a draw as a win for the side that did not win, which is the opposite~n"
       "  of exp066's own convention. THAT IS NOT DONE HERE. Under the stated~n"
       "  relation this candidate is NOT an intransitive triple, and the note's~n"
       "  proposal that it is one does not survive the recovered numbers.~n~n"
       "  THE DISTINCTION THE RECOVERED NUMBER DOES SETTLE is the OTHER leg: the~n"
       "  as-run N could not say whether predictive_gun beats the sitting duck,~n"
       "  because W = 0.0 for the duck is consistent with all draws. It is now~n"
       "  measured, and that leg IS present. So the recovery worked; it is the leg~n"
       "  the note was confident about that fails.~n",
       [rc_n(DW, M), M, rc_n(DD, M), M])].

rc_e_miss_row(Rm, M, {A, B}) ->
    {W, L, D} = rc_rates(Rm, A, B),
    io_lib:format("    MISSING: ~s -> ~s   W/L/D = ~w/~w/~w of ~w~n",
                  [rc_label(A), rc_label(B), rc_n(W, M), rc_n(L, M), rc_n(D, M), M]).

rc_e_pre(_Wm, [], _M) ->
    "\nE2. PREREGISTERED CYCLIC TRIPLES: NONE.\n\n"
    "No triple whose three pairs are all pre-registered measurements is cyclic under\n"
    "the stated relation. There is no registered intransitivity anchor here. That is\n"
    "the result; no relation was loosened to change it.\n";
rc_e_pre(Wm, Pre, M) ->
    [io_lib:format(
       "~nE2. PREREGISTERED CYCLIC TRIPLES: ~w. Each is listed with its three legs in~n"
       "cycle order, so every leg can be checked against sections A, B and C. All~n"
       "three pairs of each are measurements the pre-registered run already made:~n"
       "champion against rung is the arms' own rung profile, rung against the floor~n"
       "bot is N.~n~n", [length(Pre)]),
     [rc_e_cycle(Wm, M, T) || T <- Pre]].

rc_e_cycle(Wm, M, {tri, Ids, _Me, _O, _Cy, Fwd, _Cl}) ->
    Path = rc_path(Ids, Fwd),
    [io_lib:format("  CYCLE ~s~n", [rc_path_text(Path)]),
     [rc_e_edge(Wm, M, E) || E <- Path]].

rc_path_text([{A, _B}, {B, _C}, {C, _A}]) ->
    rc_label(A) ++ " -> " ++ rc_label(B) ++ " -> " ++ rc_label(C) ++ " -> " ++ rc_label(A).

rc_e_edge(Wm, M, {A, B}) ->
    W = rc_w(Wm, A, B),
    io_lib:format("      ~-16s beats ~-16s W = ~7.5f (~w of ~w)~n",
                  [rc_label(A), rc_label(B), W, rc_n(W, M), M]).

rc_e_ext([]) ->
    "\nE3. EXTENDED CYCLIC TRIPLES (at least one NEW rung-versus-rung pair): NONE.\n";
rc_e_ext(Ext) ->
    [io_lib:format(
       "~nE3. EXTENDED CYCLIC TRIPLES: ~w. At least one pair of each is a~n"
       "rung-versus-rung pair the as-run N never played, so these are NEW post-hoc~n"
       "triples and are NOT part of the registered anchor. Listed as paths only.~n~n",
       [length(Ext)]),
     [io_lib:format("  ~s~n", [rc_path_text(rc_path(Ids, Fwd))])
      || {tri, Ids, _Me, _O, _Cy, Fwd, _Cl} <- Ext]].

%% Which champions sit in a cycle at all, per arm. A count of triples is not a
%% count of champions, and the arms differ in what they trained against.
rc_e_arms(Objs, Cyc) ->
    In = lists:usort(lists:append([[Id || Id <- [A, B, C], element(1, Id) =:= champ]
                                   || {tri, {A, B, C}, _Me, _O, _Cy, _F, _Cl} <- Cyc])),
    [io_lib:format(
       "~nE4. WHICH CHAMPIONS SIT IN A CYCLE AT ALL, PER ARM. A triple count is not a~n"
       "champion count. Arms S and L trained on all five rungs; arm D trained on the~n"
       "floor rung ALONE (rungs(d) -> [?FLOOR]), so arm D is where a champion can be~n"
       "strong against the floor bot and weak against a rung it never saw.~n~n"
       "  arm  champions  in a cycle  seeds~n", []),
     [rc_e_arm_row(Objs, In, A) || A <- [s, l, d]]].

rc_e_arm_row(Objs, In, Arm) ->
    All = [S || {champ, A, S} <- rc_champ_ids(Objs), A =:= Arm],
    Hit = [S || {champ, A, S} <- In, A =:= Arm],
    io_lib:format("  ~3s ~10w ~11w  ~w~n",
                  [atom_to_list(Arm), length(All), length(Hit), Hit]).

%%%----------------------------------------------------------------------------
%%% F. FIX D.
%%%----------------------------------------------------------------------------
rc_sec_f(Nulls) ->
    {nulls, F} = Nulls,
    [io_lib:format(
       "~n~n-- F. FIX D: THE MATCH-LEVEL NULL WAS MIS-SCALED BY TWO --~n~n"
       "WHAT WAS WRONG. xp_from_pairs/2 built a synthetic tournament by storing a~n"
       "MARGIN V at cell {I,J} and -V at cell {J,I}. xp_mg/1 is a WIN-RATE~n"
       "differencing operator, wr(M,I,J) - wr(M,J,I), so applied to that matrix it~n"
       "returned V - (-V) = 2V. Every synthetic margin was DOUBLE the margin it~n"
       "represented, so every band was effectively HALVED against the synthetic~n"
       "nulls: the record's band-0.10 match-level row is really a band-0.05 row. The~n"
       "OBSERVED matrix holds win rates (xp_at/3 puts W(I,J) in the upper half and~n"
       "L(I,J) in the lower half) and is differenced correctly, so the observed~n"
       "counts are NOT affected.~n~n"
       "THE FIX IS AT THE SOURCE AND IT IS THE UNITS. xp_from_wins/2 stores the two~n"
       "WIN RATES of a synthetic cell, W(I,J) and 1.0 - W(I,J), which is exactly what~n"
       "xp_matrix/2 stores for the observed matrix. One differencing operator is then~n"
       "correct for both and a band means the same thing on both. There is NO~n"
       "compensating factor anywhere: xp_null_match/3 now draws a win rate,~n"
       "xp_flips(M) / M, and xp_null_sign/2 draws xp_coin_w/0, which is 0.0 or 1.0.~n"
       "Antisymmetry is still by construction, the two cells of a pair summing to 1.0.~n~n"
       "HOW THE TWO COLUMNS BELOW ARE OBTAINED. The as-run construction is kept~n"
       "verbatim as xp_from_pairs_as_run/2 and is called only here. Each column is~n"
       "drawn from a FRESHLY seeded generator, seed ~w, ~w draws, ~w champions, ~w~n"
       "matches per cell, and the two constructions consume rand identically (one~n"
       "rand:uniform(2) per coin, ~w per cell), so a given null's two columns are the~n"
       "SAME draws under two encodings.~n~n"
       "THE DOUBLING, SHOWN RATHER THAN ARGUED. The span of |margin| over every pair~n"
       "of every draw:~n"
       "  sign-only   as-built ~w   corrected ~w~n"
       "  match-level as-built ~w   corrected ~w~n~n",
       [keyget(seed, F), keyget(draws, F), keyget(champions, F),
        keyget(matches_per_cell, F), keyget(matches_per_cell, F),
        keyget(sign_as_built, keyget(abs_margin_span, F)),
        keyget(sign_corrected, keyget(abs_margin_span, F)),
        keyget(match_as_built, keyget(abs_margin_span, F)),
        keyget(match_corrected, keyget(abs_margin_span, F))]),
     rc_f_table("F1. THE MATCH-LEVEL NULL, AS-BUILT BESIDE CORRECTED.",
                keyget(match_as_built, F), keyget(match_corrected, F)),
     rc_f_halving(F),
     rc_f_boundary(F),
     rc_f_table("F2. THE SIGN-ONLY NULL, AS-BUILT BESIDE CORRECTED. VERIFIED, NOT ASSUMED.",
                keyget(sign_as_built, F), keyget(sign_corrected, F)),
     rc_f_sign(F),
     rc_f_observed(F),
     rc_f_wrong_null(F)].

rc_f_table(Title, As, Co) ->
    [io_lib:format("~n~s~n~n"
                   "band  column       ordered median  ordered range   cycles median"
                   "  cycles range  decisive median of ~w~n",
                   [Title, keyget(of_pairs, rc_band(As, 0.05))]),
     [rc_f_rows(As, Co, B) || B <- xp_bands()]].

rc_f_rows(As, Co, B) ->
    [rc_f_row(B, "as-built ", rc_band(As, B)),
     rc_f_row(B, "corrected", rc_band(Co, B))].

rc_band(Rows, B) -> element(3, lists:keyfind(B, 2, Rows)).

%% Proplist getter, same name and shape as the one the exp066 audit escripts use,
%% so a reader moving between them does not have to relearn it. Crashes on a
%% missing key on purpose: a report field that is absent is a defect, not a default.
keyget(K, Kvs) -> element(2, lists:keyfind(K, 1, Kvs)).

rc_f_row(B, Tag, Kvs) ->
    io_lib:format("~.2f  ~s ~15.1f ~15w ~15.1f ~13w ~13.1f~n",
                  [B, Tag, keyget(ordered_median, Kvs), keyget(ordered_range, Kvs),
                   keyget(cycles_median, Kvs), keyget(cycles_range, Kvs),
                   keyget(decisive_median, Kvs)]).

%% The halving, as an identity between two rows of the table above rather than as a
%% claim: the as-built row at a band is the corrected row at HALF that band.
rc_f_halving(F) ->
    As = keyget(match_as_built, F),
    Co = keyget(match_corrected, F),
    io_lib:format(
      "~nTHE HALVING IS AN IDENTITY BETWEEN TWO ROWS OF THAT TABLE, not a claim: the~n"
      "as-built row at band 0.10 is the corrected row at band 0.05, because the same~n"
      "draws are read against a band that is twice as large in one encoding.~n"
      "  as-built  at band 0.10 : ordered ~.1f ~w, cycles ~.1f ~w, decisive ~.1f~n"
      "  corrected at band 0.05 : ordered ~.1f ~w, cycles ~.1f ~w, decisive ~.1f~n"
      "  identical: ~w~n~n"
      "AGREEMENT WITH THE INDEPENDENT SCRIPT, AND IT IS PARTIAL. F1b is about that.~n",
      [keyget(ordered_median, rc_band(As, 0.10)), keyget(ordered_range, rc_band(As, 0.10)),
       keyget(cycles_median, rc_band(As, 0.10)), keyget(cycles_range, rc_band(As, 0.10)),
       keyget(decisive_median, rc_band(As, 0.10)),
       keyget(ordered_median, rc_band(Co, 0.05)), keyget(ordered_range, rc_band(Co, 0.05)),
       keyget(cycles_median, rc_band(Co, 0.05)), keyget(cycles_range, rc_band(Co, 0.05)),
       keyget(decisive_median, rc_band(Co, 0.05)),
       rc_band(As, 0.10) =:= rc_band(Co, 0.05)]).

%%% F1b. The disagreement with the independent script, reported rather than
%%% resolved by choosing whichever encoding matched.
rc_f_boundary(F) ->
    Co = keyget(match_corrected, F),
    Ha = keyget(match_corrected_half_encoding, F),
    Ex = keyget(match_corrected_exact_integer, F),
    [io_lib:format(
       "~nF1b. THE CORRECTED COLUMN DOES NOT REPRODUCE THE INDEPENDENT SCRIPT AT EVERY~n"
       "BAND, AND THE REASON IS NOT THE FIX.~n~n"
       "scripts/exp066_verify_null_scaling.escript builds its corrected column a THIRD~n"
       "way: it HALVES the margin and stores plus and minus half, so xp_mg/1 returns~n"
       "the margin once. That is algebraically the same margin as xp_from_wins/2's, and~n"
       "at band 0.05 the two agree digit for digit. At bands 0.10 and 0.15 they do NOT.~n"
       "The two encodings agree on all three bands: ~w.~n~n"
       "WHY. Every synthetic margin is (2K - M)/M for an integer K, and all three~n"
       "pre-registered bands are exact multiples of the margin quantum 2/160: 0.05 is~n"
       "8/160, 0.10 is 16/160, 0.15 is 24/160. So every draw contains edges whose~n"
       "margin equals the band EXACTLY, where 'margin > band' is mathematically FALSE.~n"
       "None of 0.05, 0.10 and 0.15 is a binary float, so each encoding renders those~n"
       "boundary edges slightly above or slightly below the band, and the two round in~n"
       "OPPOSITE directions on the negative side. Two worked examples, both exact~n"
       "ties in arithmetic:~n"
       "  K = 72 of 160, true margin -0.1 exactly. Halved encoding gives~n"
       "    -0.09999999999999998, win-rate encoding -0.10000000000000003. The reverse~n"
       "    edge is therefore NOT decisive at band 0.10 under the first and IS under~n"
       "    the second.~n"
       "  K = 68 of 160, true margin -0.15 exactly. Halved gives~n"
       "    -0.15000000000000002, win-rate -0.14999999999999997, and the reverse edge~n"
       "    flips the other way at band 0.15.~n"
       "  K = 84 of 160, true margin +0.05 exactly. BOTH encodings give~n"
       "    0.050000000000000044, so both count an exact tie as decisive at band 0.05.~n"
       "    Neither encoding is right there; they merely agree.~n~n"
       "NEITHER FLOAT ENCODING IS CORRECT ON EVERY BOUNDARY EDGE, and which ties each~n"
       "one counts varies by band. scripts/exp066_verify_recovered.escript check 5~n"
       "enumerates them: at band 0.05 both encodings count both ties (K = 76 and 84)~n"
       "as decisive and both are wrong; at 0.10 the win-rate form counts both ties~n"
       "(72 and 88) and the halved form one (88), so both are wrong and the halved one~n"
       "less so; at 0.15 the win-rate form counts NEITHER tie and is right while the~n"
       "halved form counts one (68) and is wrong. This is a property of the~n"
       "PRE-REGISTERED COUNTER, which tests a strict float inequality against a band~n"
       "that is not a binary float, and NOT of this fix. The counter is NOT touched~n"
       "here: xp_ordered/3 and xp_cycles/3 are exp057's, character for character, and~n"
       "they stay that way.~n~n"
       "THE EXACT-INTEGER COLUMN IS A NEW POST-HOC DIAGNOSTIC. Mg > B is exactly~n"
       "2K - M > B * M, and B * M is 8, 16 and 24, integers. Counting with those~n"
       "computes THE SAME TEST with no rounding error. The band is not moved. This~n"
       "column is new, unregistered, and it is here to say which float encoding is~n"
       "nearer the definition, not to replace either.~n~n"
       "band  encoding                 ordered median  cycles median  decisive median  edges exactly ON the band~n",
       [keyget(corrected_encodings_identical, F)]),
     [rc_f_b_rows(Co, Ha, Ex, B) || B <- xp_bands()],
     io_lib:format(
       "~nREADING. The exact count is at or below both float columns at every band, and~n"
       "that direction is guaranteed rather than observed: a non-boundary edge sits at~n"
       "least one quantum (0.0125) from the band, far outside float error, so the exact~n"
       "edge set is a SUBSET of each float edge set and both cycle counters are~n"
       "monotone in the edge set. Which of the two float encodings sits nearer the~n"
       "exact one varies by band; compare the rows above. NEITHER is systematically~n"
       "better and this record does not claim one is. What matters for FIX D's~n"
       "conclusion is that all three corrected columns are an order of magnitude below~n"
       "the as-built column at the headline band, so the doubling defect dominates the~n"
       "encoding question by a wide margin.~n~n"
       "ONE MORE THING ABOUT THE WORK PACKAGE'S OWN ACCEPTANCE NUMBER. It asked that~n"
       "the fixed version agree with exp066_verify_null_scaling.escript's corrected~n"
       "column at 'band 0.10, ordered median 5.0 range {0,15} and cycles median 3.0~n"
       "range {0,10}'. Those four numbers are NOT that script's. Run at its own seed~n"
       "660 it prints ordered median 3.0 range {0,12} and cycles median 2.0 range~n"
       "{0,8}. The quoted numbers are exp066_crossplay_null_audit.txt's MATCH~n"
       "CORRECTED row at band 0.10, which is drawn at seed 661 and built with the~n"
       "(1+V)/2 form, a construction BITWISE IDENTICAL to xp_from_wins/2. The medians~n"
       "this record prints at band 0.10, ordered ~.1f and cycles ~.1f, equal those~n"
       "quoted medians; the ranges differ because the seed differs. The~n"
       "misattribution is recorded rather than resolved by adjusting anything, and~n"
       "scripts/exp066_verify_recovered.escript checks all three encodings against one~n"
       "another mechanically.~n",
       [keyget(ordered_median, rc_band(Co, 0.10)), keyget(cycles_median, rc_band(Co, 0.10))])].

rc_f_b_rows(Co, Ha, Ex, B) ->
    [rc_f_b_row(B, "win-rate (this fix)  ", rc_band(Co, B), none),
     rc_f_b_row(B, "halved (the escript) ", rc_band(Ha, B), none),
     rc_f_b_row(B, "EXACT integer, NEW   ", rc_band(Ex, B),
                keyget(edges_exactly_on_band_median, rc_band(Ex, B)))].

rc_f_b_row(B, Tag, Kvs, none) ->
    io_lib:format("~.2f  ~s ~13.1f ~14.1f ~16.1f~n",
                  [B, Tag, keyget(ordered_median, Kvs), keyget(cycles_median, Kvs),
                   keyget(decisive_median, Kvs)]);
rc_f_b_row(B, Tag, Kvs, On) ->
    io_lib:format("~.2f  ~s ~13.1f ~14.1f ~16.1f ~24.1f~n",
                  [B, Tag, keyget(ordered_median, Kvs), keyget(cycles_median, Kvs),
                   keyget(decisive_median, Kvs), On]).

rc_f_sign(F) ->
    io_lib:format(
      "~nTHE SIGN-ONLY NULL IS UNAFFECTED, AND THAT IS MEASURED HERE RATHER THAN~n"
      "ASSUMED. The note's argument is that a margin of plus or minus 2 clears every~n"
      "band just as plus or minus 1 does, so no counted number can move. The two~n"
      "columns above are computed on the same draws and compared:~n"
      "  all three bands, all five numbers, identical: ~w~n"
      "The margin spans differ as expected (~w as-built against ~w corrected), so the~n"
      "encodings really are different; it is the COUNTS that cannot tell them apart,~n"
      "because every band tested is below 1.0. A band at or above 1.0 would separate~n"
      "them, and none is used.~n",
      [keyget(sign_identical, F),
       keyget(sign_as_built, keyget(abs_margin_span, F)),
       keyget(sign_corrected, keyget(abs_margin_span, F))]).

%%% What the correction does to the comparison the record actually made. The
%%% observed counts are quoted from the persisted record and are NOT recomputed
%%% here; recovered/1 does not load the cross-play matrix.
rc_f_observed(F) ->
    Co = keyget(match_corrected, F),
    As = keyget(match_as_built, F),
    [io_lib:format(
       "~nF3. WHAT THE CORRECTION DOES TO THE COMPARISON. The observed counts are~n"
       "quoted from exp066_crossplay.txt's own counts block (lines 46..67) and are~n"
       "NOT recomputed here: recovered/1 does not load the cross-play matrix.~n"
       "scripts/exp066_verify_crossplay.escript already re-derives them from the~n"
       "persisted matrix independently.~n~n"
       "band  observed cycles  as-built null median  corrected null median  observed is~n", []),
     [rc_f_obs_row(As, Co, B, C) || {B, C} <- [{0.05, 49}, {0.10, 18}, {0.15, 12}]],
     io_lib:format(
       "~nREAD THAT CAREFULLY. At the HEADLINE band 0.10 the sign of the naive~n"
       "comparison REVERSES: 18 observed cycles sit below the as-built median and~n"
       "above the corrected one. At band 0.05 the correction narrows the gap without~n"
       "crossing it, and at band 0.15 the observed count was already above both. The~n"
       "audit beside this record (exp066_crossplay_null_audit.txt) reached the same~n"
       "conclusion from the persisted matrix with a third seed, and stated there that~n"
       "the sign of the comparison depends on which null is used.~n~n"
       "THE PERSISTED BLOCK IS NOT BIT-IDENTICAL TO THE AS-BUILT COLUMN ABOVE, AND~n"
       "SHOULD NOT BE. In crossplay/1 the match-level null is drawn AFTER the~n"
       "sign-only null has consumed 190 x 200 coin flips from the same generator,~n"
       "while every column above is drawn from a freshly seeded one. Same model, same~n"
       "draw count, different draws: the persisted band-0.10 medians are 84.0 and~n"
       "55.0, the as-built column above reads ~.1f and ~.1f. Neither is more correct~n"
       "than the other; both are as-built, and both are superseded by the corrected~n"
       "column.~n",
       [keyget(ordered_median, rc_band(As, 0.10)),
        keyget(cycles_median, rc_band(As, 0.10))])].

rc_f_obs_row(As, Co, B, Obs) ->
    A = keyget(cycles_median, rc_band(As, B)),
    C = keyget(cycles_median, rc_band(Co, B)),
    io_lib:format("~.2f ~16w ~21.1f ~22.1f  ~s~n",
                  [B, Obs, A, C, rc_side_text(Obs, A, C)]).

rc_side_text(Obs, A, C) when Obs < A, Obs > C -> "BELOW as-built, ABOVE corrected: SIGN REVERSES";
rc_side_text(Obs, A, C) when Obs < A, Obs =< C -> "below both";
rc_side_text(Obs, A, C) when Obs >= A, Obs > C -> "above both";
rc_side_text(_Obs, _A, _C) -> "above as-built, below corrected".

rc_f_wrong_null(F) ->
    Co = keyget(match_corrected, F),
    Dec = keyget(decisive_median, rc_band(Co, 0.10)),
    [io_lib:format(
       "~nF4. FIXING THE ARITHMETIC DOES NOT MAKE THIS THE RIGHT NULL. STATED PLAINLY.~n~n"
       "The corrected match-level null is still NOT CONDITIONED ON OBSERVED EDGE~n"
       "DECISIVENESS. It samples fair coin play at ~w matches per cell and therefore~n"
       "produces its OWN decisiveness, which is nothing like the matrix it is being~n"
       "compared with: at band 0.10 the corrected null leaves a median of ~.1f decisive~n"
       "edges of ~w while the observed matrix has 152 (exp066_crossplay.txt, counts~n"
       "block, lines 46..67). A count of cycles is a function of how many edges are~n"
       "decisive at all, so comparing 152 decisive edges against a reference with~n"
       "~.1f is not a test of intransitivity; it is mostly a test of decisiveness, and~n"
       "the arithmetic error was hiding that behind a second one.~n",
       [keyget(matches_per_cell, F), Dec, keyget(of_pairs, rc_band(Co, 0.10)), Dec]),
     rc_f_orientation()].

rc_f_orientation() ->
    "\nTHE NULL A FUTURE RUNG SHOULD REGISTER IS THE ORIENTATION NULL: keep every\n"
    "observed |margin| edge for edge and randomise only the SIGNS. That holds\n"
    "decisive_edges identical to the observed value at every band by construction,\n"
    "so the comparison is about orientation alone, which is what a cycle is.\n"
    "exp066_crossplay_null_audit.txt already computes it (ORIENTATION rows) and\n"
    "under it the observed counts sit far BELOW chance at every band. That null is\n"
    "unregistered and self-calibrated like everything else in this probe, which is\n"
    "exactly why it should be REGISTERED IN ADVANCE rather than adopted after the\n"
    "counts are known. This record does not adopt it and claims nothing from it.\n"
    "\nBoth nulls above remain UNREGISTERED and neither is a reference this front is\n"
    "entitled to read a result off. FIX D removes an arithmetic defect. It does not\n"
    "promote the fixed instrument.\n".

%%%----------------------------------------------------------------------------
%%% G.
%%%----------------------------------------------------------------------------
rc_sec_g() ->
    "\n\n-- G. WHAT THIS RECORD DOES NOT DO --\n\n"
    "It does not re-emit exp066_crossplay.txt. That record's null_match_level block\n"
    "is as-built, the audit beside it quotes those numbers, and rewriting a\n"
    "persisted exploratory record to match a later fix would destroy the evidence\n"
    "of the defect. A FUTURE crossplay/1 run emits the corrected null, because the\n"
    "fix is at the source; when that happens the two records will differ and this\n"
    "section is the reason.\n\n"
    "It does not amend the feed above its own appended note. The feed's N line\n"
    "carries four win rates because that is what the run of 2026-07-29 computed. A\n"
    "future run's line carries four {Kind, W, L, D} tuples.\n\n"
    "It does not claim an intransitivity result for the front. Whether cross-play\n"
    "cycling among CHAMPIONS is real is phase 1's question and needs champion versus\n"
    "champion play, which is not measured here.\n\n"
    "It does not loosen the relation. One relation is stated in section D and it is\n"
    "the stricter of the two available readings. Where a triple fails to close, the\n"
    "missing leg is named and the record stops there.\n\n"
    "It does not re-run an arm, modify a genome, or move a pre-registered threshold.\n"
    "B, R_line and D_min are untouched. It signs nothing.\n\n"
    "ONE BLEMISH IN THE APPENDED NOTE, LEFT ALONE BECAUSE THE FEED IS APPEND-ONLY.\n"
    "Addendum 3's line beginning 'THE CANDIDATE DOES NOT CLOSE' prints the missing\n"
    "leg with ~w applied to two label STRINGS, so it reads as two lists of character\n"
    "codes: [115,105,...] is \"sitting_duck\" and [100,50,48,48,52] is \"d2004\". The\n"
    "content is not wrong and it is not lost: the leg table three lines above it and\n"
    "the prose immediately below it both name that pair in words. The feed is\n"
    "APPEND-ONLY so the line stands as written. rc_note_named_verdict/3 now formats\n"
    "the missing legs through rc_e_miss_row/3, which uses ~s, so a future run prints\n"
    "them readably; that means a future append would not be byte-identical to the one\n"
    "of 2026-07-30, which is expected of a one-shot append.\n".

%%%----------------------------------------------------------------------------
%%% One machine-readable term at the foot, tuples and lists only.
%%%----------------------------------------------------------------------------
rc_term(Opts, Pairs, Tris, Nulls) ->
    io_lib:format(
      "~n~n== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==~n~w.~n",
      [{recovered,
        [{date, "2026-07-30"},
         {status, "POST HOC. FIX C recovers a discarded measurement and searches "
                  "for a cyclic triple. FIX D is a defect fix to a synthetic null. "
                  "Nothing here is pre-registered and nothing is signed."},
         {engine_pin, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b"},
         {produced_by, "exp066_single_population_floor_tests:recovered/1"},
         {archive_dir, maps:get(archive_dir, Opts)},
         {starts, maps:get(heldout, Opts)},
         {matches_per_ordered_cell, 2 * maps:get(heldout, Opts)},
         {relation, "A beats B iff W(A,B) > 0.5 over the 160 matches of the ordered "
                    "cell; a win requires B dead and A alive; draws count as NOT "
                    "beating"},
         {pair_shape, {pair, id_a, id_b, provenance, {w_ab, l_ab, d_ab},
                       {w_ba, l_ba, d_ba}, transpose_exact, matches}},
         {pairs, Pairs},
         {triple_shape, {tri, {id_a, id_b, id_c}, all_pairs_measured,
                         all_edges_present, cyclic, forward_orientation, provenance}},
         {triples_enumerated, length(Tris)},
         {triples_by_class,
          [{C, length([1 || {tri, _I, _M, _O, _Cy, _F, Cl} <- Tris, Cl =:= C]),
            length([1 || {tri, _I, _M, _O, true, _F, Cl} <- Tris, Cl =:= C])}
           || C <- [preregistered, extended, unmeasured]]},
         {cyclic_triples, [T || {tri, _I, _M, _O, true, _F, _Cl} = T <- Tris]},
         Nulls]}]).

%%%----------------------------------------------------------------------------
%%% The append-only note for BOTH copies of the feed.
%%%----------------------------------------------------------------------------
rc_feed_note(Opts, Pairs, Tris, Nulls) ->
    {nulls, F} = Nulls,
    Pre = [T || {tri, _I, _Me, _O, true, _F, preregistered} = T <- Tris],
    Ext = [T || {tri, _I, _Me, _O, true, _F, extended} = T <- Tris],
    Wm = rc_wmap(Pairs),
    M = 2 * maps:get(heldout, Opts),
    [io_lib:format(
       "~n~n== ADDENDUM 3, appended 2026-07-30, POST HOC: THE DISCARDED RATES, AND~n"
       "   THE MATCH-LEVEL NULL'S SCALE ==~n~n"
       "WHAT THIS IS. Nothing above this line is changed or re-run. Two more~n"
       "defects in the RUNNER, both fixed at the source, both exercised by replaying~n"
       "archived champions at engine pin~n"
       "a5e8bcfc5646827e9be49a9629f8a6a9678c814b. NO ARM WAS RE-RUN and no genome was~n"
       "modified.~n~n"
       "THE NUMBERS ARE NOT HERE. They are in~n"
       "  ~s~n"
       "which carries the full W/L/D table for every scripted opponent against every~n"
       "one of the 40 champions in both directions, the scripted round robin, the~n"
       "triple search, and the corrected null beside the as-built one.~n~n"
       "FIX C, THE RATES scripted_null/1 THREW AWAY. It kept element 1 of rates/1,~n"
       "the win rate, and discarded L and D on the same line. W = 0.0 is consistent~n"
       "with 160 losses and with 160 draws, and those are different facts: the first~n"
       "is an EDGE from the floor bot to that rung, the second is no edge at all. So~n"
       "the N line at lines 16..19 above could not say whether the floor bot BEATS~n"
       "the lower rungs. scripted_null/1 now returns {Kind, W, L, D}; a FUTURE run's~n"
       "N line carries four 4-tuples where the line above carries four win rates.~n"
       "The line above stands as what the run of 2026-07-29 computed.~n~n"
       "RECOVERED, on the same ~w held-out starts, ~w matches per rung, counts~n"
       "exact:~n", [maps:get(rc_out, Opts), maps:get(heldout, Opts), M]),
     [rc_note_n_row(Pairs, M, Kind) || Kind <- robo_gauntlet:kinds(), Kind =/= ?FLOOR],
     io_lib:format(
       "~nSo the floor bot BEATS all four lower rungs, which the as-run N could not~n"
       "say. Against the spinner it wins ~w of ~w and draws the other ~w; the draws~n"
       "were invisible before.~n~n"
       "THE RELATION, STATED. A beats B iff W(A,B) > 0.5 over the ~w matches of that~n"
       "ordered cell, a win requiring B dead and A alive. DRAWS COUNT AS NOT BEATING,~n"
       "which is exp066's convention for its primary endpoint throughout. This is the~n"
       "STRICTER of the two readings available, since W > 0.5 implies W > L. ONE~n"
       "relation, not moved.~n~n"
       "WHAT THE SEARCH FOUND. Every triple of the 5 scripted bots and the 40~n"
       "champions was enumerated, ~w in all, and classified by the provenance of its~n"
       "three pairs. Champion-versus-champion pairs are NOT measured here (that play~n"
       "exists for arm S only, in an unregistered probe), so triples needing one are~n"
       "reported UNTESTABLE.~n"
       "  PREREGISTERED cyclic triples, all three pairs already measured by the run: ~w~n"
       "  EXTENDED cyclic triples, needing a NEW rung-versus-rung pair            : ~w~n~n",
       [rc_note_spin(Pairs, M, w), M, rc_note_spin(Pairs, M, d), M, length(Tris),
        length(Pre), length(Ext)]),
     rc_note_result(Wm, M, Pre),
     rc_note_named(Pairs, M),
     io_lib:format(
       "~nFIX D, THE MATCH-LEVEL NULL WAS MIS-SCALED BY TWO. xp_from_pairs/2 stored a~n"
       "MARGIN V at {I,J} and -V at {J,I} while xp_mg/1 differences WIN RATES, so it~n"
       "returned 2V and every band was effectively halved against the synthetic~n"
       "nulls. Fixed at the source in xp_from_wins/2, which stores the two win rates~n"
       "of a synthetic cell, the same units the observed matrix uses; no compensating~n"
       "factor at any call site. The as-run construction is kept verbatim as~n"
       "xp_from_pairs_as_run/2 so both columns come off the same draws.~n"
       "  match-level, band 0.10, ~w draws, seed ~w: as-built cycles median ~.1f,~n"
       "    corrected ~.1f. The as-built row at band 0.10 IS the corrected row at~n"
       "    band 0.05: ~w.~n"
       "  sign-only: all three bands, all five numbers, identical under both~n"
       "    constructions: ~w. Verified, not assumed. Its margins are exactly~n"
       "    +/-1.0 and +/-2.0, both representable, so no boundary edge exists there.~n"
       "  At the headline band 0.10 the sign of the naive comparison REVERSES: 18~n"
       "    observed cycles sit below the as-built median and above the corrected~n"
       "    one.~n"
       "  THE CORRECTED COLUMN DOES NOT REPRODUCE~n"
       "    scripts/exp066_verify_null_scaling.escript AT EVERY BAND, and the reason~n"
       "    is not the fix. All three bands are exact multiples of the margin quantum~n"
       "    2/160, so every draw contains edges whose margin EQUALS the band, where a~n"
       "    strict float inequality is decided by rounding; the two encodings round~n"
       "    those in opposite directions on the negative side. They agree at band~n"
       "    0.05 and differ at 0.10 and 0.15. Section F1b of the record gives the~n"
       "    worked examples and adds an EXACT-INTEGER count, a NEW post-hoc~n"
       "    diagnostic that computes the same test with no rounding: it is at or~n"
       "    below both float columns at every band. The pre-registered counter is NOT~n"
       "    touched. Related: the four numbers this work package quoted as that~n"
       "    script's corrected column at band 0.10 are in fact~n"
       "    exp066_crossplay_null_audit.txt's, at a different seed.~n~n"
       "EVEN CORRECTED, THAT NULL IS STILL THE WRONG REFERENCE, and fixing the~n"
       "arithmetic does not promote it. It is not conditioned on observed edge~n"
       "decisiveness: at band 0.10 it leaves a median of ~.1f decisive edges of ~w~n"
       "where the observed matrix has 152, so the comparison is mostly a test of~n"
       "decisiveness rather than of intransitivity. THE NULL A FUTURE RUNG SHOULD~n"
       "REGISTER IS THE ORIENTATION NULL, which keeps every observed |margin| and~n"
       "randomises only the signs, holding decisive_edges identical to the observed~n"
       "value at every band. exp066_crossplay_null_audit.txt already computes it. It~n"
       "is unregistered, so it should be registered IN ADVANCE, not adopted now.~n~n"
       "exp066_crossplay.txt IS NOT RE-EMITTED. Its null_match_level block stays~n"
       "as-built and the audit beside it quotes those numbers.~n~n"
       "PRODUCED BY. experiments/exp066_single_population_floor_tests.erl,~n"
       "recovered/1, added 2026-07-30, driven by scripts/exp066_recovered.sh, checked~n"
       "by scripts/exp066_verify_recovered.escript. The as-run copy archived beside~n"
       "the champions contains none of this.~n"
       "== END ADDENDUM 3 ==~n",
       [keyget(draws, F), keyget(seed, F),
        keyget(cycles_median, rc_band(keyget(match_as_built, F), 0.10)),
        keyget(cycles_median, rc_band(keyget(match_corrected, F), 0.10)),
        rc_band(keyget(match_as_built, F), 0.10)
            =:= rc_band(keyget(match_corrected, F), 0.05),
        keyget(sign_identical, F),
        keyget(decisive_median, rc_band(keyget(match_corrected, F), 0.10)),
        keyget(of_pairs, rc_band(keyget(match_corrected, F), 0.10))])].

rc_note_n_row(Pairs, M, Kind) ->
    Rm = rc_rmap(Pairs),
    {W, L, D} = rc_rates(Rm, {script, Kind}, {script, ?FLOOR}),
    io_lib:format("  ~-15s vs predictive_gun : W/L/D = ~4w/~4w/~4w of ~w  "
                  "(as-run N carried W = ~.5f alone)~n",
                  [atom_to_list(Kind), rc_n(W, M), rc_n(L, M), rc_n(D, M), M, W]).

%% The spinner's two numbers from the FLOOR BOT's side, named in the note's prose.
rc_note_spin(Pairs, M, Which) ->
    Rm = rc_rmap(Pairs),
    {W, _L, D} = rc_rates(Rm, {script, ?FLOOR}, {script, spinner}),
    rc_note_spin_1(Which, M, W, D).

rc_note_spin_1(w, M, W, _D) -> rc_n(W, M);
rc_note_spin_1(d, M, _W, D) -> rc_n(D, M).

%%% THE NOTE'S OWN CANDIDATE, in the feed, with its verdict COMPUTED from the
%%% measured rates rather than written out in prose. Every leg is printed whether
%%% it holds or not, and the missing ones are named.
rc_note_named(Pairs, M) ->
    Rm = rc_rmap(Pairs),
    C = {champ, d, 2004},
    G = {script, ?FLOOR},
    Duck = {script, sitting_duck},
    Legs = [{C, G}, {G, Duck}, {Duck, C}],
    Miss = [L || {A, B} = L <- Legs, element(1, rc_rates(Rm, A, B)) =< 0.5],
    [io_lib:format(
       "~nTHE CANDIDATE THE UNSIGNED NOTE NAMED, TESTED LEG BY LEG. The note proposed~n"
       "arm D seed 2004 beating predictive_gun while going 0.0125 W and 0.98125 D~n"
       "against the sitting duck, so that the third leg of a triple was already~n"
       "inside the pre-registered arms. Measured:~n~n", []),
     [rc_e_leg(Rm, M, A, B) || {A, B} <- Legs],
     rc_note_named_verdict(Rm, M, Miss)].

rc_note_named_verdict(_Rm, _M, []) ->
    "\n  ALL THREE LEGS HOLD: the note's candidate is cyclic under the stated\n"
    "  relation.\n";
%% The missing legs are printed through rc_e_miss_row/3, which formats the labels
%% with ~s. The note appended on 2026-07-30 printed them with ~w on the label
%% strings instead, so that one line of the feed reads as character codes; the feed
%% is append-only, so it stands, and the leg table three lines above it and the
%% prose below it both name the same pair in words. Fixed here for a future run.
rc_note_named_verdict(Rm, M, Miss) ->
    {DW, _DL, DD} = rc_rates(Rm, {script, sitting_duck}, {champ, d, 2004}),
    [io_lib:format("~n  THE CANDIDATE DOES NOT CLOSE. ~w of the three legs is missing:~n",
                   [length(Miss)]),
     [rc_e_miss_row(Rm, M, L) || L <- Miss],
     io_lib:format(
       "~n  The sitting duck wins ~w of ~w against arm D seed 2004 and DRAWS ~w, so~n"
       "  the duck neither beats the champion nor loses to it and the pair carries NO~n"
       "  EDGE. Turning that into an edge would need a draw read as a win for the side~n"
       "  that did not win, which is the opposite of exp066's convention. IT WAS NOT~n"
       "  DONE. What the recovered number DID settle is the other leg, the gun against~n"
       "  the duck, which W = 0.0 alone could not decide. So the recovery worked and~n"
       "  the note's candidate is refuted by the number the note asked for.~n",
       [rc_n(DW, M), M, rc_n(DD, M)])].

rc_note_result(_Wm, _M, []) ->
    "NO PREREGISTERED CYCLIC TRIPLE EXISTS. Under the stated relation there is no\n"
    "registered intransitivity anchor in the arms. No relation was loosened to\n"
    "change that; the negative is the result.\n";
rc_note_result(Wm, M, Pre) ->
    [io_lib:format(
       "A PREREGISTERED CYCLIC TRIPLE EXISTS, ~w of them. The first, in full, with~n"
       "every leg checkable against the per-seed rung profiles above:~n~n",
       [length(Pre)]),
     rc_e_cycle(Wm, M, hd(Pre)),
     io_lib:format(
       "~nThe rest are in the record. They are NOT a claim about the substrate: a~n"
       "champion beating the floor bot while losing to a rung the floor bot beats is~n"
       "an OBSERVABLE, which is what IF-10 was always declared to be, and arm D~n"
       "trained on the floor rung ALONE, so it never saw the rung that beats it.~n"
       "That is a statement about the CURRICULUM, not about the arena.~n", [])].

%%%============================================================================
%%% THE ARMS.
%%%
%%% WHY L IS MANDATORY. The encoding is built to make the floor nearly linearly
%%% representable, so a pass by arm S alone would have to be reported honestly as
%%% "a 17-channel linear map suffices and the ES found it" rather than
%%% "neuroevolution reached competence". Without this arm the phase-0 claim is
%%% inflated in a way no later analysis can undo.
%%%
%%% WHY D IS MANDATORY. The staircase is itself a curriculum, so a stall is a
%%% statement about the curriculum. If S stalls at rung 3, "did not reach the
%%% floor" would be uninterpretable in exactly the way the plan says a null must
%%% not be. D removes the curriculum entirely.
%%%
%%% WHY THE STOPPING RULE IS ASYMMETRIC. CLEARED is an EXISTENCE claim, so one
%%% optimiser class suffices. FAILED is a UNIVERSAL claim, so it needs two,
%%% because a negative from a single optimiser reproduces verbatim the search
%%% under-convergence confound this gate exists to remove. Arm M therefore runs
%%% ONLY if S does not clear. Fixed in advance so it cannot be used to shop for a
%%% result.
%%%============================================================================
arm_layers(l) -> [17, 5];
arm_layers(_Arm) -> [17, 12, 5].

arm_seeds(Arm, Opts) ->
    Seed0 = maps:get(seed0, Opts),
    lists:seq(Seed0, Seed0 + maps:get(seed_key(Arm), Opts) - 1).

seed_key(s) -> seeds_s;
seed_key(l) -> seeds_l;
seed_key(d) -> seeds_d;
seed_key(m) -> seeds_m.

arm(Arm, Opts) ->
    Layers = arm_layers(Arm),
    ?INPUTS = hd(Layers),
    pmap(fun(Seed) -> seed_run(Arm, Seed, Layers, Opts) end,
         arm_seeds(Arm, Opts), maps:get(workers, Opts)).

seed_run(Arm, Seed, Layers, Opts) ->
    {Res, {N, {Q, Fit}, Marks, Distinct, Clamp}} = one_run(Arm, Seed, Layers, Opts),
    ok = check_champion_agrees(Res, Q, Fit),
    Held = heldout_starts(Opts),
    Net = {net, Layers, Q},
    Os = heldout(Net, ?FLOOR, Held),
    {W, L, D} = rates(Os),
    #res{arm = Arm, seed = Seed, layers = Layers,
         dim = robo_net:weight_count(Layers),
         evals = evals_of(Res, N), fit = Fit, q = Q,
         w = W, l = L, d = D,
         margin = mean_margin(Os),
         caps = cap_share(Os),
         shots = mean([maps:get(shots, O) || O <- Os]),
         pulls = mean([maps:get(pulls, O) || O <- Os]),
         won_opp_shots = won_opp_shots(Os),
         train_w = win_rate(heldout(Net, ?FLOOR, train_starts(Opts))),
         distinct_last = last_or(Distinct, 0),
         clamp_last = last_or(Clamp, 0.0),
         clamp_frac = clamp_frac(Q),
         profile = profile(Net, Held),
         %% All three checkpoints are evaluated on held-out. The final checkpoint
         %% must equal the ES-returned best; check_champion_agrees/3 asserts it.
         marks = [{At, win_rate(heldout({net, Layers, MQ}, ?FLOOR, Held))}
                  || {At, {MQ, _MF}} <- Marks]}.

%% DEFECT FIX (D2). The pre-registration says "the 50,000 record MUST equal the
%% ES-returned best; that equality is the wrapper's self-check", and it was not
%% checked. The champion and every checkpoint were taken from the COLLECTOR, and
%% the optimiser's own best was read nowhere outside the determinism gate, so the
%% stated equality was true by construction: the same collector field compared
%% with itself. evals_of/2 compares evaluation COUNTS, which is a different and
%% much weaker claim than genome equality.
%%
%% The check compares FITNESS, not genome identity, and the reason is a finding in
%% its own right: the stated GENOME equality is unimplementable, and asserting it
%% raised on the first seed of the first arm.
%%
%% The two sides break ties differently over the same landscape. The collector
%% keeps the first genome reaching the maximum across EVERY evaluation, because
%% better/3 keeps the incumbent when F =< BF. sep_cma_es keeps the first across
%% GENERATION TOPS only, because it compares TopF > element(2, Best) once per
%% generation. The ladder fitness is a coarse count over six training starts, so
%% ties at the maximum are common, and on a tie the two legitimately hold
%% DIFFERENT genomes of EQUAL fitness. Neither is wrong and no reordering makes
%% them agree.
%%
%% Equal fitness is the invariant that actually matters, and it is strict in both
%% directions. Collector below optimiser means the collector missed the winner;
%% collector above means the optimiser did. Either way the seed is untrustworthy,
%% so this raises rather than warns.
check_champion_agrees(Res, _Q, Fit) ->
    agree_fitness(Fit, maps:get(fitness, Res, undefined)).

agree_fitness(_Fit, undefined) -> ok;        %% optimiser exposes no fitness; nothing to check
agree_fitness(Fit, Fit) -> ok;
agree_fitness(Fit, EsFit) ->
    error({champion_fitness_disagrees, [{collector, Fit}, {optimiser, EsFit}]}).

evals_of(Res, N) -> {maps:get(evaluations, Res, N), N}.

last_or([], D) -> D;
last_or(L, _D) -> lists:last(L).

%% Runs are independent and pure and rand state is per process, so this is
%% deterministic however it is scheduled.
%% DEFECT FIX (D4). This was not a pool. workers = 1 ran serially and any other
%% value spawned one process PER SEED regardless of the number, so workers => 4
%% gave 20 concurrent runs rather than four. Combined with a default of 1, a run
%% at pre-registered settings executed every seed sequentially: about 34 hours
%% against about 2.4 hours. It now runs in ordered chunks of N, which bounds
%% concurrency at N and preserves result order.
%%
%% Scheduling cannot affect results. Each seed is an independent pure run whose
%% rand state is seeded inside its own process, so the champion of a given seed
%% is identical however the work is spread. That is what makes it safe for the
%% default to follow the machine.
pmap(F, Xs, N) when not is_integer(N); N < 1 -> pmap(F, Xs, 1);
pmap(F, Xs, 1) -> lists:map(F, Xs);
pmap(F, Xs, N) -> lists:append([pmap_chunk(F, C) || C <- chunk(N, Xs)]).

pmap_chunk(F, Xs) ->
    Parent = self(),
    Kids = [spawn_monitor(fun() -> Parent ! {res, self(), F(X)} end) || X <- Xs],
    [collect_kid(P, R) || {P, R} <- Kids].

chunk(_N, []) -> [];
chunk(N, Xs) when length(Xs) =< N -> [Xs];
chunk(N, Xs) -> {H, T} = lists:split(N, Xs), [H | chunk(N, T)].

collect_kid(Pid, Ref) ->
    receive
        {res, Pid, V} -> demonitor(Ref, [flush]), V;
        {'DOWN', Ref, process, Pid, Reason} -> error({worker_died, Reason})
    end.

%%%============================================================================
%%% THE KILL GATES AND THE INSTRUMENT CHECKS. All before the arms, all cheap, and
%%% exported separately so they can be run before any compute is committed. ANY
%%% FAILURE STOPS THE PROTOCOL AT STEP 1.
%%%============================================================================
gates() -> gates(#{}).

gates(Opts0) ->
    Opts = merged(Opts0),
    io:format("== EXP-066 kill gates and instrument checks ==~n"),
    G = [gate_golden(), gate_topology(), gate_starts(), gate_boundary(),
         gate_channels(Opts), gate_solo(Opts), gate_determinism(Opts)],
    io:format("~n~s~n", [gate_verdict(lists:all(fun({_N, Ok, _D}) -> Ok end, G))]),
    G.

gate_verdict(true) ->
    "GATES PASS -- protocol step 2 (measure and FREEZE P, SE, S_par, B, R_line, "
    "D_min) may proceed. Nothing above commits compute to an evolution arm.";
gate_verdict(false) ->
    "GATES FAIL -- STOP. A failing instrument check makes every downstream number "
    "on this front meaningless; do not relax it, fix it.".

%% Gate 1. The engine is UNTOUCHED, asserted by recomputation rather than
%% trusted. robo_match_tests' golden vector is recomputed here through
%% robo_match's own unmodified runner, with maps canonicalised out before
%% hashing, exactly as that suite does.
gate_golden() ->
    Got = binary:encode_hex(golden_trace()),
    report_gate("golden match vector (robo_sim/net/gauntlet/match untouched)",
                Got =:= ?GOLDEN_MATCH, Got).

golden_trace() ->
    Results = [canon(robo_match:match(A, B, S))
               || {A, B} <- [{predictive_gun, circle_strafer},
                             {rammer, spinner},
                             {circle_strafer, sitting_duck}],
                  S <- robo_match:starts()],
    crypto:hash(sha256, term_to_binary(Results, [deterministic, {minor_version, 2}])).

canon(#{a := A, b := B, turns := T}) -> {T, outcome_tuple(A), outcome_tuple(B)}.

outcome_tuple(#{damage := D, survived := S, alive := L}) -> {D, S, L}.

%% Gate 2. TOPOLOGY WIDTH. robo_net:fit/2 silently pads or truncates, so a
%% mismatch between the channel count and the first layer width would never fail
%% a test. The weight counts are asserted against robo_net:weight_count/1 rather
%% than restated.
gate_topology() ->
    Wide = robo_net:weight_count([17, 12, 5]),
    Lin = robo_net:weight_count([17, 5]),
    Ok = hd(arm_layers(s)) =:= inputs() andalso hd(arm_layers(l)) =:= inputs()
        andalso Wide =:= 281 andalso Lin =:= 90
        andalso length(channels(#pilot{}, #tank{})) =:= inputs(),
    report_gate("topology width and weight counts",
                Ok, {inputs(), {'[17,12,5]', Wide}, {'[17,5]', Lin}}).

%% Gate 3. THE START GENERATOR: 120 distinct starts, separation at least 150
%% whole units so no match opens inside ram range, and at least 8 angle units of
%% heading offset on every start so no tank is ever bore-sighted at turn 1.
gate_starts() ->
    Ss = starts(),
    Ds = [robo_sim:dist({AX, AY}, {BX, BY}) || {AX, AY, _AH, BX, BY, _BH} <- Ss],
    Ok = length(lists:usort(Ss)) =:= 120 andalso lists:min(Ds) >= 150
        andalso lists:min([abs(off(I)) || I <- lists:seq(1, 120)]) >= 8
        andalso length(split(train)) =:= 6 andalso length(split(heldout)) =:= 80
        andalso length(split(calibration)) =:= 30
        andalso split(train) -- split(heldout) =:= split(train),
    report_gate("start generator: 120 distinct, min separation, offsets, disjoint splits",
                Ok, {distinct, length(lists:usort(Ss)), min_sep, lists:min(Ds),
                     median_sep, median([D * 1.0 || D <- Ds]), max_sep, lists:max(Ds)}).

%% Gate 4. THE PERCEPTION CONTRACT, on the PILOT. A controller must be handed the
%% arena whose scans were produced by the same step that produced its own tank. A
%% runner that stepped first would hand it a one-turn-stale world, silently, and
%% nothing would fail. Probed on the pilot STATE rather than the intent, because
%% two consecutive arenas can carry identical scans when nothing has moved.
gate_boundary() ->
    Arena = robo_sim:step(robo_sim:new([{a, 100, 300, 0}, {b, 400, 300, 128}]), []),
    Blind = Arena#arena{scans = []},
    T = lists:keyfind(a, #tank.id, Arena#arena.tanks),
    Net = {[17, 5], robo_net:quantize(arm_c_weights(arm_c_gains()))},
    {_, Fresh} = pilot_act(Net, pilot_init(), T, Arena),
    {_, Stale} = pilot_act(Net, pilot_init(), T, Blind),
    Ok = Arena#arena.scans =/= [] andalso Fresh =/= Stale
        andalso Stale#pilot.seen =:= 0 andalso Fresh#pilot.seen =:= 1,
    report_gate("perception contract: a stale arena is DETECTABLE for the pilot",
                Ok, {fresh_seen, Fresh#pilot.seen, stale_seen, Stale#pilot.seen}).

%% Gate 5. THE CHANNEL RANGE DIAGNOSTIC. A channel that never leaves a narrow
%% band is invisible to selection, and finding that out AFTER a null is worth
%% much less than finding it out before. Reports each channel's realised min, max
%% and variance across full matches over random genomes.
gate_channels(Opts) ->
    Layers = arm_layers(s),
    Start = hd(heldout_starts(Opts)),
    Vs = lists:append([probe_channels(Layers, Q, Start)
                       || Q <- random_genomes(Layers, maps:get(random_null, Opts))]),
    Cols = [[lists:nth(I, V) || V <- Vs] || I <- lists:seq(1, inputs())],
    Stats = [{I, lists:min(C), lists:max(C), variance(C)}
             || {I, C} <- lists:zip(lists:seq(1, inputs()), Cols)],
    [io:format("   ch ~2w  min ~5w  max ~5w  var ~10.1f~n", [I, Lo, Hi, V])
     || {I, Lo, Hi, V} <- Stats],
    Dead = [I || {I, Lo, Hi, _V} <- Stats, Hi - Lo < 4],
    report_gate("channel range diagnostic (dead channels are invisible to selection)",
                Dead =:= [], {samples, length(Vs), dead_channels, Dead}).

%% Channels are a pure function of the post-observe state and the acting tank, so
%% recording those two per turn and recomputing is EXACT, and it keeps the probe
%% out of the hot loop's arithmetic.
probe_channels(Layers, Q, Start) ->
    #{probe := Pr} = play_seat({net, Layers, Q}, {script, ?FLOOR}, Start, a, []),
    [channels(S, T) || {T, S} <- Pr].

%% Gate 6. THE SOLO OSCILLATION DIAGNOSTIC. There is no clock input and no
%% recurrence, deliberately: a hand-chosen oscillation period is a hand-designed
%% behaviour smuggled in as a sensor. Weaving and radar wobble must therefore
%% arise as limit cycles THROUGH THE WORLD. A champion flat in isolation that
%% loses to a predictive gun has failed for a REPRESENTATIONAL reason, not an
%% optimiser one, so this is measured before any champion exists.
gate_solo(Opts) ->
    Layers = maps:get(c_layers, Opts),
    Q = robo_net:quantize(arm_c_weights(maps:get(gains, Opts))),
    Cmds = solo({Layers, Q}, hd(heldout_starts(Opts)), 400),
    NA = length(lists:usort([A || {A, _B} <- Cmds])),
    NB = length(lists:usort([B || {_A, B} <- Cmds])),
    report_gate("solo oscillation: accel and turn_body are non-constant alone",
                NA > 1 orelse NB > 1, {distinct_accel, NA, distinct_turn_body, NB}).

%% robo_sim:finished/1 is true immediately with a single tank, so the arena is
%% stepped directly rather than through the match loop, exactly as
%% robo_match_tests' solo check does. The perception contract is the same: act on
%% the current arena, then step.
solo(Net, {X, Y, H, _BX, _BY, _BH}, N) ->
    solo_loop(robo_sim:new([{a, X, Y, H}]), Net, pilot_init(), N, []).

solo_loop(_Arena, _Net, _S, 0, Acc) -> lists:reverse(Acc);
solo_loop(Arena, Net, S, N, Acc) ->
    T = lists:keyfind(a, #tank.id, Arena#arena.tanks),
    {I, S2} = pilot_act(Net, S, T, Arena),
    solo_loop(robo_sim:step(Arena, [{a, I}]), Net, S2, N - 1,
              [{I#intent.accel, I#intent.turn_body} | Acc]).

%% Gate 7. DETERMINISM. Re-running one seed reproduces the champion
%% BIT-IDENTICALLY. Run at a REDUCED budget, because the pre-registration files
%% this under "all cheap" and a full-budget re-run is 2.8 CPU-hours; the property
%% under test is reproducibility of the pipeline, which a short run exercises in
%% full (seeding, x0 draw, quantisation, the cache, the collector).
gate_determinism(Opts) ->
    Probe = Opts#{budget := maps:get(probe_budget, Opts),
                  train := min(2, maps:get(train, Opts))},
    {A, _} = one_run(s, maps:get(seed0, Opts), arm_layers(s), Probe),
    {B, _} = one_run(s, maps:get(seed0, Opts), arm_layers(s), Probe),
    QA = robo_net:quantize(maps:get(best, A)),
    QB = robo_net:quantize(maps:get(best, B)),
    report_gate("determinism: a re-run reproduces the champion bit-identically",
                QA =:= QB andalso maps:get(fitness, A) =:= maps:get(fitness, B),
                {evaluations, maps:get(evaluations, A),
                 champion_id(champion(s, maps:get(seed0, Opts), arm_layers(s), QA,
                                      maps:get(fitness, A), maps:get(evaluations, A)))}).

report_gate(Name, Ok, Detail) ->
    io:format("~s ~s~n   ~p~n", [pass(Ok), Name, Detail]),
    {Name, Ok, Detail}.

pass(true) -> "PASS";
pass(false) -> "FAIL".

%%%============================================================================
%%% THE STUDY.
%%%
%%% ORDER OF OPERATIONS, AND IT IS LOAD-BEARING. Everything that could be tuned
%%% is measured and frozen BEFORE the first evolution arm runs, every
%%% generator-dependent constant is measured under the FINAL start rule, and the
%%% bar is frozen before arm C is built, so the person building arm C cannot set
%%% the difficulty of the gate they then want evolution to clear.
%%%
%%% UNGRADEABLE, and the evolution arms are NOT RUN, if W_0b is below B on both
%%% topologies under the stop rule. That is a cheap phase-0 finding and is
%%% treated as one, NOT as a reason to lower the bar.
%%%============================================================================
run() -> run(#{}).

pilot() -> run(pilot_opts()).

%% A cheap pilot: one seed, a tiny budget, a small held-out set. Anything but the
%% pre-registered configuration is a PILOT and NOT a result, and run/1 says so in
%% the feed rather than leaving a reader to notice.
pilot_opts() ->
    #{arms => [s], budget => 300, seeds_s => 1, train => 2, heldout => 8,
      calibration => 4, checkpoints => [100, 200, 300], random_null => 3,
      inert_null => 20, probe_budget => 40, feed => "exp066_pilot_feed.txt"}.

%% The cross-play probe and the post-hoc addendum both read the ARCHIVE, because
%% the run that produced these champions is over: they are the only inputs either
%% one has, and both are therefore reproducible from the archive alone. Paths are
%% relative to the faber-programmes repository root, which is where every runner
%% in this repo is run from; faber-ecosystem is its sibling checkout.
xp_defaults() ->
    Arch = "programmes/p7_coevolution/exp066_competence_floor/",
    #{archive_dir => Arch,
      xp_champions => Arch ++ "exp066_champions_s.eterm",
      xp_out => Arch ++ "exp066_crossplay.txt",
      %% ALL 80 held-out starts, so a cell holds 160 matches and one flipped match
      %% moves a margin by 0.0125 against a 0.10 band. The first pass ran 12 and
      %% persisted nothing, so nobody could tell 6 from 12 afterwards.
      xp_starts => 80,
      %% Set to none to skip; 6 reproduces the first pass's own configuration.
      xp_repro_starts => 6,
      xp_null_draws => 200,
      xp_sub_n => 10,
      xp_sub_draws => 200,
      addendum_arms => [s, l, d],
      %% flag_fixes/1 writes its own record and appends a short pointer note to
      %% the same two feed copies the addendum appends to.
      fx_out => Arch ++ "exp066_flag_fixes.txt",
      %% recovered/1 writes its own record and appends to the same two feed copies.
      %% Its null table is computed at the CROSS-PLAY probe's own configuration (20
      %% champions, 160 matches per cell, 200 draws, seed XP_SEED) so the corrected
      %% column can be set beside the as-built column the record already carries.
      rc_out => Arch ++ "exp066_recovered_rates_and_null_fix.txt",
      rc_null_n => 20,
      rc_null_cell => 160,
      addendum_feeds =>
          ["../faber-ecosystem/insights/066-raw-competence-floor.txt",
           Arch ++ "exp066_floor_feed.txt"]}.

defaults() ->
    maps:merge(xp_defaults(),
    #{arms => [s, l, d],
      budget => 50000,
      lambda => auto,
      lambda_m => 70,
      seeds_s => 20, seeds_l => 10, seeds_d => 10, seeds_m => 20,
      seed0 => 2001,
      train => 6, heldout => 80, calibration => 30,
      checkpoints => [10000, 25000, 50000],
      %% Follows the machine. Safe because seeds are independent pure runs with
      %% per-process rand state, so concurrency changes wall clock and nothing
      %% else. Set workers => 1 to force serial execution when debugging.
      workers => erlang:system_info(schedulers_online),
      probe_budget => 40,
      random_null => 30,
      inert_null => 200,
      c_layers => ?C_LAYERS,
      gains => arm_c_gains(),
      feed => "exp066_floor_feed.txt"}).

merged(Opts) -> maps:merge(defaults(), Opts).

%% Protocol step 1, enforced rather than documented. Refuses to go further if any
%% instrument check fails, and names the ones that failed rather than reporting a
%% bare false, because the operator needs to know which instrument is broken.
require_gates(Opts) ->
    Results = gates(Opts),
    case [Name || {Name, false, _} <- Results] of
        [] -> ok;
        Failed -> error({gates_failed, Failed})
    end.

run(Opts0) ->
    Opts = merged(Opts0),
    %% DEFECT FIX (D5). The protocol's step 1 is the instrument checks and says
    %% "any failure stops here", but run/1 used to begin at step 2, so the whole
    %% study, or an UNGRADEABLE verdict, could be produced on an instrument that
    %% had never passed a check. The gates cost four seconds against hours of
    %% evolution, so there was never a cost argument for keeping them optional.
    ok = require_gates(Opts),
    {ok, Fd} = file:open(maps:get(feed, Opts), [write]),
    emit(Fd, "== EXP-066: does single-population evolution reach the COMPETENCE FLOOR? ==~n"),
    emit(Fd, "~s~n", [config_note(Opts)]),
    emit(Fd, "config: ~p~n", [maps:without([gains], Opts)]),
    K0 = constants(Opts),
    emit(Fd, "~n-- FROZEN CONSTANTS (scripted bots only, measured before any arm) --~n"),
    emit(Fd, "P=~.4f  SE=~.4f (bootstrap ~.4f, binomial floor ~.4f)  S_par=~.2f  cap_share=~.4f~n",
         [maps:get(p, K0), maps:get(se, K0), maps:get(se_bootstrap, K0),
          maps:get(se_binomial, K0), maps:get(s_par, K0), maps:get(cap_share, K0)]),
    emit(Fd, "B=~.4f  R_line=~.4f  D_min=~.4f (k=4 is the ONE chosen constant)~n",
         [maps:get(b, K0), maps:get(r_line, K0), maps:get(d_min, K0)]),
    emit(Fd, "N (scripted ladder vs the floor bot) = ~p~n", [maps:get(n_scripted, K0)]),
    emit(Fd, "~s~n", [se_note(maps:get(se_bootstrap, K0))]),
    C = arm_c(Opts),
    emit(Fd, "~n-- ARM C: kill gate 0b, expressibility (built on CALIBRATION only) --~n"),
    emit(Fd, "layers=~p dim=~p calibration=~.4f  W_0b=~.4f  margin=~.2f  shots/match=~.2f  caps=~.3f~n",
         [maps:get(layers, C), maps:get(dim, C), maps:get(calibration, C),
          maps:get(w_0b, C), maps:get(margin, C), maps:get(shots, C), maps:get(caps, C)]),
    emit(Fd, "arm C ladder profile (IF-11 reads this): ~p~n", [maps:get(profile, C)]),
    gradeable(Fd, Opts, K0, C, maps:get(w_0b, C) >= maps:get(b, K0)),
    file:close(Fd),
    ok.

config_note(Opts) ->
    pilot_note(maps:get(budget, Opts) =:= 50000 andalso maps:get(heldout, Opts) =:= 80
               andalso maps:get(train, Opts) =:= 6).

pilot_note(true) -> "PRE-REGISTERED CONFIGURATION.";
pilot_note(false) ->
    "PILOT CONFIGURATION -- NOT THE PRE-REGISTERED RUN. The thresholds below are "
    "computed on a reduced ensemble and NO VERDICT FROM THIS FEED IS SIGNABLE.".

se_note(Boot) when Boot =< 0.020 ->
    "NOTE: the bootstrap SE is at or below 0.020, which FALSIFIES the design "
    "gate's own band critique. Re-derive the bar arithmetic from the bootstrap.";
se_note(_Boot) ->
    "NOTE: the bootstrap SE exceeds 0.020, so the gate's band critique stands and "
    "the four-standard-error bar is the defensible one.".

%% DEFECT FIX (D9). Arm C used to BLOCK: if its held-out rate fell below B, the
%% evolution arms were not run at all and the front reported IF-1 UNGRADEABLE as
%% a finding about the ENCODING. The pilot measured that reading to be false on
%% this very encoding. Arm S reached 0.4875 held-out against the floor bot after
%% 3,000 evaluations, with a positive damage margin, while the hand construction
%% scored 0.0000. The encoding is demonstrably adequate; the hand construction is
%% what failed, and blaming the encoding for that would have been a signed wrong
%% answer produced by the instrument rather than by the substrate.
%%
%% Blocking on arm C also reinstated as a GATE precisely the dependency the DESIGN
%% gate identified as fatal flaw 2 and removed from the BAR: the experimenter's
%% own construction skill deciding the outcome. Relocating it from the threshold
%% to the precondition does not remove it.
%%
%% Expressibility is a property of the NETWORK CLASS. An evolved champion that
%% beats the floor bot establishes it a fortiori and far more strongly than any
%% hand construction can. So arm C is now a DIAGNOSTIC that is always reported and
%% never blocks, and UNGRADEABLE is reserved for what it was meant to mean:
%% nothing, constructed OR evolved, could use the encoding at all. That is decided
%% after the arms, by ungradeable_check/4, because it cannot be known before them.
gradeable(Fd, Opts, K, C, Precondition) ->
    arm_c_note(Fd, K, C, Precondition),
    Done = [{A, arm_report(Fd, A, K, Opts)} || A <- maps:get(arms, Opts)],
    maybe_arm_m(Fd, K, Opts, lists:keyfind(s, 1, Done)),
    ungradeable_check(Fd, K, C, Done).

arm_c_note(Fd, _K, _C, true) ->
    emit(Fd, "~narm C cleared the expressibility precondition. The arms run.~n");
arm_c_note(Fd, K, C, false) ->
    emit(Fd, "~narm C did NOT clear: W_0b=~.4f is below B=~.4f. The arms RUN ANYWAY.~n",
         [maps:get(w_0b, C), maps:get(b, K)]),
    emit(Fd, "Arm C is a DIAGNOSTIC, not a gate. A hand construction failing says "
             "something about the constructor; only evolution ALSO failing says "
             "anything about the encoding. See IF-1 below, decided after the arms.~n").

%% IF-1 now needs BOTH halves: the construction failed AND evolution never beat
%% its own random-genome null. Either alone is uninformative about the encoding.
ungradeable_check(_Fd, _K, _C, []) -> ok;
ungradeable_check(Fd, K, C, Done) ->
    CFailed = maps:get(w_0b, C) < maps:get(b, K),
    NoArm = lists:all(fun({_A, V}) -> V =:= failed end, Done),
    ungradeable_verdict(Fd, CFailed andalso NoArm, CFailed).

ungradeable_verdict(Fd, true, _CFailed) ->
    emit(Fd, "~nIF-1 UNGRADEABLE: the hand construction did not clear AND no evolution arm "
             "beat its random-genome null. Nothing, constructed or evolved, could use this "
             "encoding, which is the one reading that implicates the ENCODING rather than "
             "the constructor. Next move: the encoding.~n");
ungradeable_verdict(Fd, false, true) ->
    emit(Fd, "~nIF-1 quiet: the hand construction failed but evolution did not, so "
             "expressibility is established BY EVOLUTION and the encoding is not "
             "implicated. Arm C's failure is a note about the construction only.~n");
ungradeable_verdict(_Fd, false, false) -> ok.

%% Arm M runs ONLY if S does not clear. A negative from a single optimiser class
%% reproduces the confound this gate exists to remove; running M unconditionally
%% would double the spend to harden a claim that does not need hardening.
maybe_arm_m(Fd, _K, _Opts, {s, cleared}) ->
    emit(Fd, "~narm S CLEARED, so arm M is NOT run: CLEARED is an EXISTENCE claim and one "
             "optimiser class suffices.~n");
maybe_arm_m(Fd, K, Opts, {s, _Other}) ->
    emit(Fd, "~narm S did not clear, so arm M RUNS: FAILED is a UNIVERSAL claim and needs a "
             "second optimiser class.~n"),
    _ = arm_report(Fd, m, K, Opts),
    ok;
maybe_arm_m(_Fd, _K, _Opts, false) -> ok.

arm_report(Fd, Arm, K0, Opts) ->
    Layers = arm_layers(Arm),
    Held = heldout_starts(Opts),
    R = random_null(Layers, Held, maps:get(random_null, Opts)),
    Inert = inert_null(Arm, Layers, train_starts(Opts), maps:get(inert_null, Opts)),
    K = K0#{r => R},
    Rs = arm(Arm, Opts),
    V = verdict(Rs, K),
    emit(Fd, "~n-- ARM ~s (~s, ~p, dim ~p, ~p seeds) --~n",
         [string:uppercase(atom_to_list(Arm)), optimiser(Arm), Layers,
          robo_net:weight_count(Layers), length(Rs)]),
    emit(Fd, "R (best of ~p random genomes) = ~.4f ; IF-2 inert reference (best of ~p "
             "random TRAINING fitness) = ~.4f~n",
         [maps:get(random_null, Opts), R, maps:get(inert_null, Opts), Inert]),
    %% DEFECT FIX (D10). won_opp_shots was COMPUTED per seed and then dropped by
    %% this line, so IF-12's raw material was in no record and the flag's quiet
    %% state was an assertion rather than something a reader could recompute. It is
    %% emitted here now. The 20-seed arm-S values were recovered post hoc from the
    %% champion archive; see the addendum at the foot of the feed.
    [emit(Fd, "seed ~p  W=~.4f L=~.4f D=~.4f  margin=~.2f caps=~.3f shots=~.2f pulls=~.2f "
              "won_opp_shots=~.2f trainW=~.4f fit=~.4f evals=~p distinct_last=~p clamp_gen=~.3f "
              "clamp_champ=~.3f id=~s~n",
          [X#res.seed, X#res.w, X#res.l, X#res.d, X#res.margin, X#res.caps,
           X#res.shots, X#res.pulls, X#res.won_opp_shots,
           X#res.train_w, X#res.fit, X#res.evals,
           X#res.distinct_last, X#res.clamp_last, X#res.clamp_frac,
           champion_id(champion(Arm, X#res.seed, Layers, X#res.q, X#res.fit, X#res.evals))])
     || X <- Rs],
    [emit(Fd, "seed ~p checkpoints (unique evals -> held-out W) = ~p~n",
          [X#res.seed, X#res.marks]) || X <- Rs],
    [emit(Fd, "seed ~p rung profile = ~p~n", [X#res.seed, X#res.profile]) || X <- Rs],
    emit(Fd, "median W_s=~.4f  median margin=~.2f  seeds at R_line=~p/~p  seeds directional=~p/~p~n",
         [median([X#res.w || X <- Rs]), median([X#res.margin || X <- Rs]),
          length([1 || X <- Rs, X#res.w >= maps:get(r_line, K)]), length(Rs),
          length([1 || X <- Rs, X#res.w - X#res.l >= maps:get(d_min, K)]), length(Rs)]),
    [emit(Fd, "  ~s ~s : ~p~n", [flag_mark(Fired), Code, Detail])
     || {Code, Fired, Detail} <- flags(Rs, K, Inert)],
    emit(Fd, "VERDICT arm ~p = ~s~n", [Arm, string:uppercase(atom_to_list(V))]),
    emit(Fd, "~s~n", [secondary(median([X#res.margin || X <- Rs]), V)]),
    champion_write(archive_path(Opts, Arm),
                   [champion(Arm, X#res.seed, Layers, X#res.q, X#res.fit, X#res.evals)
                    || X <- Rs]),
    V.

archive_path(Opts, Arm) ->
    maps:get(feed, Opts) ++ "." ++ atom_to_list(Arm) ++ ".champions".

optimiser(m) -> "mu_lambda_es";
optimiser(_Arm) -> "sep_cma_es".

flag_mark(true) -> "FIRED  ";
flag_mark(false) -> "quiet  ";
flag_mark(Other) -> io_lib:format("~p", [Other]).

%% THE SECONDARY ENDPOINT, with its reading pre-committed. robo_sim credits
%% damage_dealt on bullet hits ONLY, so this separates marksmanship from
%% attrition.
secondary(M, V) when V =:= failed orelse V =:= inconclusive ->
    censoring(M >= 25.0, M);
secondary(M, cleared) when M =< 0.0 ->
    io_lib:format("SECONDARY: the primary is CLEARED but median damage margin is ~.2f, "
                  "so the champion is winning by RAM OR WALL ATTRITION and that is named.", [M]);
secondary(M, _V) ->
    io_lib:format("SECONDARY: median held-out damage margin = ~.2f whole units.", [M]).

censoring(true, M) ->
    io_lib:format("SECONDARY: the champion OUT-DAMAGES the floor bot (median margin ~.2f) "
                  "but CANNOT CONVERT inside the 2000-turn cap. That is a different finding "
                  "from not reaching the floor.", [M]);
censoring(false, M) ->
    io_lib:format("SECONDARY: median held-out damage margin = ~.2f whole units; no "
                  "censoring reading is licensed.", [M]).

%%%============================================================================
%%% Small stats and the feed. The feed IS the record: all per-seed values, seeds,
%%% returned evaluation counts, per-checkpoint held-out rates, per-rung profiles
%%% and the full fingerprint go into it.
%%%============================================================================
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

variance([]) -> 0.0;
variance(L) ->
    M = mean([X * 1.0 || X <- L]),
    mean([(X - M) * (X - M) || X <- L]).

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L),
    N = length(S),
    mid(S, N, N rem 2).

mid(S, N, 1) -> lists:nth(N div 2 + 1, S) * 1.0;
mid(S, N, 0) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0.

b(true) -> 1;
b(false) -> 0.

emit(Fd, F) -> emit(Fd, F, []).

emit(Fd, F, A) -> io:format(Fd, F, A), io:format(F, A).
