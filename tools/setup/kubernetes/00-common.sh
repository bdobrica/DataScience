#!/bin/bash

if [ "${0#*\/}" == "00-common.sh" ]; then
    echo "this is a configuration file. do not run it directly!"
    exit 0
fi

QUAY_USER=""
QUAY_PASS=""

MASTER_NAME="clusterpi"
MASTER_INTERNAL_IP="192.168.99.1/24" # some IP address space
NODE_IPS=( "" ) # fill in the IPs for the additional nodes

MASTER_EXTERNAL_IP=$(ip addr show | grep wlan0 | grep inet | awk '{print $2}')
MASTER_EXTERNAL_ROUTE=$(ip route show | grep default | awk '{print $3}')
NAME_SERVERS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | tr '\n' ' ')

INTERNAL_NETMASK=${MASTER_INTERNAL_IP#*\/}

function get_ip(){
        if [ "$1" -eq "0" ]; then
                echo ${MASTER_INTERNAL_IP}
        else
                PREFIX="${MASTER_INTERNAL_IP%\.[0-9]*}"
                echo "${PREFIX}.$[$1+1]"
        fi
}
function get_name(){
        if [ "$1" -eq "0" ]; then
                echo "${MASTER_NAME}"
        else
                echo "node$(printf "%02d" $1)pi"
        fi
}
function get_cluster_name(){
        echo "$(get_name $1).cluster"
}