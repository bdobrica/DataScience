#!/bin/bash
source common.sh

curl -sfL https://get.k3s.io | sh -

for i in ${!NODE_IPS[@]}; do
        NODE_IP=${NODE_IPS[$i]}
        i=$[$i+1]
        NODE_NAME=$(get_name $i)
        NODE_INTERNAL_IP=$(get_ip $i)
        NODE_NETMASK=${MASTER_INTERNAL_IP#*\/}
        echo "${NODE_NAME} -> ${NODE_IP} ${NODE_INTERNAL_IP}"


        if ( ! grep -q "${NODE_IP}" /etc/hosts ); then
                sudo sed -i -e "\$a${NODE_IP}\t${NODE_NAME}" /etc/hosts
                ssh-copy-id pi@${NODE_IP}
        fi

        if ( ! grep -q "${NODE_INTERNAL_IP}" /etc/hosts ); then
                sudo sed -i -e "\$a${NODE_INTERNAL_IP}\t${NODE_NAME}.cluster" /etc/hosts
                for j in $(seq 0 ${#NODE_IPS[@]}); do
                        LINE=$(echo -ne "$(get_ip $j)\t$(get_cluster_name $j)")
                        ssh pi@${NODE_NAME} "echo '${LINE}' | sudo tee -a /etc/hosts > /dev/null"
                done

                ssh pi@${NODE_NAME} "echo -ne '\ninterface eth0\nstatic ip_address=${NODE_INTERNAL_IP}/${NODE_NETMASK}' | sudo tee -a /etc/dhcpcd.conf > /dev/null"
                ssh pi@${NODE_NAME} "sudo sed -i 's/rootwait/cgroup_memory=1 cgroup_enable=memory rootwait/' /boot/cmdline.txt"
                ssh pi@${NODE_NAME} "sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y install vim screen"
                ssh pi@${NODE_NAME} "sudo shutdown -r 1"

        fi
done
