#!/bin/sh
# padavan使用function声明函数会出错
# 定时任务设定 10 22 * * * /usr/bin/serverchan/serverchan send &
# 设备别名设置
# 版本：v1.80.6
# 详细配置请点击：https://github.com/Twinzo1/padavan/blob/master/serverchan/config.md

alias DATE="date '+%Y-%m-%d %H:%M:%S'"
alias CPUUSAGE="cat /proc/stat|grep '^cpu '|awk '{print \$2+\$3+\$4+\$5+\$6+\$7+\$8 \" \" \$2+\$3+\$4+\$7+\$8}'"
GW4_WAN=`curl -s localhost/device-map/internet.asp | grep "function wanlink_gw4_wan" | awk -F '[{;]' '{print $2}' | awk '{print $2}' | awk -F "'" '{print \$2}'`
alias WANLINK_UPTIME="curl -s localhost/device-map/internet.asp | grep \"function wanlink_uptime\" | awk -F '[{;]' '{print \$2}' | awk '{print \$2}'"

nvram_get() {
	local ret=$(nvram get $1 2>/dev/null)
	echo ${ret:=$2}
}

serverchan_init(){
############################# 变量填写 #############################################
	device_name=`nvram_get sc_device_name "PADAVAN"`
	sleeptime=`nvram_get sc_sleeptime 60`
	oui_data=`nvram_get sc_oui_data 0`
	oui_base="${WORKDIR}oui_base.txt"
# 钉钉推送信息，需要填写关键词
	SEND_DD=`nvram_get sc_send_dd 0`
	DD_BOT_KEYWORD=`nvram_get sc_dd_bot_keyword`
	DD_BOT_TOKEN=`nvram_get sc_dd_bot_token`
# Telegram推送信息
	SEND_TG=`nvram_get sc_send_tg 0`
	TG_BOT_TOKEN=`nvram_get sc_tg_token`
	TG_USER_ID=`nvram_get sc_tg_user_id`
	TG_API="https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage"
# 微信（方糖）推送信息
	SEND_SC=`nvram_get sc_send_sc 0`
	SCKEY=`nvram_get sc_sckey`
# 推送内容
	SERVERCHAN_IPV4=`nvram_get sc_sc_ipv4 0`
	SERVERCHAN_IPV6=`nvram_get sc_sc_ipv6 0`
	serverchan_up=`nvram_get sc_sc_up 0`
	serverchan_down=`nvram_get sc_sc_down 0`
	cpuload_enable=`nvram_get sc_cpuload_enable 1`
	cpuload=`nvram_get sc_cpuload 2`
	serverchan_client_list=`nvram_get sc_sc_cl_ls 0`
# 定时推送
	ROUTER_STATUS=`nvram_get sc_router_status 1`
	SEND_TITLE=`nvram_get sc_send_title 主路由`
	CONTENT_TITLE=`nvram_get sc_content_title "主路由"`
	ROUTER_WAN=`nvram_get sc_router_wan 1`
	CLIENT_LIST=`nvram_get sc_client_list 1`
# 免打扰
	serverchan_sheep=`nvram_get sc_sc_sheep`
	sheep_start_time=`nvram_get sc_starttime "06:00"`
	sheep_end_time=`nvram_get sc_endtime "18:00"`
	serverchan_blacklist=`nvram_get sc_sc_blacklist`
	serverchan_whitelist=`nvram_get sc_sc_whitelist`
	serverchan_interface=`nvram_get sc_sc_interface`
# 高级设置
	UP_TIMEOUT=`nvram_get sc_up_timeout 2`
	DOWN_TIMEOUT=`nvram_get sc_down_timeout 20`
	TIMEOUT_RETRY_COUNT=`nvram_get sc_time_r_c 2`
# 其它设置
	WORKDIR=`nvram_get sc_workdir "/tmp/serverchan/"`
######################################################################################
	[ $SEND_DD -eq "1" ] && APPTYPE="钉钉"
	[ $SEND_TG -eq "1" ] && APPTYPE="${APPTYPE}/TG"
	[ $SEND_SC -eq "1" ] && APPTYPE="${APPTYPE}/server酱"
	[ -z "APPTYPE" ] && logger -t "【消息推送】" "未选择推送类型，脚本退出" && exit
	[ ! -d "$WORKDIR" ] && mkdir -p "$WORKDIR"
	markdown_splitline="\n\n---\n\n";markdown_linefeed="\n\n";markdown_tab="     ";markdown_space=" "
	down_oui &
	echo "`DATE` 【初始化】载入在线设备"
	> ${WORKDIR}send_enable.lock && serverchan_first; deltemp
	echo "`DATE` 【初始化】初始化完成"
}

# 同一网段判断
netsegment(){
	wan_mod=`nvram get wan_route_x`
	[ "$wan_mod" = "IP_Bridged" ] && echo "" && return
	lan_ipaddr=`nvram get lan_ipaddr`
	lan_netmask=`nvram get lan_netmask`
}

# 获取静态ip设置的设备名称
dhcp_staticname(){
	local tmp_mac=`echo "$1" | sed 's/://g'`
	local tmp_order=`nvram show | grep "dhcp_staticmac_x" | grep -i "$tmp_mac" | awk -F "[_|=]" '{print $3}'` 
	[ -n "$tmp_order" ] && local tmp_name=`nvram show | grep "dhcp_staticname_x" | grep "$tmp_order"= | awk -F "=" '{print $2}'`
	echo $tmp_name
}

# 获取设备别名
alias_name(){
	local tmp_order=`nvram show | grep "sc_aliasmac_x" | grep -i "$1" | awk -F "[_|=]" '{print $3}'` 
	[ -n "$tmp_order" ] && local tmp_name=`nvram show | grep "sc_aliasname_x" | grep "$tmp_order"= | awk -F "=" '{print $2}'`
	echo $tmp_name
}

# 清理临时文件
deltemp(){
	unset title	content
	rm -f ${WORKDIR}title ${WORKDIR}content ${WORKDIR}top ${WORKDIR}tmp_downlist ${WORKDIR}send_enable.lock >/dev/null 2>&1
	LockFile unlock
}

