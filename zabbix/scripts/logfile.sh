#!/bin/bash

# 파라미터 검증
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <log_file> <minutes> <pattern>"
    exit 1
fi

LOG_FILE="$1"
MINUTE="$2"
PATTERN="$3"

# 로그 파일 존재 여부 확인
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Log file $LOG_FILE does not exist."
    exit 1
fi

# 쉼표 패턴을 정규식으로 변환 (쉼표를 |로 변경)
PATTERN=$(echo "$PATTERN" | sed 's/,/|/g')

# 시간 필터링 기준 계산
TIME_THRESHOLD=$(date -d "${MINUTE} minutes ago" '+%b %_d %H:%M:%S')

# 로그 필터링
tail -n 10000 "$LOG_FILE" | awk -v time="$TIME_THRESHOLD" -v pattern="$PATTERN" '
{
    log_time = $1 " " $2 " " $3;
    if (log_time >= time && $0 ~ pattern) {
        print $0;
    }
}'

