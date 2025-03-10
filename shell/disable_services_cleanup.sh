#!/bin/bash

set -e  # 오류 발생 시 스크립트 중단

echo "[INFO] Checking required commands..."
for cmd in systemctl dpkg apt; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "[ERROR] $cmd 명령어가 필요합니다."; exit 1; }
done
echo "[INFO] All required commands are available."

# 중지 및 비활성화할 서비스 목록
SERVICES=(
    snapd.socket snapd.service snapd.seeded.service
    ModemManager multipathd.socket multipathd systemd-resolved
)

echo "[INFO] Disabling and stopping unnecessary services..."
for service in "${SERVICES[@]}"; do
    if systemctl list-units --full --all | grep -q "^$service"; then
        echo "[INFO] Stopping and disabling $service..."
        systemctl stop "$service" 2>/dev/null || echo "[WARNING] Failed to stop $service"
        systemctl disable "$service" 2>/dev/null || echo "[WARNING] Failed to disable $service"
        systemctl mask "$service" 2>/dev/null || echo "[WARNING] Failed to mask $service"
    else
        echo "[INFO] $service 서비스가 존재하지 않습니다. 건너뜁니다."
    fi
done
echo "[INFO] Services disabled successfully."

# 패키지 제거
echo "[INFO] Removing unnecessary packages..."
PACKAGES=(snapd modemmanager multipath-tools)
for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        echo "[INFO] Removing $package..."
        apt remove --purge -y "$package" || {
            echo "[WARNING] $package 제거 중 오류 발생. 강제 제거 시도 중..."
            dpkg --purge --force-all "$package"
        }
        apt autoremove -y
    else
        echo "[INFO] $package is not installed. Skipping..."
    fi
done
echo "[INFO] Package cleanup completed."

# systemd-resolved 비활성화 후 /etc/resolv.conf 설정
echo "[INFO] Configuring /etc/resolv.conf..."
if [ -L /etc/resolv.conf ]; then
    echo "[INFO] Removing existing /etc/resolv.conf symlink..."
    rm -f /etc/resolv.conf
fi

echo "[INFO] Creating new /etc/resolv.conf..."
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | tee /etc/resolv.conf
echo "[INFO] DNS configuration updated."

# 변경 사항 적용
echo "[INFO] Applying changes..."
systemctl daemon-reexec
echo "[INFO] System daemon reloaded."

echo "[INFO] All tasks completed successfully."
