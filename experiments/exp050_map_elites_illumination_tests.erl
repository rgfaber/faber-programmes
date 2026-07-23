%%%-------------------------------------------------------------------
%%% @doc EXP-050 — <one-line title>
%%%
%%% Pre-registration: experiments/exp050_map_elites_illumination.md
%%% Run: scripts/run_experiment.sh exp050_map_elites_illumination_tests
%%%
%%% Archived after signing. This file is a permanent record of what was
%%% actually executed, not a maintained test.
%%% @end
%%%-------------------------------------------------------------------
-module(exp050_map_elites_illumination_tests).

-include_lib("eunit/include/eunit.hrl").

%% eunit swallows io:format for PASSING tests. Write the feed to a file
%% (run_experiment.sh captures stdout too, but the file is the reliable copy).

map_elites_illumination_test_() ->
    {timeout, 3600, fun run/0}.

run() ->
    ?assert(false).
