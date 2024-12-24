# Zabbix User Parameter

## Zabbix Agent
### zabbix agent config
#### zabbix agent config edit
```
vim /etc/zabbix/zabbix_agent2.conf
```
```
echo "UserParameter=z_ping[*],echo \$1" | tee -a /etc/zabbix/zabbix_agent2.conf
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
zabbix_agent2 -t z_ping
```
```
zabbix_agent2 -t z_uptime
```
```
zabbix_agent2 -t z_command
```

## Zabbix Server
### zabbix server
```
zabbix_get -s 211.239.167.24 -k "z_command"
```
```
zabbix_get -s 211.239.167.24 -k "z_ping"
```
```
zabbix_get -s 211.239.167.24 -k "z_uptime"
```
