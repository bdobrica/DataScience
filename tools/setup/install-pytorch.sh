#!/bin/bash
PYTHORCH_VENV="python-pytorch"
ADDED_ENV="no"

if [ ! -d ~/.venvs ]; then
    mkdir -p ~/.venvs
fi

if [ ! -f ~/.venvs/${PYTHORCH_VENV}/bin/activate ]; then
    if [ -d ~/.venvs/${PYTHORCH_VENV} ]; then
        rm -rf ~/.venvs/${PYTHORCH_VENV}
    fi
    ## Create a virtual environment for OpenCV
    python3 -m venv ~/.venvs/${PYTHORCH_VENV}
    ADDED_VENV="yes"
fi

## Activate the PYTHORCH_VENV virtual environment
source ~/.venvs/${PYTHORCH_VENV}/bin/activate

## Install the OpenCV library. This specific version is the only one I was able to quickly install
pip3 install opencv-contrib-python-headless
## Install PyTorch
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
## Install matplotlib which will help in displaying the images
pip3 install matplotlib
## Deactivate the PYTHORCH_VENV virtual environment
deactivate

## Add the virtual environment to jupyter notebook
if [ "${ADDED_VENV}" == "yes" ]; then
    python3 -m ipykernel install --user --name=${PYTHORCH_VENV}
fi

## Fix the Jupyer Notebook problem with VENVs
SWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
chmod +x ${SWD}/*.sh
DIR=${SWD%/*}
chmod +x ${DIR}/*.sh
${DIR}/fix-venv.sh
