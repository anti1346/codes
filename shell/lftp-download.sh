#!/bin/bash

# 환경 변수 설정
USER="FTP_ID"
PASSWORD="FTP_PASSWORD"
SERVER="FTP_SERVER_IP"
PORT="FTP_PORT"
REMOTE_DIR="/"
LOCAL_DIR="/root/lftp/prod"
LOG_FILE="/root/lftp/log/lftp_mirror.log"

# 로그 파일 디렉토리 생성
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"

# lftp 명령 실행
{
    echo "Starting FTP mirroring process..."
    lftp -u "$USER","$PASSWORD" "ftp://$SERVER:$PORT" <<EOF
    mirror --verbose $REMOTE_DIR $LOCAL_DIR
    bye
EOF

    if [ $? -eq 0 ]; then
        echo "FTP mirroring completed successfully."
    else
        echo "FTP mirroring encountered an error."
    fi
} 2>&1 | tee -a "$LOG_FILE"

# 권한 설정을 통해 로그 파일의 보안도 강화
chmod 600 "$LOG_FILE"