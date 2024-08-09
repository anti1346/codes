#!/bin/bash

# 환경 변수 설정
LOAD_BALANCER_DNS="192.168.0.130"

# kubeadm 설정 파일 생성
cat << EOF > kubeadmcfg.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${LOAD_BALANCER_DNS}
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "192.168.0.0/16"
etcd:
  external:
    endpoints:
    - https://${LOAD_BALANCER_DNS}:2379
    caFile: /etc/etcd/ssl/ca.crt
    certFile: /etc/etcd/ssl/peer.crt
    keyFile: /etc/etcd/ssl/peer.key
EOF



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-config.sh -o kubeadm-config.sh
# chmod +x kubeadm-config.sh

