#!/bin/bash

if [ "${UID}" -ne "0" ]; then
    echo "you need to use sudo to run this script"
    exit 0
fi

# https://github.com/minio/operator
kubectl krew install minio
kubectl minio init --namespace minio-operator --cluster-domain cluster.local
kubectl minio proxy -n minio-operator