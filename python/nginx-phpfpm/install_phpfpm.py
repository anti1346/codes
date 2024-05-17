import subprocess

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    else:
        print(result.stdout)

# 필수 패키지 설치
run_command("sudo apt-get install -y zlib1g-dev software-properties-common")
run_command("sudo add-apt-repository -y ppa:ondrej/php")
run_command("sudo apt-get update")

# PHP 8.1 및 관련 패키지 설치
run_command("sudo apt-get install -y --no-install-recommends php8.1-fpm php8.1-cli php8.1-common php8.1-dev php-pear")
run_command("sudo apt-get install -y php8.1-gd php8.1-xml php8.1-curl php8.1-igbinary")
run_command("sudo apt-get install -y php8.1-redis php8.1-mongodb php8.1-zip php8.1-imagick")
run_command("sudo apt-get install -y librdkafka-dev")
run_command("sudo pecl install rdkafka")
run_command('echo "extension=rdkafka.so" | sudo tee /etc/php/8.1/mods-available/rdkafka.ini')
run_command("sudo ln -s /etc/php/8.1/mods-available/rdkafka.ini /etc/php/8.1/fpm/conf.d/20-rdkafka.ini")
run_command("sudo ln -s /etc/php/8.1/mods-available/rdkafka.ini /etc/php/8.1/cli/conf.d/20-rdkafka.ini")

# PHP-FPM 버전 확인
run_command("php-fpm8.1 --version")

# PHP-FPM 서비스 활성화 및 시작
run_command("sudo systemctl --now enable php8.1-fpm")

# PHP 설정 파일 확인
run_command("php --ini | egrep 'Loaded Configuration File'")

# expose_php 설정 수정
run_command("sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/8.1/cli/php.ini")

# PHP-FPM 설정 테스트
run_command("php-fpm8.1 -t")

# PHP 모듈 확인
run_command("php -m | egrep 'redis|mongodb|zip|imagick|rdkafka'")

# phpinfo 파일 생성
run_command("echo '<?php phpinfo();' | sudo tee /var/www/html/test.php")
run_command("echo '<?php phpinfo();' | sudo tee /usr/share/nginx/html/test.php")

print("PHP 8.1 및 관련 모듈 설치가 완료되었습니다.")

