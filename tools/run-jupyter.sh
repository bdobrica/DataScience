#!/bin/bash
INTERNAL_PORT=8888 ## This is the port on which Jupyter Notebook runs on Raspberry Pi
EXTERNAL_PORT=8889 ## This is the port on which Jupyter Notebook is accessible from outside

## Run the Jupyter notebook by specifying that there's no local browser (--no-browser),
##  the port on which to run (--port) and to allow remote access (--NotebookApp.allow_remote_access=1).
jupyter notebook --no-browser --port=${INTERNAL_PORT} --NotebookApp.allow_remote_access=1 &
## Wait 5 seconds for everything to start correctly
sleep 5
## Link the internal port address to external IP address
socat TCP6-LISTEN:${EXTERNAL_PORT},fork TCP4:127.0.0.1:${INTERNAL_PORT} &