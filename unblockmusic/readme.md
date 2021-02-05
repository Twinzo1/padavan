## 说明
### 参数设置
```
# 设置局域网设备代理模式
# 有多少设备
nvram set wyy_staticnum_x="1"
nvram set wyy_ip_x0="10.0.0.2"
# 代理模式：["disable","http","https"]
## 不代理HTTP和HTTPS，不代理HTTP，不代理HTTPS
nvram set wyy_ip_road_x0="disable"

# 启用["0","1"]
nvram set wyy_enable="1"

# 解锁程序：本地解锁还是云解锁["go","cloud"]
nvram set wyy_apptype="cloud"

# 本地解锁，音源选择
## ["default","netease","qq","xiami","baidu","kugou","kuwo","migu","joox","coustom"]
## 默认，网易云音乐，QQ音乐，虾米音乐，百度音乐，酷狗音乐，酷我音乐，咕咪音乐，JOOX音乐，自定义
nvram set wyy_musicapptype="default"

# 启用无损音质["0","1"]
nvram set wyy_flac="1"

# 云解锁是否自定义
## [CTCGFW] 腾讯云上海（高音质）："cdn-shanghai.service.project-openwrt.eu.org:30000:30001"
## [hyird] 阿里云北京（高音质）："hyird.xyz:30000:30001"
## 阿里云北京（高音质）："39.96.56.58:30000:30000">[Sunsky]
## [CTCGFW] 移动河南（无损音质）："cdn-henan.service.project-openwrt.eu.org:33221:33222"
## 自定义："custom"
nvram set wyy_cloudserver="custom"

# 自定义云解锁服务器（IP[域名]:HTTP端口:HTTPS端口）
## 如果服务器为LAN内网IP，需要将这个服务器IP放入例外客户端 (不代理HTTP和HTTPS)
nvram set wyy_coustom_server="10.0.0.2:5200:5201"

```
### 下载
```
logger -t "【音乐解锁】" "正在下载旁路由辅助脚本"
if [ ! -e "/etc/storage/unblockmusic.sh" ]; then
    curl -k -s -o /etc/storage/bypa.sh --connect-timeout 10 --retry 3 https://ghproxy.com/https://raw.githubusercontent.com/Twinzo1/learning/master/padavan/unblockmusic/unblockmusic.sh -v
    chmod 755 /etc/storage/unblockmusic.sh && mtd_storage.sh save
    /etc/storage/unblockmusic.sh start
else
    logger -t "【音乐解锁】" "脚本已存在，无需下载"
fi
```
