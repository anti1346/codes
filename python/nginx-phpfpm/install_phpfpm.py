import os
import subprocess
import datetime

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
required_packages = ["zlib1g-dev", "software-properties-common"]
install_packages(required_packages)

# PHP 저장소 추가 및 업데이트
run_command(f"sudo add-apt-repository -y ppa:ondrej/php")
run_command("sudo apt-get update")

# PHP 8.1 패키지 설치
php_packages = [f"php{php_version}-fpm", f"php{php_version}-cli", f"php{php_version}-common",f"php{php_version}-dev"]
install_packages(php_packages)

# PHP 관련 패키지 설치
php_required_packages = [
    f"php{php_version}-fpm", f"php{php_version}-cli", f"php{php_version}-common",
    f"php{php_version}-dev", "php-pear", f"php{php_version}-gd", f"php{php_version}-xml",
    f"php{php_version}-curl", f"php{php_version}-igbinary", f"php{php_version}-redis",
    f"php{php_version}-mongodb", f"php{php_version}-zip", f"php{php_version}-imagick"
]
install_packages(php_required_packages)

# librdkafka-dev 및 rdkafka 설치 및 활성화
run_command("sudo apt-get install -y librdkafka-dev")
run_command("sudo pecl install rdkafka")
run_command(f'echo "extension=rdkafka.so" | sudo tee /etc/php/{php_version}/mods-available/rdkafka.ini')
run_command(f"sudo ln -s /etc/php/{php_version}/mods-available/rdkafka.ini /etc/php/{php_version}/fpm/conf.d/20-rdkafka.ini")
run_command(f"sudo ln -s /etc/php/{php_version}/mods-available/rdkafka.ini /etc/php/{php_version}/cli/conf.d/20-rdkafka.ini")

# PHP-FPM 설정 파일 백업
now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
run_command(f"sudo cp /etc/php/{php_version}/fpm/php-fpm.conf /etc/php/{php_version}/fpm/php-fpm.conf_{now}")
run_command(f"sudo cp /etc/php/{php_version}/fpm/pool.d/www.conf /etc/php/{php_version}/fpm/pool.d/www.conf_{now}")

# PHP-FPM 로그 디렉토리 생성
os.makedirs('/var/log/php-fpm', exist_ok=True)

# PHP-FPM 디렉토리 심볼릭 링크 설정
run_command(f"sudo ln -s /etc/php/{php_version} /etc/php/php-fpm")

# PHP-FPM 서비스 활성화 및 시작
run_command(f"sudo systemctl --now enable php{php_version}-fpm")

# expose_php 설정 수정
run_command(f"sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/{php_version}/cli/php.ini")

# PHP-FPM 설정 테스트
run_command(f"php-fpm{php_version} -t")

# PHP-FPM php-fpm.conf 설정 추가
php_fpm_conf_content = """
include = /etc/php/php-fpm/fpm/pool.d/*.conf

[global]
pid = /run/php/php-fpm.pid
error_log = /var/log/php-fpm/php-fpm.log
daemonize = yes
"""
# php-fpm.conf 파일 쓰기
with open(f'/etc/php/{php_version}/fpm/php-fpm.conf', 'w') as file:
    file.write(php_fpm_conf_content)
print(f"Configuration file '/etc/php/{php_version}/fpm/php-fpm.conf' created.")

# PHP-FPM www.conf 설정 추가
www_conf_content = f"""
[www]
; 사용자와 그룹 설정
user = www-data
group = www-data

; 소켓과 권한 설정
listen = /run/php/php-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0666
;listen.allowed_clients = 127.0.0.1

; 프로세스 관리 설정
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

; Health check 경로 설정
ping.path = /ping
pm.status_path = /status

; 요청 종료 및 슬로우 로그 설정
request_terminate_timeout = 30
request_slowlog_timeout = 10
slowlog = /var/log/php-fpm/www-slow.log

; 액세스 로그 설정
access.log = /var/log/php-fpm/www-access.log
access.format = "[%%t] %%m %{{REQUEST_SCHEME}}e://%%{HTTP_HOST}e%%{REQUEST_URI}e %%f pid:%%p TIME:%%ds MEM:%%{{mega}}Mmb CPU:%%C%% status:%%s {%%{REMOTE_ADDR}e|%%{HTTP_USER_AGENT}e}"

; 에러 로그 및 로그 기록 활성화 설정
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
"""
# www.conf 파일 쓰기
with open('/etc/php/{php_version}/fpm/pool.d/www.conf', 'w') as file:
    file.write(www_conf_content)
print("Configuration file '/etc/php/{php_version}/fpm/pool.d/www.conf' created.")

# default.conf 설정 추가
nginx_conf_default_content = """
server {
    listen 80;
    server_name _;
    
    access_log /var/log/nginx/default-access.log main;
    error_log  /var/log/nginx/default-error.log;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
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
        allow 10.11.0.0/16;
        allow 10.21.0.0/16;
        allow 10.31.0.0/16;
        deny all;
        access_log off;
    }
    
    location ~ /\.ht {
        deny  all;
    }
}
"""
# default.conf 파일 쓰기
with open('/etc/nginx/conf.d/default.conf', 'w') as file:
    file.write(nginx_conf_default_content)
print("Configuration file '/etc/nginx/conf.d/default.conf' created.")

# phpinfo 파일 생성
run_command("echo '<?php phpinfo();' | sudo tee /usr/share/nginx/html/test.php")

# NGINX 재시작
run_command("sudo systemctl restart nginx")

# PHP 설정 파일 확인
run_command(f"php --ini | egrep 'Loaded Configuration File'")

# PHP-FPM 버전 확인
run_command(f"php-fpm{php_version} --version")

# PHP 모듈 확인
run_command(f"php -m | egrep 'redis|mongodb|zip|imagick|rdkafka'")

print(f"PHP {php_version} 및 관련 모듈 설치가 완료되었습니다.")
