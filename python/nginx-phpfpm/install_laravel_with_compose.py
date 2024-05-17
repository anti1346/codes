import os
import subprocess

# 실행 결과를 출력하는 함수
def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        print(result.stdout)

# 패키지 설치 함수
def install_packages(packages):
    for package in packages:
        run_command(f"sudo apt-get install -y {package}")

# 업데이트 및 필수 패키지 설치
run_command("sudo apt-get update")
required_packages = [f"php8.1-intl", f"php8.1-mbstring", "composer"]
install_packages(required_packages)

# PHP-FPM 서비스 재시작
run_command("sudo systemctl restart php8.1-fpm")

# composer 설치
composer_install_command = "sudo apt-get install -y composer"
subprocess.run(composer_install_command, shell=True)

# Laravel 설치
laravel_install_command = "composer global require laravel/installer"
subprocess.run(laravel_install_command, shell=True)

# Nginx 설정 파일 업데이트
nginx_conf_default_content = """
server {
    listen 80;
    server_name _;
    
    access_log /var/log/nginx/default-access.log main;
    error_log /var/log/nginx/default-error.log;

    # root /usr/share/nginx/html;
    root /usr/share/nginx/html/laravel_project/public;
    
    index index.php index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # nginx status
    location /nginx_status {
        stub_status;
        access_log off;
        allow 127.0.0.1;
        allow 192.168.56.0/24;
        deny all;
    }

    # php-fpm status
    location ~ ^/(status|ping)$ {
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
        include fastcgi_params;
        allow 127.0.0.1;
        deny all;
        access_log off;
    }
    
    location ~ /\.ht {
        deny  all;
    }
}
"""
with open('/etc/nginx/conf.d/default.conf', 'w') as file:
    file.write(nginx_conf_default_content)
print("Configuration file '/etc/nginx/conf.d/default.conf' created.")

# Laravel 프로젝트 생성 디렉토리가 존재하고 비어 있지 않으면 삭제
laravel_project_path = "/usr/share/nginx/html"
laravel_project_name = "laravel_project"
laravel_project_full_path = os.path.join(laravel_project_path, laravel_project_name)

if os.path.exists(laravel_project_full_path) and os.listdir(laravel_project_full_path):
    run_command(f"sudo rm -rf {laravel_project_full_path}")

# Laravel 프로젝트 생성
laravel_create_command = f"cd {laravel_project_path} && composer create-project --prefer-dist laravel/laravel {laravel_project_name}"
run_command(laravel_create_command)

# Laravel 프로젝트 디렉토리 권한 설정
laravel_chmod_command = f"sudo chown -R www-data:www-data {laravel_project_full_path}"
run_command(laravel_chmod_command)

# Nginx 서비스 재시작
nginx_restart_command = "sudo systemctl restart nginx"
run_command(nginx_restart_command)

print("Laravel 설치 및 연동이 완료되었습니다.")
