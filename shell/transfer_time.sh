#!/bin/bash

# 입력 인자: FILE_SIZE (파일 크기), SPEED (전송 속도)
FILE_SIZE=$1
SPEED=$2
UNIT=$3  # 파일 크기 단위 (GB, MB)

# 단위에서 숫자만 추출하는 함수
get_number() {
    echo $1 | sed 's/[^0-9.]//g'
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
FILE_SIZE_NUM=$(get_number $FILE_SIZE)
SPEED_NUM=$(get_number $SPEED)
FILE_SIZE_UNIT=$(echo $FILE_SIZE | sed 's/[0-9]*//g')
SPEED_UNIT=$(echo $SPEED | sed 's/[0-9]*//g')

# 단위가 맞는지 확인
if [[ "$FILE_SIZE_UNIT" != "GB" && "$FILE_SIZE_UNIT" != "MB" ]]; then
    echo "Invalid file size unit. Use 'GB' or 'MB'."
    exit 1
fi

if [[ "$SPEED_UNIT" != "GB" && "$SPEED_UNIT" != "MB" ]]; then
    echo "Invalid speed unit. Use 'GB' or 'MB'."
    exit 1
fi

# 파일 크기와 전송 속도를 바이트로 변환
FILE_SIZE_IN_BYTES=$(convert $FILE_SIZE_UNIT)
SPEED_IN_BYTES=$(convert $SPEED_UNIT)

# 전송 시간 계산
TRANSFER_TIME=$(echo "scale=2; $FILE_SIZE_NUM * $FILE_SIZE_IN_BYTES / ($SPEED_NUM * $SPEED_IN_BYTES)" | bc)

# 결과 출력
echo "Transfer time: $TRANSFER_TIME seconds"
