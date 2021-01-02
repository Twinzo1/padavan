## 配置说明
* "="后面的是默认值
### 配置
>#### 基本设置
>>* 本设备名称 ```nvram set sc_device_name="PADAVAN"```
>>* 检测时间间隔 ```nvram set sc_sleeptime="60"```
>>* MAC设备信息数据库 ```nvram_get sc_oui_data="0"```
>>> * 关闭：0或为空
>>> * 下载简化版：1
>>> * 下载完整版：2
>>> * 网络查询：3
>#### 推送模式选择
>>##### 钉钉推送
>>>* 推送开关 ```nvram_get sc_send_dd="0"```
>>>* 关键词 ```nvram_get sc_dd_bot_keyword=""```
>>>* token ```nvram_get sc_dd_bot_token=""```
>>##### Telegram推送信息
>>>* 推送开关 ```nvram_get sc_send_tg="0"```
>>>* TOKEN ```nvram_get sc_tg_token=""```
>>>* User ID ```nvram_get sc_tg_user_id=""```
>>#####  微信（方糖）推送
>>>* 推送开关 ```nvram_get sc_send_sc="0"```
>>>*	SCKEY ```nvram_get sc_sckey=""```
>#### 推送内容
>>* ipv4 变动通知 ```nvram_get sc_sc_ipv4="0"```
>>* ipv6 变动通知 ```nvram_get sc_sc_ipv6="0"```
>>* 设备上线通知 ```nvram_get sc_sc_up="0"```
>>* 设备离线通知 ```nvram_get sc_sc_down="0"```
>>* CPU 负载报警 ```nvram_get sc_cpuload_enable="1"```
>>* 负载报警阈值 ```nvram_get sc_cpuload 2```
>>* 是否推送当前设备列表 ```nvram_get sc_sc_cl_ls 0```
>#### 定时推送
>>* 路由器状态推送控制 ```nvram_get sc_router_status 1```
>>* 推送标题，不要有空格 ```nvram_get sc_send_title 主路由```
>>* 内容页标题，不要有空格，针对钉钉 ```nvram_get sc_content_title "主路由"```
>>* WAN信息 ```nvram_get sc_router_wan 1```
>>* 客户端列表 ```nvram_get sc_client_list 1```
### 高级设置
>* 设备上线检测超时 ```nvram_get sc_up_timeout 2```
>* 设备离线检测超时 ```nvram_get sc_down_timeout 20```
>* 离线检测次数 ```nvram_get sc_time_r_c 2```
### 其它设置
>* 工作目录 ```nvram_get sc_workdir "/tmp/serverchan/"```
