#!/bin/bash

# 환경 변수 설정
MASTER_NODE_IP="192.168.0.131"
LOAD_BALANCER_DNS="192.168.0.130"
ETCD_NODE1_IP="192.168.0.131"
ETCD_NODE2_IP="192.168.0.132"
ETCD_NODE3_IP="192.168.0.111"

# kubeadm 설정 파일 생성
cat << EOF > kubeadmcfg.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${MASTER_NODE_IP}
  bindPort: 6443
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.27.0
controlPlaneEndpoint: "${LOAD_BALANCER_DNS}:2379"
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
  podSubnet: 192.168.0.0/16
etcd:
  external:
    endpoints:
    - https://${ETCD_NODE1_IP}:2379
    - https://${ETCD_NODE2_IP}:2379
    - https://${ETCD_NODE3_IP}:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/etcd/peer.crt
    keyFile: /etc/kubernetes/pki/etcd/peer.key
EOF



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-config.sh -o kubeadm-config.sh
# chmod +x kubeadm-config.sh

