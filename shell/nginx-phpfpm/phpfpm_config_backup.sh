#!/bin/bash
set -euo pipefail

# 변수 정의
host_name=$(hostname)
ip_address=$(hostname -I | awk '{print $1}')
timestamp=$(date +%Y%m%d%H%M%S)
backup_dir="/tmp/phpfpm_${host_name}_${ip_address}_${timestamp}"
backup_archive="${backup_dir}.tar.gz"
php_config="/etc/php.ini"
phpfpm_config="/etc/php-fpm.conf"
phpfpm_pools_dir="/etc/php-fpm.d"

# 함수 정의: 에러 핸들링
cleanup() {
    echo "정리 중: 임시 디렉토리를 삭제합니다..."
    [[ -d "$backup_dir" ]] && rm -rf "$backup_dir"
}
trap cleanup EXIT

# 백업 디렉토리 생성
echo "백업 디렉토리 생성: $backup_dir"
mkdir -p "$backup_dir"

# 파일 복사
echo "PHP-FPM 설정 및 PHP-FPM POOL 디렉토리 복사 중..."
cp -p "$php_config" "$backup_dir/" || { echo "php.ini 복사 실패"; exit 1; }
cp -p "$phpfpm_config" "$backup_dir/" || { echo "php-fpm.conf 복사 실패"; exit 1; }
cp -rp "$phpfpm_pools_dir" "$backup_dir/" || { echo "php-fpm.d 디렉토리 복사 실패"; exit 1; }

# 압축
echo "백업 압축 생성: $backup_archive"
tar cfz "$backup_archive" -C /tmp "$(basename "$backup_dir")" || { echo "압축 실패"; exit 1; }

# 완료 메시지
echo "백업 완료: $backup_archive"
