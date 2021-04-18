#!/bin/bash
ADDED_ENV="no"

## Install dependencies
sudo apt-get -y install gfortran
sudo apt-get -y install libhdf5-dev libc-ares-dev libeigen3-dev
sudo apt-get -y install libatlas-base-dev libopenblas-dev libblas-dev
sudo apt-get -y install openmpi-bin libopenmpi-dev
sudo apt-get -y install liblapack-dev cython

## Create a python-tf virtual environment
if [ ! -d ~/.venvs/python-tf2 ]; then
	python3 -m venv ~/.venvs/python-tf2
	ADDED_ENV="yes"
fi

## How to use a virtual environment: this will activate the environment
source ~/.venvs/python-tf2/bin/activate
## Uninstall existing tensorflow (if exists)
pip3 uninstall tensorflow

## Install Keras tools (keras is a high-level tensorflow wrapper)
pip3 install keras_applications==1.0.8 --no-deps
pip3 install keras_preprocessing==1.1.0 --no-deps
pip3 install six wheel mock
pip3 install pybind11
pip3 install h5py==2.10.0
pip3 install --upgrade setuptools
## This is a tool for downloading files from Google Drive
pip3 install gdown
## Needed to download the 2.2.0 version of TensorFlow
gdown https://drive.google.com/uc?id=11mujzVaFqa7R1_lB7q0kVPW22Ol51MPg
## And install it
pip3 install tensorflow-2.2.0-cp37-cp37m-linux_armv7l.whl
## And remove it, to not waste space
rm tensorflow-2.2.0-cp37-cp37m-linux_armv7l.whl
## Install the OpenCV library. This specific version is the only one I was able to quickly install
pip3 install opencv-contrib-python==4.1.0.25
## Install matplotlib which will help in displaying the images
pip3 install matplotlib
## Install dlib which will help with detecting face features
pip3 install dlib

## Deactivate the python-opencv virtual environment
deactivate

## Add the virtual environment to jupyter notebook
if [ "${ADDED_ENV}" == "yes" ]; then
	python3 -m ipykernel install --user --name=python-tf2
fi

## Fix the Jupyer Notebook problem with VENVs
SWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
chmod +x ${SWD}/*.sh
DIR=${SWD%/*}
chmod +x ${DIR}/*.sh
${DIR}/fix-venv.sh
