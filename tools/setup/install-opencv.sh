#!/bin/bash
ADDED_VENV="no"

## Install various dependencies: build tools (compiles and libraries), also image and video libraries
sudo apt-get install -y build-essential cmake pkg-config
sudo apt-get install -y libjpeg-dev libtiff5-dev libjasper-dev libpng-dev
sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt-get install -y libxvidcore-dev libx264-dev
sudo apt-get install -y libfontconfig1-dev libcairo2-dev
sudo apt-get install -y libgdk-pixbuf2.0-dev libpango1.0-dev
sudo apt-get install -y libgtk2.0-dev libgtk-3-dev
sudo apt-get install -y libatlas-base-dev gfortran
sudo apt-get install -y libhdf5-dev libhdf5-serial-dev libhdf5-103
sudo apt-get install -y libqtgui4 libqtwebkit4 libqt4-test python3-pyqt5
sudo apt-get install -y libilmbase-dev libopenexr-dev libgstreamer1.0-dev
sudo apt-get install -y libssl-dev libffi-dev

## Install Python specific dependencies
sudo apt-get install -y python3-dev python3-picamera

if [ ! -d ~/.venvs/python-opencv ]; then
    ## Create a virtual environment for OpenCV
    python3 -m venv ~/.venvs/python-opencv
    ADDED_VENV="yes"
fi

## Activate the opencv-python virtual environment
source ~/.venvs/python-opencv/bin/activate
## Install the OpenCV library. This specific version is the only one I was able to quickly install
pip3 install opencv-contrib-python==4.4.0.46
## Install matplotlib which will help in displaying the images
pip3 install matplotlib
## Deactivate the python-opencv virtual environment
deactivate

## Add the virtual environment to jupyter notebook
if [ "${ADDED_VENV}" == "yes" ]; then
    python3 -m ipykernel install --user --name=python-opencv
fi

## Fix the Jupyer Notebook problem with VENVs
SWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
chmod +x ${SWD}/*.sh
DIR=${SWD%/*}
chmod +x ${DIR}/*.sh
${DIR}/fix-venv.sh
