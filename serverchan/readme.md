## padavan_serverchan
### 参考 [tty28](https://github.com/tty228/luci-app-serverchan) 和 [zzsj0928](https://github.com/zzsj0928/luci-app-serverchand)，将serverchan移植到padavan
* [x] 微信推送
* [x] 钉钉推送
* [ ] TG推送，未测试
* [x] MAC过滤
* [ ] 免打扰时段，定时推送不受控制（已添加，未完善）
* [x] 支持静态ip绑定的设备名称
* [ ] ~~无人值守任务，不准备添加~~
### 在自定义脚本防火墙前添加:
```
logger -t "【消息推送】" "serverchan脚本"
[ ! -f /opt/bin/serverchan.sh ] && curl -k -s -o /opt/bin/serverchan.sh --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/Twinzo1/padavan/master/serverchan/serverchan.sh
# 主要变量设置
nvram set sc_send_dd="1"
nvram set sc_dd_bot_keyword=""
nvram set sc_dd_bot_token=""
nvram set sc_send_sc="1"
nvram set sc_sckey=""
nvram set serverchan_enable="1"
nvram set sc_oui_data="1"
nvram commit
chmod 755 /opt/bin/serverchan.sh && /opt/bin/serverchan.sh start &
```
### 简单说明
* 定时推送，每天 22:10 进行推送```10 22 * * * /opt/bin/serverchan.sh send```
* 后台监控 ```/opt/bin/serverchan.sh start &```
* 停止 ```nvram set serverchan_enable="0" && nvram commit 或 /opt/bin/serverchan.sh stop```
### 建议
* 如果设备没有设置每日重启，最好添加定时任务，定时清理脚本```0 0 * * * killall serverchan.sh; /opt/bin/serverchan.sh start &```
### 详细配置
* [脚本配置说明](https://github.com/Twinzo1/padavan/blob/master/serverchan/config.md)
# Donate
如果你觉得此项目对你有帮助，请捐助我们，以使项目能持续发展，更加完善。

<img src="https://github.com/Twinzo1/padavan/blob/master/sundry/1.jpg" width = "300" alt="图片描述" align=center />
