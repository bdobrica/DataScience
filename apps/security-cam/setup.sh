#!/bin/bash
SECURITY_CAM_VENV="python-security-cam"

if [ ! -d ~/.venvs/${SECURITY_CAM_VENV} ]; then
	python3 -m venv ~/.venvs/${SECURITY_CAM_VENV}

    source ~/.venvs/${SECURITY_CAM_VENV}/bin/activate

    pip3 install opencv-contrib-python-headless
    pip3 install flask

    deactivate


    ## Copy the missing packages from the system to the virtual environment
    VENV_SITE_PACKAGES=$(find ~/.venvs/${SECURITY_CAM_VENV} -name "site-packages" | head -n 1)
    NEEDED_PACKAGES=( "pykms" "simplejpeg" "pidng" "piexif" "prctl" "v4l2" "libcamera" "picamera2" )
    for NEEDED_PACKAGE in "${NEEDED_PACKAGES[@]}"; do
        find /usr/lib/python3/dist-packages -maxdepth 1 -name "*${NEEDED_PACKAGE}*" | while read d; do
            cp -r "$d" "${VENV_SITE_PACKAGES}/$(basename "$d")";
        done
    done
fi
