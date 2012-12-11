
-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,multicastIp,port,currentSlot,receiver,sender,slotWishes}).

init(TeamNo,StationNo,MulticastIp)->
    Port=TeamNo+15000,
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,Port) end),
    Sender=spawn(fun()->sender:init(Coordinator,Port) end),
    loop(#state{teamNo=TeamNo,stationNo=StationNo,multicastIp=MulticastIp,port=Port,currentSlot=(random:uniform(20)-1),receiver=Receiver,sender=Sender,slotWishes=dict:new()}).

loop(State=#state{})->
    receive
	{Slot,Time,Packet}->
	    SlotWishes=update_slot_wishes(Packet,State),
	    loop(State#state{slotWishes=SlotWishes});
	kill -> 
	    io:format("Received kill command"),
	    Receiver ! kill,
	    Sender ! kill,
	    exit(normal);
	Any -> io:format("Received garbage: ~p~n",[Any])
    end.

update_slot_wishes(_Packet=<<_Rest:64,StationBin:2/binary,_Rest1:14/binary,SlotBin:1/binary,_Rest2>>,State=#state{slotWishes=SlotWishes))->
    Sation=list_to_integer(binary_to_list(StationBin)),
    Slot=list_to_integer(binary_to_list(SlotBin)),
    NewSlotWishes=dict:append(Slot,Station,SlotWishes).
    
    
			 
			   
