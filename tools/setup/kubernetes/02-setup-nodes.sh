#!/bin/bash
source 00-common.sh

# install Rancher's K3S on master node
# quick guide: https://rancher.com/docs/k3s/latest/en/quick-start/
# setup options: https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/
curl -sfL https://get.k3s.io | sh -

# for each node specified in 00-common.sh
for i in ${!NODE_IPS[@]}; do
        # get the node external IP
        NODE_IP=${NODE_IPS[$i]}

        # get the node's name and the node's internal IP
        i=$[$i+1]
        NODE_NAME=$(get_name $i)
        NODE_INTERNAL_IP=$(get_ip $i)
        echo "${NODE_NAME} -> ${NODE_IP} ${NODE_INTERNAL_IP}"


        # if the node external name is not added to /etc/hosts
        if ( ! grep -q "${NODE_IP}" /etc/hosts ); then
                # add it,
                sudo sed -i -e "\$a${NODE_IP}\t${NODE_NAME}" /etc/hosts
                # then copy the master ssh key to the node
                ssh-copy-id pi@${NODE_IP}
        fi

        # if the node internal name is not added to /etc/hosts
        if ( ! grep -q "${NODE_INTERNAL_IP}" /etc/hosts ); then
                # add it,
                sudo sed -i -e "\$a${NODE_INTERNAL_IP}\t${NODE_NAME}.cluster" /etc/hosts
                # add other nodes and master node to the node's /etc/hosts
                for j in $(seq 0 ${#NODE_IPS[@]}); do
                        LINE=$(echo -ne "$(get_ip $j)\t$(get_cluster_name $j)")
                        ssh pi@${NODE_NAME} "echo '${LINE}' | sudo tee -a /etc/hosts > /dev/null"
                done

                # configure the LAN on the remote node with a static IP address
                ssh pi@${NODE_NAME} "echo -ne '\ninterface eth0\nstatic ip_address=${NODE_INTERNAL_IP}/${INTERNAL_NETMASK}' | sudo tee -a /etc/dhcpcd.conf > /dev/null"
                # enable the cgroup settings on the remote node
                ssh pi@${NODE_NAME} "sudo sed -i 's/rootwait/cgroup_memory=1 cgroup_enable=memory rootwait/' /boot/cmdline.txt"
                # update the OS on the remote node
                ssh pi@${NODE_NAME} "sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y install vim screen open-iscsi"
                # restart the remote node (after 1 minute)
                ssh pi@${NODE_NAME} "sudo shutdown -r 1"

        fi
done
