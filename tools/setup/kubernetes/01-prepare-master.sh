#!/bin/bash
source 00-common.sh

# check if the cgroup boot setting is not modified
if ( ! grep -q cgroup_enable /boot/cmdline.txt ); then
    # do a system update, just to be sure
    sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y install vim screen

    # set up the static networking
    echo -ne "\ninterface wlan0\nstatic ip_address=${MASTER_EXTERNAL_IP}\nstatic routers=${MASTER_EXTERNAL_ROUTE}\nstatic domain_name_servers=${NAME_SERVERS}" | sudo tee -a /etc/dhcpcd.conf > /dev/null
    echo -ne "\n\ninterface eth0\nstatic ip_address=${MASTER_INTERNAL_IP}" | sudo tee -a /etc/dhcpcd.conf > /dev/null

    # configure cgroup boot options
    sudo sed -i 's/rootwait/cgroup_memory=1 cgroup_enable=memory rootwait/' /boot/cmdline.txt

    # generate a ssh key without password to connect to other nodes
    ssh-keygen -P "" -f /home/pi/.ssh/id_rsa

    # restart
    sudo shutdown -r 1
fi