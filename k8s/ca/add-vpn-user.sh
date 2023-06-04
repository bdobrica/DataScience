#!/bin/bash

# based on:
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-debian-11

function with_srv {
  rm pki
  ln -s pki-srv pki
}

function with_ca {
  rm pki
  ln -s pki-ca pki
}

current_path=$(dirname $(realpath ${BASH_SOURCE[0]}))

cd "${current_path}"
cat "./user-list.txt" | while read client_name; do
  echo "${client_name}"

  echo " ... create request ... "
  with_srv
  cat << EOF | ./easyrsa gen-req "${client_name}" nopass
${client_name}
EOF

  echo " ... sign the request ..."
  with_ca
  ./easyrsa import-req "./pki-srv/reqs/${client_name}.req" "${client_name}"
  cat << EOF | ./easyrsa sign-req client "${client_name}"
yes
EOF
done