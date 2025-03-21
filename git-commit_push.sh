#!/bin/bash

# 스크립트 실행 중 오류 발생 시 즉시 종료
set -e

# 현재 날짜와 시간을 커밋 메시지에 추가
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# 현재 브랜치 가져오기
CURRENT_BRANCH=$(git branch --show-current)

# 변경 사항이 있는지 확인
if [[ -z $(git status --porcelain) ]]; then
    echo -e "\033[33m[INFO] 변경 사항이 없습니다. 스크립트를 종료합니다.\033[0m"
    exit 0
fi

# 상태 출력
echo -e "\033[34m[INFO] 현재 브랜치: \033[1m$CURRENT_BRANCH\033[0m"
echo -e "\033[34m[INFO] 변경 사항을 스테이징합니다...\033[0m"

# 변경 사항 스테이징
git add -A

# 커밋 생성
echo -e "\033[34m[INFO] 커밋 메시지: '\033[1mcommit update : $DATE\033[0m'"
git commit -m "commit update : $DATE"

# 변경 사항 푸시
echo -e "\033[34m[INFO] 변경 사항을 원격 저장소로 푸시합니다...\033[0m"
if ! git push origin "$CURRENT_BRANCH"; then
    echo -e "\033[31m[ERROR] git push 실패. 원격 저장소를 확인하세요.\033[0m"
    exit 1
fi

echo -e "\033[32m[SUCCESS] 작업이 완료되었습니다!\033[0m"
