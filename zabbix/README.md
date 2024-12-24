# Zabbix User Parameter

## Zabbix Agent
### zabbix agent config
#### zabbix agent config edit
```
vim /etc/zabbix/zabbix_agent2.conf
```
```
echo "UserParameter=z_echo[*],echo \$1" | tee -a /etc/zabbix/zabbix_agent2.conf
```
```
echo 'UserParameter=z_ping[*],ping -c 3 -W 3 \$1 | grep -v grep | grep "from \$1" | wc -l' | tee -a /etc/zabbix/zabbix_agent2.conf
```
```
echo "UserParameter=z_uptime,uptime" | tee -a /etc/zabbix/zabbix_agent2.conf
```
```
echo "UserParameter=z_command[*],\$1" | tee -a /etc/zabbix/zabbix_agent2.conf
```
#### zabbix agent config check
```
zabbix_agent2 -T /etc/zabbix/zabbix_agent2.conf
```
#### zabbix agent restart
```
systemctl restart zabbix-agent2
```

### zabbix agent
```
zabbix_agent2 -t z_echo["test string"]
```
```
zabbix_agent2 -t z_ping[127.0.0.1]
```
```
zabbix_agent2 -t z_uptime
```
```
zabbix_agent2 -t z_command[date]
```

## Zabbix Server
### zabbix server
```
zabbix_get -s {zabbix agent ip} -k "z_echo["test string"]"
```
```
zabbix_get -s {zabbix agent ip} -k "z_ping[127.0.0.1]"
```
```
zabbix_get -s {zabbix agent ip} -k "z_uptime"
```
```
zabbix_get -s {zabbix agent ip} -k "z_command[date]"
```
