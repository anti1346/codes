import os
import subprocess
import datetime

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        print(result.stdout)

def install_packages(packages):
    for package in packages:
        run_command(f"sudo apt-get install -y {package}")

# Step 1: Install Nginx
def install_nginx():
    print("Installing Nginx...")
    run_command("sudo apt-get update")
    required_packages = ["curl", "gnupg2", "ca-certificates", "lsb-release", "ubuntu-keyring", "apt-transport-https"]
    install_packages(required_packages)
    run_command("curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null")
    lsb_release = subprocess.run("lsb_release -cs", shell=True, capture_output=True, text=True).stdout.strip()
    nginx_repo_command = f'echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu {lsb_release} nginx" | sudo tee /etc/apt/sources.list.d/nginx.list'
    run_command(nginx_repo_command)
    run_command("sudo apt-get update")
    install_packages(["nginx"])
    
    print("Configuring Nginx Backup...")
    now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    run_command(f"sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_{now}")
    run_command(f"sudo cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf_{now}")

    print("Configuring Nginx user...")
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
    run_command("sudo systemctl restart nginx")
    print("Nginx installed and configured.")

# Step 2: Install PHP-FPM
def install_php_fpm():
    print("Installing PHP-FPM...")
    php_version = "8.1"
    
    required_packages = ["zlib1g-dev", "software-properties-common"]
    install_packages(required_packages)

    run_command("sudo add-apt-repository -y ppa:ondrej/php")
    run_command("sudo apt-get update")

    php_packages = [f"php{php_version}-fpm", f"php{php_version}-cli", f"php{php_version}-common", f"php{php_version}-dev"]
    install_packages(php_packages)

    php_required_packages = [
        "php-pear", f"php{php_version}-gd", f"php{php_version}-xml", f"php{php_version}-curl",
        f"php{php_version}-igbinary", f"php{php_version}-zip"
    ]
    install_packages(php_required_packages)

    now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    run_command(f"sudo cp /etc/php/{php_version}/fpm/php-fpm.conf /etc/php/{php_version}/fpm/php-fpm.conf_{now}")
    run_command(f"sudo cp /etc/php/{php_version}/fpm/pool.d/www.conf /etc/php/{php_version}/fpm/pool.d/www.conf_{now}")

    os.makedirs('/var/log/php-fpm', exist_ok=True)

    run_command(f"sudo ln -s /etc/php/{php_version} /etc/php/php-fpm")

    # PHP-FPM php-fpm.conf 설정 추가
    #############################################################################
    php_fpm_conf_content = """
include = /etc/php/php-fpm/fpm/pool.d/*.conf

[global]
pid = /run/php/php-fpm.pid
error_log = /var/log/php-fpm/php-fpm.log
daemonize = yes
    """
    with open(f'/etc/php/php-fpm/fpm/php-fpm.conf', 'w') as file:
        file.write(php_fpm_conf_content)
    print(f"Configuration file '/etc/php/php-fpm/fpm/php-fpm.conf' created.")

    # PHP-FPM www.conf 설정 추가
    #############################################################################
    www_conf_content = """
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
access.format = "[%t] %m %{REQUEST_SCHEME}e://%{HTTP_HOST}e%{REQUEST_URI}e %f pid:%p TIME:%ds MEM:%{mega}Mmb CPU:%C%% status:%s {%{REMOTE_ADDR}e|%{HTTP_USER_AGENT}e}"

; 에러 로그 및 로그 기록 활성화 설정
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
    """
    with open('/etc/php/php-fpm/fpm/pool.d/www.conf', 'w') as file:
        file.write(www_conf_content)
    print("Configuration file '/etc/php/php-fpm/fpm/pool.d/www.conf' created.")
    
    run_command(f"sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/{php_version}/cli/php.ini")
    
    run_command(f"sudo systemctl restart php{php_version}-fpm")

    print("PHP-FPM installed and configured.")

# Step 3: Install Laravel with Composer
def install_laravel_with_composer():
    php_version = "8.1"
    
    print("Installing Laravel with Composer...")
    run_command(f"sudo apt-get install -y php{php_version}-intl php{php_version}-mbstring")
    run_command("sudo apt-get update")
    run_command(f"sudo systemctl restart php{php_version}-fpm")

    run_command("sudo apt-get install -y composer")
    run_command("composer global require laravel/installer")

    nginx_conf_default_content = """
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html/laravel_project/public;
    index index.php index.html;

    access_log /var/log/nginx/default-access.log main;
    error_log /var/log/nginx/default-error.log;

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
    print("Nginx configuration for Laravel created.")

    laravel_project_path = "/usr/share/nginx/html"
    laravel_project_name = "laravel_project"
    laravel_create_command = f"cd {laravel_project_path} && composer create-project --prefer-dist laravel/laravel {laravel_project_name}"
    run_command(laravel_create_command)

    laravel_chmod_command = f"sudo chown -R www-data:www-data {laravel_project_path}/{laravel_project_name}"
    run_command(laravel_chmod_command)

    run_command("sudo systemctl restart nginx")
    print("Laravel installed and configured.")

# Main execution
def main():
    install_nginx()
    install_php_fpm()
    install_laravel_with_composer()
    print("All installations and configurations are completed.")

if __name__ == "__main__":
    main()
