#!/bin/bash

git config --global user.email "you@example.com"
git config --global user.name "YourName"

# 현재 시간을 변수에 저장
current_time=$(date '+%Y%m%d-%H%M%S')

# 변경 사항을 추가하고 커밋
git add .

git commit -m "Update : $current_time"

# 변경 사항을 푸시
git push origin main
