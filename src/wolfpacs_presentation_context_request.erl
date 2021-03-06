%%%-------------------------------------------------------------------
%% @doc WolfPACS's DICOM Presentation Context.
%%
%% A presentation Context, during Association-RQ, is composed of one Abstract Syntax and
%% a list of negotiable Transfer Syntax.
%%
%% Abstract Syntax - "What"
%% Transfer Syntax - "How"
%%
%% @end
%%%-------------------------------------------------------------------

-module(wolfpacs_presentation_context_request).
-export([encode/3,
	 decode/1]).
-include("abstract_syntax.hrl").
-include("transfer_syntax.hrl").

%%-------------------------------------------------------------------
%% @doc Encodes a presentation contex during Associate-RQ.
%%
%% @end
%%-------------------------------------------------------------------
-spec encode(byte(), binary(), list(binary())) -> binary().
encode(PrCID, AbstractSyntax, TransferSyntax) ->
    What = wolfpacs_abstract_syntax:encode(AbstractSyntax),
    How = wolfpacs_transfer_syntax:encode_list(TransferSyntax),
    WhatHow = <<What/binary,
		How/binary>>,
    Payload = <<PrCID,
		0,
		0,
		0,
		WhatHow/binary>>,
    Length = byte_size(Payload),
    <<16#20,
      0,
      Length:16,
      Payload/binary>>.

%%-------------------------------------------------------------------
%% @doc Decodes a presentation contex during Associate-RQ.
%%
%% @end
%%-------------------------------------------------------------------
-spec decode(binary()) -> {ok, byte(), binary(), list(binary()), binary()} | {error, binary()}.
decode(AllData = <<16#20, _, Length:16, Payload/binary>>) ->
    NbBytes = byte_size(Payload),
    <<PrCID,
      _,
      _,
      _,
      WhatHow/binary>> = Payload,
    case Length =< NbBytes of
	true ->
	    case try_decode(PrCID, WhatHow) of
		{error, Error} ->
		    {error, AllData, Error};
		Success ->
		    Success
	    end;
	false ->
	    {error, AllData, ["not enough data in payload"]}
    end;
decode(Payload) ->
    {error, Payload, ["incorrect header"]}.

%%==============================================================================
%% Private
%%==============================================================================

-spec try_decode(byte(), binary()) -> {ok, byte(), binary(), list(binary()), binary()} | {error, atom()}.
try_decode(PrCID, Data) ->
    MaybeAbstractSynatx = wolfpacs_abstract_syntax:decode(Data),
    decode_with_abstract_syntax(PrCID, MaybeAbstractSynatx).

decode_with_abstract_syntax(PrCID, {ok, AbstractSyntax, Data}) ->
    MaybeTransferSyntax = wolfpacs_transfer_syntax:decode_list(Data),
    decode_with_transfer_syntax(PrCID, AbstractSyntax, MaybeTransferSyntax);
decode_with_abstract_syntax(_, _) ->
    {error, ["unable to decode abstract syntax"]}.

decode_with_transfer_syntax(PrCID, AbstractSyntax, {ok, TransferSyntax, Rest}) ->
    {ok, PrCID, AbstractSyntax, TransferSyntax, Rest};
decode_with_transfer_syntax(_, _, _) ->
    {error, ["unable to decode transfer syntax"]}.

%%==============================================================================
%% Test
%%==============================================================================

-include_lib("eunit/include/eunit.hrl").

encode_decode_test_() ->
    PrCID = 42,
    AbstractSyntax = ?VERIFICATION,
    TransferSyntax = [?IMPLICIT_LITTLE_ENDIAN,
		      ?EXPLICIT_LITTLE_ENDIAN,
		      ?EXPLICIT_BIG_ENDIAN],
    Encoded0 = encode(PrCID, AbstractSyntax, TransferSyntax),
    Encoded1 = <<Encoded0/binary, 42>>,
    Incorrect0 = wolfpacs_utils:drop_last_byte(Encoded0),
    Incorrect1 = <<1,2,3,4>>,
    [ ?_assertEqual(decode(Encoded0), {ok, PrCID, AbstractSyntax, TransferSyntax, <<>>}),
      ?_assertEqual(decode(Encoded1), {ok, PrCID, AbstractSyntax, TransferSyntax, <<42>>}),
      ?_assertEqual(decode(Incorrect0), {error, Incorrect0, ["not enough data in payload"]}),
      ?_assertEqual(decode(Incorrect1), {error, Incorrect1, ["incorrect header"]}) ].
