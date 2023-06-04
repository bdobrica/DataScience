#!/bin/bash

# check if you have root privileges
if [ "${UID}" -ne "0" ]; then
    echo "you need to use sudo to run this script"
    exit 0
fi

# install git
apt-get -y install git

# follow the instructions from: https://krew.sigs.k8s.io/docs/user-guide/setup/install/
# install krew
(
set -x; cd "$(mktemp -d)" &&
OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
KREW="krew-${OS}_${ARCH}" &&
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
tar zxvf "${KREW}.tar.gz" &&
./"${KREW}" install krew
)

# add the kew install folder to PATH
export 'PATH="${PATH}:${HOME}/.krew/bin"' >> ${HOME}/.bashrc