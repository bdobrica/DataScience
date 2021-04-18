#!/bin/bash

## Update the software catalogue
sudo apt-get update
## Install some common tools
sudo apt-get install -y git vim screen socat unzip wget
## Install pip for Python (the Python package manager) and the Python virtual environment
sudo apt-get install -y python3-pip python3-venv
## Globally install numpy and jupyter notebook
sudo python3 -m pip install -U pip numpy notebook

## Create a hidden folder in the pi home directory to store the virtual environments
mkdir ~/.venvs

SWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
chmod +x ${SWD}/*.sh
DIR=${SWD%/*}
chmod +x ${DIR}/*.sh
