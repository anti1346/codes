#!/bin/bash

set -e

SSL_DIR="/etc/kubernetes/pki/etcd"
CERT_DAYS=3650
KEY_BITS=2048

# Create directories for storing certificates
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
C  = KR
ST = Seoul
L  = Jongno-gu
O  = SangChul Blog
OU = IT Department
CN = etcd-${type}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = localhost
DNS.2   = node111
DNS.3   = node112
DNS.4   = node113
IP.1    = 127.0.0.1
IP.2    = 192.168.10.111
IP.3    = 192.168.10.112
IP.4    = 192.168.10.113
EOF
}

# 1. CA 인증서 생성
# CA 개인 키 생성
openssl genpkey -algorithm RSA -out ${SSL_DIR}/ca.key -pkeyopt rsa_keygen_bits:${KEY_BITS}
chmod 600 ${SSL_DIR}/ca.key

# CA 인증서 생성
openssl req -x509 -new -nodes -key ${SSL_DIR}/ca.key -sha256 -days ${CERT_DAYS} -out ${SSL_DIR}/ca.crt -subj "/CN=etcd-ca/O=SangChul Blog/OU=IT Department"

create_cert() {
  local name=$1
  local config_file=${SSL_DIR}/etcd-${name}-csr.conf

  # 개인 키 생성
  openssl genpkey -algorithm RSA -out ${SSL_DIR}/${name}.key -pkeyopt rsa_keygen_bits:${KEY_BITS}
  chmod 600 ${SSL_DIR}/${name}.key

  # CSR 구성 파일 생성 및 CSR 생성
  generate_csr_conf ${name} > ${config_file}
  openssl req -new -key ${SSL_DIR}/${name}.key -out ${SSL_DIR}/etcd-${name}.csr -config ${config_file}

  # 인증서 생성
  openssl x509 -req -in ${SSL_DIR}/etcd-${name}.csr -CA ${SSL_DIR}/ca.crt -CAkey ${SSL_DIR}/ca.key -CAcreateserial -out ${SSL_DIR}/${name}.crt -days ${CERT_DAYS} -sha256 -extensions req_ext -extfile ${config_file}
  chmod 644 ${SSL_DIR}/${name}.crt
}

# 2. etcd 서버 인증서 생성
create_cert server

# 3. etcd 피어 인증서 생성
create_cert peer

# 4. 클라이언트 인증서 생성
create_cert healthcheck-client

echo "모든 인증서가 생성되었습니다."
