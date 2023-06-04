#!/bin/bash
source 00-common.sh

# the script shutsdown all the cluster nodes, including the master

MASTER_NAME=$(get_cluster_name 0)

# for each node specified in 00-common.sh
for i in ${!NODE_IPS[@]}; do
        i=$[$i+1]
        NODE_NAME=$(get_cluster_name $i)
        NODE_IP=$(get_ip $i)
        echo "${NODE_NAME} -> ${NODE_IP} -> ${MASTER_NAME}"

        # shutdown the remote node
        ssh pi@${NODE_NAME} "sudo shutdown -h 1"
done

# shutdown the master node
sudo shutdown -h 1
