-module(dataqueue).
-compile(export_all).
-record(state,{queue}).

start()->
	Self=self(),
	%% register only for testing!
	register(dataqueue,Self),
	spawn(fun()->read(Self) end),
	loop(#state{queue=queue:new()}).

read(Pid)->
	Input=io:get_chars("",24),
	%% io:format("~p: ~s~n",[N,Input]),
	Pid ! {input,Input},
	read(Pid).

loop(State=#state{queue=Queue})->
	receive
		{input,Input} -> 
			      NewQueue=queue:in(Input,Queue),
			      loop(State#state{queue=NewQueue});
		{get_data,Pid} -> 
			 {Item,NewQueue}=queue:out(Queue),
			 Pid ! {send_data,Item},
			 loop(State#state{queue=NewQueue})
	end.

	