#!/bin/bash

# 시스템 패키지 업데이트 및 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release curl

# Docker GPG 키 추가 및 Docker 리포지토리 설정
sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Docker 및 containerd 설치
sudo apt-get update
sudo apt-get install -y containerd
# sudo apt-get install -y containerd.io

# containerd 설정 및 재시작
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
# cat /etc/containerd/config.toml | egrep SystemdCgroup
# sudo containerd config dump | egrep SystemdCgroup
# sudo systemctl status containerd
# sudo journalctl -u containerd -f


# containerd CNI 플러그인 
CNI_VERSION=v1.5.1
CNI_TGZ=https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-amd64-$CNI_VERSION.tgz
sudo mkdir -p /opt/cni/bin
curl -fsSL $CNI_TGZ | sudo tar -C /opt/cni/bin -xz

# # CNI 설정 파일
# sudo cat <<EOF> /etc/cni/net.d/10-bridge.conf 
# {
#   "cniVersion": "0.3.1",
#   "name": "my-bridge-network",
#   "type": "bridge",
#   "bridge": "cni0",
#   "isGateway": true,
#   "ipMasq": true,
#   "ipam": {
#     "type": "host-local",
#     "subnet": "10.22.0.0/16",
#     "routes": [
#       { "dst": "0.0.0.0/0" }
#     ]
#   }
# }
# EOF
# sudo systemctl restart containerd

# Kubernetes GPG 키 추가 및 리포지토리 설정
sudo mkdir -p -m 755 /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Kubernetes 구성 요소 설치 및 고정
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm init phase kubelet-start

# kubelet 설정 및 재시작
mkdir /etc/systemd/system/kubelet.service.d/
touch /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo 'KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///run/containerd/containerd.sock' | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet
# sudo systemctl status kubelet
# sudo journalctl -u kubelet -f
# sudo journalctl -u kubelet -n 100 --no-pager


#sudo update-alternatives --set iptables /usr/sbin/iptables-legacy

