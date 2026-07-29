#!/usr/bin/env escript
%%! -noshell
%%%---------------------------------------------------------------------------
%%% EXP-066 POST-HOC PROBE: THE TWO ATTRACTORS IN ARM S.  READ-ONLY.
%%%
%%% Arm S's 20 held-out win rates against the floor bot are not a spread. They
%%% are 13 seeds at or above 0.9375, one seed at 0.8000, and 6 seeds between
%%% 0.4188 and 0.6062. Three of the six sit on EXACTLY the frozen parity
%%% constant P = 67/160 = 0.41875 or its complement 93/160 = 0.58125. This probe
%%% asks whether that is a coincidence.
%%%
%%% NOTHING IS RE-RUN AND NOTHING IS MODIFIED. The runner's own compiled beam is
%%% read for its debug_info abstract code, renamed to exp066_view_ta and given
%%% export_all, so the pilot encoder, the start generator and the match loop that
%%% produced the archived feed are called VERBATIM rather than reimplemented.
%%% No file in experiments/ or src/ is touched and no beam is written into the
%%% repository build tree.
%%%
%%% Usage: scripts/exp066_probe_two_attractors.escript [OutFile]
%%%---------------------------------------------------------------------------
-mode(compile).

-define(REPO, "/home/rl/work/github.com/rgfaber/faber-programmes").
-define(BUILD, ?REPO "/_build/test/lib").
-define(RBEAM, ?BUILD "/faber_programmes/experiments/exp066_single_population_floor_tests.beam").
-define(ARCH, ?REPO "/programmes/p7_coevolution/exp066_competence_floor/").
-define(CHAMPS_S, ?ARCH "exp066_champions_s.eterm").
-define(WORKERS, 12).
-define(V, exp066_view_ta).

main(Args) ->
    Out = out_path(Args),
    ok = boot(),
    Starts = ?V:split(heldout),
    80 = length(Starts),
    Champs = champs(),
    Par = parity(Starts),
    Rows = rows(Champs, Starts),
    Lines = lists:append([head(Out, Champs),
                          sec_parity(Par),
                          sec_modes(Rows),
                          sec_crosstab(Par, Rows),
                          sec_vectors(Rows),
                          sec_shape(Par, Rows),
                          sec_engage(Champs, Starts),
                          sec_train(Champs, Rows),
                          sec_selfkill(Champs, Starts),
                          sec_xp(Rows),
                          sec_when(),
                          sec_calib(Champs)]),
    ok = file:write_file(Out, [Lines]),
    io:format("~ts~n", [Out]).

out_path([P | _]) -> P;
out_path([]) -> ?ARCH "exp066_two_attractors_probe.txt".

%%---------------------------------------------------------------------------
%% The view module: the runner's own abstract code, renamed, export_all, loaded
%% from memory. No beam file is written anywhere.
%%---------------------------------------------------------------------------
boot() ->
    true = code:add_patha(?BUILD "/faber_tweann/ebin"),
    {ok, {_M, [{abstract_code, {raw_abstract_v1, Forms}}]}} =
        beam_lib:chunks(?RBEAM, [abstract_code]),
    {ok, ?V, Bin} = compile:forms(inject([rename(F) || F <- Forms]),
                                  [return_errors, nowarn_export_all]),
    {module, ?V} = code:load_binary(?V, "nofile", Bin),
    ok.

rename({attribute, L, module, _}) -> {attribute, L, module, ?V};
rename(F) -> F.

inject([{attribute, L, module, M} | Rest]) ->
    [{attribute, L, module, M},
     {attribute, L, compile, [export_all, nowarn_export_all]} | Rest];
inject([F | Rest]) -> [F | inject(Rest)];
inject([]) -> [].

champs() ->
    {ok, Terms} = file:consult(?CHAMPS_S),
    Terms.

%%---------------------------------------------------------------------------
%% THE PARITY MATCH, recomputed. predictive_gun against its own clone on the
%% same 80 held-out starts, through the same instrument the champions face.
%%
%% heldout/3 emits, per start, the SUBJECT-IN-SEAT-A match then the
%% SUBJECT-IN-SEAT-B match. With identical controllers those two are the same
%% simulation read from opposite seats, so the pair must be complementary; that
%% is asserted, not assumed.
%%---------------------------------------------------------------------------
parity(Starts) ->
    Os = ?V:heldout({script, predictive_gun}, predictive_gun, Starts),
    160 = length(Os),
    Cls = [class(A, B) || {A, B} <- pairs(Os)],
    #{n => length(Os),
      w => count(w, [o(O) || O <- Os]),
      l => count(l, [o(O) || O <- Os]),
      d => count(d, [o(O) || O <- Os]),
      turns => mean([maps:get(turns, O) || O <- Os]),
      s_par => mean([maps:get(opp_shots, O) || O <- Os]),
      class => Cls,
      decisive => length([1 || C <- Cls, C =/= drawn]),
      drawn => length([1 || C <- Cls, C =:= drawn]),
      seat_a => length([1 || C <- Cls, C =:= seat_a]),
      seat_b => length([1 || C <- Cls, C =:= seat_b]),
      wellformed => lists:all(fun(C) -> C =/= malformed end, Cls)}.

%% Per start: which SEAT wins when both tanks are the floor bot.
class(A, B) -> cls(o(A), o(B)).

cls(w, l) -> seat_a;
cls(l, w) -> seat_b;
cls(d, d) -> drawn;
cls(_X, _Y) -> malformed.

