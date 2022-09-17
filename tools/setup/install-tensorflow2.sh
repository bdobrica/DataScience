#!/bin/bash
ADDED_ENV="no"

## Install dependencies
sudo apt-get -y install gfortran
sudo apt-get -y install libhdf5-dev libc-ares-dev libeigen3-dev
sudo apt-get -y install libatlas-base-dev libopenblas-dev libblas-dev
sudo apt-get -y install openmpi-bin libopenmpi-dev
sudo apt-get -y install liblapack-dev

sudo apt-get -y install build-essential
sudo apt-get -y install libncurses5-dev libncursesw5-dev libreadline6-dev
sudo apt-get -y install libdb5.3-dev libgdbm-dev libsqlite3-dev
sudo apt-get -y install libssl-dev libffi-dev
sudo apt-get -y install libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev

## Install Python3.7
wget https://www.python.org/ftp/python/3.7.14/Python-3.7.14.tgz
tar xzf Python-3.7.14.tgz
CURRENT_FOLDER=$(pwd)
cd Python-3.7.14
./configure
make -j 4
sudo make altinstall
cd "${CURRENT_FOLDER}"
rm -Rf Python-3.7.14*

## Create a python-tf virtual environment
if [ ! -d ~/.venvs/python-tf2 ]; then
	python3.7 -m venv ~/.venvs/python-tf2
	ADDED_ENV="yes"
fi

## How to use a virtual environment: this will activate the environment
source ~/.venvs/python-tf2/bin/activate
## Uninstall existing tensorflow (if exists)
pip3 uninstall tensorflow

## Install Keras tools (keras is a high-level tensorflow wrapper)
pip3 install numpy
pip3 install keras_applications==1.0.8 --no-deps
pip3 install keras_preprocessing==1.1.0 --no-deps
pip3 install six wheel mock
pip3 install pybind11
pip3 install h5py==2.10.0
pip3 install --upgrade setuptools
## This is a tool for downloading files from Google Drive
pip3 install gdown
## Needed to download the 2.2.0 version of TensorFlow
gdown https://drive.google.com/uc?id=1QjsBN5fKAd-5gi01UqdeYpy9Wc0Gd8Fw
## And install it
pip3 install tensorflow-2.3.0-cp37-cp37m-linux_aarch64.whl
## And remove it, to not waste space
rm tensorflow-2.3.0-cp37-cp37m-linux_aarch64.whl
## Install the OpenCV library. This specific version is the only one I was able to quickly install
pip3 install opencv-contrib-python-headless==4.6.0.66
## Install matplotlib which will help in displaying the images
pip3 install matplotlib
## Install dlib which will help with detecting face features
pip3 install dlib

## Deactivate the python-tf2 virtual environment
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
