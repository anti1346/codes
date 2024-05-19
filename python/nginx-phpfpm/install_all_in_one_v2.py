import os
import subprocess
import datetime
import requests

# PHP 버전 및 GitHub 리포지토리 정보
PHP_VERSION = "8.1"
GITHUB_CONTENT = "https://raw.githubusercontent.com/anti1346"
GITHUB_REPOSITORY = "codes/main/python/nginx-phpfpm/conf"

# 다운로드할 파일의 URL
NGINX_CONF_URL = f"{GITHUB_CONTENT}/{GITHUB_REPOSITORY}/nginx.conf"
NGINX_DEFAULT_CONF_URL = f"{GITHUB_CONTENT}/{GITHUB_REPOSITORY}/default.conf"
PHP_FPM_CONF_URL = f"{GITHUB_CONTENT}/{GITHUB_REPOSITORY}/php-fpm.conf"
PHP_FPM_WWW_CONF_URL = f"{GITHUB_CONTENT}/{GITHUB_REPOSITORY}/www.conf"

def run_command(command, check=True):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    return result.stdout.strip()

def install_packages(packages):
    run_command("sudo apt-get update")
    for package in packages:
        run_command(f"sudo apt-get install -y {package}")

def remove_packages(packages):
    run_command("sudo apt-get update")
    for package in packages:
        run_command(f"sudo apt-get remove -y {package}")

def create_backup(file_path):
    if os.path.exists(file_path):
        now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_path = f"{file_path}_{now}"
        run_command(f"sudo cp {file_path} {backup_path}")
        print(f"Backup created for {file_path} at {backup_path}")

def download_config(url, save_path):
    response = requests.get(url)
    if response.status_code == 200:
        config_content = response.text
        with open(save_path, 'w') as file:
            file.write(config_content)
        print(f"Configuration file downloaded and saved at {save_path}")
    else:
        print(f"Failed to download configuration file from {url}")

# Step 1: Install Nginx
def install_nginx():
    print("Step 1: Installing and configuring Nginx...")
    required_packages = ["curl", "gnupg2", "ca-certificates", "lsb-release", "ubuntu-keyring", "apt-transport-https"]
    install_packages(required_packages)
    run_command("curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null")
    
    lsb_release = run_command("lsb_release -cs")
    nginx_repo_command = f'echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu {lsb_release} nginx" | sudo tee /etc/apt/sources.list.d/nginx.list'
    run_command(nginx_repo_command)

    install_packages(["nginx"])
    
    create_backup("/etc/nginx/nginx.conf")
    create_backup("/etc/nginx/conf.d/default.conf")

    download_config(NGINX_CONF_URL, '/etc/nginx/nginx.conf')
    
    run_command("sudo systemctl restart nginx")
    
    print("Nginx installed and configured.")

# Step 2: Install PHP-FPM
def install_php_fpm():
    print("Step 2: Installing and configuring PHP-FPM...")
    required_packages = ["zlib1g-dev", "software-properties-common"]
    install_packages(required_packages)

    run_command("sudo add-apt-repository -y ppa:ondrej/php")

    php_packages = [f"php{PHP_VERSION}-fpm", f"php{PHP_VERSION}-cli", f"php{PHP_VERSION}-common", f"php{PHP_VERSION}-dev"]
    install_packages(php_packages)

    php_required_packages = [
        "php-pear", f"php{PHP_VERSION}-gd", f"php{PHP_VERSION}-xml", f"php{PHP_VERSION}-curl",
        f"php{PHP_VERSION}-igbinary", f"php{PHP_VERSION}-zip"
    ]
    install_packages(php_required_packages)

    create_backup(f"/etc/php/{PHP_VERSION}/fpm/php-fpm.conf")
    create_backup(f"/etc/php/{PHP_VERSION}/fpm/pool.d/www.conf")

    os.makedirs('/var/log/php-fpm', exist_ok=True)
    run_command(f"sudo ln -s /etc/php/{PHP_VERSION} /etc/php/php-fpm", check=False)

    download_config(PHP_FPM_CONF_URL, f'/etc/php/{PHP_VERSION}/fpm/php-fpm.conf')
    download_config(PHP_FPM_WWW_CONF_URL, f'/etc/php/{PHP_VERSION}/fpm/pool.d/www.conf')
    
    run_command(f"sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/{PHP_VERSION}/cli/php.ini")
    
    run_command(f"sudo systemctl restart php{PHP_VERSION}-fpm")

    print("PHP-FPM installed and configured.")

# Step 3: Install PHP-FPM Modules
def install_php_modules():
    print("Step 3: Installing PHP-FPM modules...")
    php_modules_packages = [f"php{PHP_VERSION}-redis", f"php{PHP_VERSION}-mongodb", f"php{PHP_VERSION}-imagick"]
    install_packages(php_modules_packages)

    # librdkafka-dev 및 rdkafka 설치 및 활성화
    rdkafka_installed = "rdkafka" in run_command(f"php{PHP_VERSION} -m")
    if not rdkafka_installed:
        install_packages(["librdkafka-dev"])
        run_command(f"echo '' | sudo pecl install rdkafka")
        run_command(f'echo "extension=rdkafka.so" | sudo tee /etc/php/{PHP_VERSION}/mods-available/rdkafka.ini')
        run_command(f"sudo ln -s /etc/php/{PHP_VERSION}/mods-available/rdkafka.ini /etc/php/{PHP_VERSION}/fpm/conf.d/20-rdkafka.ini")
        run_command(f"sudo ln -s /etc/php/{PHP_VERSION}/mods-available/rdkafka.ini /etc/php/{PHP_VERSION}/cli/conf.d/20-rdkafka.ini")
        print("PHP-FPM modules installed.")
    else:
        print("rdkafka PHP module is already installed.")

# Step 4: Remove PHP-FPM
def remove_php_fpm():
    print("Step 4: Removing PHP-FPM 8.3 packages...")
    required_packages = ["php8.3-common", "php8.3-xml"]
    remove_packages(required_packages)

    purge_list = run_command("dpkg -l | awk '/^rc/ { print $2 }'", check=False)
    if purge_list:
        run_command(f"sudo dpkg --purge {purge_list}")
    else:
        print("No packages to purge.")
    print("PHP-FPM 8.3 removal complete.")

# Step 5: Install Laravel with Composer
def install_laravel_with_composer():
    print("Step 5: Installing Laravel with Composer...")
    run_command(f"sudo apt-get install -y php{PHP_VERSION}-intl php{PHP_VERSION}-mbstring")
    run_command(f"sudo systemctl restart php{PHP_VERSION}-fpm")

    run_command("sudo apt-get install -y composer")
    run_command("composer global require laravel/installer")

    download_config(NGINX_DEFAULT_CONF_URL, '/etc/nginx/conf.d/default.conf')
    
    laravel_project_path = "/usr/share/nginx/html"
    laravel_project_name = "laravel_project"
    laravel_full_path = os.path.join(laravel_project_path, laravel_project_name)
    if os.path.exists(laravel_full_path):
        run_command(f"sudo rm -rf {laravel_full_path}")

    run_command(f"cd {laravel_project_path} && composer create-project --prefer-dist laravel/laravel {laravel_project_name}")
    
    run_command(f"sudo chown -R www-data:www-data {laravel_full_path}")

    run_command("sudo systemctl restart nginx")
    
    print("Laravel installed and configured.")

# Main execution
def main():
    install_nginx()
    install_php_fpm()
    #install_php_modules()
    remove_php_fpm()
    install_laravel_with_composer()
    print("All installations and configurations are completed.")

if __name__ == "__main__":
    main()
