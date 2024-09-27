#!/bin/bash

# PHP 버전 및 GitHub 리포지토리 정보
export PHP_VERSION="8.3"
GITHUB_BASE_URL="https://raw.githubusercontent.com/anti1346"
REPO_PATH="codes/main/python/nginx-phpfpm/conf"

# 다운로드할 파일의 URL
NGINX_CONFIG_URL="${GITHUB_BASE_URL}/${REPO_PATH}/nginx.conf"
NGINX_DEFAULT_CONFIG_URL="${GITHUB_BASE_URL}/${REPO_PATH}/default.conf"
PHP_FPM_CONFIG_URL="${GITHUB_BASE_URL}/${REPO_PATH}/php-fpm.conf"
PHP_FPM_POOL_CONFIG_URL="${GITHUB_BASE_URL}/${REPO_PATH}/www.conf"

# 파일 다운로드 함수 (다운로드 및 검증)
download_and_verify() {
    local file_url=$1
    local destination_path=$2

    echo "Downloading $file_url to $destination_path..."
    curl -fsSL --retry 3 --retry-delay 2 --retry-max-time 10 "$file_url" -o "$destination_path"
    
    if [[ ! -f "$destination_path" ]]; then
        echo "Error: Failed to download $file_url"
        exit 1
    fi
}

install_nginx() {
    echo "Step 1: Installing and configuring Nginx..."
    
    sudo apt-get update
    sudo apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring apt-transport-https || exit 1
    
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /etc/apt/keyrings/nginx_signing.asc >/dev/null || exit 1

    echo "deb [signed-by=/etc/apt/keyrings/nginx_signing.asc] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

    sudo apt-get update
    sudo apt-get install -y nginx || exit 1
    
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_$(date +"%Y%m%d-%H%M%S")
    sudo cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf_$(date +"%Y%m%d-%H%M%S")
    
    download_and_verify "$NGINX_CONFIG_URL" "/etc/nginx/nginx.conf"
    
    sudo systemctl restart nginx || exit 1
    
    echo "Nginx installed and configured."
}

install_php_fpm() {
    echo "Step 2: Installing and configuring PHP-FPM..."

    sudo apt-get update
    sudo apt-get install -y zlib1g-dev software-properties-common || exit 1

    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get update
    sudo apt-get install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-dev || exit 1
    sudo apt-get install -y php-pear php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-igbinary php${PHP_VERSION}-zip || exit 1

    sudo cp /etc/php/${PHP_VERSION}/fpm/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf_$(date +"%Y%m%d-%H%M%S")
    sudo cp /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf_$(date +"%Y%m%d-%H%M%S")

    sudo mkdir -p /var/log/php-fpm
    
    download_and_verify "$PHP_FPM_CONFIG_URL" "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
    download_and_verify "$PHP_FPM_POOL_CONFIG_URL" "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

    sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/${PHP_VERSION}/cli/php.ini

    sudo systemctl restart php${PHP_VERSION}-fpm || exit 1

    echo "PHP-FPM installed and configured."
}

install_laravel() {
    echo "Step 3: Installing Laravel with Composer..."

    sudo apt-get install -y php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring composer || exit 1
    sudo systemctl restart php${PHP_VERSION}-fpm || exit 1

    composer global require laravel/installer || exit 1

    download_and_verify "$NGINX_DEFAULT_CONFIG_URL" "/etc/nginx/conf.d/default.conf"

    laravel_root_path="/usr/share/nginx/html"
    laravel_project_name="laravel_project"
    laravel_full_path="${laravel_root_path}/${laravel_project_name}"

    if [ -d "$laravel_full_path" ]; then
        read -p "Laravel project already exists. Do you want to remove it? [y/N]: " user_choice
        if [[ "$user_choice" =~ ^[Yy]$ ]]; then
            sudo rm -rf "$laravel_full_path"
        fi
    fi

    cd "$laravel_root_path" && composer create-project --prefer-dist laravel/laravel "$laravel_project_name" || exit 1
    sudo chown -R www-data:www-data "$laravel_full_path"
    
    sudo systemctl restart nginx || exit 1

    echo "Laravel installed and configured."
}

# 실행
install_nginx
install_php_fpm
#install_laravel
