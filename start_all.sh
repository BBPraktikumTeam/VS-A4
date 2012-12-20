#!/bin/bash
TEAM_NO=10
MULTICAST_IP="225.10.1.6"
IF_NAME=eth2
for host in "$@"
do
    ssh $USER@$host -o StrictHostKeyChecking=no -o BatchMode=yes "cd /$HOME/workspace/VS-A4/; ./start.sh $TEAM_NO $MULTICAST_IP $IF_NAME &"
done