# 获取 ip
getip(){
	[ ! "$1" ] && return
	if [ $1 == "wanipv4" ] ;then
		local wanIP=`/sbin/ifconfig | grep "inet addr" | grep -Ev "$(hostname -i)|127.0.0.1" | awk '{print $2}' | awk -F ":" '{print $2}'`
		echo "$wanIP"
	elif [ $1 == "hostipv4" ] ;then
		local ipv4_URL="members.3322.org/dyndns/getip"
		local hostIP=$(curl -k -s -4 ${ipv4_URL})
		echo "$hostIP"
	elif [ $1 == "wanipv6" ] ;then
		local wanIPv6=$(ip addr show|grep -v deprecated|grep -A1 'inet6 [^f:]'|sed -nr ':a;N;s#^ +inet6 ([a-f0-9:]+)/.+? scope global .*? valid_lft ([0-9]+sec) .*#\2 \1#p;ta'|sort -nr|head -n1|awk '{print $2}')
		[ -z "$wanipv6" ] && local wanIPv6=`curl -s localhost/device-map/internet.asp | grep "function wanlink_ip6_wan" | awk -F '[{;]' '{print $2}'|  awk -F "['/]" '{print $2}'`
		echo "$wanIPv6"
	elif [ $1 == "hostipv6" ] ;then
		local ipv6_URL="v6.ipv6-test.com/api/myip.php"
		local hostIPv6=$(curl -k -s -6 ${ipv6_URL})
		echo "$hostIPv6"
	fi
}