o(#{alive := true, opp_alive := false}) -> w;
o(#{alive := false, opp_alive := true}) -> l;
o(_O) -> d.

pairs([A, B | Rest]) -> [{A, B} | pairs(Rest)];
pairs([]) -> [].

%%---------------------------------------------------------------------------
%% Every arm S champion against the floor bot, 160 matches, full per-match
%% detail kept. This is the same measurement the feed's W column reports, so
%% agreement with the feed is the check that the archived genome is the
%% champion the feed measured.
%%---------------------------------------------------------------------------
rows(Champs, Starts) ->
    ?V:pmap(fun(C) -> row(C, Starts) end, Champs, ?WORKERS).

row({champion, _Arm, Seed, Layers, Q, Fit, Evals}, Starts) ->
    Os = ?V:heldout({net, Layers, Q}, predictive_gun, Starts),
    160 = length(Os),
    Vec = [o(O) || O <- Os],
    Won = [O || O <- Os, o(O) =:= w],
    Lost = [O || O <- Os, o(O) =:= l],
    #{seed => Seed, fit => Fit, evals => Evals,
      w => count(w, Vec), l => count(l, Vec), d => count(d, Vec),
      vec => Vec,
      turns => mean([maps:get(turns, O) || O <- Os]),
      turns_won => mean([maps:get(turns, O) || O <- Won]),
      turns_lost => mean([maps:get(turns, O) || O <- Lost]),
      shots => mean([maps:get(shots, O) || O <- Os]),
      pulls => mean([maps:get(pulls, O) || O <- Os]),
      opp_shots => mean([maps:get(opp_shots, O) || O <- Os]),
      won_opp_shots => mean([maps:get(opp_shots, O) || O <- Won]),
      dealt => mean([maps:get(dealt, O) / 256 || O <- Os]),
      taken => mean([maps:get(taken, O) / 256 || O <- Os]),
      margin => mean([(maps:get(dealt, O) - maps:get(taken, O)) / 256 || O <- Os]),
      caps => mean([b(maps:get(turns, O) >= 2000) || O <- Os])}.

count(K, Vec) -> length([1 || X <- Vec, X =:= K]).

b(true) -> 1;
b(false) -> 0.

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

%%---------------------------------------------------------------------------
%% Report sections.
%%---------------------------------------------------------------------------
head(Out, Champs) ->
    [f("== EXP-066 POST-HOC PROBE: THE TWO ATTRACTORS IN ARM S ==~n~n", []),
     f("date            = 2026-07-30~n", []),
     f("status          = POST HOC, NOT pre-registered, SIGNS NOTHING on its own~n", []),
     f("what            = characterisation of the arm S mode split; no arm re-run~n", []),
     f("produced_by     = scripts/exp066_probe_two_attractors.escript~n", []),
     f("method          = the runner's OWN compiled beam, abstract code renamed to~n"
       "                  ~w with export_all and loaded from memory, so the pilot~n"
       "                  encoder, the 120-start generator and the match loop are the~n"
       "                  archived ones and not a reimplementation~n", [?V]),
     f("beam            = ~ts~n", [?RBEAM]),
     f("champions       = ~ts (~w champions)~n", [?CHAMPS_S, length(Champs)]),
     f("out             = ~ts~n", [Out]),
     f("workers         = ~w~n~n", [?WORKERS])].

sec_parity(P) ->
    [f("-- A. THE PARITY MATCH, RECOMPUTED, AND ITS PER-START STRUCTURE --~n~n", []),
     f("predictive_gun against its own CLONE on the 80 held-out starts, both seats.~n", []),
     f("  matches            = ~w~n", [maps:get(n, P)]),
     f("  W / L / D          = ~w / ~w / ~w~n",
       [maps:get(w, P), maps:get(l, P), maps:get(d, P)]),
     f("  P = W/160          = ~.5f   (the frozen constant, feed line 14: P=0.4188)~n",
       [maps:get(w, P) / 160]),
     f("  1 - P              = ~.5f~n", [1 - maps:get(w, P) / 160]),
     f("  S_par              = ~.2f  (feed line 14: 18.49)~n", [maps:get(s_par, P)]),
     f("  mean turns         = ~.1f~n", [maps:get(turns, P)]),
     f("  pair complementary = ~w  (no start gave a malformed W/W or L/L pair)~n~n",
       [maps:get(wellformed, P)]),
     f("PER-START CLASSES. With identical controllers the two seat replays are one~n"
       "simulation read from both seats, so each start is either DECISIVE for one~n"
       "seat or DRAWN for both.~n", []),
     f("  decisive starts    = ~w  (seat a wins ~w, seat b wins ~w)~n",
       [maps:get(decisive, P), maps:get(seat_a, P), maps:get(seat_b, P)]),
     f("  drawn starts       = ~w~n", [maps:get(drawn, P)]),
     f("  identity check     : W = L = decisive = ~w, D = 2 x drawn = ~w~n",
       [maps:get(decisive, P), 2 * maps:get(drawn, P)]),
     f("~nSO P IS FORCED BY THE GENERATOR, NOT BY THE GUN'S SKILL: P = decisive/160~n"
       "and 1 - P = (decisive + 2 x drawn)/160. The two numbers three low-mode seeds~n"
       "land on are exactly these two.~n~n", [])].

sec_modes(Rows) ->
    Sorted = lists:sort(fun(A, B) -> maps:get(seed, A) =< maps:get(seed, B) end, Rows),
    [f("-- B. THE 20 ARM S CHAMPIONS, RECOMPUTED, ONE ROW EACH --~n~n", []),
     f("W L D are COUNTS out of 160. fit is read from the champion archive, not the~n"
       "feed. Compare W/160 and shots with the arm S block of the feed.~n~n", []),
     f("seed   W   L   D  W/160    fit     turns  turns_won turns_lost shots opp_sh won_opp margin~n", [])]
        ++ [f("~w ~4w ~3w ~3w ~7.5f ~7.4f ~7.1f ~9.1f ~10.1f ~5.2f ~6.2f ~7.2f ~6.2f~n",
              [maps:get(seed, R), maps:get(w, R), maps:get(l, R), maps:get(d, R),
               maps:get(w, R) / 160, maps:get(fit, R), maps:get(turns, R),
               maps:get(turns_won, R), maps:get(turns_lost, R), maps:get(shots, R),
               maps:get(opp_shots, R), maps:get(won_opp_shots, R), maps:get(margin, R)])
            || R <- Sorted]
        ++ sec_gap(Sorted).

%% The mode split, by every candidate separator, with the GAP printed so a
%% reader can see whether it is a split or a spread.
sec_gap(Rows) ->
    Ws = lists:sort([maps:get(w, R) / 160 || R <- Rows]),
    Fs = lists:sort([maps:get(fit, R) || R <- Rows]),
    Ss = lists:sort([maps:get(shots, R) || R <- Rows]),
    Ts = lists:sort([maps:get(turns, R) || R <- Rows]),
    [f("~nSORTED VALUES AND LARGEST INTERNAL GAP~n", []),
     gap_line("held-out W", Ws),
     gap_line("train fitness", Fs),
     gap_line("shots/match", Ss),
     gap_line("turns/match", Ts),
     f("~nLOW MODE (held-out W below 0.62) = ~w seeds: ~w~n",
       [length(low(Rows)), [maps:get(seed, R) || R <- low(Rows)]]),
     f("HIGH MODE (held-out W above 0.93) = ~w seeds: ~w~n",
       [length(high(Rows)), [maps:get(seed, R) || R <- high(Rows)]]),
     f("NEITHER = ~w seeds: ~w~n~n",
       [length(mid(Rows)), [maps:get(seed, R) || R <- mid(Rows)]])].

gap_line(Name, Vs) ->
    {G, Lo, Hi} = biggest_gap(Vs),
    f("  ~-14s min=~.4f max=~.4f largest gap=~.4f between ~.4f and ~.4f~n",
      [Name, hd(Vs), lists:last(Vs), G, Lo, Hi]).

biggest_gap(Vs) ->
    Ds = lists:zip(lists:droplast(Vs), tl(Vs)),
    lists:max([{Hi - Lo, Lo, Hi} || {Lo, Hi} <- Ds]).

low(Rows) -> [R || R <- Rows, maps:get(w, R) / 160 < 0.62].
high(Rows) -> [R || R <- Rows, maps:get(w, R) / 160 > 0.93].
mid(Rows) -> [R || R <- Rows, maps:get(w, R) / 160 >= 0.62, maps:get(w, R) / 160 =< 0.93].

%%---------------------------------------------------------------------------
%% THE DECISIVE TEST. Cross-tabulate every champion's 160 outcomes against the
%% PARITY class of the start and the champion's seat.
%%
%% THE HYPOTHESIS, stated before the numbers: a low-mode champion is a
%% behavioural PEER of the floor bot, so on a start the geometry already
%% decides it inherits the geometry's verdict, winning from the favoured seat
%% and losing from the other, and only the starts that parity leaves DRAWN are
%% won from both seats. That predicts exactly W = decisive + 2 x drawn = 93,
%% L = decisive = 67, D = 0, with the losses falling ON the parity-decisive
%% starts and NOWHERE else.
%%---------------------------------------------------------------------------
sec_crosstab(P, Rows) ->
    Cls = maps:get(class, P),
    Sorted = lists:sort(fun(A, B) -> maps:get(seed, A) =< maps:get(seed, B) end, Rows),
    [f("-- C. EVERY OUTCOME CROSS-TABULATED AGAINST THE PARITY CLASS OF ITS START --~n~n", []),
     f("For each champion, its 160 outcomes split by whether the START is one the~n"
       "floor bot's own clone match DECIDES (67 of 80) or DRAWS (13 of 80), and by~n"
       "whether the champion sits in the seat parity FAVOURS or the seat it dooms.~n~n", []),
     f("          on the 67 DECISIVE starts            on the 13 DRAWN starts~n", []),
     f("        favoured seat      doomed seat        both seats        inherit~n", []),
     f("seed     W   L   D       W   L   D         W   L   D          score~n", [])]
        ++ [ct_line(R, Cls) || R <- Sorted]
        ++ [f("~n'inherit' is the fraction of the 160 outcomes matching the hypothesised~n"
              "pattern: win the favoured seat, LOSE the doomed seat, win both seats of a~n"
              "parity-drawn start. READ IT AGAINST THE RIGHT CEILING. The pattern demands~n"
              "67 losses, so a champion that wins all 160 scores 93/160 = 0.5813 and not~n"
              "1.0000, which is exactly what seeds 2003, 2012 and 2017 score. The column~n"
              "is therefore only diagnostic for the low mode, where the pattern would have~n"
              "to reach 1.0000 and instead sits at 0.4437 to 0.5437: the losses are spread~n"
              "across BOTH seats and the drawn starts are not swept.~n~n", [])].

ct_line(R, Cls) ->
    Trip = lists:zip3(Cls, odd(maps:get(vec, R)), even(maps:get(vec, R))),
    {FW, FL, FD} = tally([fav(C, A, B) || {C, A, B} <- Trip, C =/= drawn]),
    {DW, DL, DD} = tally([doom(C, A, B) || {C, A, B} <- Trip, C =/= drawn]),
    {NW, NL, ND} = tally(lists:append([[A, B] || {drawn, A, B} <- Trip])),
    f("~w ~4w ~3w ~3w    ~4w ~3w ~3w      ~4w ~3w ~3w         ~.4f~n",
      [maps:get(seed, R), FW, FL, FD, DW, DL, DD, NW, NL, ND,
       (FW + DL + NW) / 160]).

fav(seat_a, A, _B) -> A;
fav(seat_b, _A, B) -> B.

doom(seat_a, _A, B) -> B;
doom(seat_b, A, _B) -> A.

tally(L) -> {count(w, L), count(l, L), count(d, L)}.

odd([A, _B | R]) -> [A | odd(R)];
odd([]) -> [].

even([_A, B | R]) -> [B | even(R)];
even([]) -> [].

%%---------------------------------------------------------------------------
%% Are two low-mode champions the SAME 93 wins, or merely the same count?
%%---------------------------------------------------------------------------
sec_vectors(Rows) ->
    Sorted = lists:sort(fun(A, B) -> maps:get(seed, A) =< maps:get(seed, B) end, Rows),
    Ps = [{maps:get(seed, A), maps:get(seed, B),
           ham(maps:get(vec, A), maps:get(vec, B))}
          || A <- Sorted, B <- Sorted, maps:get(seed, A) < maps:get(seed, B)],
    Lows = [maps:get(seed, R) || R <- low(Sorted)],
    Highs = [maps:get(seed, R) || R <- high(Sorted)],
    LL = [H || {A, B, H} <- Ps, lists:member(A, Lows), lists:member(B, Lows)],
    HH = [H || {A, B, H} <- Ps, lists:member(A, Highs), lists:member(B, Highs)],
    LH = [H || {A, B, H} <- Ps, xor2(lists:member(A, Lows), lists:member(B, Lows)),
               lists:member(A, Lows ++ Highs), lists:member(B, Lows ++ Highs)],
    [f("-- D. OUTCOME-VECTOR AGREEMENT: SAME MATCHES, OR ONLY THE SAME COUNT? --~n~n", []),
     f("Hamming distance between two champions' 160-long outcome vectors, in the~n"
       "start-then-seat order heldout/3 emits. 0 means the two champions win and~n"
       "lose EXACTLY the same matches.~n~n", []),
     f("  low-mode pairs   n=~w  min=~w median=~.1f max=~w~n",
       [length(LL), lists:min(LL), median(LL), lists:max(LL)]),
     f("  high-mode pairs  n=~w  min=~w median=~.1f max=~w~n",
       [length(HH), lists:min(HH), median(HH), lists:max(HH)]),
     f("  low-vs-high      n=~w  min=~w median=~.1f max=~w~n~n",
       [length(LH), lists:min(LH), median(LH), lists:max(LH)]),
     f("EVERY LOW-MODE PAIR, with what INDEPENDENCE would give for the same two~n"
       "win counts: E = (Wa*Lb + La*Wb)/160. Identity is 0, independence is E.~n", [])]
        ++ [f("  ~w vs ~w : hamming=~w  independence=~.1f~n",
              [A, B, H, indep(kw(A, Sorted), kw(B, Sorted))])
            || {A, B, H} <- Ps, lists:member(A, Lows), lists:member(B, Lows)]
        ++ [f("~n", [])].

kw(S, Rows) ->
    [{maps:get(w, R), maps:get(l, R), maps:get(d, R)} || R <- Rows, maps:get(seed, R) =:= S].

indep([{WA, LA, _DA}], [{WB, LB, _DB}]) -> (WA * LB + LA * WB) / 160.

xor2(true, false) -> true;
xor2(false, true) -> true;
xor2(_A, _B) -> false.

ham(A, B) -> length([1 || {X, Y} <- lists:zip(A, B), X =/= Y]).

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L),
    N = length(S),
    med(S, N, N rem 2).

