## 配置说明
* "="后面的是默认值，0为禁用，1为启用
### 配置
>#### 基本设置
>>* 本设备名称 ```nvram set sc_device_name="PADAVAN"```
>>* 检测时间间隔 ```nvram set sc_sleeptime="60"```
>>* MAC设备信息数据库 ```nvram set sc_oui_data="0"```
>>> * 关闭：0或为空
>>> * 下载简化版：1
>>> * 下载完整版：2
>>> * 网络查询：3
>#### 推送模式选择
>>##### 钉钉推送
>>>* 推送开关 ```nvram set sc_send_dd="0"```
>>>* 关键词 ```nvram set sc_dd_bot_keyword=""```
>>>* token ```nvram set sc_dd_bot_token=""```
>>##### Telegram推送信息
>>>* 推送开关 ```nvram set sc_send_tg="0"```
>>>* TOKEN ```nvram set sc_tg_token=""```
>>>* User ID ```nvram set sc_tg_user_id=""```
>>#####  微信（方糖）推送
>>>* 推送开关 ```nvram set sc_send_sc="0"```
>>>*	SCKEY ```nvram set sc_sckey=""```
>#### 推送内容
>>* ipv4 变动通知 ```nvram set sc_sc_ipv4="0"```
>>* ipv6 变动通知 ```nvram set sc_sc_ipv6="0"```
>>* 设备上线通知 ```nvram set sc_sc_up="0"```
>>* 设备离线通知 ```nvram set sc_sc_down="0"```
>>* CPU 负载报警 ```nvram set sc_cpuload_enable="1"```
>>* 负载报警阈值 ```nvram set sc_cpuload="2"```
>>* 是否推送当前设备列表 ```nvram set sc_sc_cl_ls="0"```
>#### 定时推送
>>* 路由器状态推送控制 ```nvram set sc_router_status="1"```
>>* 推送标题，不要有空格 ```nvram set sc_send_title="主路由"```
>>* 内容页标题，不要有空格，针对钉钉 ```nvram set sc_content_title="主路由"```
>>* WAN信息 ```nvram set sc_router_wan="1"```
>>* 客户端列表 ```nvram set sc_client_list="1"```
>#### 免打扰
>>* 免打扰时段设置```nvram set sc_sc_sheep=""```
>>>* 关闭：留空
>>>* 模式一：1
>>>* 模式二：2
>>* 免打扰开始时间```nvram set sc_starttime="06:00"```
>>>* 支持0600或6
>>* 免打扰结束时间```nvram set sc_endtime="18:00"```
>>>* 支持1800或18
>>>* 设为下午6:30，填18:30或1830
>>* MAC过滤，只能选其中一种
>>>* 关注列表（仅通知列表内设备）```nvram set sc_sc_blacklist=""```
>>>>* ```nvram set sc_sc_blacklist="'11:11:11:11:11:11' '12:91:11:11:11:11'"```
>>>* 忽略列表（忽略列表内设备）```nvram set sc_sc_whitelist=""```
>>>>* ```nvram set sc_sc_blacklist="'11:11:11:24:11:11' '12:91:11:44:88:11'"```
>>>* 接口名称（仅通知次接口设备）```nvram set sc_sc_interface=""```
### 高级设置
>* 设备上线检测超时 ```nvram set sc_up_timeout="2"```
>* 设备离线检测超时 ```nvram set sc_down_timeout="20"```
>* 离线检测次数 ```nvram set sc_time_r_c="2"```
### 其它设置
>* 工作目录 ```nvram set sc_workdir="/tmp/serverchan/"```
>* 总开关（定时推送不受控制）```nvram set serverchan_enable="0"```
> #### 设备别名设置
>> * 以此类推
  ```
  nvram set sc_aliasmac_x0="00:00:00:00:00:00"; nvram set sc_aliasname_x0="我的电脑"
  nvram set sc_aliasmac_x1="11:11:11:11:11:11"; nvram set sc_aliasname_x1="我的手机"
  nvram set sc_aliasmac_x2=""; nvram set sc_aliasname_x2=""
  nvram set sc_aliasmac_x3=""; nvram set sc_aliasname_x3=""
  nvram set sc_aliasmac_x4=""; nvram set sc_aliasname_x4=""
  ```