# 获取正确的时间设置
format_time(){
	[ -z "$1" ] && echo "" && return
	local tmp_time=`echo $1 | sed 's/://'`
	[ ${#tmp_time} -ge 5 ] && logger -t "【${APPTYPE}推送】" "免打扰时间参数设置错误" && echo "" && return
	[ ${#tmp_time} -le 3 ] && echo `echo ${tmp_time}000 | cut -c 1-4`
}

# 免打扰检测
serverchan_disturb(){
	[ -z "$serverchan_sheep" ] || [ -z "$sheep_start_time" ] || [ -z "$sheep_end_time" ] && return 0
	local nowtime=`date +%H%M`
	local starttime=`format_time "$sheep_start_time"`
	local endtime=`format_time "$sheep_end_time"`
	if [ $nowtime -ge $endtime -a $starttime -lt $endtime ] || [ $nowtime -lt $starttime -a $starttime -lt $endtime ] || [ $nowtime -lt $starttime -a $nowtime -ge $endtime -a $starttime -gt $endtime ]; then
		unset sheep_starttime
		return 0
	else
		[ -z "$sheep_starttime" ] && logger -t "【${APPTYPE}推送】" "【免打扰】夜深了，该休息了" && sheep_starttime=`date +%s`
		if [ "$serverchan_sheep" -eq "1" ] ;then
			while [ `date +%H%M` -lt "$endtime" ]; do
				[ $(nvram get serverchan_enable) -ne "1" ] && close || sleep 1 
				sleep $sleeptime
			done
		elif  [ "$serverchan_sheep" -eq "2" ] ;then
			disturb_text="【免打扰】"
			return 1
		fi
	fi
}

# 检查CPU状态
cpu_load(){
	if [ "$cpuload_enable" -eq "1" ] && [ ! -z "$cpuload" ]; then
		[ -z "$cpuload_time" ] && cpuload_time=`date +%s`
		local cpu_fuzai=`cat /proc/loadavg|awk '{print $1}'` 2>/dev/null
		[ -z "$cpu_fuzai" ] && logger -t "【${APPTYPE}推送】" "无法读取设备负载，请检查命令！！！"
		[ `expr $cpu_fuzai \> $cpuload` -eq "1" ] && \
		( logger -t "【${APPTYPE}推送】" "【！！警报！！】 CPU 负载过高: ${cpu_fuzai}"; cputop log ) || cpuload_time=`date +%s`
		
		if [ "$((`date +%s`-$cpuload_time))" -ge "300" ] && [ -z "$cpucd_time" ]; then
			unset getlogtop
			[ ! -z "$title" ] && $(echo "$title"|grep -q "过高") && title="设备报警！" || title="CPU 负载过高！"
			cpucd_time=`date +%s`
			logger -t "【${APPTYPE}推送】" " CPU 负 载过高: ${cpu_fuzai}"
			content="${content}${markdown_splitline}#### <font color=#FF6666>CPU 负载过高</font>${markdown_linefeed}${markdown_tab}CPU 负载已连续五分钟超过预设${markdown_linefeed}${markdown_tab}接下来一小时不再提示${markdown_linefeed}${markdown_tab}当前负载：${cpu_fuzai}"
			cputop
		elif [ ! -z "$cpucd_time" ] && [ "$((`date +%s`-$cpucd_time))" -ge "3300" ] ;then
			unset cpucd_time
		fi
	fi
}

# CPU占用进程
cputop(){
	[ -z "$1" ] && content="${content}${markdown_splitline}#### 当前 CPU 占用前三的进程"
	local i=1 && local top_i=5 && `top -bn 1 > ${WORKDIR}top` >/dev/null 2>&1
	while [ $i -le 3 ]; do
		if ( ! cat ${WORKDIR}top|awk 'NR=='${top_i}|grep -q "top -bn 1" ); then
			local top_name=`cat ${WORKDIR}top|awk 'NR=='${top_i}|awk '{print $8}'`; [ "$top_name" == "/bin/sh" ] || [ "$top_name" == "/bin/bash" ] && local top_name=`cat ${WORKDIR}top|awk 'NR=='${top_i}|awk '{print $9}'`
			local top_load=`cat ${WORKDIR}top|awk 'NR=='${top_i}|awk '{print $7}'`
			local temp_top="${top_name} ${top_load}"
			[ ! -z "$1" ] && local logtop="$logtop  $temp_top" || content="${content}${markdown_linefeed}${markdown_tab}${temp_top}"
			local i=`expr ${i} + 1`
		fi
		local top_i=`expr ${top_i} + 1`
	done
	[ ! -z "$1" ] && logger -t "【${APPTYPE}推送】" "【！！警报！！】 CPU 占用前三: ${logtop}"
	rm -f ${WORKDIR}top >/dev/null 2>&1
}

# CPU 占用率
getcpu(){
	local AT=`CPUUSAGE`; sleep 3; local BT=`CPUUSAGE`
	printf "%.01f%%" $(echo ${AT} ${BT}|awk '{print (($4-$2)/($3-$1))*100}')
} 
# ping
getping(){
	for i in `seq 1 ${3}`; do
		( ! echo "$ip_ms"|grep -q "ms" ) && local ip_ms=$( arping -I `cat /proc/net/arp|grep -w ${1}|awk '{print $6}'|grep -v "^$"|sort -u` -c 20 -f -w ${2} $1 ) 2>/dev/null
		( ! echo "$ip_ms"|grep -q "ms" ) && local ip_ms=`ping -c 5 -w ${2} ${1}|grep -v '100% packet loss'` 2>/dev/null
		( ! echo "$ip_ms"|grep -q "ms" ) && sleep 1
	done
	( echo "$ip_ms"|grep -q "ms" )
}

# 发送定时数据
send(){
	local send_disturb=$?
	router_status=$ROUTER_STATUS
	[ -z "$SEND_TITLE" ] && local SEND_TITLE="路由状态："
	[ ! -z "$CLIENT_LIST" ] && [ "$CLIENT_LIST" -eq "1" ] && > ${WORKDIR}send_enable.lock && serverchan_first &

	if [ "$router_status" -eq "1" ]; then
		local systemload=`cat /proc/loadavg|awk '{print $1" "$2" "$3}'`
		local cpuload=`getcpu`
		local ramload=`free -m|sed -n '2p'|awk '{print""($3/$2)*100"%"}'`
		local systemstatustime=`cat /proc/uptime|awk -F. '{run_days=$1 / 86400;run_hour=($1 % 86400)/3600;run_minute=($1 % 3600)/60;run_second=$1 % 60;printf("运行时间：%d天%d时%d分%d秒",run_days,run_hour,run_minute,run_second)}'`;unset run_days run_hour run_minute run_second
		local wanlink_uptime=`WANLINK_UPTIME | awk -F. '{run_days=$1 / 86400;run_hour=($1 % 86400)/3600;run_minute=($1 % 3600)/60;run_second=$1 % 60;printf("外网连接时间：%d天%d时%d分%d秒",run_days,run_hour,run_minute,run_second)}'` && unset run_days run_hour run_minute run_second
		local send_content="${send_content}${markdown_splitline}#### **<font color=#76CCFF>系统运行状态</font>**"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}平均负载：${systemload}"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}CPU占用：${cpuload}"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}内存占用：${ramload}"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}${systemstatustime}"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}${wanlink_uptime}"
	fi

	if [ ! -z "$ROUTER_WAN" ] && [ "$ROUTER_WAN" -eq "1" ]; then
		local send_wanIP=`getip wanipv4`;local send_hostIP=`getip hostipv4`
		local send_content="${send_content}${markdown_splitline}#### **<font color=#76CCFF>WAN 口信息</font>**${markdown_linefeed}${markdown_tab}接口ip:${send_wanIP}"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}外网ip:${send_hostIP}"
		if [ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -ne "0" ]; then
			local send_wanIPv6=`getip wanipv6`;local send_hostIPv6=`getip hostipv6`
			local send_content="${send_content}${markdown_linefeed}${markdown_tab}IPV6接口ip:${send_wanIPv6}"
			local send_content="${send_content}${markdown_linefeed}${markdown_tab}IPV6外网ip:${send_hostIPv6}"
		fi
		( ! echo "$send_wanIP"|grep -q -w ${send_hostIP} ) && local send_content="${send_content}${markdown_linefeed}${markdown_tab}外网 ip 与接口 ip 不一致，你的 ipv4地址 不是公网 ip"
		local send_content="${send_content}${markdown_linefeed}${markdown_tab}${wanstatustime}"
	fi

	if [ ! -z "$CLIENT_LIST" ] && [ "$CLIENT_LIST" -eq "1" ]; then
		wait
		local IPLIST=`cat ${WORKDIR}ipAddress 2>/dev/null|awk '{print $1}'`
		[ -z "$IPLIST" ] && local send_content="${send_content}${markdown_splitline} \n #### **<font color=#FF6666>当前无在线设备</font>**" || local send_content="${send_content}${markdown_splitline}#### **<font color=#76CCFF>在线设备</font>**"
		for ip in $IPLIST; do
			[ "$ip" == "$GW4_WAN" ] && continue
			local time_up=`cat ${WORKDIR}ipAddress|grep -w ${ip}|awk '{print $4}'|grep -v "^$"|sort -u`
			local time1=`date +%s`
			local time1=$(time_for_humans `expr ${time1} - ${time_up}`)
			local ip_mac=`getmac ${ip}`
			local ip_name=`getname ${ip} ${ip_mac}`
#			local ip_name=$(cut_str $ip_name 18)
			local send_content="${send_content}${markdown_linefeed}${markdown_tab}<font color=#92D050>【${ip_name}】</font>  ${ip}${markdown_linefeed}${markdown_tab}${ip_total}在线 ${time1}"
			unset time_down time_up time1 ip_mac ip_name
		done
	fi
	[ ! -z "$device_name" ] && local SEND_TITLE="【$device_name】${SEND_TITLE}" && CONTENT_TITLE="【$device_name】${CONTENT_TITLE}"
	local SEND_TITLE=`echo "$SEND_TITLE"|sed $'s/\ / /g'|sed $'s/\"/%22/g'|sed $'s/\#/%23/g'|sed $'s/\&/%26/g'|sed $'s/\,/%2C/g'|sed $'s/\//%2F/g'|sed $'s/\:/%3A/g'|sed $'s/\;/%3B/g'|sed $'s/\=/%3D/g'|sed $'s/\@/%40/g'`
	[ -z "$send_content" ] && local send_content="${markdown_splitline}#### <font color=#FF6666>我遇到了一个难题</font>${markdown_linefeed}${markdown_tab}定时发送选项错误，你没有选择需要发送的项目，该怎么办呢${markdown_splitline}"
	local dd_send_content="${send_content}${markdown_splitline}【KEYWORD】 ${DD_BOT_KEYWORD}${markdown_linefeed}${markdown_tab}【发送时间】 $(DATE)"
	local dd_send="curl -k -s \"https://oapi.dingtalk.com/robot/send?access_token=${DD_BOT_TOKEN}\" -H 'Content-Type: application/json' -d '{\"msgtype\": \"markdown\",\"markdown\": {\"title\":\"${SEND_TITLE}\",\"text\":\"${CONTENT_TITLE}${markdown_linefeed}${dd_send_content}\"}}'"
	local tg_send="curl -s -d \"text=${SEND_TITLE}${markdown_linefeed}$(DATE)${markdown_linefeed}${send_content}\" -X POST \"${TG_API}\" -d chat_id=\"${TG_USER_IDID}\""
	local sc_send="curl -k -s \"https://sc.ftqq.com/${SCKEY}.send?text=${SEND_TITLE}\" -d \"desp=$(DATE)${markdown_linefeed}${send_content}${markdown_linefeed}\\\`\\\`\\\`\""
	local sc_send=`echo "${sc_send}" | sed 's/\*\*\\\n\\\n/\*\*%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A/g; s/\\\n\\\n---/%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A---/g; s/%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A---/\\\n\\\n---/; s/\\\n\\\n/%0D%0A%0D%0A/g'`
	[ "$send_disturb" -eq "0" ] && [ "$SEND_DD" -eq "1" ] && [ -n $DD_BOT_KEYWORD ] &&[ -n $DD_BOT_TOKEN ] && echo `eval $dd_send`
	[ "$send_disturb" -eq "0" ] && [ "$SEND_TG" -eq "1" ] && [ -n $TG_BOT_TOKEN ] && [ -n $TG_USER_ID ] && echo `eval $tg_send`
	[ "$send_disturb" -eq "0" ] && [ "$SEND_SC" -eq "1" ] && [ -n $SCKEY ] && echo `eval $sc_send`
	deltemp
	logger -t "【${APPTYPE}推送】" "定时推送任务完成"
}

