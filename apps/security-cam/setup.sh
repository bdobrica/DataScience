#!/bin/bash
SECURITY_CAM_VENV="python-security-cam"

if [ ! -d ~/.venvs/${SECURITY_CAM_VENV} ]; then
	python3 -m venv ~/.venvs/${SECURITY_CAM_VENV}

    source ~/.venvs/${SECURITY_CAM_VENV}/bin/activate

    # 4.5.5.64 is the latest version that works on Raspberry Pi 3
    # Check here: https://www.piwheels.org/project/opencv-python-headless/
    python3 -m pip install --only-binary ":all:" opencv-contrib-python-headless
    python3 -m pip install pillow
    python3 -m pip install flask

    deactivate


    ## Copy the missing packages from the system to the virtual environment
    VENV_SITE_PACKAGES=$(find ~/.venvs/${SECURITY_CAM_VENV} -name "site-packages" | head -n 1)
    NEEDED_PACKAGES=( "pykms" "simplejpeg" "pidng" "piexif" "prctl" "v4l2" "libcamera" "picamera2" )
    for NEEDED_PACKAGE in "${NEEDED_PACKAGES[@]}"; do
        find /usr/lib/python3/dist-packages -maxdepth 1 -name "*${NEEDED_PACKAGE}*" | while read d; do
            cp -r "$d" "${VENV_SITE_PACKAGES}/$(basename "$d")";
        done
    done

    ## Copy the init.d script
    sudo cp "$(dirname "${BASH_SOURCE[0]}")/security-cam" /etc/init.d/security-cam

    ## Show the user the next steps
    echo "The virtual environment ${SECURITY_CAM_VENV} was created and the OpenCV library was installed."
    echo " * start the service by running: sudo service security-cam start"
    echo " * access the service by opening a browser and going to: http://$(hostname -I | cut -d' ' -f1):8080"
    echo " * find the PIN for the camera in "$(dirname "${BASH_SOURCE[0]}")"/config.ini"
    echo " * processing camera frames can be done in camera.PiVideoStream.read method"
fi
