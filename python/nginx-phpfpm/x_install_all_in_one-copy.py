import os
import subprocess
import datetime

php_version = "8.1"

def run_command(command, check=True):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    return result.stdout.strip()

def install_packages(packages):
    for package in packages:
        run_command(f"sudo apt-get install -y {package}")

def create_backup(file_path):
    if os.path.exists(file_path):
        now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_path = f"{file_path}_{now}"
        run_command(f"sudo cp {file_path} {backup_path}")
        print(f"Backup created for {file_path} at {backup_path}")

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
    
    print("Configuring Nginx backup...")
    create_backup("/etc/nginx/nginx.conf")
    create_backup("/etc/nginx/conf.d/default.conf")

    print("Configuring Nginx user...")
    nginx_conf_content = """
user www-data www-data;
worker_processes auto;
}
    """
    with open('/etc/nginx/nginx.conf', 'w') as file:
        file.write(nginx_conf_content)
    run_command("sudo systemctl restart nginx")
    print("Nginx installed and configured.")

# Step 2: Install PHP-FPM
def install_php_fpm():
    print("Installing PHP-FPM...")
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

    create_backup(f"/etc/php/{php_version}/fpm/php-fpm.conf")
    create_backup(f"/etc/php/{php_version}/fpm/pool.d/www.conf")

    os.makedirs('/var/log/php-fpm', exist_ok=True)

    run_command(f"sudo ln -s /etc/php/{php_version} /etc/php/php-fpm", check=False)

    # PHP-FPM php-fpm.conf 설정 추가
    #############################################################################
    php_fpm_conf_content = """
include = /etc/php/php-fpm/fpm/pool.d/*.conf
    """
    with open(f'/etc/php/php-fpm/fpm/php-fpm.conf', 'w') as file:
        file.write(php_fpm_conf_content)
    print(f"Configuration file '/etc/php/php-fpm/fpm/php-fpm.conf' created.")

    # PHP-FPM www.conf 설정 추가
    #############################################################################
    www_conf_content = """
[www]
    """
    with open('/etc/php/php-fpm/fpm/pool.d/www.conf', 'w') as file:
        file.write(www_conf_content)
    print("Configuration file '/etc/php/php-fpm/fpm/pool.d/www.conf' created.")
    
    run_command(f"sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/{php_version}/cli/php.ini")
    
    run_command(f"sudo systemctl restart php{php_version}-fpm")

    print("PHP-FPM installed and configured.")

# Step 3: Install Laravel with Composer
def install_laravel_with_composer():
    print("Installing Laravel with Composer...")
    run_command(f"sudo apt-get install -y php{php_version}-intl php{php_version}-mbstring")
    run_command(f"sudo systemctl restart php{php_version}-fpm")

    run_command("sudo apt-get install -y composer")
    run_command("composer global require laravel/installer")

    # NGINX default.conf 설정 추가
    #############################################################################
    nginx_conf_default_content = """
server {
    listen 80;
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
