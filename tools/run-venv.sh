#!/bin/bash
source ~/.venvs/$1/bin/activate
python3 -m pip install ipykernel > /dev/null 2>&1
python3 "${@:2}"
