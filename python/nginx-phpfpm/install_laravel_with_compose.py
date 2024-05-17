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

# PHP 버전 변수 정의
php_version = "8.1"

# 필수 패키지 설치
required_packages = [f"php{php_version}-intl"]
install_packages(required_packages)

# 업데이트
run_command("sudo apt-get update")

# PHP-FPM 서비스 재시작
run_command(f"sudo systemctl restart php{php_version}-fpm")

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
    root /usr/share/nginx/html/laravel_project;
    
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

# Laravel 프로젝트 생성
laravel_project_path = "/usr/share/nginx/html"
laravel_project_name = "laravel_project"
laravel_create_command = f"cd {laravel_project_path} && composer create-project --prefer-dist laravel/laravel {laravel_project_name}"
subprocess.run(laravel_create_command, shell=True)

# Laravel 프로젝트 디렉토리 권한 설정
laravel_chmod_command = f"sudo chown -R www-data:www-data {laravel_project_path}/{laravel_project_name}"
subprocess.run(laravel_chmod_command, shell=True)

# Nginx 서비스 재시작
nginx_restart_command = "sudo systemctl restart nginx"
subprocess.run(nginx_restart_command, shell=True)

print("Laravel 설치 및 연동이 완료되었습니다.")
