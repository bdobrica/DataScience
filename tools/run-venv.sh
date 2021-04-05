#!/bin/bash
source ~/.venvs/$1/bin/activate && python3 "${@:2}"
