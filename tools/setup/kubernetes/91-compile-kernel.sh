#!/bin/bash

PWD=$(pwd)

sudo apt-get install -y git bc bison flex libssl-dev make

git clone --depth=1 https://github.com/raspberrypi/linux
cd linux
KERNEL=kernel8 make bcm2711_defconfig

sed -i -e 's/^CONFIG_LOCALVERSION.\+$/CONFIG_LOCALVERSION="-v8-scylla"/' -e 's/\(CONFIG_ARM64_VA_BITS.\)39/\148/' .config

make -j4 Image.gz modules dtbs
sudo make modules_install
sudo cp arch/arm64/boot/dts/broadcom/*.dtb /boot/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* /boot/overlays/
sudo cp arch/arm64/boot/dts/overlays/README /boot/overlays/
KERNEL=kernel8 sudo cp arch/arm64/boot/Image.gz /boot/${KERNEL}.img

cd "${PWD}"