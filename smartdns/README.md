### padavan_smartdns
script smartdns for hiboy padavan
不能与与v2ray同用

在自定义脚本防火墙前添加:

```
logger -t "SmartDNS" "正在下载smartdns脚本"
curl -k -s -o /opt/bin/smartdns.sh --connect-timeout 10 --retry 3 https://ghproxy.com/https://raw.githubusercontent.com/Twinzo1/padavan/master/smartdns/smartdns.sh
chmod 755 /opt/bin/smartdns.sh && /opt/bin/smartdns.sh start
```

hiboy已经内置smartdns，在搭建web环境→chinadns-ng里