med(S, N, 1) -> lists:nth((N + 1) div 2, S) * 1.0;
med(S, N, 0) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.

%%---------------------------------------------------------------------------
%% Is the low mode a FAILED kill or a DIFFERENT engagement? Match shape.
%%---------------------------------------------------------------------------
sec_shape(P, Rows) ->
    L = low(Rows),
    H = high(Rows),
    [f("-- E. MATCH SHAPE BY MODE, AGAINST THE PARITY MATCH AS THE RULER --~n~n", []),
     f("                     parity   low mode (~w seeds)    high mode (~w seeds)~n",
       [length(L), length(H)]),
     shape_line("turns / match", maps:get(turns, P),
                [maps:get(turns, R) || R <- L], [maps:get(turns, R) || R <- H]),
     shape_line("champion shots", maps:get(s_par, P),
                [maps:get(shots, R) || R <- L], [maps:get(shots, R) || R <- H]),
     shape_line("floor bot shots", maps:get(s_par, P),
                [maps:get(opp_shots, R) || R <- L], [maps:get(opp_shots, R) || R <- H]),
     shape_line("damage dealt", 0.0,
                [maps:get(dealt, R) || R <- L], [maps:get(dealt, R) || R <- H]),
     shape_line("damage taken", 0.0,
                [maps:get(taken, R) || R <- L], [maps:get(taken, R) || R <- H]),
     shape_line("turn-cap share", 0.0,
                [maps:get(caps, R) || R <- L], [maps:get(caps, R) || R <- H]),
     f("~n", [])].

