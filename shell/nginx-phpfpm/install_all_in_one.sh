#!/bin/bash

# PHP 버전 및 GitHub 리포지토리 정보
PHP_VERSION="8.1"
GITHUB_CONTENT="https://raw.githubusercontent.com/anti1346"
GITHUB_REPOSITORY="codes/main/python/nginx-phpfpm/conf"

# 다운로드할 파일의 URL
NGINX_CONF_URL="${GITHUB_CONTENT}/${GITHUB_REPOSITORY}/nginx.conf"
NGINX_DEFAULT_CONF_URL="${GITHUB_CONTENT}/${GITHUB_REPOSITORY}/default.conf"
PHP_FPM_CONF_URL="${GITHUB_CONTENT}/${GITHUB_REPOSITORY}/php-fpm.conf"
PHP_FPM_WWW_CONF_URL="${GITHUB_CONTENT}/${GITHUB_REPOSITORY}/www.conf"

install_nginx() {
    echo "Step 1: Installing and configuring Nginx..."
    
    sudo apt-get update
    sudo apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring apt-transport-https
    
    curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

    sudo apt-get install -y nginx
    
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_$(date +"%Y%m%d-%H%M%S")
    sudo cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf_$(date +"%Y%m%d-%H%M%S")
    
    curl -fsSL --retry 3 --retry-delay 2 --retry-max-time 10 "$NGINX_CONF_URL" -o /etc/nginx/nginx.conf
    
    sudo systemctl restart nginx
    
    echo "Nginx installed and configured."
}

install_php_fpm() {
    echo "Step 2: Installing and configuring PHP-FPM..."

    sudo apt-get update
    sudo apt-get install -y zlib1g-dev software-properties-common

    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get update
    sudo apt-get install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-dev
    sudo apt-get install -y php-pear php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-igbinary php${PHP_VERSION}-zip

    sudo cp /etc/php/${PHP_VERSION}/fpm/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf_$(date +"%Y%m%d-%H%M%S")
    sudo cp /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf_$(date +"%Y%m%d-%H%M%S")

    sudo mkdir -p /var/log/php-fpm
    sudo ln -s /etc/php/${PHP_VERSION} /etc/php/php-fpm
    
    curl -fsSL --retry 3 --retry-delay 2 --retry-max-time 10 $PHP_FPM_CONF_URL -o /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
    curl -fsSL --retry 3 --retry-delay 2 --retry-max-time 10 $PHP_FPM_WWW_CONF_URL -o /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

    sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/${PHP_VERSION}/cli/php.ini

    sudo systemctl restart php${PHP_VERSION}-fpm

    echo "PHP-FPM installed and configured."
}

install_php_modules() {
    echo "Step 3: Installing PHP-FPM modules..."

    sudo apt-get install -y php${PHP_VERSION}-redis php${PHP_VERSION}-mongodb php${PHP_VERSION}-imagick
    
    if ! php${PHP_VERSION} -m | grep -q rdkafka; then
        sudo apt-get install -y librdkafka-dev
        sudo pecl install rdkafka <<< ''
        echo 'extension=rdkafka.so' | sudo tee "/etc/php/${PHP_VERSION}/mods-available/rdkafka.ini" >/dev/null
        sudo ln -s "/etc/php/${PHP_VERSION}/mods-available/rdkafka.ini" "/etc/php/${PHP_VERSION}/fpm/conf.d/20-rdkafka.ini" >/dev/null 2>&1
        sudo ln -s "/etc/php/${PHP_VERSION}/mods-available/rdkafka.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/20-rdkafka.ini" >/dev/null 2>&1
        echo "PHP-FPM modules installed."
    else
        echo "PHP-FPM modules module is already installed."
    fi

    echo "PHP-FPM modules installed"
}

remove_php_fpm() {
    echo "Step 4: Removing PHP-FPM 8.3 packages..."

    sudo apt-get remove -y php8.3-common php8.3-xml

    purge_list=$(dpkg -l | awk '/^rc/ { print $2 }')
    if [ -n "$purge_list" ]; then
        sudo dpkg --purge "$purge_list"
    else
        echo "No packages to purge."
    fi

    echo "PHP-FPM 8.3 removal complete."
}


install_laravel_with_composer() {
    echo "Step 5: Installing Laravel with Composer..."

    sudo apt-get install -y php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring composer
    
    sudo systemctl restart php${PHP_VERSION}-fpm
    
    composer global require laravel/installer
    
    curl -fsSL --retry 3 --retry-delay 2 --retry-max-time 10 $NGINX_DEFAULT_CONF_URL -o /etc/nginx/conf.d/default.conf

    laravel_project_path="/usr/share/nginx/html"
    laravel_project_name="laravel_project"
    laravel_full_path="${laravel_project_path}/${laravel_project_name}"
    if [ -d "$laravel_full_path" ]; then
        sudo rm -rf "$laravel_full_path"
    fi

    cd "$laravel_project_path" && composer create-project --prefer-dist laravel/laravel "$laravel_project_name"
    sudo chown -R www-data:www-data "$laravel_full_path"
    
    sudo systemctl restart nginx
    
    echo "Laravel installed and configured."
}

install_nginx
install_php_fpm
#install_php_modules
remove_php_fpm
install_laravel_with_composer