# 查询 mac 地址
getmac(){
	( echo "$tmp_mac"| grep -q "unknown" ) && unset tmp_mac # 为unknown时重新读取
	[ -f "${WORKDIR}ipAddress" ] && [ -z "$tmp_mac" ] && local tmp_mac=`cat ${WORKDIR}ipAddress|grep -w ${1}|awk '{print $2}'|grep -v "^$"|sort -u`
	[ -f "${WORKDIR}tmp_downlist" ] && [ -z "$tmp_mac" ] && local tmp_mac=`cat ${WORKDIR}tmp_downlist|grep -w ${1}|awk '{print $2}'|grep -v "^$"|sort -u`
	[ -f "/tmp/dnsmasq.leases" ] && [ -z "$tmp_mac" ] && local tmp_mac=`cat /tmp/dnsmasq.leases|grep -w ${1}|awk '{print $2}'|grep -v "^$"|sort -u`
	[ -z "$tmp_mac" ] && local tmp_mac=`cat /proc/net/arp|grep "0x2\|0x6"|grep -w ${1}|awk '{print $4}'|grep -v "^$"|sort -u`
	[ -z "$tmp_mac" ] && local tmp_mac="unknown"
	echo "$tmp_mac"
}

# 查询主机名
getname(){
	[ -z "$tmp_name" ] && local tmp_name=`alias_name $2|grep -v "^$"|sort -u`
	[ -z "$tmp_name" ] && local tmp_name=`dhcp_staticname $2|grep -v "^$"|sort -u` 
	[ -f "${WORKDIR}ipAddress" ] && [ -z "$tmp_name" ] && local tmp_name=`cat ${WORKDIR}ipAddress|grep -w ${1}|awk '{print $3}'|grep -v "^$"|sort -u`
	[ -f "${WORKDIR}tmp_downlist" ] && [ -z "$tmp_name" ] && local tmp_name=`cat ${WORKDIR}tmp_downlist|grep -w ${1}|awk '{print $3}'|grep -v "^$"|sort -u`
	( ! echo "$tmp_name"|grep -q -w "unknown\|*" ) && [ ! -z "$tmp_name" ] && echo "$tmp_name" && return || unset tmp_name # 为unknown时重新读取
	[ -f "/tmp/dnsmasq.leases" ] && [ -z "$tmp_name" ] && local tmp_name=`cat /tmp/dnsmasq.leases|grep -w ${1}|awk '{print $4}'|grep -v "^$"|sort -u`

	( ! echo "$tmp_name"|grep -q -w "unknown\|*" ) && [ ! -z "$tmp_name" ] && echo "$tmp_name" && return || unset tmp_name # 为unknown时重新读取
	[ -f "$oui_base" ] && local tmp_name=$(cat $oui_base|grep -i $(echo "$2"|cut -c 1,2,4,5,7,8)|sed -nr 's#^.*16)..(.*)#\1#gp'|sed 's/ /_/g')
	[ "$oui_data" -eq "3" ] && local tmp_name=$(curl -sS "http://standards-oui.ieee.org/oui.txt"|grep -i $(echo "$2"|cut -c 1,2,4,5,7,8)|sed -nr 's#^.*16)..(.*)#\1#gp'|sed 's/ /_/g')
	[ -z "$tmp_name" ] && local tmp_name="unknown"
	echo "$tmp_name"
}

# 下载设备MAC厂商信息
down_oui(){
	[ -f ${oui_base} ] && local logrow=$(grep -c "" ${oui_base}) || local logrow="0"
	[ $logrow -lt "10" ] && rm -f ${oui_base} >/dev/null 2>&1
	if [ ! -z "$oui_data" ] && [ "$oui_data" -ne "3" ] && [ ! -f ${oui_base} ]; then
		logger -t "【${APPTYPE}推送】" "【初始化】设备MAC厂商信息不存在，重新下载"
		curl -k -s -o ${WORKDIR}oui.txt --connect-timeout 10 --retry 3 https://linuxnet.ca/ieee/oui.txt
		if [ -f ${WORKDIR}oui.txt ] && [ "$oui_data" -eq "1" ]; then
			cat ${WORKDIR}oui.txt|grep "base 16"|grep -i "apple\|aruba\|asus\|autelan\|belkin\|bhu\|buffalo\|cctf\|cisco\|comba\|datang\|dell\|dlink\|dowell\|ericsson\|fast\|feixun\|\
fiberhome\|fujitsu\|grentech\|h3c\|hisense\|hiwifi\|honghai\|honghao\|hp\|htc\|huawei\|intel\|jinli\|jse\|lenovo\|lg\|liteon\|malata\|meizu\|mercury\|meru\|moto\|netcore\|\
netgear\|nokia\|omron\|oneplus\|oppo\|philips\|router_unkown\|samsung\|shanzhai\|sony\|start_net\|sunyuanda\|tcl\|tenda\|texas\|tianyu\|tp-link\|ubq\|undefine\|VMware\|\
utstarcom\|volans\|xerox\|xiaomi\|zdc\|zhongxing\|smartisan" > ${oui_base} && logger -t "【${APPTYPE}推送】" "【初始化】设备MAC厂商信息下载成功" || logger -t "【${APPTYPE}推送】" "【！！！】设备MAC厂商信息下载失败" 
		fi
		if [ -f ${WORKDIR}oui.txt ] && [ "$oui_data" -eq "2" ]; then
			cat ${WORKDIR}oui.txt|grep "base 16" > ${oui_base} && logger -t "【${APPTYPE}推送】" "【初始化】设备MAC厂商信息下载成功" || logger -t "【${APPTYPE}推送】" "【！！！】设备MAC厂商信息下载失败"
		fi
		rm -f ${WORKDIR}oui.txt >/dev/null 2>&1
	fi
}