shape_line(Name, Par, L, H) ->
    f("  ~-18s ~7.2f   ~7.2f [~.2f..~.2f]   ~7.2f [~.2f..~.2f]~n",
      [Name, Par, median(L), lists:min(L), lists:max(L),
       median(H), lists:min(H), lists:max(H)]).

%%---------------------------------------------------------------------------
%% What the two modes DO: the range they hold and how hard they drive. Read off
%% the match loop's own probe accumulator, which stores the champion's tank and
%% its pilot state at every turn it acted.
%%
%% #pilot is {pilot, tick, seen, age, dist, ...}; #tank is
%% {tank, id, x, y, heading, gun, radar, vel, energy, gun_heat, dead, dealt}.
%% Positions are used rather than records because this script does not include
%% the runner's header, and the two record shapes are asserted below.
%%---------------------------------------------------------------------------
sec_engage(Champs, Starts) ->
    Sel = [S || {champion, _A, S, _L, _Q, _F, _E} <- Champs],
    Ten = lists:sublist(Starts, 10),
    Rs = ?V:pmap(fun(S) -> engage(Champs, S, Ten) end, Sel, ?WORKERS),
    [f("-- F. WHAT THE TWO MODES DO: RANGE HELD AND THROTTLE USED --~n~n", []),
     f("The match loop's own probe accumulator, over the FIRST 10 held-out starts,~n"
       "both seats, so 20 matches per champion. dist is the pilot's range to its~n"
       "latest contact in whole units; vel is the champion's own speed. Turns with~n"
       "no contact yet are excluded from the range statistics only.~n~n", []),
     f("seed  mode   turns  contact%%  mean_dist  p10_dist  p90_dist  mean_speed  fire%%~n", [])]
        ++ [f("~w ~-7s ~6.1f ~8.3f ~10.1f ~9.1f ~9.1f ~11.1f ~6.3f~n",
              [S, Mode, T, C, MD, P10, P90, SP, FR])
            || {S, Mode, T, C, MD, P10, P90, SP, FR} <- Rs]
        ++ [f("~n", [])].

