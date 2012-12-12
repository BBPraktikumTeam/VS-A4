
-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,socket,currentSlot,receiver,sender,slotWishes}).

init(TeamNo,StationNo,MulticastIp)->
    Port=TeamNo+15000,
	{ok,Socket}=gen_udp:open(Port),
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,Socket) end),
    Sender=spawn(fun()->sender:init(Coordinator,Socket,MulticastIp) end),
    loop(#state{teamNo=TeamNo,stationNo=StationNo,socket=Socket,currentSlot=(random:uniform(20)-1),receiver=Receiver,sender=Sender,slotWishes=dict:new()}).

loop(State=#state{slotWishes = SlotWishes, stationNo = StationNo, sender = Sender,receiver=Receiver})->
    receive
		reset_slot_wishes ->
			Slot = calculate_slot_from_slotwishes(StationNo, SlotWishes),
			Sender ! {slot, Slot},
			loop(State#state{slotWishes=dict:new()});
		{received,Slot,Time,Packet} ->
			SlotWishesNew=update_slot_wishes(Packet,SlotWishes),
			loop(State#state{slotWishes=SlotWishesNew});
		kill -> 
			io:format("Received kill command"),
			Receiver ! kill,
			Sender ! kill,
			exit(normal);
		Any -> io:format("Received garbage: ~p~n",[Any]),
			loop(State#state{})
    end.

update_slot_wishes(Packet,SlotWishes)->
    {Station,Slot,_,_} = match_message(Packet),
    NewSlotWishes=dict:append(Slot,Station,SlotWishes).
    
    
match_message(_Packet= <<_Rest:8/binary,StationBin:2/binary,NutzdatenBin:14/binary,SlotBin:8/integer,TimestampBin/integer>>)	->
	%% TODO MATCHING
	Station=list_to_integer(binary_to_list(StationBin)),
    Slot=SlotBin,
	Timestamp=TimestampBin,
	Nutzdaten= binary_to_list(NutzdatenBin),
	{Station,Slot,Nutzdaten,Timestamp}.

			   
calculate_slot_from_slotwishes(StationNo, SlotWishes) ->
	%%TODO CRAZY SCHEISS
	1.
	
	


