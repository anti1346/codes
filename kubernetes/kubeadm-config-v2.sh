#!/bin/bash

# 환경 변수 설정
LOAD_BALANCER_PUBLIC_IP="192.168.10.111"
K8S_API_SERVER_IP="192.168.10.111"

# kubeadm 설정 파일 생성
cat << EOF > kubeadmcfg.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${K8S_API_SERVER_IP}
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
controlPlaneEndpoint: "${K8S_API_SERVER_IP}:6443"
networking:
  podSubnet: "10.244.0.0/16"
etcd:
  external:
    endpoints:
    - https://${LOAD_BALANCER_PUBLIC_IP}:2379
    caFile: /etc/etcd/ssl/ca.crt
    certFile: /etc/etcd/ssl/peer.crt
    keyFile: /etc/etcd/ssl/peer.key
EOF

echo "sudo kubeadm init --config kubeadmcfg.yaml --upload-certs | tee $HOME/kubeadm_init_output.log"



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-config.sh -o kubeadm-config.sh
# chmod +x kubeadm-config.sh

