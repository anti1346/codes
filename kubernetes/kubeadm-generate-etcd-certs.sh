#!/bin/bash

# 환경 변수 설정
ETCD_NODE_1_HOSTNAME="node111"
ETCD_NODE_2_HOSTNAME="node112"
ETCD_NODE_3_HOSTNAME="node113"
ETCD_NODE_1_IP="192.168.10.111"
ETCD_NODE_2_IP="192.168.10.112"
ETCD_NODE_3_IP="192.168.10.113"

NODE_HOSTNAMES=(${ETCD_NODE_1_HOSTNAME} ${ETCD_NODE_2_HOSTNAME} ${ETCD_NODE_3_HOSTNAME})

# 주어진 노드에 대한 etcd 인증서를 생성하는 함수
generate_etcd_certs() {
    local NODE=$1
    echo "Generating certificates for ${NODE}..."
    
    kubeadm init phase certs etcd-server --config="tmp/${NODE}/kubeadmcfg.yaml"
    kubeadm init phase certs etcd-peer --config="tmp/${NODE}/kubeadmcfg.yaml"
    kubeadm init phase certs etcd-healthcheck-client --config="tmp/${NODE}/kubeadmcfg.yaml"
    kubeadm init phase certs apiserver-etcd-client --config="tmp/${NODE}/kubeadmcfg.yaml"
    
    if [[ ${NODE} != ${ETCD_NODE_1_HOSTNAME} ]]; then
        echo "Copying certificates to tmp/${NODE}..."
        cp -R /etc/kubernetes/pki "tmp/${NODE}/"
        
        echo "Cleaning up sensitive files from /etc/kubernetes/pki..."
        find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
    fi
}

# 각 노드에 대한 인증서 생성
for NODE in "${NODE_HOSTNAMES[@]}"; do
    generate_etcd_certs ${NODE}
done

# 보조 노드에서 민감한 파일 정리
for NODE in "${NODE_HOSTNAMES[@]:1}"; do
    echo "Deleting ca.key from tmp/${NODE}..."
    find "tmp/${NODE}" -name ca.key -type f -delete
done

echo "인증서 생성 및 정리가 성공적으로 완료되었습니다."



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-generate-etcd-certs.sh -o kubeadm-generate-etcd-certs.sh
# chmod +x kubeadm-generate-etcd-certs.sh

