#!/bin/bash

# 환경 변수 설정
# .env 파일 로드
if [ -f ./config.env ]; then
  export $(grep -v '^#' config.env | xargs)
else
  echo "config.env 파일을 찾을 수 없습니다. 스크립트를 종료합니다."
  exit 1
fi

# kubeadm 설정 파일 생성
cat << EOF > kubeadmcfg.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${K8S_API_SERVER_IP}
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "192.168.0.0/16"
etcd:
  external:
    endpoints:
    - https://${LOAD_BALANCER_PUBLIC_IP}:2379
    caFile: /etc/etcd/ssl/ca.crt
    certFile: /etc/etcd/ssl/peer.crt
    keyFile: /etc/etcd/ssl/peer.key
EOF

echo "sudo kubeadm init --config kubeadmcfg.yaml --upload-certs"



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-config.sh -o kubeadm-config.sh
# chmod +x kubeadm-config.sh