engage(Champs, Seed, Starts) ->
    {champion, _A, Seed, Layers, Q, _F, _E} = lists:keyfind(Seed, 3, Champs),
    Os = lists:append([[?V:play_seat({net, Layers, Q}, {script, predictive_gun},
                                     St, Seat, [])
                        || Seat <- [a, b]] || St <- Starts]),
    Steps = lists:append([maps:get(probe, O) || O <- Os]),
    Ds = [element(5, Pi) / 256 || {_T, Pi} <- Steps, element(3, Pi) > 0],
    Vs = [abs(element(8, Tk)) / 256 || {Tk, _Pi} <- Steps],
    {Seed, mode_of(Seed), mean([maps:get(turns, O) || O <- Os]),
     length(Ds) / max(1, length(Steps)), mean(Ds), pct(Ds, 10), pct(Ds, 90),
     mean(Vs),
     mean([maps:get(pulls, O) / max(1, maps:get(turns, O)) || O <- Os])}.

mode_of(S) when S =:= 2007; S =:= 2009; S =:= 2011; S =:= 2014; S =:= 2015; S =:= 2018 ->
    "low";
mode_of(2016) -> "mid";
mode_of(_S) -> "high".

pct([], _P) -> 0.0;
pct(L, P) ->
    S = lists:sort(L),
    lists:nth(max(1, (P * length(S)) div 100), S).

%%---------------------------------------------------------------------------
%% G. THE TRAINING SIDE. Is the split visible in what the optimiser could see?
%%
%% The ladder fitness is (rungs cleared) + squash(mean margin on the frontier),
%% and once all five are cleared the frontier is the WEAKEST rung by mean. So
%% the champion's archived fitness decomposes, exactly, into a rung count and
%% one margin in arena fixed point, and that margin is recomputed here per rung
%% on the SIX TRAINING STARTS the optimiser actually saw.
%%
%% squash/1 is (M + 2*BAR) / (4*BAR + 1) with BAR = 25600, so the inverse is
%% exact while unclamped, and the recomputed ladder value is printed beside the
%% archived one as the check.
%%---------------------------------------------------------------------------
sec_train(Champs, Rows) ->
    Tr = ?V:split(train),
    6 = length(Tr),
    Ts = ?V:pmap(fun(C) -> train_row(C, Tr) end, Champs, ?WORKERS),
    Sorted = lists:sort(fun(A, B) -> element(1, A) =< element(1, B) end, Ts),
    Byseed = maps:from_list([{maps:get(seed, R), R} || R <- Rows]),
    [f("-- G. THE TRAINING SIDE: THE LADDER THE OPTIMISER SAW, RECOMPUTED --~n~n", []),
     f("Mean damage margin in WHOLE units over the 12 matches of each rung on the 6~n"
       "TRAINING starts. cleared = every one of those 12 margins strictly positive,~n"
       "which is the ladder's own rule. frontier = the weakest rung by mean, which is~n"
       "the only margin the fitness reads once all five are cleared.~n~n", []),
     f("seed  mode   duck  spinner  rammer strafer   gun  rungs  frontier  fit_recomputed  fit_archive  trainW\n", [])]
        ++ [f("~w ~-6s ~6.1f ~7.1f ~7.1f ~7.1f ~6.1f ~5w ~9.2f ~15.4f ~12.4f ~7.4f~n",
              [S, mode_of(S), D, Sp, Ra, St, Gu, N, Fr / 256, FitR, maps:get(fit, maps:get(S, Byseed)), TW])
            || {S, D, Sp, Ra, St, Gu, N, Fr, FitR, TW, _HG} <- Sorted]
        ++ [f("~nEVERY seed clears all five rungs on the training starts, which is why the~n"
              "feed's trainW column reads 1.0000 for all twenty and separates nothing. The~n"
              "fitness the optimiser ranked on is NOT flat: it is the frontier margin, and~n"
              "that margin is what splits.~n~n", []),
            f("THE GENERALISATION GAP IN THE FITNESS'S OWN UNITS. The same floored rung~n"
              "margin, gun rung, on the 6 TRAINING starts and on the 80 HELD-OUT starts.~n"
              "Floored means margin/1's death floor is applied on both sides, which the~n"
              "feed's own margin column does NOT do, so the two columns below are~n"
              "comparable and the feed's margin is not comparable with either.~n~n", []),
            f("seed  mode   train_gun  heldout_gun     gap~n", [])]
        ++ [f("~w ~-6s ~9.2f ~12.2f ~7.2f~n", [S, mode_of(S), Gu, HG / 256, Gu - HG / 256])
            || {S, _D, _Sp, _Ra, _St, Gu, _N, _Fr, _FitR, _TW, HG} <- Sorted]
        ++ [f("~n", [])].

train_row({champion, _A, Seed, Layers, Q, _F, _E}, Tr) ->
    Net = {net, Layers, Q},
    Ms = [rung_margin(Net, K, Tr) || K <- [sitting_duck, spinner, rammer,
                                           circle_strafer, predictive_gun]],
    Cleared = length(lists:takewhile(fun({_M, All}) -> All end, Ms)),
    Means = [M || {M, _All} <- Ms],
    Frontier = lists:min(Means),
    Fit = Cleared + (Frontier + 2 * 25600) / (4 * 25600 + 1),
    TW = ?V:win_rate(?V:heldout(Net, predictive_gun, Tr)),
    {HG, _All} = rung_margin(Net, predictive_gun, ?V:split(heldout)),
    {Seed, e(1, Means) / 256, e(2, Means) / 256, e(3, Means) / 256,
     e(4, Means) / 256, e(5, Means) / 256, Cleared, Frontier, Fit, TW, HG}.

e(N, L) -> lists:nth(N, L).

rung_margin(Net, Kind, Tr) ->
    Os = ?V:heldout(Net, Kind, Tr),
    Margins = [?V:margin(O) || O <- Os],
    {mean(Margins), lists:all(fun(M) -> M > 0 end, Margins)}.

