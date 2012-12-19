-module(utilities).
-compile(export_all).

% gets a timestamp in ms from the epoch
get_timestamp() ->
    {Mega,Sec,Micro} = erlang:now(),
    ((Mega*1000000+Sec)*1000000+Micro) div 1000.

get_slot_for_msec(Time)->
    erlang:trunc(((Time rem 1000)/50)).

get_current_frame()->
	{_,CurrentFrame,_}=erlang:now(),
	CurrentFrame.
	
match_message(_Packet= <<_Rest:8/binary,StationBin:2/binary,NutzdatenBin:14/binary,SlotBin:8/integer,TimestampBin:64/integer>>)	->
	Station=list_to_integer(binary_to_list(StationBin)),
    Slot=SlotBin,
	Timestamp=TimestampBin,
	Nutzdaten= binary_to_list(NutzdatenBin),
	{Station,Slot,Nutzdaten,Timestamp}.