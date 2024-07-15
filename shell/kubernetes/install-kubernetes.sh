#!/bin/bash

# 시스템 패키지 업데이트 및 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release curl

# Docker GPG 키 추가 및 Docker 리포지토리 설정
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Docker 및 containerd 설치
sudo apt-get update
sudo apt-get install -y containerd.io

# containerd 설정 및 재시작
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Kubernetes GPG 키 추가 및 리포지토리 설정
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Kubernetes 구성 요소 설치 및 고정
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# kubelet 설정 및 재시작
echo 'KUBELET_EXTRA_ARGS="--container-runtime-endpoint=unix:///run/containerd/containerd.sock"' | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy


##### Verify #####
# cat /etc/containerd/config.toml | egrep SystemdCgroup
# sudo containerd config dump | egrep SystemdCgroup
# sudo systemctl status containerd
# sudo journalctl -u containerd -f
# 
# sudo systemctl status kubelet
# sudo journalctl -u kubelet -f
# sudo journalctl -u kubelet -n 100 --no-pager
