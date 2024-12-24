# Zabbix User Parameter

## Zabbix Agent
### zabbix agent config
```
vim /etc/zabbix/zabbix_agent2.conf
```
```
echo "UserParameter=z_ping[*],echo $1" >> /etc/zabbix/zabbix_agent2.conf
```
```
echo "UserParameter=z_uptime,uptime" >> /etc/zabbix/zabbix_agent2.conf
```
```
zabbix_agent2 -T /etc/zabbix/zabbix_agent2.conf
```
```
systemctl restart zabbix-agent2
```

### zabbix agent
```
zabbix_agentd -t z_uptime
```

## Zabbix Server
### zabbix server
```
zabbix_get -s 211.239.167.24 -k "z_uptime"
```