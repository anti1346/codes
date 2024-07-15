#!/bin/bash

# 방화벽 중지 및 비활성화
sudo systemctl stop ufw
sudo systemctl disable ufw

# 스왑 비활성화
sudo swapoff -a
sudo sed -i '/\/swap\.img[[:space:]]\+none[[:space:]]\+swap[[:space:]]\+sw[[:space:]]\+0[[:space:]]\+0/s/^/#/' /etc/fstab

# 필요한 커널 모듈 로드
sudo tee /etc/modules-load.d/k8s.conf > /dev/null <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 네트워크 설정
sudo tee /etc/sysctl.d/k8s.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# 네트워크 설정 적용
sudo sysctl --system

# 시스템 재기동
# reboot

# systemctl status ufw
# swapon -s
# lsmod | grep "overlay\|br_netfilter"
