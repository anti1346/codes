#!/usr/bin/env python3

import subprocess

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        print(result.stdout)

# NGINX 서비스 비활성화 및 중지
run_command("sudo systemctl disable nginx")
run_command("sudo systemctl stop nginx")

# NGINX 패키지 제거
run_command("sudo apt-get purge -y nginx nginx-common nginx-full")

# 사용하지 않는 패키지 제거
run_command("sudo apt-get autoremove")

# NGINX 설정 및 로그 디렉토리 제거
run_command("sudo rm -rf /etc/nginx")
run_command("sudo rm -rf /var/log/nginx")
run_command("sudo rm -rf /var/www/html")

# 잔여 패키지 제거
run_command("sudo dpkg --purge $(dpkg -l | awk '/^rc/ { print $2 }')")

