#!/bin/bash
INTERNAL_PORT=8888 ## This is the port on which Jupyter Notebook runs on Raspberry Pi
EXTERNAL_PORT=8889 ## This is the port on which Jupyter Notebook is accessible from outside
SWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PWD=/home/pi
PASSWORD_FILE=${PWD}/.jupyter/password

## In order to run the Jupyer notebook at startup, first we must be sure that we're in the correct directory
cd ${PWD}

## This is how we generate a password for Jupyer Notebook
if [ ! -f ${PASSWORD_FILE} ]; then
    chmod +x ${SWD}/gen-password.py
    ${SWD}/gen-password.py
fi

## Read the generated password hash to use in starting the Jupyter Notebook
PASSWORD=$(cat ${PASSWORD_FILE})

RUNNING_JUPYTER=$(ps ax | grep jupyter-notebook | grep -v grep)
if [ "${RUNNING_JUPYTER}" != "" ]; then
    PID=$(echo "${RUNNING_JUPYTER}" | awk '{print $1}')
    kill -9 ${PID} > /dev/null 2>&1 || true
    sleep 1
    kill -9 ${PID} > /dev/null 2>&1 || true
    sleep 1
fi
RUNNING_SOCAT=$(ps ax | grep socat | grep ${INTERNAL_PORT})
if [ "${RUNNING_SOCAT}" != "" ]; then
    PID=$(echo "${RUNNING_SOCAT}" | awk '{print $1}')
    kill -9 ${PID} > /dev/null 2>&1 || true
    sleep 1
    kill -9 ${PID} > /dev/null 2>&1 || true
    sleep 1
fi

## Run the Jupyter notebook by specifying that there's no local browser (--no-browser),
##  the port on which to run (--port) and to allow remote access (--NotebookApp.allow_remote_access=1).
jupyter notebook --no-browser --port=${INTERNAL_PORT} --NotebookApp.allow_remote_access=1 --NotebookApp.password="${PASSWORD}" --NotebookApp.token='' &
## Wait 5 seconds for everything to start correctly
sleep 5
## Link the internal port address to external IP address
socat TCP6-LISTEN:${EXTERNAL_PORT},fork TCP4:127.0.0.1:${INTERNAL_PORT} &
