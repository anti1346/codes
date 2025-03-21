#!/bin/bash

# 스크립트 실행 중 오류 발생 시 즉시 종료
set -e

# 현재 브랜치 가져오기
CURRENT_BRANCH=$(git branch --show-current)

echo -e "\033[34m[INFO] 현재 브랜치: \033[1m$CURRENT_BRANCH\033[0m"

# 로컬 변경 사항 확인
if [[ -n $(git status --porcelain) ]]; then
    echo -e "\033[33m[INFO] 로컬 변경 사항이 감지되었습니다. 임시 저장 후 진행합니다.\033[0m"
    git stash push -m "Auto stash before pull"
fi

# 원격 변경 사항 가져오기
echo -e "\033[34m[INFO] 최신 변경 사항을 가져옵니다...\033[0m"
git pull origin "$CURRENT_BRANCH"

# 강제 초기화 옵션 (필요할 때만 실행)
if [[ "$1" == "--hard-reset" ]]; then
    echo -e "\033[31m[WARNING] 강제 초기화를 수행합니다. 로컬 변경 사항이 삭제됩니다!\033[0m"
    git fetch origin
    git reset --hard "origin/$CURRENT_BRANCH"
fi

echo -e "\033[32m[SUCCESS] Git 업데이트 완료!\033[0m"
