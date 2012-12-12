
-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,multicastIp,port,currentSlot,receiver,sender,slotWishes}).

init(TeamNo,StationNo,MulticastIp)->
    Port=TeamNo+15000,
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,Port) end),
    Sender=spawn(fun()->sender:init(Coordinator,Port) end),
    loop(#state{teamNo=TeamNo,stationNo=StationNo,multicastIp=MulticastIp,port=Port,currentSlot=(random:uniform(20)-1),receiver=Receiver,sender=Sender,slotWishes=dict:new()}).

loop(State=#state{slotWishes = SlotWishes})->
    receive
		reset_slot_wishes ->
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
			loop(State#state{});
    end.

update_slot_wishes(Packet,SlotWishes)->
    {Station,Slot,_,_} = match_message(Packet),
    NewSlotWishes=dict:append(Slot,Station,SlotWishes).
    
    
match_message(_Packet=<<_Rest:8/binary,StationBin:2/binary,NutzdatenBin:14/binary,SlotBin:1/binary,TimestampBin/binary>>)	->
	Station=list_to_integer(binary_to_list(StationBin)),
    Slot=list_to_integer(binary_to_list(SlotBin)),
	Timestamp=list_to_integer(binary_to_list(TimestampBin)),
	Nutzdaten= binary_to_list(NutzdatenBin),
	{Station,Slot,Nutzdaten,Timestamp}.

			   
