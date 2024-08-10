#!/bin/bash

# 환경 변수 설정
ETCD_ENDPOINT_IP="192.168.10.111"
K8S_API_SERVER_IP="192.168.10.111"

ETCD_NODE_1_HOSTNAME="node111"
ETCD_NODE_2_HOSTNAME="node112"
ETCD_NODE_3_HOSTNAME="node113"
ETCD_NODE_1_IP="192.168.10.111"
ETCD_NODE_2_IP="192.168.10.112"
ETCD_NODE_3_IP="192.168.10.113"

K8S_NODE_1_HOSTNAME="node111"
K8S_NODE_2_HOSTNAME="node112"
K8S_NODE_3_HOSTNAME="node113"
K8S_NODE_1_IP="192.168.10.111"
K8S_NODE_2_IP="192.168.10.112"
K8S_NODE_3_IP="192.168.10.113"

WORKDIR="$HOME/kubernetes_work_directory"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 호스트 이름과 IP 주소를 보유하는 배열
NODE_HOSTNAMES=(${ETCD_NODE_1_HOSTNAME} ${ETCD_NODE_2_HOSTNAME} ${ETCD_NODE_3_HOSTNAME})
NODE_IPS=(${ETCD_NODE_1_IP} ${ETCD_NODE_2_IP} ${ETCD_NODE_3_IP})

# 각 노드에 대한 디렉터리 생성
for NODE_HOSTNAME in "${NODE_HOSTNAMES[@]}"; do
    mkdir -p "${WORKDIR}/tmp/${NODE_HOSTNAME}/"
done

# 각 노드에 대한 kubeadm 구성 파일 생성
for i in "${!NODE_IPS[@]}"; do
    HOSTNAME=${NODE_HOSTNAMES[$i]}
    IP_ADDRESS=${NODE_IPS[$i]}
    
    cat << EOF > "${WORKDIR}/tmp/${HOSTNAME}/kubeadmcfg.yaml"
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: InitConfiguration
localAPIEndpoint:
    advertiseAddress: ${K8S_API_SERVER_IP}
    bindPort: 6443
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: ClusterConfiguration
networking:
    podSubnet: "10.244.0.0/16"
etcd:
    external:
        endpoints:
            - https://${ETCD_ENDPOIN_IP}:2379
        caFile: /etc/etcd/ssl/ca.crt
        certFile: /etc/etcd/ssl/peer.crt
        keyFile: /etc/etcd/ssl/peer.key
EOF

done

echo "kubeadm init phase certs etcd-ca"
#echo "sudo kubeadm init --config kubeadmcfg.yaml --upload-certs | tee $HOME/kubeadm_init_output.log"



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-config.sh -o kubeadm-config.sh
# chmod +x kubeadm-config.sh

