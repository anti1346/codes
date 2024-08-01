cat <<EOF | sudo tee /etc/default/etcd
ETCD_NAME="node111"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.10.111:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.111:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.111:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.111:2380"
ETCD_INITIAL_CLUSTER="node111=https://192.168.10.111:2380,node112=https://192.168.10.112:2380,node113=https://192.168.10.113:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

ETCD_TRUSTED_CA_FILE="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT_FILE="/etc/kubernetes/pki/etcd/server.crt"
ETCD_KEY_FILE="/etc/kubernetes/pki/etcd/server.key"
ETCD_CLIENT_CERT_AUTH="true"

ETCD_PEER_TRUSTED_CA_FILE="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_PEER_CERT_FILE="/etc/kubernetes/pki/etcd/peer.crt"
ETCD_PEER_KEY_FILE="/etc/kubernetes/pki/etcd/peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
EOF



cat <<EOF | sudo tee /etc/default/etcd
ETCD_NAME="node112"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.10.112:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.112:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.112:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.112:2380"
ETCD_INITIAL_CLUSTER="node111=https://192.168.10.111:2380,node112=https://192.168.10.112:2380,node113=https://192.168.10.113:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

ETCD_TRUSTED_CA_FILE="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT_FILE="/etc/kubernetes/pki/etcd/server.crt"
ETCD_KEY_FILE="/etc/kubernetes/pki/etcd/server.key"
ETCD_CLIENT_CERT_AUTH="true"

ETCD_PEER_TRUSTED_CA_FILE="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_PEER_CERT_FILE="/etc/kubernetes/pki/etcd/peer.crt"
ETCD_PEER_KEY_FILE="/etc/kubernetes/pki/etcd/peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
EOF



cat <<EOF | sudo tee /etc/default/etcd
ETCD_NAME="node113"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.10.113:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.113:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.113:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.113:2380"
ETCD_INITIAL_CLUSTER="node111=https://192.168.10.111:2380,node112=https://192.168.10.112:2380,node113=https://192.168.10.113:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

ETCD_TRUSTED_CA_FILE="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT_FILE="/etc/kubernetes/pki/etcd/server.crt"
ETCD_KEY_FILE="/etc/kubernetes/pki/etcd/server.key"
ETCD_CLIENT_CERT_AUTH="true"

ETCD_PEER_TRUSTED_CA_FILE="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_PEER_CERT_FILE="/etc/kubernetes/pki/etcd/peer.crt"
ETCD_PEER_KEY_FILE="/etc/kubernetes/pki/etcd/peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
EOF


###########################################################################################################################################

chown -R etcd.etcd /etc/kubernetes/pki/etcd


sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chown -R etcd:etcd /var/lib/etcd
sudo chown -R etcd:etcd /etc/etcd
sudo chmod -R 700 /var/lib/etcd






