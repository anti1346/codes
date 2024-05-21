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

run_command() {
    local command=$1
    local check=${2:-true}
    result=$(eval "$command")
    if $check && [ $? -ne 0 ]; then
        echo "Command failed: $command"
        exit 1
    fi
    echo "$result"
}

install_packages() {
    run_command "sudo apt-get update"
    for package in "$@"; do
        run_command "sudo apt-get install -y $package"
    done
}

remove_packages() {
    run_command "sudo apt-get update"
    for package in "$@"; do
        run_command "sudo apt-get remove -y $package"
    done
}

create_backup() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        now=$(date +"%Y%m%d-%H%M%S")
        backup_path="${file_path}_${now}"
        run_command "sudo cp $file_path $backup_path"
        echo "Backup created for $file_path at $backup_path"
    fi
}

download_config() {
    local url=$1
    local save_path=$2
    response=$(curl -sS "$url")
    if [ $? -eq 0 ]; then
        echo "$response" > "$save_path"
        echo "Configuration file downloaded and saved at $save_path"
    else
        echo "Failed to download configuration file from $url"
    fi
}

# Step 1: Install Nginx
install_nginx() {
    echo "Step 1: Installing and configuring Nginx..."
    required_packages=("curl" "gnupg2" "ca-certificates" "lsb-release" "ubuntu-keyring" "apt-transport-https")
    install_packages "${required_packages[@]}"
    run_command "curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null"
    lsb_release=$(run_command "lsb_release -cs")
    nginx_repo_command="echo \"deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $lsb_release nginx\" | sudo tee /etc/apt/sources.list.d/nginx.list"
    run_command "$nginx_repo_command"
    install_packages "nginx"
    create_backup "/etc/nginx/nginx.conf"
    create_backup "/etc/nginx/conf.d/default.conf"
    download_config "$NGINX_CONF_URL" "/etc/nginx/nginx.conf"
    run_command "sudo systemctl restart nginx"
    echo "Nginx installed and configured."
}

# Step 2: Install PHP-FPM
install_php_fpm() {
    echo "Step 2: Installing and configuring PHP-FPM..."
    required_packages=("zlib1g-dev" "software-properties-common")
    install_packages "${required_packages[@]}"
    run_command "sudo add-apt-repository -y ppa:ondrej/php"
    php_packages=("php${PHP_VERSION}-fpm" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-common" "php${PHP_VERSION}-dev")
    install_packages "${php_packages[@]}"
    php_required_packages=("php-pear" "php${PHP_VERSION}-gd" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-curl" "php${PHP_VERSION}-igbinary" "php${PHP_VERSION}-zip")
    install_packages "${php_required_packages[@]}"
    create_backup "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
    create_backup "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    mkdir -p "/var/log/php-fpm"
    run_command "sudo ln -s /etc/php/${PHP_VERSION} /etc/php/php-fpm" false
    download_config "$PHP_FPM_CONF_URL" "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
    download_config "$PHP_FPM_WWW_CONF_URL" "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    run_command "sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/${PHP_VERSION}/cli/php.ini"
    run_command "sudo systemctl restart php${PHP_VERSION}-fpm"
    echo "PHP-FPM installed and configured."
}

# Step 3: Install PHP-FPM Modules
install_php_modules() {
    echo "Step 3: Installing PHP-FPM modules..."
    php_modules_packages=("php${PHP_VERSION}-redis" "php${PHP_VERSION}-mongodb" "php${PHP_VERSION}-imagick")
    install_packages "${php_modules_packages[@]}"
    rdkafka_installed=$(run_command "php${PHP_VERSION} -m | grep -q rdkafka && echo true || echo false")
    if [ "$rdkafka_installed" != true ]; then
        install_packages "librdkafka-dev"
        run_command "sudo pecl install rdkafka <<< ''"
        run_command "echo 'extension=rdkafka.so' | sudo tee /etc/php/${PHP_VERSION}/mods-available/rdkafka.ini"
        run_command "sudo ln -s /etc/php/${PHP_VERSION}/mods-available/rdkafka.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-rdkafka.ini"
        run_command "sudo ln -s /etc/php/${PHP_VERSION}/mods-available/rdkafka.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-rdkafka.ini"
        echo "PHP-FPM modules installed."
    else
        echo "rdkafka PHP module is already installed."
    fi
}

# Step 4: Remove PHP-FPM
remove_php_fpm() {
    echo "Step 4: Removing PHP-FPM 8.3 packages..."
    required_packages=("php8.3-common" "php8.3-xml")
    remove_packages "${required_packages[@]}"
    purge_list=$(run_command "dpkg -l | awk '/^rc/ { print \$2 }'" false)
    if [ -n "$purge_list" ]; then
        run_command "sudo dpkg --purge $purge_list"
    else
        echo "No packages to purge."
    fi
    echo "PHP-FPM 8.3 removal complete."
}

# Step 5: Install Laravel with Composer
install_laravel_with_composer() {
    echo "Step 5: Installing Laravel with Composer..."
    install_packages "php${PHP_VERSION}-intl" "php${PHP_VERSION}-mbstring" "composer"
    run_command "sudo systemctl restart php${PHP_VERSION}-fpm"
    run_command "composer global require laravel/installer"
    download_config "$NGINX_DEFAULT_CONF_URL" "/etc/nginx/conf.d/default.conf"
    laravel_project_path="/usr/share/nginx/html"
    laravel_project_name="laravel_project"
    laravel_full_path="${laravel_project_path}/${laravel_project_name}"
    if [ -d "$laravel_full_path" ]; then
        run_command "sudo rm -rf $laravel_full_path"
    fi
    run_command "cd $laravel_project_path && composer create-project --prefer-dist laravel/laravel $laravel_project_name"
    run_command "sudo chown -R www-data:www-data $laravel_full_path"
    run_command "sudo systemctl restart nginx"
    echo "Laravel installed and configured."
}

install_nginx
install_php_fpm
#install_php_modules
remove_php_fpm
install_laravel_with_composer
echo "All installations and configurations are completed."
