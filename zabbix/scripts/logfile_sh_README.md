# LogFile

```
cd /etc/zabbix/zabbix_agent2.d
```

```
curl -fsSL https://raw.githubusercontent.com/anti1346/codes/refs/heads/main/zabbix/scripts/logfile.sh -o logfile.sh
```

```
echo "UserParameter=z_logfile[*],bash logfile.sh" | tee -a /etc/zabbix/zabbix_agent2.conf
```

```
zabbix_agent2 -t z_logfile[/var/log/syslog,5,debug]
```

```
zabbix_get -s ${ZABBIX_AGENT_IP} -k "z_uptime"
```
