#!/bin/bash

# 에러 발생 시 스크립트 중단
#set -e

# systemd 데몬 다시 로드 및 kubelet, containerd 서비스 중지
sudo systemctl daemon-reload
sudo systemctl stop kubelet || true
sudo systemctl stop containerd || true
sudo systemctl disable kubelet || true
sudo systemctl disable containerd || true

# 시스템 부팅 시간 확인 (초 단위로 변환)
uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
uptime_minutes=$((uptime_seconds / 60))

if [ "$uptime_minutes" -lt 10 ]; then
    echo "시스템 부팅 시간이 10분 미만이므로 재부팅을 건너뜁니다."
else
    # 시스템 재부팅 여부 확인 및 재부팅
    read -p "시스템을 재부팅하시겠습니까? (y/n): " reboot_choice
    if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
        echo "시스템을 재부팅합니다..."
        sudo reboot
    else
        echo "스크립트가 완료되었습니다. 시스템이 재부팅되지 않았습니다."
    fi
fi

# 쿠버네티스 관련 패키지 제거
k8s_packages=("kubeadm" "kubelet" "kubectl" "kubernetes-cni" "kube*")
sudo apt-get purge -y --allow-change-held-packages "${k8s_packages[@]}"

# containerd 및 관련 패키지 제거
cri_packages=("containerd" "containerd.io" "docker-ce" "docker-ce-cli")
sudo apt-get purge -y "${cri_packages[@]}" 

sudo apt-get autoremove -y

# 쿠버네티스 관련 디렉토리 및 파일 제거
sudo rm -rf ~/.kube
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/dockershim
sudo rm -rf /var/lib/cni
sudo rm -rf /var/log/pods
sudo rm -rf /usr/libexec/kubernetes

# containerd 관련 디렉토리 및 파일 제거
sudo rm -rf /etc/cni
sudo rm -rf /etc/containerd
sudo rm -rf /opt/cni
sudo rm -rf /opt/containerd
sudo rm -rf /var/lib/containerd
sudo rm -rf /var/log/containers

# systemd 서비스 파일 삭제
sudo rm -rf /etc/systemd/system/kubelet.service.d
sudo rm -rf /etc/systemd/system/kubelet.service
sudo rm -rf /etc/systemd/system/containerd.service

# Kubernetes APT 저장소 및 키 제거
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# APT 캐시 정리
sudo apt-get clean

echo "Kubernetes 및 containerd가 성공적으로 제거되었습니다."
