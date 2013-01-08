-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,currentSlot,receiver,sender,slotWishes, usedSlots, ownPacketCollided ,slotAlreadyChosen}).

start([Port,TeamNo,StationNo,MulticastIp,LocalIp])->
    {ok,MulticastIpTuple}=inet_parse:address(atom_to_list(MulticastIp)),
    {ok,LocalIpTuple}=inet_parse:address(atom_to_list(LocalIp)),
    init(list_to_integer(atom_to_list(Port)),list_to_integer(atom_to_list(TeamNo)),list_to_integer(atom_to_list(StationNo)),MulticastIpTuple,LocalIpTuple).

init(Port,TeamNo,StationNo,MulticastIp,LocalIp)->
    ReceivePort=Port,
    SendPort=StationNo+14000,
    io:format("Starting Receive-Socket~n"),
    {ok,ReceiveSocket}=gen_udp:open(ReceivePort, [binary, {active, true}, {multicast_if, LocalIp}, inet, {reuseaddr,true}, {multicast_loop, true}, {add_membership, {MulticastIp,LocalIp}}]),
    io:format("Starting Send-Socket~n"),
    {ok,SendSocket}=gen_udp:open(SendPort, [binary, {active, true}, {ip, LocalIp}, inet, {multicast_loop, true}, {multicast_if, LocalIp}]),
    io:format("SendSocket running on: ~p~n",[SendPort]),
    io:format("ReceiveSocket running on: ~p~n",[ReceivePort]),
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,ReceiveSocket) end),
    gen_udp:controlling_process(ReceiveSocket,Receiver),
    Sender=spawn(fun()->sender:init(SendSocket,MulticastIp,ReceivePort, Coordinator) end),
    gen_udp:controlling_process(SendSocket,Sender),
    timer:sleep(1000 - (utilities:get_timestamp() rem 1000)), %% wait for first slot / first full second
	self() ! reset_slot_wishes,
    %%timer:send_after(1000,self(),reset_slot_wishes), %% set the first timer that calls to reset the slot wishes dict every second
    {FirstSlot,_}=(random:uniform_s(20,now())),
    loop(#state{teamNo=TeamNo,stationNo=StationNo,currentSlot=FirstSlot-1,receiver=Receiver,sender=Sender,slotWishes=dict:new(), usedSlots = [], ownPacketCollided = false, slotAlreadyChosen =false}).

loop(State=#state{slotWishes = SlotWishes, currentSlot = CurrentSlot, stationNo = StationNo, sender = Sender,receiver=Receiver, usedSlots = UsedSlots, ownPacketCollided = OwnPacketCollided, slotAlreadyChosen = SlotAlreadyChosen})->
    receive
		reset_slot_wishes ->
			io:format("coordinator: reset_slot_wishes~n"),
			timer:send_after(1000 - (utilities:get_timestamp() rem 1000),self(),reset_slot_wishes), %% reset slot wishes every second/frame
			if
				OwnPacketCollided and not SlotAlreadyChosen ->
					
					Slot = calculate_slot_from_slotwishes(SlotWishes);
				true ->
					Slot = CurrentSlot
			end,
			Sender ! {slot, {CurrentSlot,Slot}},
			loop(State#state{slotWishes=dict:new(), usedSlots = [], ownPacketCollided = false, currentSlot = Slot, slotAlreadyChosen =false});
		{received,Slot,Time,Packet} ->
			io:format("coordinator: Received: slot:~p;time: ~p;packet: ~p~n",[Slot,Time,utilities:message_to_string(Packet)]),
			IsCollision = ((lists:member(Slot, UsedSlots)) or (Slot == CurrentSlot)),
			if
				IsCollision ->
					SlotWishesNew = update_slot_wishes(Packet, SlotWishes),
					%%CollidedStations = dict:fetch(Slot, SlotWishesNew),
					OwnStationInvolved = Slot == CurrentSlot,
					if
						OwnStationInvolved ->	
							io:format("coordinator: Collision detected in Slot ~p, own packet involved~n",[Slot]),
							SlotWishesWithOwn = dict:append(Slot, StationNo, SlotWishesNew),	
							loop(State#state{slotWishes=SlotWishesWithOwn, ownPacketCollided = true});
						true ->
							io:format("coordinator: Collision detected in Slot ~p~n",[Slot]),
							loop(State#state{slotWishes=SlotWishesNew})
					end;
				true ->
					SlotWishesNew=update_slot_wishes(Packet,SlotWishes),
					UsedSlotsNew = lists:append([Slot], UsedSlots),
					loop(State#state{slotWishes=SlotWishesNew, usedSlots=UsedSlotsNew})
			end;
		{validate_slot, Slot} ->
			io:format("coordinator: try to validate slot~n"),
			IsValid = not dict:is_key(Slot, SlotWishes),
			
			if 
				IsValid ->
					io:format("coordinator: slot is valid~n"),
					Sender ! slot_ok,
					loop(State);
				true ->
					NewSlot = calculate_slot_from_slotwishes(SlotWishes),
					io:format("coordinator: slot was invalid, new slot: ~p~n", [NewSlot]),
					Sender ! {new_slot, NewSlot},
					loop(State#state{currentSlot = NewSlot, slotAlreadyChosen =true})
			end;
		kill -> 
			io:format("Received kill command"),
			Receiver ! kill,
			Sender ! kill,
			exit(normal);
		Any -> io:format("coordinator: Received garbage: ~p~n",[Any]),
			loop(State#state{})
    end.

update_slot_wishes(Packet,SlotWishes)->
    {Station,Slot,_,_} = utilities:match_message(Packet),
	%% Appends the Clients to each SlotWish, so we can choose free slots afterwards
    dict:append(Slot,Station,SlotWishes).
    
    


			   
calculate_slot_from_slotwishes(SlotWishes) ->
	ValidSlotWishes = dict:filter(fun(_,V) -> (length(V) == 1) end, SlotWishes),		%%remove collisions
	FreeSlots = lists:subtract(lists:seq(0,19), dict:fetch_keys(ValidSlotWishes)),
	{NthSlotList,_}=random:uniform_s(length(FreeSlots),now()),
	io:format("Choosing Slot ~p from ~p~n",[lists:nth(NthSlotList,FreeSlots), FreeSlots]),
	lists:nth(NthSlotList, FreeSlots).
