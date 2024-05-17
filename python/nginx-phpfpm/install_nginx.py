import subprocess

def run_command(command):
    # subprocess.run()으로 명령어 실행하고 stdout, stderr를 분리하여 출력합니다.
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        # 명령어 실행 실패 시 에러 메시지 출력하고 종료합니다.
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        # 명령어 실행 성공 시 표준 출력을 출력합니다.
        print(result.stdout)

# 업데이트
run_command("sudo apt-get update")

# 필수 패키지 설치
required_packages = ["curl", "gnupg2", "ca-certificates", "lsb-release", "ubuntu-keyring", "apt-transport-https"]
for package in required_packages:
    run_command(f"sudo apt-get install -y {package}")

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
run_command("sudo apt-get install -y nginx")

# NGINX 버전 확인
run_command("nginx -v")

# NGINX 서비스 활성화 및 시작
run_command("sudo systemctl --now enable nginx")

# NGINX 상태 확인
run_command("sudo systemctl status nginx")

# nginx.conf 설정 추가
nginx_conf_path = "/etc/nginx/nginx.conf"
with open(nginx_conf_path, 'r') as file:
    nginx_conf = file.readlines()

http_index = next(i for i, line in enumerate(nginx_conf) if line.strip() == "http {")
server_block = """
    server_tokens off;
"""
nginx_conf.insert(http_index + 1, server_block)

with open(nginx_conf_path, 'w') as file:
    file.writelines(nginx_conf)

# default.conf 설정 추가
nginx_conf_default_path = "/etc/nginx/conf.d/default.conf"
with open(nginx_conf_default_path, 'r') as file:
    nginx_conf_default = file.readlines()

http_index = next(i for i, line in enumerate(nginx_conf_default) if line.strip() == "http {")
server_block = """
    server {
        listen       80;
        server_name  _;
        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }
        location /nginx_status {
            stub_status;
            access_log off;
            allow 127.0.0.1;
            allow 192.168.56.0/24;
            deny all;
        }
        location ~ /\.ht {
            deny  all;
        }
    }
"""
nginx_conf_default.insert(http_index + 1, server_block)

with open(nginx_conf_default_path, 'w') as file:
    file.writelines(nginx_conf_default)

# NGINX 설정 테스트
run_command("nginx -t")

# NGINX 재시작
run_command("sudo systemctl restart nginx")
