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

# PHP-FPM 서비스 활성화 및 시작
run_command(f"sudo systemctl --now enable php{php_version}-fpm")

# expose_php 설정 수정
run_command(f"sudo sed -i 's/expose_php = On/expose_php = Off/g' /etc/php/{php_version}/cli/php.ini")

# PHP-FPM 설정 테스트
run_command(f"php-fpm{php_version} -t")

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