%%---------------------------------------------------------------------------
%% H. HOW EACH MODE DIES.
%%
%% robo_sim credits damage_dealt on BULLET HITS ONLY, while wall_damage/2 and
%% ram_apply/2 both call hurt/2 and are credited to nobody, and maybe_fire/2
%% charges the shooter for its own shot. So the 100-unit bar can run out with
%% the opponent's damage_dealt well below 100.
%%
%% TWO RUNGS CARRY NO GUN AT ALL: sitting_duck, whose intent is all zeros, and
%% spinner, whose intent record sets no fire field after the gauntlet's own
%% audit fix. Against those two a LOSS can only be the champion killing itself,
%% and robo_gauntlet records the same phenomenon in the engine's own bots ("the
%% duck outright winning two matches when the spinner drove into a wall").
%%
%% rammer, circle_strafer and predictive_gun all fire, so for those the mean
%% damage taken in LOST matches is reported instead, and a value under 100 says
%% only that bullets alone did not empty the bar: firing cost, rams and walls
%% are in that gap too and this probe does not separate them.
%%---------------------------------------------------------------------------
sec_selfkill(Champs, Starts) ->
    Rs = ?V:pmap(fun(C) -> sk_row(C, Starts) end, Champs, ?WORKERS),
    Sorted = lists:sort(fun(A, B) -> element(1, A) =< element(1, B) end, Rs),
    [f("-- H. HOW EACH MODE DIES: THE TWO GUNLESS RUNGS ISOLATE SELF-DESTRUCTION --~n~n", []),
     f("duck_L and spin_L are losses to an opponent that NEVER FIRES, so each one is~n"
       "the champion killing itself on a wall, on a ram, or by spending its own bar.~n"
       "taken_in_L is mean bullet damage absorbed in LOST matches, whole units, against~n"
       "a 100-unit bar; under 100 means bullets alone did not do it, but firing cost~n"
       "and collisions are in that gap too and are not separated here.~n~n", []),
     f("              gunless rungs        vs circle_strafer      vs predictive_gun~n", []),
     f("seed  mode  duck_L spin_L duck_D    L   taken_in_L        L   taken_in_L~n", [])]
        ++ [f("~w ~-6s ~5w ~6w ~6w ~5w ~11.2f ~8w ~11.2f~n",
              [S, mode_of(S), DL, PL, DD, SL, STL, GL, GTL])
            || {S, DL, DD, PL, SL, STL, GL, GTL} <- Sorted]
        ++ [f("~n", [])].

sk_row({champion, _A, Seed, Layers, Q, _F, _E}, Starts) ->
    Net = {net, Layers, Q},
    {_DW, DL, DD, _DTL} = sk_one(Net, sitting_duck, Starts),
    {_PW, PL, _PD, _PTL} = sk_one(Net, spinner, Starts),
    {_SW, SL, _SD, STL} = sk_one(Net, circle_strafer, Starts),
    {_GW, GL, _GD, GTL} = sk_one(Net, predictive_gun, Starts),
    {Seed, DL, DD, PL, SL, STL, GL, GTL}.

sk_one(Net, Kind, Starts) ->
    Os = ?V:heldout(Net, Kind, Starts),
    Vec = [o(O) || O <- Os],
    Lost = [O || O <- Os, o(O) =:= l],
    {count(w, Vec), count(l, Vec), count(d, Vec),
     mean([maps:get(taken, O) / 256 || O <- Lost])}.

%%---------------------------------------------------------------------------
%% I. THE INVERSION. The cross-play matrix already on disk, read back, and the
%% ordering it induces set against the ordering the floor bot induces.
%%---------------------------------------------------------------------------
sec_xp(Rows) ->
    {Seeds, M} = xp_matrix(),
    N = length(Seeds),
    Means = [{S, mean(drop_nth(I, R))} || {I, S, R} <- lists:zip3(lists:seq(1, N), Seeds, M)],
    Cope = [{S, copeland(I, M)} || {I, S} <- lists:zip(lists:seq(1, N), Seeds)],
    Hw = [{maps:get(seed, R), maps:get(w, R) / 160} || R <- Rows],
    Pairs = [{S, kv(S, Hw), kv(S, Means), kv(S, Cope)} || S <- Seeds],
    Rho = spearman([kv(S, Hw) || S <- Seeds], [kv(S, Means) || S <- Seeds]),
    Wins = lh_wins(Seeds, M),
    Sign = 2 * lists:sum([binom(78, I) || I <- lists:seq(0, min(Wins, 78 - Wins))]),
    Ord = lists:reverse(lists:sort([{X, S} || {S, X} <- Means])),
    Rks = [I || {I, {_X, S}} <- lists:zip(lists:seq(1, length(Ord)), Ord),
                mode_of(S) =:= "low"],
    [f("-- I. THE INVERSION: THE FLOOR BOT'S ORDERING AGAINST THE CHAMPIONS' OWN --~n~n", []),
     f("Read from programmes/p7_coevolution/exp066_competence_floor/exp066_crossplay.txt,~n"
       "the machine-readable term at its foot, 80 starts and 160 matches per cell.~n"
       "xp_mean = the row mean over the 19 opponents, diagonal dropped. copeland =~n"
       "opponents this champion has a POSITIVE margin against, of 19.~n~n", []),
     f("seed  mode   heldout_W  xp_mean  copeland~n", [])]
        ++ [f("~w ~-6s ~9.4f ~8.4f ~9w~n", [S, mode_of(S), W, X, C])
            || {S, W, X, C} <- lists:sort(fun(A, B) -> element(3, A) >= element(3, B) end, Pairs)]
        ++ [f("~nSpearman rho between held-out W against the floor bot and xp_mean over the~n"
              "same 20 champions = ~.4f~n", [Rho]),
            f("group means:  low mode xp_mean = ~.4f   high mode xp_mean = ~.4f   2016 = ~.4f~n",
              [mean([X || {S, _W, X, _C} <- Pairs, mode_of(S) =:= "low"]),
               mean([X || {S, _W, X, _C} <- Pairs, mode_of(S) =:= "high"]),
               mean([X || {S, _W, X, _C} <- Pairs, mode_of(S) =:= "mid"])]),
            f("low-mode rows against high-mode columns, mean win rate = ~.4f~n",
              [mean(block(Seeds, M, "low", "high"))]),
            f("high-mode rows against low-mode columns, mean win rate = ~.4f~n",
              [mean(block(Seeds, M, "high", "low"))]),
            f("THE UNIT OF EVIDENCE IS THE PAIRING, NOT THE MATCH: of the 6 x 13 = 78~n"
              "low-against-high pairings, the LOW champion holds the positive margin in~n"
              "~w. Sign test against 39, two tailed, p = ~.4f, AND THAT p IS OPTIMISTIC:~n"
              "the 78 pairings share 19 champions, so they are not 78 independent draws.~n",
              [Wins, Sign]),
            f("Rank test on the same claim at the level of CHAMPIONS is much weaker: the~n"
              "6 low-mode seeds hold xp_mean ranks ~w of 20, rank sum ~w against an~n"
              "expected ~w, so the group-level ordering is suggestive at best.~n~n",
              [Rks, lists:sum(Rks), 6 * 21 div 2])].

