%%%-------------------------------------------------------------------
%% @doc File Format.
%%
%% @end
%%%-------------------------------------------------------------------

-module(wolfpacs_file_format).
-export([encode/2,
	 decode/2]).
-include("wolfpacs_types.hrl").

%%-------------------------------------------------------------------
%% @doc Encodes a File Format.
%%
%% @end
%%-------------------------------------------------------------------
-spec encode(strategy(), binary()) -> binary().
encode(Strategy, Data) ->
    MetaInformation = wolfpacs_file_meta_information:encode(Strategy, meta_info()),
    <<MetaInformation/binary, Data/binary>>.

%%-------------------------------------------------------------------
%% @doc Decodes a File Format.
%%
%% @end
%%-------------------------------------------------------------------
-spec decode(strategy(), binary()) -> {ok, {map(), map()}, binary()} | {error, binary()}.
decode(Strategy, Data) ->
    case wolfpacs_file_meta_information:decode(Strategy, Data) of
	{error, _} ->
	    lager:warning("[file_format] Failed to decode file meta information"),
	    {error, Data};
	{ok, Meta, Rest} ->
	    case wolfpacs_data_elements:decode(Strategy, Rest) of
		{error, _} ->
		    {error, Data};
		{ok, Content, Rest2} ->
		    {ok, {Meta, Content}, Rest2}
	    end
    end.

%%==============================================================================
%% Private
%%==============================================================================

-spec meta_info() -> map().
meta_info() ->
    #{{2, 1} => [0, 1],
      {2, 2} => <<"1.2.840.10008.5.1.4.1.1.2">>,
      {2, 3} => <<"2.16.840.1.113662.2.1.4519.41582.4105152.419990505.410523251">>,
      {2, 16#10} => <<"1.2.840.10008.1.2.1">>,
      {2, 16#12} => <<"2.16.840.1.113662.2.1.1">>,
      {2, 16#16} => <<"PHOENIXSCP">>
     }.

%%==============================================================================
%% Test
%%==============================================================================

-include_lib("eunit/include/eunit.hrl").

encode_decode_test_() ->
    Strategy = {explicit, little},
    Content = #{{16#7fe0, 16#10, "OB"} => [255, 254, 255, 254]},
    Content2 = #{{16#7fe0, 16#10} => [255, 254, 255, 254]},
    Data = wolfpacs_data_elements:encode({explicit, little}, Content),

    Encoded0 = encode(Strategy, Data),
    Encoded1 = <<Encoded0/binary, 42>>,
    Incorrect0 = wolfpacs_utils:drop_first_byte(Encoded0),
    Incorrect1 = <<1, 2, 3, 4, 5>>,

    [ ?_assertEqual(decode(Strategy, Encoded0), {ok, {meta_info(), Content2}, <<>>}),
      ?_assertEqual(decode(Strategy, Encoded1), {ok, {meta_info(), Content2}, <<42>>}),
      ?_assertEqual(decode(Strategy, Incorrect0), {error, Incorrect0}),
      ?_assertEqual(decode(Strategy, Incorrect1), {error, Incorrect1}) ].
