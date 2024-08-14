#!/bin/bash

# 에러 발생 시 스크립트 중단
# set -e

# 쿠버네티스 버전 설정
KUBERNETES_VERSION="v1.30"

# NTP 설치 및 시작
sudo apt-get install -y ntp
sudo systemctl enable --now ntp
ntpq -p

# 기본 패키지 설치
sudo apt-get update
sudo apt-get install -y gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release curl

# Containerd 설치
sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -y -o /etc/apt/trusted.gpg.d/docker.gpg
echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get install -y containerd.io
sudo systemctl enable --now containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Kubernetes APT 저장소 설정
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

echo "Kubernetes 및 Containerd 설치가 완료되었습니다."



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/k8s_install.sh -o k8s_install.sh
# chmod +x k8s_install.sh
# bash k8s_install.sh
