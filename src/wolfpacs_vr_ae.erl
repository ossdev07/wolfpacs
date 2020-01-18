%%%-------------------------------------------------------------------
%% @doc Value Representation Application Entity.
%%
%% @end
%%%-------------------------------------------------------------------

-module(wolfpacs_vr_ae).
-export([encode/1,
	 decode/1]).
-import(wolfpacs_vr_utils, [pad_binary/1,
			    exact_binary/2,
			    trim_binary/1]).

-spec encode(list()) -> binary().
encode(UI) when is_list(UI) ->
    encode(list_to_binary(UI));
encode(UI) ->
    exact_binary(pad_binary(UI), 16).

-spec decode(binary()) -> binary().
decode(Data) ->
    trim_binary(Data).

%%==============================================================================
%% Private
%%==============================================================================

%%==============================================================================
%% Test
%%==============================================================================

-include_lib("eunit/include/eunit.hrl").

encode_test_() ->
    [?_assertEqual(encode(""),     <<0:128>>),
     ?_assertEqual(encode("A"),    <<"A", 0:120>>),
     ?_assertEqual(encode("AB"),   <<"AB", 0:112>>),
     ?_assertEqual(encode("12345678901234567890"),   <<"1234567890123456">>) ].

encode_decode_test_() ->
    Long = [$A || _ <- lists:seq(1, 32)],
    Trimmed = list_to_binary([$A || _ <- lists:seq(1, 16)]),
    [?_assertEqual(decode(encode("")), <<"">>),
     ?_assertEqual(decode(encode("A")), <<"A">>),
     ?_assertEqual(decode(encode("AB")), <<"AB">>),
     ?_assertEqual(decode(encode("ABC")), <<"ABC">>),
     ?_assertEqual(decode(encode("ABCD")), <<"ABCD">>),
     ?_assertEqual(decode(encode(Long)), Trimmed) ].