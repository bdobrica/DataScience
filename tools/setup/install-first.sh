#!/bin/bash
set -e

## Update the software catalogue
sudo apt-get update
## Upgrade the software
sudo apt-get upgrade -y
## Install some common tools
sudo apt-get install -y git vim screen socat unzip wget
## Install pip for Python (the Python package manager) and the Python virtual environment
sudo apt-get install -y python3-pip python3-venv
## Globally install numpy and jupyter notebook
sudo apt-get install -y python3-numpy python3-notebook

## Create a hidden folder in the pi home directory to store the virtual environments
if [ ! -d ~/.venvs ]; then
    mkdir -p ~/.venvs
fi

SWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
chmod +x ${SWD}/*.sh
DIR=${SWD%/*}
chmod +x ${DIR}/*.sh
