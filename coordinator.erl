
-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,socket,currentSlot,receiver,sender,slotWishes}).

init(TeamNo,StationNo,MulticastIp)->
    Port=TeamNo+15000,
	{ok,Socket}=gen_udp:open(Port),
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,Socket) end),
    Sender=spawn(fun()->sender:init(Coordinator,Socket,MulticastIp) end),
	timer:sleep(1000 - (utilities:get_timestamp() rem 1000)), %% wait for first slot / first full second
	timer:send_after(1000,self(),reset_slot_wishes), %% set the first timer that calls to reset the slot wishes dict every second
    loop(#state{teamNo=TeamNo,stationNo=StationNo,socket=Socket,currentSlot=(random:uniform(20)-1),receiver=Receiver,sender=Sender,slotWishes=dict:new()}).

loop(State=#state{slotWishes = SlotWishes, stationNo = StationNo, sender = Sender,receiver=Receiver})->
    receive
		reset_slot_wishes ->
			timer:send_after(1000,self(),reset_slot_wishes), %% reset slot wishes every second/frame
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
    {Station,Slot,_,_} = utilities:match_message(Packet),
	%% Appends the Clients to each SlotWish, so we can choose free slots afterwards
    NewSlotWishes=dict:append(Slot,Station,SlotWishes).
    
    


			   
calculate_slot_from_slotwishes(StationNo, SlotWishes) ->
	%% Todo CrazyScheiss, Ignore when several wishes for the same slot
	%% Choose free slots or slots with conflict then get a random one.
	1.
