# padavan_smartdns
script smartdns for hiboy padavan

在自定义脚本防火墙前添加:
```logger -t "SmartDNS" "正在下载smartdns脚本"```
```curl -k -s -o /opt/bin/smartdns.sh --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/Twinzo1/padavan_smartdns/master/smartdns.sh && chmod 755 /opt/bin/smartdns.sh```
