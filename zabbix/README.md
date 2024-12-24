# Zabbix User Parameter

## Zabbix Agent
### Zabbix Agent 구성 파일 편집
```
vim /etc/zabbix/zabbix_agent2.conf
```
### (또는) UserParameter 추가
##### 테스트용 UserParameter (입력 받은 문자열을 그대로 반환)
```
echo "UserParameter=z_echo[*],echo \$1" | tee -a /etc/zabbix/zabbix_agent2.conf
```
##### ping 명령어로 특정 IP가 응답하는지 확인 (예: 3번 시도)
```
echo 'UserParameter=z_ping[*],ping -c 3 -W 3 \$1 | grep -v grep | grep "from \$1" | wc -l' | tee -a /etc/zabbix/zabbix_agent2.conf
```
##### 시스템의 uptime 정보 출력
```
echo "UserParameter=z_uptime,uptime" | tee -a /etc/zabbix/zabbix_agent2.conf
```
##### 사용자 정의 명령어 (예: $1로 입력 받은 명령어 실행)
```
echo "UserParameter=z_command[*],\$1" | tee -a /etc/zabbix/zabbix_agent2.conf
```
#### Zabbix Agent 설정 파일 확인
```
zabbix_agent2 -T /etc/zabbix/zabbix_agent2.conf
```
#### Zabbix Agent 재시작
```
systemctl restart zabbix-agent2
```

### Zabbix Agent 테스트
##### "test string" 출력
```
zabbix_agent2 -t z_echo["test string"]
```
##### 127.0.0.1에 ping 응답 여부
```
zabbix_agent2 -t z_ping[127.0.0.1]
```
##### 시스템 uptime 출력
```
zabbix_agent2 -t z_uptime
```
##### 'date' 명령어 출력
```
zabbix_agent2 -t z_command[date]
```

## Zabbix Server
### Zabbix Server에서 테스트
```
export ZABBIX_AGENT_IP=127.0.0.1
```
```
echo ${ZABBIX_AGENT_IP}
```
### UserParameter 결과 확인
##### "test string" 출력
```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_echo[test string]"
```
##### 127.0.0.1에 ping 응답 여부
```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_ping[127.0.0.1]"
```
##### 시스템 uptime 출력
```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_uptime"
```
##### 'date' 명령어 출력
```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_command[date]"
```
