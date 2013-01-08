#!/bin/bash
PORT=15050
TEAM_NO=10
MULTICAST_IP="225.10.1.2"
IF_NAME=eth2
for host in "$@"
do
    ssh $USER@$host -o StrictHostKeyChecking=no -o BatchMode=yes "cd /$HOME/workspace/VS-A4/; ./start.sh $PORT $TEAM_NO $MULTICAST_IP $IF_NAME &"
done