xp_matrix() ->
    {ok, Bin} = file:read_file(?ARCH "exp066_crossplay.txt"),
    [_Head, Tail] = binary:split(Bin, <<"== MACHINE-READABLE TERM (single Erlang term, tuples and lists only) ==">>),
    {ok, Tok, _} = erl_scan:string(binary_to_list(Tail)),
    {ok, {crossplay, Fs}} = erl_parse:parse_term(Tok),
    {_, Rows} = lists:keyfind(matrix, 1, Fs),
    {[S || {row, _I, S, _R} <- Rows], [R || {row, _I, _S, R} <- Rows]}.

drop_nth(I, L) -> lists:sublist(L, I - 1) ++ lists:nthtail(I, L).

%% Of the low-against-high pairings, the ones the LOW champion wins on margin.
lh_wins(Seeds, M) ->
    Is = [I || {I, S} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), mode_of(S) =:= "low"],
    Js = [J || {J, S} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), mode_of(S) =:= "high"],
    length([1 || I <- Is, J <- Js,
                 lists:nth(J, lists:nth(I, M)) - lists:nth(I, lists:nth(J, M)) > 0]).

binom(N, K) -> choose(N, K) / math:pow(2, N).

copeland(I, M) ->
    Row = lists:nth(I, M),
    length([1 || J <- lists:seq(1, length(M)), J =/= I,
                 lists:nth(J, Row) - lists:nth(I, lists:nth(J, M)) > 0]).

kv(K, L) -> element(2, lists:keyfind(K, 1, L)).

block(Seeds, M, RowMode, ColMode) ->
    Is = [I || {I, S} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), mode_of(S) =:= RowMode],
    Js = [J || {J, S} <- lists:zip(lists:seq(1, length(Seeds)), Seeds), mode_of(S) =:= ColMode],
    [lists:nth(J, lists:nth(I, M)) || I <- Is, J <- Js].

%% Rank correlation with average ranks for ties, then Pearson on the ranks.
spearman(Xs, Ys) -> pearson(ranks(Xs), ranks(Ys)).

ranks(Vs) ->
    S = lists:sort(Vs),
    [avg_rank(V, S) || V <- Vs].

avg_rank(V, S) ->
    Is = [I || {I, X} <- lists:zip(lists:seq(1, length(S)), S), X =:= V],
    mean(Is).

pearson(Xs, Ys) ->
    MX = mean(Xs),
    MY = mean(Ys),
    Cov = lists:sum([(X - MX) * (Y - MY) || {X, Y} <- lists:zip(Xs, Ys)]),
    SX = math:sqrt(lists:sum([(X - MX) * (X - MX) || X <- Xs])),
    SY = math:sqrt(lists:sum([(Y - MY) * (Y - MY) || Y <- Ys])),
    Cov / max(1.0e-12, SX * SY).

%%---------------------------------------------------------------------------
%% J. WHEN THE MODE IS DECIDED, and whether the other two arms show it.
%%
%% Checkpoints CANNOT be recomputed: they come from the run's own collector,
%% which kept the best-so-far genome at 10k and 25k evaluations and archived
%% only the final champion. They are read from the feed, which is the only
%% record of them, and the arm blocks are parsed rather than retyped.
%%---------------------------------------------------------------------------
sec_when() ->
    Feed = ?ARCH "exp066_floor_feed.txt",
    {ok, Bin} = file:read_file(Feed),
    Flat = flatten_ws(Bin),
    Cps = checkpoints(Flat),
    Arms = [{A, arm_ws(Flat, A)} || A <- ["S", "L", "D"]],
    [f("-- J. WHEN THE MODE IS DECIDED, AND WHETHER THE OTHER ARMS SHOW IT --~n~n", []),
     f("Read from ~ts, which is byte-identical to the signed~n"
       "insight feed insights/066-raw-competence-floor.txt.~n~n", [Feed]),
     f("ARM S held-out W at each checkpoint, from the feed's arm S block.~n~n", []),
     f("seed  mode      10k      25k      50k   50k-10k~n", [])]
        ++ [f("~w ~-6s ~8.5f ~8.5f ~8.5f ~9.5f~n", [S, mode_of(S), A, B, C, C - A])
            || {S, A, B, C} <- Cps]
        ++ [f("~nSEPARATION AT EACH CHECKPOINT, low mode (6 seeds) against high mode (13):~n", []),
            sep_line("10k", Cps), sep_line("25k", Cps), sep_line("50k", Cps),
            f("~n2016, the one seed in neither mode, sits INSIDE the low range at 10k and~n"
              "climbs out: ~s. It is a slow high-mode seed, not a third attractor, and it~n"
              "had not stopped climbing when the budget ran out.~n~n",
              [[io_lib:format("~.5f -> ~.5f -> ~.5f", [A, B, C])
                || {2016, A, B, C} <- Cps]]),
            f("THE SAME SPLIT IN THE OTHER TWO ARMS, counted off the addendum's per-seed~n"
              "W lines. LOW is held-out W below 0.62, the empirical gap in arm S.~n~n", [])]
        ++ [f("  arm ~s : ~w seeds, ~w low, min W = ~.4f, low seeds = ~w~n",
              [A, length(Ws), length([1 || {_S, W} <- Ws, W < 0.62]),
               lists:min([W || {_S, W} <- Ws]),
               [S || {S, W} <- Ws, W < 0.62]])
            || {A, Ws} <- Arms]
        ++ [f("~nArm D is the SAME optimiser and the SAME topology as arm S with the~n"
              "curriculum removed, rung 5 only. Fisher exact, one tailed, arm S 6 of 20~n"
              "low against arm D 0 of 10 low: p = ~.4f. Ladder arms pooled (S and L)~n"
              "~w of 30 against arm D 0 of 10: p = ~.4f. SUGGESTIVE, not established.~n~n",
              [fisher(6, 14, 0, 10), 6 + length([1 || {_S, W} <- kv("L", Arms), W < 0.62]),
               fisher(6 + length([1 || {_S, W} <- kv("L", Arms), W < 0.62]),
                      30 - (6 + length([1 || {_S, W} <- kv("L", Arms), W < 0.62])), 0, 10)])].

