#!/bin/bash
set -e

# update the package index
sudo apt-get update
# enable I2C and SPI
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_spi 0
# change to home directory
cd ~/
# clone the repository (the official one doesn't support the latest kernel)
git clone https://github.com/HinTak/seeed-voicecard.git
cd seeed-voicecard
# modify this based on your kernel version; v5.16 works for me
# check the kernel version with uname -a
git checkout v5.16
sudo ./install.sh
# reboot
sudo reboot
