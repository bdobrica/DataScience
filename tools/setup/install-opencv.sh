#!/bin/bash
set -e

OPENCV_VENV="python-opencv"
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
sudo apt-get install -y liblapack-dev liblapacke-dev libopenblas-dev
sudo apt-get install -y libhdf5-dev libhdf5-serial-dev libhdf5-103
sudo apt-get install -y libilmbase-dev libopenexr-dev libgstreamer1.0-dev
sudo apt-get install -y libgstreamer-plugins-base1.0-dev
sudo apt-get install -y libssl-dev libffi-dev libgflags-dev protobuf-compiler
sudo apt-get install -y python3-picamera2

## Install Python specific dependencies
sudo apt-get install -y python3-dev

if [ ! -d ~/.venvs ]; then
    mkdir -p ~/.venvs
fi

if [ ! -f ~/.venvs/${OPENCV_VENV}/bin/activate ]; then
    if [ -d ~/.venvs/${OPENCV_VENV} ]; then
        rm -rf ~/.venvs/${OPENCV_VENV}
    fi
    ## Create a virtual environment for OpenCV
    python3 -m venv ~/.venvs/${OPENCV_VENV}
    ADDED_VENV="yes"
fi

## Activate the opencv-python virtual environment
source ~/.venvs/${OPENCV_VENV}/bin/activate
## Install the OpenCV library. This specific version is the only one I was able to quickly install
pip3 install --only-binary ":all:" opencv-contrib-python-headless
## Install matplotlib which will help in displaying the images
pip3 install matplotlib
## Deactivate the OPENCV_VENV virtual environment
deactivate

## Add the virtual environment to jupyter notebook
if [ "${ADDED_VENV}" == "yes" ]; then
    python3 -m ipykernel install --user --name=${OPENCV_VENV}

    ## Copy the missing packages from the system to the virtual environment
    VENV_SITE_PACKAGES=$(find ~/.venvs/${OPENCV_VENV} -name "site-packages" | head -n 1)
    NEEDED_PACKAGES=( "pykms" "simplejpeg" "pidng" "piexif" "prctl" "v4l2" "libcamera" "picamera2" )
    for NEEDED_PACKAGE in "${NEEDED_PACKAGES[@]}"; do
        find /usr/lib/python3/dist-packages -maxdepth 1 -name "*${NEEDED_PACKAGE}*" | while read d; do
            cp -r "$d" "${VENV_SITE_PACKAGES}/$(basename "$d")";
        done
    done
fi

## Fix the Jupyer Notebook problem with VENVs
SWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
chmod +x ${SWD}/*.sh
DIR=${SWD%/*}
chmod +x ${DIR}/*.sh
${DIR}/fix-venv.sh
