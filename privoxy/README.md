### padavan_privoxy
script privoxy for padavan

在开机启动前添加:

```
logger -t "【Privoxy】" "正在下载Privoxy脚本"
curl -k -s -o /opt/bin/privoxy.sh --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/Twinzo1/padavan/master/privoxy/privoxy.sh 
chmod 755 /opt/bin/privoxy.sh && /opt/bin/privoxy.sh start
```

hiboy已经内置smartdns，在搭建web环境→chinadns-ng里
