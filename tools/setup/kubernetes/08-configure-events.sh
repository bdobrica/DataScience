#!/bin/bash

# get the AMQP URL
AMQP_USER="$(sudo kubectl get secret rabbitmq-tenant-1-default-user -n rabbitmq-tenant-1 -o jsonpath='{.data.username}' | base64 --decode)"
AMQP_PASS="$(sudo kubectl get secret rabbitmq-tenant-1-default-user -n rabbitmq-tenant-1 -o jsonpath='{.data.password}' | base64 --decode)"
AMQP_ADDR="$(sudo kubectl get service rabbitmq-tenant-1 -n rabbitmq-tenant-1 -o jsonpath='{.spec.clusterIP}')"
AMQP_URL="amqp://${AMQP_USER}:${AMQP_PASS}@${AMQP_ADDR}:5672"

# install js to query JSON files https://stedolan.github.io/jq/
sudo apt-get -y install jq

# get the minio access and secret keys from the tenant's credentials.json
S3_ACCESS_KEY=$(jq '.accessKey' credentials.json)
S3_SECRET_KEY=$(jq '.secretKey' credentials.json)

# setup mc, the minio CLI interface
mkdir -p ${HOME}/.mc/bin
wget https://dl.minio.io/client/mc/release/linux-$(uname -m | sed 's/aarch64/arm64/')/mc -O ${HOME}/.mc/bin/mc
chmod +x ${HOME}/.mc/bin/mc
MC=`${HOME}/.mc/bin/mc`

# configuring the CLI
${MC} config host add "${MINIO_TENANT}" http://localhost:9000 "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"

# https://min.io/docs/minio/linux/reference/minio-mc-admin/mc-admin-config.html?ref=docs-redirect
# configuring the SQSs
${MC} admin config set notify_amqp:${SQS_NAME} \
   url="${AMQP_URL}" \
   exchange="minio.exchange" \
   exchange_type="direct" \
   routing_key="minio.source" \
   durable="on" \
   no_wait="on" \
   delivery_mode=1

SQS_ARN="arn:minio:sqs::${SQS_NAME}:amqp"

${MC} admin service restart minio-tenant-1

# add the buckets 
# link the events
${MC} mb source
${MC} mb staged
${MC} mb prepared
${MC} event add --event "put" "${MINIO_TENANT}/source" "${SQS_ARN}"