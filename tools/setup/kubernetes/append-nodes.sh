#!/bin/bash
source common.sh

K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/token)
MASTER_NAME=$(get_cluster_name 0)

for i in ${!NODE_IPS[@]}; do
        i=$[$i+1]
        NODE_NAME=$(get_cluster_name $i)
        NODE_IP=$(get_ip $i)
        echo "${NODE_NAME} -> ${NODE_IP} -> ${MASTER_NAME}"
        ssh pi@${NODE_NAME} "curl -sfL https://get.k3s.io | K3S_NODE_NAME='${NODE_NAME}' K3S_URL='https://${MASTER_NAME}:6443' K3S_TOKEN='${K3S_TOKEN}' sh -"
done
