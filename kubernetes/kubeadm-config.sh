#!/bin/bash

# 환경 변수 설정
ETCD_NODE_1_HOSTNAME="node111"
ETCD_NODE_2_HOSTNAME="node112"
ETCD_NODE_3_HOSTNAME="node113"
ETCD_NODE_1_IP="192.168.10.111"
ETCD_NODE_2_IP="192.168.10.112"
ETCD_NODE_3_IP="192.168.10.113"

# Arrays to hold the hostnames and IP addresses
NODE_HOSTNAMES=(${ETCD_NODE_1_HOSTNAME} ${ETCD_NODE_2_HOSTNAME} ${ETCD_NODE_3_HOSTNAME})
NODE_IPS=(${ETCD_NODE_1_IP} ${ETCD_NODE_2_IP} ${ETCD_NODE_3_IP})

# Create directories for each node
for NODE_HOSTNAME in "${NODE_HOSTNAMES[@]}"; do
    mkdir -p "/tmp/${NODE_HOSTNAME}/"
done

# Generate kubeadm configuration files for each node
for i in "${!NODE_IPS[@]}"; do
    HOSTNAME=${NODE_HOSTNAMES[$i]}
    IP_ADDRESS=${NODE_IPS[$i]}
    
    cat << EOF > "/tmp/${HOSTNAME}/kubeadmcfg.yaml"
apiVersion: "kubeadm.k8s.io/v1beta2"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${IP_ADDRESS}"
        peerCertSANs:
        - "${IP_ADDRESS}"
        extraArgs:
            initial-cluster: ${NODE_HOSTNAMES[0]}=https://${NODE_IPS[0]}:2380,${NODE_HOSTNAMES[1]}=https://${NODE_IPS[1]}:2380,${NODE_HOSTNAMES[2]}=https://${NODE_IPS[2]}:2380
            initial-cluster-state: new
            name: ${HOSTNAME}
            listen-peer-urls: https://${IP_ADDRESS}:2380
            listen-client-urls: https://${IP_ADDRESS}:2379
            advertise-client-urls: https://${IP_ADDRESS}:2379
            initial-advertise-peer-urls: https://${IP_ADDRESS}:2380
EOF

done

echo "kubeadm init phase certs etcd-ca"
#echo "sudo kubeadm init --config kubeadmcfg.yaml --upload-certs | tee $HOME/kubeadm_init_output.log"



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubeadm-config.sh -o kubeadm-config.sh
# chmod +x kubeadm-config.sh