# 流量数据单位换算
bytes_for_humans() {
	[ ! "$1" ] && return
	[ "$1" -gt 1073741824 ] && echo "`awk 'BEGIN{printf "%.2f\n",'$1'/'1073741824'}'`G" && return
	[ "$1" -gt 1048576 ] && echo "`awk 'BEGIN{printf "%.2f\n",'$1'/'1048576'}'` M" && return
	[ "$1" -gt 1024 ] && echo "`awk 'BEGIN{printf "%.2f\n",'$1'/'1024'}'` K" && return
	echo "${1} bytes"
}

# 时间单位换算
time_for_humans() {
	[ ! "$1" ] && return
	if [ "$1" -lt 60 ]; then
		echo "${1} 秒"
	elif [ "$1" -lt 3600 ]; then
		local usetime_min=`expr $1 / 60`
		local usetime_sec=`expr $usetime_min \* 60`
		local usetime_sec=`expr $1 - $usetime_sec`
		echo "${usetime_min} 分 ${usetime_sec} 秒"
	elif [ "$1" -lt 86400 ]; then
		local usetime_hour=`expr $1 / 3600`
		local usetime_min=`expr $usetime_hour \* 3600`
		local usetime_min=`expr $1 - $usetime_min`
		local usetime_min=`expr $usetime_min / 60`
		echo "${usetime_hour} 小时 ${usetime_min} 分"
	else
		local usetime_day=`expr $1 / 86400`
		local usetime_hour=`expr $usetime_day \* 86400`
		local usetime_hour=`expr $1 - $usetime_hour`
		local usetime_hour=`expr $usetime_hour / 3600`
		echo "${usetime_day} 天 ${usetime_hour} 小时"
	fi
}

# 计算字符真实长度
length_str() {
	[ ! "$1" ] && return
	local length_zh=`echo "$1"|awk '{print gensub(/[\u4e00-\u9FA5A-Za-z0-9_]/,"","g",$0)}'|awk -F "" '{print NF}'`
	local length_en=`echo "$1"|awk '{print gensub(/[^\u4e00-\u9FA5A-Za-z0-9_]/,"","g",$0)}'|awk -F "" '{print NF}'`
	echo `expr $length_zh / 3 \* 2 + $length_en`
}

