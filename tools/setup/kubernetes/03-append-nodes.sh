#!/bin/bash
source 00-common.sh

# get the Kubernetes token
K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/token)
# and the master name
MASTER_NAME=$(get_cluster_name 0)

# for each node defined in 00-common.sh
for i in ${!NODE_IPS[@]}; do
        i=$[$i+1]
        # get the node's internal name and internal IP
        NODE_NAME=$(get_cluster_name $i)
        NODE_IP=$(get_ip $i)
        echo "${NODE_NAME} -> ${NODE_IP} -> ${MASTER_NAME}"

        # add the node to the cluster
        ssh pi@${NODE_NAME} "curl -sfL https://get.k3s.io | K3S_NODE_NAME='${NODE_NAME}' K3S_URL='https://${MASTER_NAME}:6443' K3S_TOKEN='${K3S_TOKEN}' sh -"
done
