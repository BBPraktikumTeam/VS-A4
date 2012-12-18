VS-A4
=====

Verteilte Systeme Aufgabe 4

Multicast in Erlang:
gen_udp:open(?PORT_NUM_TX_MULTI,
                                       [binary, {active, true},
                                        {ip, GwIP},
                                        inet, {multicast_ttl, 255},
                                        {multicast_loop, false},
                                        {multicast_if, GwIP}]),

Receive:

gen_udp:open(?PORT_NUM_RX_MULTI,
                                       [binary, {active, true},
                                        {multicast_if, GwIP},
                                        inet,{multicast_ttl, 255},
                                        {multicast_loop, false},
                                        {add_membership,
{MultiAddr,GwIP}}]),

http://erlang.org/pipermail/erlang-questions/2009-November/047568.html