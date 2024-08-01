#!/bin/bash

set -e

cat <<EOF | sudo tee kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "192.168.10.111"
  bindPort: 6443
nodeRegistration:
  name: "node111"
  kubeletExtraArgs:
    node-labels: "node-role.kubernetes.io/master="
  criSocket: "/var/run/containerd/containerd.sock"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: "kubernetes"
kubernetesVersion: "v1.27.0"
controlPlaneEndpoint: "192.168.10.111:6443"
apiServer:
  certSANs:
  - "192.168.10.111"
  - "192.168.10.112"
  - "192.168.10.113"
  - "node111"
  - "node112"
  - "node113"
etcd:
  external:
    endpoints:
    - https://192.168.10.111:2379
    - https://192.168.10.112:2379
    - https://192.168.10.113:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/etcd/healthcheck-client.crt
    keyFile: /etc/kubernetes/pki/etcd/healthcheck-client.key
networking:
  podSubnet: "10.244.0.0/16"
EOF

kubeadm init --config kubeadm-config.yaml