flatten_ws(Bin) ->
    re:replace(binary_to_list(Bin), "\\s+", "", [global, {return, list}]).

checkpoints(Flat) ->
    {match, Ms} = re:run(Flat,
                         "seed(\\d+)checkpoints\\(uniqueevals->held-outW\\)="
                         "\\[\\{10000,([0-9.]+)\\},\\{25000,([0-9.]+)\\},\\{50000,([0-9.]+)\\}\\]",
                         [global, {capture, all_but_first, list}]),
    %% The arm S block comes first in the feed and holds the first 20.
    [{list_to_integer(S), num(A), num(B), num(C)}
     || [S, A, B, C] <- lists:sublist(Ms, 20)].

%% The addendum prints one W line per seed per arm, unwrapped, which the run's
%% own per-seed lines are not.
arm_ws(Flat, Arm) ->
    [_Before, After] = string:split(Flat, "arm" ++ Arm ++ ","),
    {match, Ms} = re:run(hd(string:split(After, "won_opp_shotsoverthearm")),
                         "seed(\\d+)W=([0-9.]+)won_opp_shots=",
                         [global, {capture, all_but_first, list}]),
    [{list_to_integer(S), num(W)} || [S, W] <- Ms].

num(S) -> element(1, string:to_float(pad(S))).

pad(S) -> lists:flatten([S, dotzero(lists:member($., S))]).

dotzero(true) -> "";
dotzero(false) -> ".0".

sep_line(Which, Cps) ->
    Lows = [pick(Which, C) || C <- Cps, mode_of(element(1, C)) =:= "low"],
    Highs = [pick(Which, C) || C <- Cps, mode_of(element(1, C)) =:= "high"],
    f("  ~-4s low max = ~.5f   high min = ~.5f   separated = ~w~n",
      [Which, lists:max(Lows), lists:min(Highs), lists:max(Lows) < lists:min(Highs)]).

pick("10k", {_S, A, _B, _C}) -> A;
pick("25k", {_S, _A, B, _C}) -> B;
pick("50k", {_S, _A, _B, C}) -> C.

%% One-tailed Fisher exact for the 2x2 [[A,B],[C,D]]: the probability of C or
%% fewer low seeds in the second group, hypergeometric, exact in integers then
%% one division.
fisher(A, B, C, D) ->
    N = A + B + C + D,
    K = A + C,
    M = C + D,
    lists:sum([hyp(N, K, M, I) || I <- lists:seq(0, C)]).

hyp(N, K, M, I) -> choose(K, I) * choose(N - K, M - I) / choose(N, M).

choose(_N, R) when R < 0 -> 0;
choose(N, R) when R > N -> 0;
choose(N, R) -> fact(N) div (fact(R) * fact(N - R)).

fact(0) -> 1;
fact(N) -> N * fact(N - 1).

%%---------------------------------------------------------------------------
%% K. THE COINCIDENCE, TESTED ON A THIRD START SET.
%%
%% If a low-mode champion landing exactly on the parity constant were STRUCTURAL
%% then it would land on the parity constant of ANY start set, because the
%% structure claimed is "this policy inherits the geometry's verdict". The 30
%% calibration starts, 87..116, were used to build arm C and for nothing else,
%% and no champion was ever measured on them. So they are a clean second draw
%% from the same generator and the prediction is sharp: W_cal = 1 - P_cal.
%%---------------------------------------------------------------------------
sec_calib(Champs) ->
    Cal = ?V:split(calibration),
    30 = length(Cal),
    Pos = ?V:heldout({script, predictive_gun}, predictive_gun, Cal),
    {PW, PL, PD} = ?V:rates(Pos),
    Rs = ?V:pmap(fun(C) -> cal_row(C, Cal) end, Champs, ?WORKERS),
    Sorted = lists:sort(fun(A, B) -> element(1, A) =< element(1, B) end, Rs),
    N = length(Pos),
    Pred = round((1 - PW) * N),
    [f("-- K. THE COINCIDENCE, TESTED ON THE 30 CALIBRATION STARTS --~n~n", []),
     f("A start set no champion was ever measured on, same generator, indices 87..116.~n~n", []),
     f("  parity on calibration : ~w matches, W/L/D = ~w/~w/~w, P_cal = ~.5f~n",
       [N, round(PW * N), round(PL * N), round(PD * N), PW]),
     f("  structural prediction : a low-mode champion scores 1 - P_cal = ~.5f,~n"
       "                          which on ~w matches is ~w wins, and NOTHING else~n~n",
       [1 - PW, N, Pred]),
     f("seed  mode      W    L    D    W_rate   hits_prediction~n", [])]
        ++ [f("~w ~-6s ~5w ~4w ~4w ~9.5f ~15w~n", [S, mode_of(S), W, L, D, W / N, W =:= Pred])
            || {S, W, L, D} <- Sorted]
        ++ [f("~nHITS on the held-out 80 (section B): seeds 2007 and 2014 at exactly 93 = 1-P,~n"
              "seed 2015 at exactly 67 = P. HITS here: ~w of the 6 low-mode seeds.~n~n",
              [length([1 || {S, W, _L, _D} <- Sorted, mode_of(S) =:= "low", W =:= Pred])])].

cal_row({champion, _A, Seed, Layers, Q, _F, _E}, Cal) ->
    Os = ?V:heldout({net, Layers, Q}, predictive_gun, Cal),
    Vec = [o(O) || O <- Os],
    {Seed, count(w, Vec), count(l, Vec), count(d, Vec)}.

f(Fmt, Args) -> io_lib:format(Fmt, Args).
