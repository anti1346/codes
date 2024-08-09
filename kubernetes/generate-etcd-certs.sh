#!/bin/bash

set -e

# .env 파일 로드
if [ -f ./config.env ]; then
  export $(grep -v '^#' config.env | xargs -d '\n')
else
  echo "config.env 파일을 찾을 수 없습니다. 스크립트를 종료합니다."
  exit 1
fi

COUNTRY="KR"
STATE="Seoul"
LOCALITY="Jongno-gu"
ORGANIZATION="SangChul Blog"
ORGANIZATIONAL_UNIT="IT Department"
COMMON_NAME="etcd"

CSR_DIR="csr"
SSL_DIR="ssl"
CA_CERT_DAYS=3650
CERT_DAYS=3650
KEY_BITS=2048

# Create directories for storing certificates
mkdir -p ${CSR_DIR}
mkdir -p ${SSL_DIR}

generate_csr_conf() {
  local type=$1
  cat <<EOF
[ req ]
default_bits       = ${KEY_BITS}
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
C  = ${COUNTRY}
ST = ${STATE}
L  = ${LOCALITY}
O  = ${ORGANIZATION}
OU = ${ORGANIZATIONAL_UNIT}
CN = ${COMMON_NAME}-${type}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = localhost
DNS.2   = ${ETCD_NODE_1_HOSTNAME}
DNS.3   = ${ETCD_NODE_2_HOSTNAME}
DNS.4   = ${ETCD_NODE_3_HOSTNAME}
IP.1    = 127.0.0.1
IP.2    = ${ETCD_NODE_1_IP}
IP.3    = ${ETCD_NODE_2_IP}
IP.4    = ${ETCD_NODE_3_IP}
EOF
}

# 1. CA 인증서 생성
# CA 개인 키 생성
openssl genpkey -algorithm RSA -out ${SSL_DIR}/ca.key -pkeyopt rsa_keygen_bits:${KEY_BITS}

# CA 인증서 생성
openssl req -x509 -new -nodes -key ${SSL_DIR}/ca.key -sha256 -days ${CA_CERT_DAYS} -out ${SSL_DIR}/ca.crt -subj "/CN=etcd-ca/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}"

create_cert() {
    local name=$1
    local config_file=${CSR_DIR}/etcd-${name}-csr.conf

    # 개인 키 생성
    openssl genpkey -algorithm RSA -out ${SSL_DIR}/${name}.key -pkeyopt rsa_keygen_bits:${KEY_BITS}

    # CSR 구성 파일 생성 및 CSR 생성
    generate_csr_conf ${name} > ${config_file}
    openssl req -new -key ${SSL_DIR}/${name}.key -out ${CSR_DIR}/etcd-${name}.csr -config ${config_file}

    # 인증서 생성
    openssl x509 -req -in ${CSR_DIR}/etcd-${name}.csr -CA ${SSL_DIR}/ca.crt -CAkey ${SSL_DIR}/ca.key -CAcreateserial -out ${SSL_DIR}/${name}.crt -days ${CERT_DAYS} -sha256 -extensions req_ext -extfile ${config_file}

    # CSR 파일 삭제 (선택 사항)
    rm -f ${CSR_DIR}/etcd-${name}.csr

    # KEY, CRT 파일 권한 설정
    chmod 600 ${SSL_DIR}/*.key
    chmod 644 ${SSL_DIR}/*.crt
}

# 2. etcd 서버 인증서 생성
create_cert server

# 3. etcd 피어 인증서 생성
create_cert peer

# 4. 클라이언트 인증서 생성
create_cert healthcheck-client

echo "모든 인증서가 생성되었습니다."



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/generate-etcd-certs.sh -o generate-etcd-certs.sh
# chmod +x generate-etcd-certs.sh

