#!/bin/bash
source 00-common.sh

# https://www.rabbitmq.com/kubernetes/operator/install-operator.html
# https://github.com/rabbitmq/cluster-operator/issues/366

# install podman and git
sudo apt-get update && sudo apt-get -y install git podman
# add the search registries for podman
echo -ne '\nunqualified-search-registries = ["docker.io", "quay.io"]\n' | sudo tee -a /etc/containers/registries.conf > /dev/null

wget https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml -O $(pwd)/charts/cluster-operator.yaml

git clone https://github.com/rabbitmq/cluster-operator.git
cd cluster-operator
rm -Rf .git*

sed 's/GOARCH=amd64/GOARCH=arm64/' Dockerfile

sudo podman build --build-arg GIT_COMMIT=first -t quay.io/${QUAY_USER}/cluster-operator -f Dockerfile .
sudo podman login -u="${QUAY_USER}" -p="${QUAY_PASS}" quay.io
sudo podman push quay.io/${QUAY_USER}/cluster-operator

sed -i 's#rabbitmqoperator/cluster-operator:.\+#quay.io/bdobrica/cluster-operator:latest#' $(pwd)/charts/cluster-operator.yaml

sudo kubectl apply -f $(pwd)/charts/cluster-operator.yaml
sudo kubectl apply -f $(pwd)/charts/rabbitmq-tenant-1.yaml

sudo kubectl port-forward pod/rabbitmq-tenant-1-server-0 -n rabbitmq-tenant-1 --address "${MASTER_EXTERNAL_IP}" 15672:15672 &