#!/bin/bash
USERNAME=$1
TEAM_NO=10
MULTICAST_IP="225.10.1.5"
IF_NAME=eth2
shift
for host in "$@"
do
    HOST_NO=${HOSTNAME##lab}
    ssh $USERNAME@$host "cd /home/stud6/$USERNAME/workspace/VS-A4/; ./start.sh $TEAM_NO $HOST_NO $MULTICAST_IP $IF_NAME &"
done
