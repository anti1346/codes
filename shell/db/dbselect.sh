#!/bin/bash

# MySQL 연결 정보
LOGIN_PATH="testdb"             # MySQL 로그인 경로 설정
TIMEOUT_DURATION=3              # 타임아웃 시간 (초)
SLEEP_INTERVAL=1                # 반복 간격 (초)
QUERY="SELECT NOW();"           # 실행할 쿼리 (예: 현재 시간 확인)

# 무한 반복
while true; do
    # 현재 시간 출력
    echo "[$(date)] Starting query execution..."
    echo "----------------------------------------"

    # MySQL 쿼리 실행
    RESULT=$(timeout "$TIMEOUT_DURATION" mysql --login-path="$LOGIN_PATH" -e "$QUERY" 2>&1)
    
    # 결과 출력
    if [ $? -eq 124 ]; then
        echo "[$(date)] Query execution timed out."
    else
        echo "$RESULT"
        echo "[$(date)] Query executed successfully."
    fi

    echo "----------------------------------------"
    echo ""

    # 1초 대기
    sleep "$SLEEP_INTERVAL"
done
