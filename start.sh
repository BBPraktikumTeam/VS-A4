#!/bin/bash
# example usage: 10 10 "225.10.1.2" eth0
IF_IP=$(/sbin/ifconfig $4 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
echo "Using IP:" $IF_IP "for interface" $4
java datasource.DataSource $1 $2 | erl -sname sender -setcookie hallo -boot start_sasl -noshell -s coordinator start $1 $2 $3 $IF_IP
