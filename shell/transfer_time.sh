#!/bin/bash

# 입력값 처리
FILE_SIZE_WITH_UNIT=$1
SPEED_WITH_UNIT=$2

# 단위가 포함된 값을 분리하는 함수
extract_value() {
    echo $1 | sed 's/[^0-9.]//g'  # 숫자와 소수점을 추출
}

extract_unit() {
    echo $1 | sed 's/[0-9.]//g'  # 숫자를 제외한 부분 추출
}

# 단위 변환 함수
convert() {
    case $1 in
        GB)
            echo $((1024 * 1024 * 1024))  # GB -> 바이트 변환
            ;;
        MB)
            echo $((1024 * 1024))  # MB -> 바이트 변환
            ;;
        *)
            echo "Invalid unit. Please use 'GB' or 'MB'."
            exit 1
            ;;
    esac
}

# 파일 크기와 전송 속도에서 숫자와 단위를 분리
FILE_SIZE=$(extract_value $FILE_SIZE_WITH_UNIT)
SPEED=$(extract_value $SPEED_WITH_UNIT)

FILE_UNIT=$(extract_unit $FILE_SIZE_WITH_UNIT)
SPEED_UNIT=$(extract_unit $SPEED_WITH_UNIT)

# 단위 변환
FILE_SIZE_IN_BYTES=$(convert $FILE_UNIT)
SPEED_IN_BYTES=$(convert $SPEED_UNIT)

# 전송 시간 계산
TRANSFER_TIME=$(echo "scale=2; $FILE_SIZE * $FILE_SIZE_IN_BYTES / ($SPEED * $SPEED_IN_BYTES)" | bc)

# 결과 출력
echo "Transfer time: $TRANSFER_TIME seconds"
