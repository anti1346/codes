#!/bin/bash

set -e

# .env 파일 로드
if [ -f ./config.env ]; then
  source ./config.env
else
  echo "config.env 파일을 찾을 수 없습니다. 스크립트를 종료합니다."
  exit 1
fi

ETCD_CERT_DIR="/etc/etcd/ssl"
ETCD_DATA="/var/lib/etcd"

generate_etcd_config() {
  local NODE_NAME=$1
  local NODE_IP=$2

  sudo tee ${NODE_NAME}.conf > /dev/null <<EOF
ETCD_NAME="${NODE_NAME}"
ETCD_DATA_DIR="${ETCD_DATA}"
ETCD_LISTEN_PEER_URLS="https://${NODE_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="https://${NODE_IP}:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://${NODE_IP}:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${NODE_IP}:2380"
ETCD_INITIAL_CLUSTER="${ETCD_NODE_1_HOSTNAME}=https://${ETCD_NODE_1_IP}:2380,${ETCD_NODE_2_HOSTNAME}=https://${ETCD_NODE_2_IP}:2380,${ETCD_NODE_3_HOSTNAME}=https://${ETCD_NODE_3_IP}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

ETCD_TRUSTED_CA_FILE="${ETCD_CERT_DIR}/ca.crt"
ETCD_CERT_FILE="${ETCD_CERT_DIR}/server.crt"
ETCD_KEY_FILE="${ETCD_CERT_DIR}/server.key"
ETCD_CLIENT_CERT_AUTH="true"

ETCD_PEER_TRUSTED_CA_FILE="${ETCD_CERT_DIR}/ca.crt"
ETCD_PEER_CERT_FILE="${ETCD_CERT_DIR}/peer.crt"
ETCD_PEER_KEY_FILE="${ETCD_CERT_DIR}/peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
EOF

  echo "Configuration for ${NODE_NAME}.conf has been created at /etc/default/etcd"
}

# 각 노드에 대해 설정 파일 생성
generate_etcd_config "${ETCD_NODE_1_HOSTNAME}" "${ETCD_NODE_1_IP}"
generate_etcd_config "${ETCD_NODE_2_HOSTNAME}" "${ETCD_NODE_2_IP}"
generate_etcd_config "${ETCD_NODE_3_HOSTNAME}" "${ETCD_NODE_3_IP}"

echo "etcd 설정 파일이 모두 생성되었습니다."



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/generate-etcd-config.sh -o generate-etcd-config.sh
# chmod +x generate-etcd-config.sh

