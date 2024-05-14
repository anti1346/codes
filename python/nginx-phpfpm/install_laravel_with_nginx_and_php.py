import subprocess

# composer 설치
composer_install_command = "sudo apt-get install -y composer"
subprocess.run(composer_install_command, shell=True)

# Nginx 설치
nginx_install_command = "sudo apt-get install nginx -y"
subprocess.run(nginx_install_command, shell=True)

# PHP-FPM 설치
php_install_command = "sudo apt-get install php-fpm -y"
subprocess.run(php_install_command, shell=True)

# Laravel 설치
laravel_install_command = "composer global require laravel/installer"
subprocess.run(laravel_install_command, shell=True)

# Nginx 설정 파일 업데이트
nginx_config = """
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name example.com;
    root /var/www/html/public;

    index index.php index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock; # PHP 버전에 따라 변경
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
"""
nginx_config_file_path = "/etc/nginx/sites-available/default"
with open(nginx_config_file_path, "w") as nginx_config_file:
    nginx_config_file.write(nginx_config)

# Laravel 프로젝트 생성
laravel_project_path = "/var/www/html"
laravel_project_name = "laravel_project"
laravel_create_command = f"cd {laravel_project_path} && composer create-project --prefer-dist laravel/laravel {laravel_project_name}"
subprocess.run(laravel_create_command, shell=True)

# Laravel 프로젝트 디렉토리 권한 설정
laravel_chmod_command = f"sudo chown -R www-data:www-data {laravel_project_path}/{laravel_project_name}"
subprocess.run(laravel_chmod_command, shell=True)

# Nginx 서비스 재시작
nginx_restart_command = "sudo systemctl restart nginx"
subprocess.run(nginx_restart_command, shell=True)

print("Nginx, PHP-FPM, Laravel 설치 및 연동이 완료되었습니다.")
