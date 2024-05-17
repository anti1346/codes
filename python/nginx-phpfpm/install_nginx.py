import subprocess

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        print(result.stdout)

# 업데이트
run_command("sudo apt-get update")

# 필수 패키지 설치
run_command("sudo apt-get install -y curl gnupg2 ca-certificates lsb-release")
run_command("sudo apt-get install -y ubuntu-keyring apt-transport-https")

# NGINX 키 설치
run_command("curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null")

# 키 확인
run_command("gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg")

# NGINX 저장소 추가
lsb_release = subprocess.run("lsb_release -cs", shell=True, capture_output=True, text=True).stdout.strip()
run_command(f'echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu {lsb_release} nginx" | sudo tee /etc/apt/sources.list.d/nginx.list')

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

    server {
        listen 80;
        server_name _;

        location /nginx_status {
            stub_status;
            access_log off;
            allow 127.0.0.1;
            allow 192.168.56.0/24;
            deny all;
        }
    }
"""
nginx_conf.insert(http_index + 1, server_block)

with open(nginx_conf_path, 'w') as file:
    file.writelines(nginx_conf)

# NGINX 설정 테스트
run_command("nginx -t")

# NGINX 재시작
run_command("sudo systemctl restart nginx")

