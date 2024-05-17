import os
import subprocess
import datetime

def run_command(command):
    """명령어를 실행하고 결과를 출력합니다."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        print(result.stdout)

def install_packages(packages):
    """주어진 패키지들을 설치합니다."""
    for package in packages:
        run_command(f"sudo apt-get install -y {package}")

# 업데이트
run_command("sudo apt-get update")

# 필수 패키지 설치
required_packages = ["curl", "gnupg2", "ca-certificates", "lsb-release", "ubuntu-keyring", "apt-transport-https"]
install_packages(required_packages)

# NGINX 키 설치
run_command("curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null")

# 키 확인
run_command("gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg")

# NGINX 저장소 추가
lsb_release = subprocess.run("lsb_release -cs", shell=True, capture_output=True, text=True).stdout.strip()
nginx_repo_command = f'echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu {lsb_release} nginx" | sudo tee /etc/apt/sources.list.d/nginx.list'
run_command(nginx_repo_command)

# 업데이트
run_command("sudo apt-get update")

# NGINX 설치
install_packages(["nginx"])

# NGINX 버전 확인
run_command("nginx -v")

# NGINX 서비스 활성화 및 시작
run_command("sudo systemctl --now enable nginx")

# NGINX 상태 확인
run_command("sudo systemctl status nginx")

# NGINX 설정 파일 백업
now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
run_command(f"sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_{now}")
run_command(f"sudo cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf_{now}")

# NGINX 설정 추가
#############################################################################
nginx_conf_content = """
user www-data www-data;
worker_processes auto;

pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    server_tokens off;

    sendfile on;
    keepalive_timeout 65;
    
    gzip on;

    include /etc/nginx/conf.d/*.conf;
}
"""
with open('/etc/nginx/nginx.conf', 'w') as file:
    file.write(nginx_conf_content)
print("Configuration file '/etc/nginx/nginx.conf' created.")

# default.conf 설정 추가
#############################################################################
nginx_conf_default_content = """
server {
    listen 80;
    server_name _;
    
    access_log /var/log/nginx/default-access.log main;
    error_log /var/log/nginx/default-error.log;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
    
    location /nginx_status {
        stub_status;
        access_log off;
        allow 127.0.0.1;
        allow 0.0.0.0/0;
        deny all;
    }
    
    location ~ /\.ht {
        deny  all;
    }
}
"""
with open('/etc/nginx/conf.d/default.conf', 'w') as file:
    file.write(nginx_conf_default_content)
print("Configuration file '/etc/nginx/conf.d/default.conf' created.")

# NGINX 설정 테스트
run_command("nginx -t")

# NGINX 재시작
run_command("sudo systemctl restart nginx")

# Test 파일 생성
hostname = os.getenv('HOSTNAME', 'Unknown')
with open('/usr/share/nginx/html/test.html', 'w') as file:
    file.write(hostname)
print(f"Hostname '{hostname}' written to '/usr/share/nginx/html/test.html'")

# curl 명령어를 통한 nginx 상태 확인
run_command("curl http://localhost/nginx_status")

print("Nginx 설치가 완료되었습니다.")
