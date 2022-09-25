#!/bin/bash
source common.sh

MASTER_NAME=$(get_cluster_name 0)

for i in ${!NODE_IPS[@]}; do
        i=$[$i+1]
        NODE_NAME=$(get_cluster_name $i)
        NODE_IP=$(get_ip $i)
        echo "${NODE_NAME} -> ${NODE_IP} -> ${MASTER_NAME}"
        ssh pi@${NODE_NAME} "sudo shutdown -h 1"
done

sudo shutdown -h 1
