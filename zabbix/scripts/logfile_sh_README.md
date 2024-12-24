# LogFile
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
/etc/zabbix/zabbix_agent2.d/logfile.sh /var/log/syslog 5 Starting
```
```
echo "UserParameter=z_logfile[*],/bin/bash /etc/zabbix/zabbix_agent2.d/logfile.sh \$1 \$2 \$3" | tee -a /etc/zabbix/zabbix_agent2.conf
```
```
zabbix_agent2 -T /etc/zabbix/zabbix_agent2.conf
```
```
systemctl restart zabbix-agent2
```
```
zabbix_agent2 -t z_logfile[/var/log/syslog,5,Starting]
```
```
export ZABBIX_AGENT_IP=211.239.167.24
```
```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_logfile[/var/log/syslog,5,Starting]"

```
