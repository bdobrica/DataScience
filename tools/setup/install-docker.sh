#!/bin/bash
set -e

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
sudo usermod -aG docker pi
