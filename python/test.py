import os
import requests

github_content = "https://raw.githubusercontent.com/anti1346"
github_repository = "codes/main/python/nginx-phpfpm/conf"
nginx_conf_url = f"{github_content}/{github_repository}/nginx.conf"
nginx_default_conf_url = f"{github_content}/{github_repository}/default.conf"
php_fpm_conf_url = f"{github_content}/{github_repository}/php-fpm.conf"
php_fpm_www_conf_url = f"{github_content}/{github_repository}/www.conf"

def download_config(url, save_path):
    response = requests.get(url)
    if response.status_code == 200:
        config_content = response.text
        with open(save_path, 'w') as file:
            file.write(config_content)
        print(f"Configuration file downloaded and saved at {save_path}")
    else:
        print(f"Failed to download configuration file from {url}")

# Main execution
def main():
    download_config(nginx_conf_url, '/etc/nginx/nginx.conf')
    download_config(nginx_default_conf_url, '/etc/nginx/conf.d/default.conf')
    download_config(php_fpm_conf_url, f'/etc/php/{php_version}/fpm/php-fpm.conf')
    download_config(php_fpm_www_conf_url, f'/etc/php/{php_version}/fpm/pool.d/www.conf')

if __name__ == "__main__":
    main()
