-module(utilities).
-compile(export_all).

% gets a timestamp in ms from the epoch
get_timestamp() ->
    {Mega,Sec,Micro} = erlang:now(),
    (Mega*1000000+Sec)*1000000+Micro.

get_slot_for_msec(Time)->
    erlang:trunc(((Time rem 1000)/50)).

get_current_frame()->
	{_,CurrentFrame,_}=erlang:now(),
	CurrentFrame.