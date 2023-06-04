 #!/bin/bash

function display_help {
    echo "Usage: $0 hostname"
    exit 0
}

function parse_args {
    while getopts "h" opt; do
        case $opt in
            h)
                display_help
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
        esac
    done
}

function create_root_ca {
    openssl genrsa -out rootCA.key 4096
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt -config rootCA.conf
}

HOST="$1"

if [ -z "${HOST}" ]; then
    echo "Error! Expected: $0 hostname"
    exit 1
fi

cat << EOF > "$HOST.csr.conf"
[ req ]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = RO
ST = Bucharest
L = Bucharest
O = 3NanoSAE
OU = 3NanoSAE R&D
CN = minio.intranet

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${HOST}.intranet
DNS.2 = www.${HOST}.intranet
IP.1 = 172.16.0.1
IP.2 = 172.16.0.2

EOF

cat << EOF > "${HOST}.cert.conf"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOST}.intranet
DNS.2 = www.${HOST}.intranet
IP.1 = 172.16.0.1
IP.2 = 172.16.0.2

EOF

openssl genrsa -out ${HOST}.key 4096
openssl req -new -key ${HOST}.key -out ${HOST}.csr -config ${HOST}.csr.conf
openssl x509 -req -in ${HOST}.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out ${HOST}.crt -days 365 -sha256 -extfile ${HOST}.cert.conf


HOST_CRT=$(cat $HOST.crt | base64 | tr -d "\n")
HOST_KEY=$(cat $HOST.key | base64 | tr -d "\n")

echo "  tls.crt: ${HOST_CRT}" > $HOST.yaml
echo "  tls.key: ${HOST_KEY}" >> $HOST.yaml
