#!/bin/bash
set -euo pipefail

# 변수 정의
backup_dir="/tmp/$(hostname)-$(date +%Y%m%d)"
backup_archive="${backup_dir}.tar.gz"
nginx_config_dir="/etc/nginx"

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
echo "NGINX 설정 및 SSL 디렉토리 복사 중..."
cp -p "$nginx_config_dir/nginx.conf" "$backup_dir/" || { echo "nginx.conf 복사 실패"; exit 1; }
cp -rp "$nginx_config_dir/conf.d" "$backup_dir/" || { echo "conf.d 복사 실패"; exit 1; }
cp -rp "$nginx_config_dir/ssl" "$backup_dir/" || { echo "ssl 디렉토리 복사 실패"; exit 1; }

# 압축
echo "백업 압축 생성: $backup_archive"
tar cfz "$backup_archive" -C /tmp "$(basename "$backup_dir")" || { echo "압축 실패"; exit 1; }

# 완료 메시지
echo "백업 완료: $backup_archive"
