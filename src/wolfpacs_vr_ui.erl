%%%-------------------------------------------------------------------
%% @doc Value Representation UI.
%%
%% @end
%%%-------------------------------------------------------------------

-module(wolfpacs_vr_ui).
-export([encode/1,
	 decode/1]).
-import(wolfpacs_vr_utils, [pad_binary/1,
			    limit_binary/2,
			    trim_binary/1]).

-type ui() :: list() | binary().

-spec encode(ui()) -> binary().
encode(UI) when is_list(UI) ->
    encode(list_to_binary(UI));
encode(UI) ->
    limit_binary(pad_binary(UI), 64).

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
    [?_assertEqual(encode(""), <<"">>),
     ?_assertEqual(encode("A"), <<"A", 0>>),
     ?_assertEqual(encode("AB"), <<"AB">>),
     ?_assertEqual(encode("ABC"), <<"ABC", 0>>),
     ?_assertEqual(encode("ABCD"), <<"ABCD">>) ].

encode_decode_test_() ->
    Long = [$A || _ <- lists:seq(1, 128)],
    Trimmed = list_to_binary([$A || _ <- lists:seq(1, 64)]),
    [?_assertEqual(decode(encode("")), <<"">>),
     ?_assertEqual(decode(encode("A")), <<"A">>),
     ?_assertEqual(decode(encode("AB")), <<"AB">>),
     ?_assertEqual(decode(encode("ABC")), <<"ABC">>),
     ?_assertEqual(decode(encode("ABCD")), <<"ABCD">>),
     ?_assertEqual(decode(encode(Long)), Trimmed) ].