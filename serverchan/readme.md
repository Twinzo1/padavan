### padavan_serverchan

* [x] 微信推送

* [x] 钉钉推送

* [ ] TG推送，未测试

### 在自定义脚本防火墙前添加:

```
logger -t "【消息推送】" "serverchan脚本"
curl -k -s -o /opt/bin/smartdns.sh --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/Twinzo1/padavan/master/serverchan/serverchan.sh
chmod 755 /opt/bin/serverchan.sh && /opt/bin/serverchan.sh start
```
### 配置
* 请看脚本内部
* 参照 https://github.com/tty228/luci-app-serverchan 和 https://github.com/zzsj0928/luci-app-serverchand
