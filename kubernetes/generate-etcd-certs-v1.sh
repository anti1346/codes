#!/bin/bash

set -e

export NAME1="node111"
export ADDRESS1="192.168.10.111"
export NAME2="node112"
export ADDRESS2="192.168.10.112"
export NAME3="node113"
export ADDRESS3="192.168.10.113"

export COUNTRY="KR"
export STATE="Seoul"
export LOCALITY="Jongno-gu"
export ORGANIZATION="SangChul Blog"
export ORGANIZATIONAL_UNIT="IT Department"
export COMMON_NAME="etcd"

SSL_DIR="/etc/kubernetes/pki/etcd"

# Create directories for storing certificates
mkdir -p ${SSL_DIR}

# 1. CA 인증서 생성
# CA 개인 키 생성
openssl genpkey -algorithm RSA -out ${SSL_DIR}/ca.key -pkeyopt rsa_keygen_bits:2048

# CA 인증서 생성
openssl req -x509 -new -nodes -key ${SSL_DIR}/ca.key -sha256 -days 3650 -out ${SSL_DIR}/ca.crt -subj "/CN=${COMMON_NAME}-ca/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}"

# 2. etcd 서버 인증서 생성
# 서버 개인 키 생성
openssl genpkey -algorithm RSA -out ${SSL_DIR}/server.key -pkeyopt rsa_keygen_bits:2048

# 서버 CSR 구성 파일 생성
cat <<EOF > etcd-server-csr.conf
[ req ]
default_bits       = 2048
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
CN = ${COMMON_NAME}-server

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = localhost
DNS.2   = ${NAME1}
DNS.3   = ${NAME2}
DNS.4   = ${NAME3}
IP.1    = 127.0.0.1
IP.2    = ${ADDRESS1}
IP.3    = ${ADDRESS2}
IP.4    = ${ADDRESS3}
EOF

# 서버 CSR 생성
openssl req -new -key ${SSL_DIR}/server.key -out ${SSL_DIR}/etcd-server.csr -config etcd-server-csr.conf

# 서버 인증서 생성
openssl x509 -req -in ${SSL_DIR}/etcd-server.csr -CA ${SSL_DIR}/ca.crt -CAkey ${SSL_DIR}/ca.key -CAcreateserial -out ${SSL_DIR}/server.crt -days 365 -sha256 -extensions req_ext -extfile etcd-server-csr.conf

# 3. etcd 피어 인증서 생성
# 피어 개인 키 생성
openssl genpkey -algorithm RSA -out ${SSL_DIR}/peer.key -pkeyopt rsa_keygen_bits:2048

# 피어 CSR 구성 파일 생성
cat <<EOF > etcd-peer-csr.conf
[ req ]
default_bits       = 2048
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
CN = ${COMMON_NAME}-peer

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = localhost
DNS.2   = ${NAME1}
DNS.3   = ${NAME2}
DNS.4   = ${NAME3}
IP.1    = 127.0.0.1
IP.2    = ${ADDRESS1}
IP.3    = ${ADDRESS2}
IP.4    = ${ADDRESS3}
EOF

# 피어 CSR 생성
openssl req -new -key ${SSL_DIR}/peer.key -out ${SSL_DIR}/etcd-peer.csr -config etcd-peer-csr.conf

# 피어 인증서 생성
openssl x509 -req -in ${SSL_DIR}/etcd-peer.csr -CA ${SSL_DIR}/ca.crt -CAkey ${SSL_DIR}/ca.key -CAcreateserial -out ${SSL_DIR}/peer.crt -days 365 -sha256 -extensions req_ext -extfile etcd-peer-csr.conf

# 4. 클라이언트 인증서 생성
# 클라이언트 개인 키 생성
openssl genpkey -algorithm RSA -out ${SSL_DIR}/healthcheck-client.key -pkeyopt rsa_keygen_bits:2048

# 클라이언트 CSR 구성 파일 생성
cat <<EOF > etcd-client-csr.conf
[ req ]
default_bits       = 2048
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
CN = ${COMMON_NAME}-client

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = localhost
DNS.2   = ${NAME1}
DNS.3   = ${NAME2}
DNS.4   = ${NAME3}
IP.1    = 127.0.0.1
IP.2    = ${ADDRESS1}
IP.3    = ${ADDRESS2}
IP.4    = ${ADDRESS3}
EOF

# 클라이언트 CSR 생성
openssl req -new -key ${SSL_DIR}/healthcheck-client.key -out ${SSL_DIR}/etcd-client.csr -config etcd-client-csr.conf

# 클라이언트 인증서 생성
openssl x509 -req -in ${SSL_DIR}/etcd-client.csr -CA ${SSL_DIR}/ca.crt -CAkey ${SSL_DIR}/ca.key -CAcreateserial -out ${SSL_DIR}/healthcheck-client.crt -days 365 -sha256 -extensions req_ext -extfile etcd-client-csr.conf

echo "모든 인증서가 생성되었습니다."



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/generate-etcd-certs.sh -o generate-etcd-certs.sh
# chmod +x generate-etcd-certs.sh

