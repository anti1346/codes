# LogFile
### 스크립트 다운로드 및 설정
```
cd /etc/zabbix/zabbix_agent2.d
```
```
curl -fsSL https://raw.githubusercontent.com/anti1346/codes/refs/heads/main/zabbix/scripts/logfile.sh -o logfile.sh
```
```
chmod +x logfile.sh
```
```
/etc/zabbix/zabbix_agent2.d/logfile.sh /var/log/syslog 5 error
```

#### Syslog severity levels
- Emergency	: 시스템을 사용할 수 없습니다
- Alert	: 즉각적인 조치를 취해야 합니다.
- Critical : 중요한 조건
- Error	: 오류 조건

### UserParameter 추가
```
echo "UserParameter=z_logfile[*],/bin/bash /etc/zabbix/zabbix_agent2.d/logfile.sh \$1 \$2 \$3" | tee -a /etc/zabbix/zabbix_agent2.conf
```
### Zabbix 에이전트 구성 파일 검증
```
zabbix_agent2 -T /etc/zabbix/zabbix_agent2.conf
```
### Zabbix 에이전트 재시작
```
systemctl restart zabbix-agent2
```
### 테스트
```
zabbix_agent2 -t z_logfile[/var/log/syslog,5,error]
```
```
export ZABBIX_AGENT_IP=127.0.0.1
```
```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_logfile[/var/log/syslog,5,error]"

```
