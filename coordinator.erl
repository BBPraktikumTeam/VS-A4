-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,socket,currentSlot,receiver,sender,slotWishes, usedSlots, ownPacketCollided}).

start([TeamNo,StationNo,MulticastIp,LocalIp])->
    init(list_to_integer(atom_to_list(TeamNo)),list_to_integer(atom_to_list(StationNo)),atom_to_list(MulticastIp),atom_to_list(LocalIp)).

init(TeamNo,StationNo,MulticastIp,LocalIp)->
    Port=TeamNo+15000,
	{ok,Socket}=gen_udp:open(Port, [binary, {ip, LocalIp}, {add_membership, {MulticastIp, LocalIp}}]),
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,Socket) end),
    Sender=spawn(fun()->sender:init(Coordinator,Socket,MulticastIp) end),
	timer:sleep(1000 - (utilities:get_timestamp() rem 1000)), %% wait for first slot / first full second
	timer:send_after(1000,self(),reset_slot_wishes), %% set the first timer that calls to reset the slot wishes dict every second
    loop(#state{teamNo=TeamNo,stationNo=StationNo,socket=Socket,currentSlot=(random:uniform(20)-1),receiver=Receiver,sender=Sender,slotWishes=dict:new(), usedSlots = [], ownPacketCollided = false}).

loop(State=#state{slotWishes = SlotWishes, currentSlot = CurrentSlot, stationNo = StationNo, sender = Sender,receiver=Receiver, usedSlots = UsedSlots, ownPacketCollided = OwnPacketCollided})->
    receive
		reset_slot_wishes ->
			timer:send_after(1000,self(),reset_slot_wishes), %% reset slot wishes every second/frame
			if
				OwnPacketCollided ->
					Slot = calculate_slot_from_slotwishes(SlotWishes);
				true ->
					Slot = CurrentSlot
			end,
			Sender ! {slot, Slot},
			loop(State#state{slotWishes=dict:new(), usedSlots = [], ownPacketCollided = false, currentSlot = Slot});
		{received,Slot,Time,Packet} ->
			IsCollision = lists:member(Slot, UsedSlots),
			if
				IsCollision ->
					io:format("Collision detected in Slot ~p~n",[Slot]),
					%% other packets received on that slot can't be evaluated, therefore their slotWishes were invalid
					SlotWishesNew=dict:erase(Slot, SlotWishes),
					{Station, _, _, _} = utilities:match_message(Packet),
					if
						Station == StationNo ->		%% funktioniert das so oder enthält "Station" auch noch die TeamNo?
							loop(State#state{slotWishes=SlotWishesNew, ownPacketCollided = true});
						true ->
							loop(State#state{slotWishes=SlotWishesNew})
					end;
				true ->
					SlotWishesNew=update_slot_wishes(Packet,SlotWishes),
					UsedSlotsNew = lists:append([Slot], UsedSlots),
					loop(State#state{slotWishes=SlotWishesNew, usedSlots=UsedSlotsNew})
			end;
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
    dict:append(Slot,Station,SlotWishes).
    
    


			   
calculate_slot_from_slotwishes(SlotWishes) ->
	FreeSlots = lists:subtract(lists:seq(0,19), dict:fetch_keys(SlotWishes)),
	lists:nth(random:uniform(length(FreeSlots)), FreeSlots).
