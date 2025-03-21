#!/bin/bash

server_list="192.168.0.141 192.168.0.123"
comparefile="/etc/nginx/nginx.conf"

# 기존 결과 파일 삭제
rm -f *.txt

for server in $server_list; do
    echo "Checking $server..."
    ssh vagrant@$server "md5sum $comparefile" > "compare-$server.txt" 2>/dev/null

    # SSH 오류 확인
    if [[ $? -ne 0 ]]; then
        echo "Failed to connect to $server" >&2
        rm -f "$server.txt"
    fi
done

# 파일 개수 확인 후 비교
file_count=$(ls *.txt 2>/dev/null | wc -l)
if [[ $file_count -ge 2 ]]; then
    diff compare-*.txt
else
    echo "Not enough files for comparison."
fi
