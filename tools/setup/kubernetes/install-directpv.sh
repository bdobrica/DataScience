#!/bin/bash

if [ "${UID}" -ne "0" ]; then
    echo "you need to use sudo to run this script"
    exit 0
fi

# https://github.com/minio/directpv
kubectl krew install directpv
kubectl directpv install --dry-run > deploy-directpv.yaml
sed -i 's$image: quay.io/minio/csi-node-driver-registrar@.\+$image: registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.5.0$' deploy-directpv.yaml
sed -i 's$image: quay.io/minio/livenessprobe@.\+$image: registry.k8s.io/sig-storage/livenessprobe:v2.7.0$' deploy-directpv.yaml
sed -i 's$image: quay.io/minio/csi-provisioner@.\+$registry.k8s.io/sig-storage/csi-provisioner:v3.1.0$' deploy-directpv.yaml
kubectl create -f deploy-directpv.yaml
kubectl directpv drives format --force --drives /dev/sda1 --nodes node01pi.cluster
kubectl directpv info