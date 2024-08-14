#!/bin/bash

# 에러 발생 시 스크립트 중단
# set -e

# UFW 비활성화 및 중지
sudo systemctl disable --now ufw || echo "UFW가 이미 비활성화되어 있거나 중지되어 있습니다."

# 스왑 비활성화 및 fstab 수정
sudo swapoff -a
sudo sed -i '/\s*swap\s*/ s/^/#/' /etc/fstab

# 필요한 커널 모듈 로드 및 설정
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 네트워크 설정 적용
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# 재부팅 여부 확인 및 재부팅
read -p "시스템을 재부팅하시겠습니까? (y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "시스템을 재부팅합니다..."
    sudo reboot
else
    echo "스크립트가 완료되었습니다. 시스템이 재부팅되지 않았습니다."
fi



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/k8s_system_setup -o k8s_system_setup.sh
# chmod +x k8s_system_setup.sh
# bash k8s_system_setup.sh