# 截取字符，避免中文乱码
cut_str() {
	[ ! "$1" ] && return
	[ ! "$2" ] && return
	[ `length_str $1` -le "$2" ] && echo "$1" && return
	local temp_length=$2
	while [ $(length_str `echo "$1"|cut -c -$temp_length`) -lt "$2" ]; do
		temp_length=`expr $temp_length + 1`
	done
	while [ $(printf "%d" \'`echo "$1"|cut -c $temp_length`) -ge "128" ] && [ $(printf "%d" \'`echo "$1"|cut -c $temp_length`) -lt "224" ]; do
		temp_length=`expr $temp_length + 1`
	done
	temp_length=`expr $temp_length - 1`
	echo $(echo "$1"|cut -c -$temp_length)"*"
}

# 在线设备列表
serverchan_first(){
	[ -f "${WORKDIR}ipAddress" ] && local IPLIST=`cat ${WORKDIR}ipAddress|awk '{print $1}'|grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}"|grep -Ev "^$|${GW4_WAN}"|sort -u`
	for ip in $IPLIST; do
		read -u 5
		{
			down $ip
		}&
	done
	wait
	unset ip IPLIST
	local IPLIST=`cat /proc/net/arp|grep "0x2\|0x6"|awk '{print $1}'|grep -v "^169.254."|grep -Ev "^$|${GW4_WAN}"|sort -u`
	for ip in $IPLIST; do
		read -u 5
		{
			up $ip
		}&
	done
	wait
}

# 查询设备接口
getinterface(){
	[ -f "${WORKDIR}ipAddress" ] && local ip_interface=`cat ${WORKDIR}ipAddress|grep -w ${1}|awk '{print $5}'|grep -v "^$"|sort -u`
	[ -f "${WORKDIR}tmp_downlist" ] && [ -z "$ip_interface" ] && local ip_interface=`cat ${WORKDIR}tmp_downlist|grep -w ${1}|awk '{print $5}'|grep -v "^$"|sort -u`
	if [ -z "$ip_interface" ] && [ ! -z "$wlan_interface" ]; then
		for interface in $wlan_interface; do
			local ip_interface=`iw dev $interface station dump 2>/dev/null|grep Station|grep -i -w ${1}|sed -nr 's#^.*on (.*))#\1#gp'` >/dev/null 2>&1
			[ ! -z "$ip_interface" ] && echo "$ip_interface" && return
		done
	fi
	[ -z "$ip_interface" ] && local ip_interface=`cat /proc/net/arp|grep "0x2\|0x6"|grep -i -w ${1}|awk '{print $6}'|grep -v "^$"|sort -u`
	echo "$ip_interface"
}

# 文件锁
LockFile(){
	if [ $1 = "lock" ] ;then
		[ ! -f "${WORKDIR}serverchan.lock" ] && > ${WORKDIR}serverchan.lock && return
		LockFile lock
	fi
	[ $1 = "unlock" ] && rm -f ${WORKDIR}serverchan.lock >/dev/null 2>&1
}

# 检测黑白名单
blackwhitelist(){
	[ ! "$1" ] && return 1
	[ -z "$serverchan_whitelist" ] && [ -z "$serverchan_blacklist" ] && [ -z "$serverchan_interface" ] && return
	[ ! -z "$serverchan_whitelist" ] && ( ! echo "$serverchan_whitelist"|grep -q -i -w $1) && return
	[ ! -z "$serverchan_blacklist" ] && ( echo "$serverchan_blacklist"|grep -q -i -w $1) && return
	[ ! -z "$serverchan_interface" ] && ( echo `getinterface ${1}`|grep -q -i -w $serverchan_interface ) && return
}

# 检测设备上线
up(){
	[ -f ${WORKDIR}ipAddress ] && ( cat ${WORKDIR}ipAddress|grep -q -w $1 ) && return
	local ip_mac=`getmac $1`
	local ip_interface=`getinterface ${ip_mac}`
	getping ${1} ${UP_TIMEOUT} "1";local ping_online=$?
	if [ "$ping_online" -eq "0" ]; then
		LockFile lock
		[ -f "${WORKDIR}tmp_downlist" ] && local tmp_downip=`cat ${WORKDIR}tmp_downlist|grep -w ${1}|grep -v "^$"|sort -u`
		if [ ! -z "$tmp_downip" ]; then
			cat ${WORKDIR}tmp_downlist|grep -w ${1}|grep -v "^$"|sort -u >> ${WORKDIR}ipAddress
			sed -i "/^${1} /d" ${WORKDIR}tmp_downlist
		else
			local ip_name=`getname ${1} ${ip_mac}`
			blackwhitelist ${ip_mac};local ip_blackwhite=$?
			grep -w ${ip_mac} ${WORKDIR}ipAddress && return || echo "$1 ${ip_mac} ${ip_name} `date +%s` ${ip_interface}" >> ${WORKDIR}ipAddress
			[ -f "${WORKDIR}send_enable.lock" ] || [ -z "$serverchan_up" ] || [ "$serverchan_up" -ne "1" ] || [ -z "$ip_blackwhite" ] || [ "$ip_blackwhite" -ne 0 ] && LockFile unlock && return
			[ -f "${WORKDIR}title" ] && local title=`cat ${WORKDIR}title`
			[ -f "${WORKDIR}content" ] && local content=`cat ${WORKDIR}content`	
			if [ -z "$title" ]; then
				local title="有设备【上线】"
				local content="${markdown_linefeed}${ip_name} 连接了你的路由器${markdown_splitline}#### **<font color=#92D050>新设备连接</font>**${markdown_linefeed}${markdown_tab}客户端名：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_name}${markdown_linefeed}${markdown_tab}客户端IP： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${1}${markdown_linefeed}${markdown_tab}客户端MAC：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_mac}${markdown_linefeed}${markdown_tab}网络接口：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_interface}"
			elif ( echo ${title}|grep -q "有设备【上线】" ); then
				local title="有设备【上线】"
				local content="${markdown_splitline}${markdown_tab}客户端名：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_name}${markdown_linefeed}${markdown_tab}客户端IP： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${1}${markdown_linefeed}${markdown_tab}客户端MAC：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_mac}${markdown_linefeed}${markdown_tab}网络接口：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_interface}"
			else
				local title="设备状态变化"
				local content="${markdown_linefeed}${ip_name} 连接了你的路由器${markdown_splitline}#### **<font color=#92D050>新设备连接</font>**${markdown_linefeed}${markdown_tab}客户端名：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_name}${markdown_linefeed}${markdown_tab}客户端IP： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${1}${markdown_linefeed}${markdown_tab}客户端MAC：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_mac}${markdown_linefeed}${markdown_tab}网络接口：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_interface}"
			fi				
			logger -t "【${APPTYPE}推送】" "新设备 ${ip_name} ${1} 连接了"
			[ ! -z "$serverchan_blacklist" ] && local title="你偷偷关注的设备上线了"
			[ ! -z "$title" ] && echo "$title" >${WORKDIR}title
			[ ! -z "$content" ] && echo -n "$content" >>${WORKDIR}content
		fi
	fi
	LockFile unlock
}

# 检测 ip 状况
ip_changes(){
	[ ! -z "$SERVERCHAN_IPV4" ] && [ "$SERVERCHAN_IPV4" -eq "1" ] && local IPv4=`getip wanipv4`
	[ ! -z "$SERVERCHAN_IPV4" ] && [ "$SERVERCHAN_IPV4" -eq "2" ] && local IPv4=`getip hostipv4`
	[ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -eq "1" ] && local IPv6=`getip wanipv6`
	[ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -eq "2" ] && local IPv6=`getip hostipv6`

	if [ -f ${WORKDIR}ip ]; then
		local last_IPv4=$(cat "${WORKDIR}ip"|grep IPv4|awk '{print $2}'|grep -v "^$"|sort -u)
		local last_IPv6=$(cat "${WORKDIR}ip"|grep IPv6|awk '{print $2}'|grep -v "^$"|sort -u)
		if [ ! -z "$SERVERCHAN_IPV4" ] && [ "$SERVERCHAN_IPV4" -ne "0" ] && [ ! -z "$IPv4" ] && ( ! echo ${IPv4}|grep -w -q ${last_IPv4} ); then
			logger -t "【${APPTYPE}推送】" "当前IP：${IPv4}"
			echo IPv4 $IPv4 > ${WORKDIR}ip && echo -e IPv6 $last_IPv6 >> ${WORKDIR}ip
			title="IP 地址变化"
			content="${content}${markdown_splitline}#### <font color=#92D050>IP 地址变化</font>${markdown_linefeed}${markdown_tab}当前 IP：${IPv4}"
		elif [ ! -z "$SERVERCHAN_IPV4" ] && [ "$SERVERCHAN_IPV4" -ne "0" ] && [ -z "$IPv4" ]; then
			logger -t "【${APPTYPE}推送】" "【！！！】获取 IPv4 地址失败"
		fi
		
		if [ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -ne "0" ] && [ ! -z "$IPv6" ] && ( ! echo "$IPv6"|grep -w -q ${last_IPv6} ); then
			logger -t "【${APPTYPE}推送】" "当前IPv6：${IPv6}"
			echo IPv4 $IPv4 > ${WORKDIR}ip && echo -e IPv6 $IPv6 >> ${WORKDIR}ip
			[ -z "$title" ] && title="IPv6 地址变化"
			[ ! -z "$title" ] && title="IP 地址变化"
			content="${content}${markdown_splitline}#### <font color=#92D050>IPv6 地址变化</font>${markdown_linefeed}${markdown_tab}当前 IPv6：${IPv6}"				
		elif [ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -ne "0" ] && [ -z "$IPv6" ]; then
			logger -t "【${APPTYPE}推送】" "【！！！】获取 IPv6 地址失败"
		fi
		
	else
		logger -t "【${APPTYPE}推送】" "路由器已经重启!"
		[ ! -z "$SERVERCHAN_IPV4" ] && [ "$SERVERCHAN_IPV4" -ne "0" ] && logger -t "【${APPTYPE}推送】" " 当前IP: ${IPv4}"
		[ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -ne "0" ] && logger -t "【${APPTYPE}推送】" " 当前IPv6: ${IPv6}"
		echo IPv4 $IPv4 > ${WORKDIR}ip && echo -e IPv6 $IPv6 >> ${WORKDIR}ip	
		title="路由器重新启动"
		content="${content}${markdown_splitline}#### <font color=#92D050>路由器重新启动</font>"
		[ ! -z "$SERVERCHAN_IPV4" ] && [ "$SERVERCHAN_IPV4" -ne "0" ] && content="${content}${markdown_linefeed}${markdown_tab}当前IP：${IPv4}"
		[ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV6" -ne "0" ] && content="${content}${markdown_linefeed}${markdown_tab}当前IPv6：${IPv6}"
	fi
	
}

# 检测设备离线
down(){
	local ip_mac=`getmac $1`
	local ip_name=`getname ${1} ${ip_mac}`
	local ip_interface=`getinterface ${ip_mac}`
	getping ${1} ${DOWN_TIMEOUT} ${TIMEOUT_RETRY_COUNT};local ping_online=$?
	if [ "$ping_online" -eq "1" ]; then
		LockFile lock
		[ ! -f "${WORKDIR}send_enable.lock" ] && cat ${WORKDIR}ipAddress|grep -w ${1}|grep -v "^$"|sort -u >> ${WORKDIR}tmp_downlist
		sed -i "/^${1} /d" ${WORKDIR}ipAddress
		LockFile unlock
	else
		local tmp_name=`cat ${WORKDIR}ipAddress|grep -w ${1}|awk '{print $3}'|grep -v "^$"|sort -u`
		if [ "$ip_name" != "$tmp_name" ]; then
			LockFile lock
			local tmp_str=$(echo "$1 ${ip_mac} ${ip_name} `cat ${WORKDIR}ipAddress|grep -w ${1}|awk '{print $4}'|grep -v "^$"|sort -u` ${ip_interface}")
			sed -i "/^${1} /d" ${WORKDIR}ipAddress
			echo "$tmp_str" >> ${WORKDIR}ipAddress
			LockFile unlock
		fi
	fi
}

# 设备离线通知
down_send(){
	[ ! -f "${WORKDIR}tmp_downlist" ] && return
	local IPLIST=`cat ${WORKDIR}tmp_downlist|awk '{print $1}'`
	for ip in $IPLIST; do
		local ip_mac=`getmac ${ip}`
		disturb_text="wei"
		blackwhitelist ${ip_mac};local ip_blackwhite=$?
		[ -z "$serverchan_down" ] || [ "$serverchan_down" -ne "1" ] || [ -z "$ip_blackwhite" ] || [ "$ip_blackwhite" -ne 0 ] && continue
		local ip_name=`getname ${ip} ${ip_mac}`
		local time_up=`cat ${WORKDIR}tmp_downlist|grep -w ${ip}|awk '{print $4}'|grep -v "^$"|sort -u`
		local time1=`date +%s`
		local time1=$(time_for_humans `expr ${time1} - ${time_up}`)
		if [ -z "$title" ]; then
			title="有设备【离线】"
			content="${markdown_linefeed}${ip_name} 断开连接${content}${markdown_splitline}#### **<font color=#FF6666>设备断开连接</font>**${markdown_linefeed}${markdown_tab}客户端名：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_name}${markdown_linefeed}${markdown_tab}客户端IP： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip}${markdown_linefeed}${markdown_tab}客户端MAC：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_mac}$ip_total${markdown_linefeed}${markdown_tab}在线时间： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${time1}"
		elif ( echo "$title"|grep -q "设备【离线】" ); then
			title="有设备【离线】"
			content="${content}${markdown_splitline}${markdown_tab}客户端名：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_name}${markdown_linefeed}${markdown_tab}客户端IP： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip}${markdown_linefeed}${markdown_tab}客户端MAC：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_mac}$ip_total${markdown_linefeed}${markdown_tab}在线时间： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${time1}"
		else
			title="设备状态变化"
			content="${markdown_linefeed}${ip_name} 断开连接${content}${markdown_splitline}#### **<font color=#FF6666>设备断开连接</font>**${markdown_linefeed}${markdown_tab}客户端名：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_name}${markdown_linefeed}${markdown_tab}客户端IP： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip}${markdown_linefeed}${markdown_tab}客户端MAC：${markdown_space}${markdown_space}${markdown_space}${markdown_space}${ip_mac}$ip_total${markdown_linefeed}${markdown_tab}在线时间： ${markdown_space}${markdown_space}${markdown_space}${markdown_space}${time1}"
		fi
		logger -t "【${APPTYPE}推送】" "设备 ${ip_name} ${ip} 断开连接 "
	done
	rm -f ${WORKDIR}tmp_downlist > /dev/null 2>&1
}

# 当前设备列表
current_device(){
	[ -f ${WORKDIR}ipAddress ] && local logrow=$(grep -c "" ${WORKDIR}ipAddress) || local logrow="0";[ $logrow -eq "0" ] && return
	content="${content}${markdown_splitline}#### **<font color=#76CCFF>现有在线设备 ${logrow} 台，具体如下</font>**${markdown_linefeed}${markdown_tab}IP 地址<font color=#76CCFF>┋</font><font color=#76CCFF>┋</font>**客户端名**"
	local IPLIST=`cat ${WORKDIR}ipAddress|awk '{print $1}'`
	for ip in $IPLIST; do
		local ip_mac=`getmac ${ip}`
		local ip_name=`getname ${ip} ${ip_mac}`
#		local ip_name=`cut_str $ip_name 15`
		if [ "${#ip}" -lt "15" ]; then 
			local n=`expr 15 - ${#ip}`
			for i in `seq 1 $n`; do
				local ip="${ip}"
			done
			unset i n
		fi
		if [ ! -z "$ip_total" ]; then	
			local n=`expr 11 - ${#ip_total}`
			for i in `seq 1 $n`; do
				local ip_total="${ip_total}"
			done
		fi
		content="${content}${markdown_linefeed}${markdown_tab}${ip}<font color=#76CCFF>┋</font>${ip_total}<font color=#76CCFF>┋</font>**<font color=#92D050>${ip_name}</font>**"
		unset i n ip_total ip_mac ip_name
	done
}

loop(){
	# 循环
	[ "$(nvram get serverchan_enable)" -eq "1" ] && logger -t "【${APPTYPE}推送】" "启动成功" || logger -t "【${APPTYPE}推送】" "脚本未成功启动，未设置启动参数 serverchan_enable"
	while [ "$(nvram get serverchan_enable)" -eq "1" ]; do
		deltemp;serverchan_disturb;local send_disturb=$?

		# 外网IP变化检测
		if [ ! -z "$SERVERCHAN_IPV4" ] && [ ! -z "$SERVERCHAN_IPV6" ] && [ "$SERVERCHAN_IPV4" -ne "0" ] || [ "$SERVERCHAN_IPV6" -ne "0" ]; then
	#		rand_geturl
			ip_changes
		fi
		
		# 设备列表
		if [ ! -f "${WORKDIR}send_enable.lock" ]; then
			[ ! -z "$title" ] && echo "$title" > ${WORKDIR}title
			[ ! -z "$content" ] && echo "$content" > ${WORKDIR}content
			serverchan_first
			[ -f "${WORKDIR}title" ] && title=`cat ${WORKDIR}title` && rm -f ${WORKDIR}title >/dev/null 2>&1
			[ -f "${WORKDIR}content" ] && content=`cat ${WORKDIR}content` && rm -f ${WORKDIR}content >/dev/null 2>&1
		fi
		
		# 离线缓存区推送
		[ ! -f "${WORKDIR}send_enable.lock" ] && down_send
		
		# 当前设备列表
		[ "$serverchan_client_list" -eq "1" ] && [ ! -z "$content" ] && [ ! -f "${WORKDIR}send_enable.lock" ] && current_device

		# CPU 检测
		[ ! -f "${WORKDIR}send_enable.lock" ] && cpu_load
		if [ ! -f "${WORKDIR}send_enable.lock" ] && [ ! -z "$title" ] && [ ! -z "$content" ]; then
			[ ! -z "$device_name" ] && title="【${device_name}${CONTENT_TITLE}】$title"
			title=`echo "$title"|sed $'s/\ / /g'|sed $'s/\"/%22/g'|sed $'s/\#/%23/g'|sed $'s/\&/%26/g'|sed $'s/\,/%2C/g'|sed $'s/\//%2F/g'|sed $'s/\:/%3A/g'|sed $'s/\;/%3B/g'|sed $'s/\=/%3D/g'|sed $'s/\@/%40/g'`
			local dd_send_content="${content}${markdown_splitline}【KEYWORD】 ${DD_BOT_KEYWORD}${markdown_linefeed}${markdown_tab}【发送时间】 $(DATE)"
			local dd_send="curl -k -s \"https://oapi.dingtalk.com/robot/send?access_token=${DD_BOT_TOKEN}\" -H 'Content-Type: application/json' -d '{\"msgtype\": \"markdown\",\"markdown\": {\"title\":\"${title}\",\"text\":\"${title}${markdown_linefeed}${dd_send_content}\"}}'"
			local tg_send="curl -s -d \"text=${title}${markdown_linefeed}$(DATE)${markdown_linefeed}${content}\" -X POST \"${TG_API}\" -d chat_id=\"${TG_USER_IDID}\""
			local sc_send="curl -k -s \"https://sc.ftqq.com/${SCKEY}.send?text=${title}&#9829\" -d \"desp=$(DATE)${markdown_linefeed}${content}\""
			local sc_send=`echo "${sc_send}" | sed 's/\*\*\\\n\\\n/\*\*%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A/; s/\*\*\\\n\\\n/\*\*%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A/'`
			local sc_send=`echo "${sc_send}" | sed 's/\\\n\\\n---/%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A---/g; s/%0D%0A\\\\\`\\\\\`\\\\\`%0D%0A---/\\\n\\\n---/; s/\*\*//g; s/\\\n\\\n/%0D%0A%0D%0A/g'`
			[ "$send_disturb" -eq "0" ] && [ "$SEND_DD" -eq "1" ] && [ -n $DD_BOT_KEYWORD ] &&[ -n $DD_BOT_TOKEN ] && echo `eval $dd_send`
			[ "$send_disturb" -eq "0" ] && [ "$SEND_TG" -eq "1" ] && [ -n $TG_BOT_TOKEN ] && [ -n $TG_USER_ID ] && echo `eval $tg_send`
			[ "$send_disturb" -eq "0" ] && [ "$SEND_SC" -eq "1" ] && [ -n $SCKEY ] && echo `eval $sc_send`
	
		fi
		
		while [ -f "${WORKDIR}send_enable.lock" ]; do
			sleep $sleeptime
		done
		sleep $sleeptime
		continue
	done
	logger -t "【${APPTYPE}推送】" "退出脚本"
}

close(){
	nvram set serverchan_enable="0"
	nvram commit
	killall serverchan.sh
	killall -9 serverchan.sh
	logger -t "【${APPTYPE}推送】" "脚本已停止"
}

case $1 in
start)
	serverchan_init
	loop
	;;
send)
	serverchan_init
	send
	;;
stop)
	close
	;;
*)
	logger -t "【信息推送】" "参数错误"
	;;
esac
