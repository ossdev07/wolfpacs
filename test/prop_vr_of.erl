-module(prop_vr_of).
-include_lib("proper/include/proper.hrl").

%%%%%%%%%%%%%%%%%%
%%% Properties %%%
%%%%%%%%%%%%%%%%%%
prop_random_clear_test() ->
    ?FORALL(_, term(),
	    begin
		Strategy = {explicit, little},
		Info = [1, 2, 3, 4],
		Encoded = wolfpacs_vr_of:encode(Strategy, Info),
		Corrupt = wolfpacs_utils:random_clear(Encoded, 0.2),
		case wolfpacs_vr_of:decode(Strategy, Corrupt) of
		    {ok, _, _} ->
			true;
		    {error, Corrupt, _} ->
			true;
		    _ ->
			false
		end
	    end).

prop_decode_test() ->
    ?FORALL(Data, binary(),
	    begin
		Strategy = wolfpacs_test_generators:valid_strategy(),
		case wolfpacs_vr_of:decode(Strategy, Data) of
		    {ok, _, _} ->
			true;
		    {error, Data, _} ->
			true;
		    _ ->
			false
		end
	    end).

%%%%%%%%%%%%%%%
%%% Helpers %%%
%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
%%% Generators %%%
%%%%%%%%%%%%%%%%%%
