#!/bin/bash

set -e  # 오류 발생 시 스크립트 중단

# 필요한 명령어가 있는지 확인
echo "Checking required commands..."
command -v systemctl >/dev/null 2>&1 || { echo "[ERROR] systemctl 명령어가 필요합니다."; exit 1; }
command -v dpkg >/dev/null 2>&1 || { echo "[ERROR] dpkg 명령어가 필요합니다."; exit 1; }
command -v apt >/dev/null 2>&1 || { echo "[ERROR] apt 명령어가 필요합니다."; exit 1; }

echo "All required commands are available."

# 중지 및 비활성화할 서비스 목록
SERVICES=(snapd ModemManager systemd-resolved)

echo "Disabling and stopping unnecessary services..."
# 서비스 중지 및 비활성화
for service in "${SERVICES[@]}"; do
    if systemctl list-units --full --all | grep -q "^$service"; then
        echo "Stopping and disabling $service..."
        systemctl stop "$service" 2>/dev/null || true  # 오류 발생해도 무시
        systemctl disable "$service" 2>/dev/null || true
        systemctl mask "$service" 2>/dev/null || true  # 서비스가 다시 실행되지 않도록 마스킹
    else
        echo "$service 서비스가 존재하지 않습니다. 건너뜁니다."
    fi
done

echo "Services disabled successfully."

# multipathd 비활성화 및 제거
echo "Disabling and removing multipathd..."
systemctl disable --now multipathd.socket 2>/dev/null || true
systemctl disable --now multipathd 2>/dev/null || true
apt remove --purge -y multipath-tools
apt autoremove -y
echo "Multipathd removed successfully."

# 패키지 제거
echo "Removing unnecessary packages..."
PACKAGES=(snapd modemmanager)
for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        echo "Removing $package..."
        apt remove --purge -y "$package" || {
            echo "[WARNING] $package 제거 중 오류 발생. 강제 제거 시도 중..."
            dpkg --purge --force-all "$package"
        }
    else
        echo "$package is not installed. Skipping..."
    fi
done
echo "Package cleanup completed."

# systemd-resolved 비활성화 후 /etc/resolv.conf 설정
echo "Configuring /etc/resolv.conf..."
if [ -L /etc/resolv.conf ]; then
    echo "Removing existing /etc/resolv.conf symlink..."
    rm -f /etc/resolv.conf
fi

echo "Creating new /etc/resolv.conf..."
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | tee /etc/resolv.conf
echo "DNS configuration updated."

# 변경 사항 적용
echo "Applying changes..."
systemctl daemon-reexec
echo "System daemon reloaded."

echo "All tasks completed successfully."