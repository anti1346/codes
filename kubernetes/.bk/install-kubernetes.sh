#!/bin/bash

###### 시스템 패키지 업데이트 및 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release curl

###### Docker GPG 키 추가 및 Docker 리포지토리 설정
sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

###### Containerd 설치
sudo apt-get update
sudo apt-get install -y containerd.io

###### containerd 설정 및 재시작
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl --now enable containerd

###### containerd CNI 플러그인 
CNI_VERSION="v1.5.1"
CNI_TGZ=https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
curl -fsSL $CNI_TGZ | sudo tar -C /opt/cni/bin -xz

###### Kubernetes GPG 키 추가 및 리포지토리 설정
KUBERNETES_VERSION="v1.27"
sudo mkdir -p -m 755 /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

###### Kubernetes 구성 요소 설치 및 고정
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl --now enable kubelet

###### Kubernetes 초기 설정
kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16


###### kubelet 설정 및 재시작
sudo systemctl daemon-reload; sudo systemctl restart kubelet
knode112, knode121, knode122