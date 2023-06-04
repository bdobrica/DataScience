#!/bin/bash

if [ "${UID}" -ne "0" ]; then
    echo "you need to use sudo to run this script"
    exit 0
fi

# follow the instructions from: https://github.com/minio/operator
# install minio on cluster
kubectl krew install minio

# initialize the minio-operator
kubectl minio init --namespace minio-operator --cluster-domain cluster.local

# start the web interface for the minio operator
# you can access the UI on http://${MASTER_EXTERNAL_IP}:9090
kubectl minio proxy -n minio-operator &