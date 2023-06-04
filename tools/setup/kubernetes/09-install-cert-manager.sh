#!/bin/bash

sudo kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml

wget https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cmctl-linux-arm64.tar.gz -O cmctl.tar.gz
tar xvf cmctl.tar.gz
sudo mv cmctl /usr/local/bin/