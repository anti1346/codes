import os
import subprocess

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
    install_packages(["nginx"])
    print("Configuring Nginx user...")
    nginx_conf_content = """
    user www-data www-data;
    worker_processes auto;

    pid /var/run/nginx.pid;
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
    """
    with open('/etc/php/php-fpm/fpm/pool.d/www.conf', 'w') as file:
        file.write(www_conf_content)
    print("Configuration file '/etc/php/php-fpm/fpm/pool.d/www.conf' created.")

    print("PHP-FPM installed and configured.")

# Step 3: Install Laravel with Composer
def install_laravel_with_composer():
    print("Installing Laravel with Composer...")
    run_command("sudo apt-get install -y php-intl")
    run_command("sudo apt-get update")
    run_command("sudo systemctl restart php8.1-fpm")

    run_command("sudo apt-get install -y composer")
    run_command("composer global require laravel/installer")

    nginx_conf_default_content = """
    server {
        listen 80;
        server_name _;
        # root /usr/share/nginx/html;
        root /usr/share/nginx/html/laravel_project/public;
        index index.php index.html;
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
