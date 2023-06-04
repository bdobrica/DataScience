#!/bin/bash

if [ ! -d ~/.venvs/python-security-cam ]; then
	python3 -m venv ~/.venvs/python-security-cam
fi

source ~/.venvs/python-security-cam/bin/activate

pip3 install opencv-contrib-python-headless
pip3 install flask
pip3 install imutils
pip3 install picamera

deactivate
