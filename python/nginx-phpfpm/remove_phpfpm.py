import subprocess

# PHP 버전 변수 정의
php_version = "8.1"

# PHP-FPM 서비스 상태 확인
try:
    subprocess.run(f"sudo systemctl status php{php_version}-fpm", shell=True, check=True)
except subprocess.CalledProcessError as e:
    print(f"Error: PHP-FPM service for PHP {php_version} is not loaded or already removed.")

# 명령어 리스트
commands = [
    # PHP-FPM 서비스 중지 및 비활성화
    f"sudo systemctl stop php{php_version}-fpm",
    f"sudo systemctl disable php{php_version}-fpm",
    # PHP 관련 패키지 제거
    f"sudo apt-get purge -y php-cli php-common php-composer-ca-bundle php-composer-metadata-minifier php-composer-pcre php-composer-semver php-composer-spdx-licenses php-composer-xdebug-handler php-intl php-json-schema php-mbstring php-psr-container php-psr-log php-react-promise php-symfony-console php-symfony-deprecation-contracts php-symfony-filesystem php-symfony-finder php-symfony-polyfill-php80 php-symfony-process php-symfony-service-contracts php-symfony-string php{php_version}-cli php{php_version}-common php{php_version}-intl php{php_version}-mbstring php{php_version}-opcache php{php_version}-readline",
    # 사용하지 않는 패키지 자동 제거
    "sudo apt-get autoremove -y",
    # 설정 파일 및 로그 파일 삭제
    "sudo rm -rf /etc/php/ /var/log/php/",
    # APT 패키지 캐시 정리
    "sudo apt-get clean"
]

# 각 명령어 실행
for command in commands:
    try:
        # 명령어 실행
        subprocess.run(command, shell=True, check=True)
        # 실행 성공 메시지 출력
        print(f"Command '{command}' executed successfully.")
    except subprocess.CalledProcessError as e:
        # 실행 오류 메시지 출력
        print(f"Error executing command '{command}': {e}")
