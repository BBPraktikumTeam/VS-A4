#!/bin/bash
TEAM_NO=10
MULTICAST_IP="225.10.1.5"
IF_NAME=eth2

for i in `nmap -sP 172.16.1.2-18 | grep "appears to be up"`
do
  if [[ $i =~ ^[[:digit:]] ]]
  then
    ./start_all.sh $i
  fi
done
