#!/bin/sh
SMARTDNS_CONF_DIR="/opt/etc/smartdns"
[ ! -d "$SMARTDNS_CONF_DIR" ] && mkdir $SMARTDNS_CONF_DIR
SMARTDNS_CONF="$SMARTDNS_CONF_DIR/smartdns.conf"
ADDRESS_CONF="$SMARTDNS_CONF_DIR/smartdns_address.conf"
BLACKLIST_IP_CONF="$SMARTDNS_CONF_DIR/smartdns_blacklist-ip.conf"
# WHITELIST_IP_CONF="$SMARTDNS_CONF_DIR/smartdns_whitelist-ip.conf"
CUSTOM_CONF="$SMARTDNS_CONF_DIR/smartdns_custom.conf"
smartdns_file="/opt/bin/smartdns"
##常规设置
nvram set sdns_enable="1" 		#启用
nvram set sdns_name="PDCN"		#服务器名称
nvram set sdns_port="6053" 		#本地端口
nvram set sdns_tcp_server="1"  	#TCP服务器
nvram set sdns_ipv6_server="1" 	#IPV6服务器
nvram set sdns_ip_change="1"	#双栈ip优选
nvram set sdns_www="1" 			#域名预加载
nvram set sdns_redirect="1"		#重定向53端口 "1"为上游服务器 "2"重定向到53端口
nvram set sdns_cache=""			#缓存大小
nvram set sdns_ttl="300" 		#域名TTL
nvram set sdns_ttl_min="60"		#域名TTL最小值
nvram set sdns_ttl_max="86400"	#域名TTL最大值
##第二DNS服务器
nvram set sdnse_enable="0"		#启用
nvram set sdnse_port="7053" 	#本地端口
nvram set sdnse_tcp="0" 		#TCP服务器
nvram set sdnse_speed="0"		#跳过测速
nvram set sdnse_name= 			#服务器组
nvram set sdnse_address="0" 	#跳过address规则
nvram set sdnse_ns="0" 			#跳过Nameserver规则
nvram set sdnse_ipset="0" 		#跳过ipset规则
nvram set sdnse_as="0" 			#跳过address SOA(#)规则
nvram set sdnse_no_d_ip_s="0"	#跳过双栈优选
nvram set sdnse_cache="0" 		#跳过cache
##自定义设置
cat > $SMARTDNS_CONF_DIR/smartdns_custom.conf << EOC
# Add custom settings here.

# set log level
# log-level [level], level=fatal, error, warn, notice, info, debug
# log-level error

# log-size k,m,g
# log-size 128k

# log-file /var/log/smartdns.log
# log-num 2

# List of hosts that supply bogus NX domain results 
# bogus-nxdomain [ip/subnet]
EOC
nvram set sdns_coredump="0" 		#生成coredump

##上游服务器
upStream_server(){
	nvram set sdnss_enable_x$1="$2"
	nvram set sdnss_name_x$1="$3"
	nvram set sdnss_ip_x$1="$4"
	nvram set sdnss_port_x$1="$5"
	nvram set sdnss_type_x$1="$6"
	nvram set sdnss_server_group_x$1="$7"
	nvram set sdnss_blacklist_ip_x$1="$8"
}
upStream_server "0" "1" "移动DNS" "211.136.192.6" 	"default" "tcp" "" "0"
upStream_server "1" "1" "移动DNS" "211.136.192.6" 	"default" "udp" "" "0"
upStream_server "2" "1" "阿里DNS" "223.5.5.5" 		"default" "tcp" "" "0"
upStream_server "3" "1" "阿里DNS" "223.5.5.5" 		"default" "udp" "" "0"
upStream_server "4" "1" "谷歌DNS" "8.8.4.4"			"default" "tcp"	"" "0"
upStream_server "5" "1" "谷歌DNS" "8.8.4.4"			"default" "udp"	"" "0"
upStream_server "6" "1" "ipv6DNS" "240C::6666" 		"default" "tcp"	"" "0"
upStream_server "7" "1" "ipv6DNS" "240C::6666" 		"default" "udp"	"" "0"
upStream_server "8" "1" "OpenDNS" "208.67.222.222" 	"default" "tcp"	"" "0"
upStream_server "9" "1" "OpenDNS" "208.67.222.222" 	"default" "udp"	"" "0"
nvram set sdnss_staticnum_x="10" ##有几个上游服务器
##域名地址
cat > $SMARTDNS_CONF_DIR/smartdns_address.conf << EOT
# 指定特定的域名地址
# Add domains which you want to force to an IP address here.
# The example below send any host in example.com to a local webserver.
# address /domain/[ip|-|-4|-6|#|#4|#6]
# address /www.example.com/1.2.3.4, return ip 1.2.3.4 to client
# address /www.example.com/-, ignore address, query from upstream, suffix 4, for ipv4, 6 for ipv6, none for all
# address /www.example.com/#, return SOA to client, suffix 4, for ipv4, 6 for ipv6, none for all

# specific ipset to domain
# ipset /domain/[ipset|-]
# ipset /www.example.com/block, set ipset with ipset name of block 
# ipset /www.example.com/-, ignore this domain

# specific nameserver to domain
# nameserver /domain/[group|-]
# nameserver /www.example.com/office, Set the domain name to use the appropriate server group.
# nameserver /www.example.com/-, ignore this domain
EOT
##IP黑名单
cat > $SMARTDNS_CONF_DIR/smartdns_blacklist-ip.conf << EOB
# Add IP blacklist which you want to filtering from some DNS server here.
# The example below filtering ip from the result of DNS server which is configured with -blacklist-ip.
# blacklist-ip [ip/subnet]
# blacklist-ip 254.0.0.1/16
EOB
nvram commit

sdns_enable=`nvram get sdns_enable`
sdns_name=`nvram get sdns_name`
sdns_port=`nvram get sdns_port`
sdns_tcp_server=`nvram get sdns_tcp_server`
sdns_ipv6_server=`nvram get sdns_ipv6_server`
sdns_ip_change=`nvram get sdns_ip_change`
sdns_www=`nvram get sdns_www`
# sdns_exp=`nvram get sdns_exp`
sdns_redirect=`nvram get sdns_redirect`
sdns_cache=`nvram get sdns_cache`
sdns_ttl=`nvram get sdns_ttl`
sdns_ttl_min=`nvram get sdns_ttl_min`
sdns_ttl_max=`nvram get sdns_ttl_max`
sdnse_enable=`nvram get sdnse_enable`
sdnse_port=`nvram get sdnse_port`
sdnse_tcp=`nvram get sdnse_tcp`
sdnse_speed=`nvram get sdnse_speed`
sdnse_name=`nvram get sdnse_name`
sdnse_address=`nvram get sdnse_address`
sdnse_ns=`nvram get sdnse_ns`
sdnse_ipset=`nvram get sdnse_ipset`
sdnse_as=`nvram get sdnse_as`
sdnse_ipc=`nvram get sdnse_ipc`
sdnse_cache=`nvram get sdnse_cache`
ss_white=`nvram get ss_white`
ss_black=`nvram get ss_black`

check_ss(){
if [ $(nvram get ss_enable) = 1 ] && [ $(nvram get ss_run_mode) = "router" ] && [ $(nvram get pdnsd_enable) = 0 ]; then
	logger -t "SmartDNS" "系统检测到SS模式为绕过大陆模式，并且启用了pdnsd,请先调整SS解析使用自定义模式！程序将退出。"
	nvram set sdns_enable=0
	exit 0
else
	logger -t "SmartDNS" "SS模式没问题"
fi
}

set_forward_dnsmasq() {
	sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
	sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
no-resolv
server=127.0.0.1#$sdns_port
EOF
	/sbin/restart_dhcpd
	logger -t "SmartDNS" "添加DNS转发到$sdns_port端口"
}

stop_forward_dnsmasq() {
	sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
	sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
	/sbin/restart_dhcpd
}

set_iptable()
{
	ipv6_server=$1
	tcp_server=$2

	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		if [ "$tcp_server" == "1" ]; then
			iptables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $sdns_port >/dev/null 2>&1
		fi
		iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $sdns_port >/dev/null 2>&1
	done

	if [ "$ipv6_server" == 0 ]; then
		return
	fi

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		if [ "$tcp_server" == "1" ]; then
			ip6tables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $sdns_port >/dev/null 2>&1
		fi
		ip6tables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $sdns_port >/dev/null 2>&1
	done
	logger -t "SmartDNS" "重定向53端口"
}

clear_iptable()
{
	local OLD_PORT="$1"
	local ipv6_server=$2
	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		iptables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done

	if [ "$ipv6_server" == 0 ]; then
		return
	fi

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		ip6tables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done
	logger -t "SmartDNS" "清理防火墙规则"
}

conf_append(){
	echo "$1" "$2" >> $SMARTDNS_CONF
}

get_tz() ##读取时区
{
	SET_TZ=""
	for tzfile in /etc/TZ
	do
		if [ ! -e "$tzfile" ]; then
			continue
		fi		
		tz="`cat $tzfile 2>/dev/null`"
	done	
	if [ -z "$tz" ]; then
		return	
	fi	
	SET_TZ=$tz
}

gensmartconf(){
	rm -f $SMARTDNS_CONF
	touch $SMARTDNS_CONF
	conf_append "server-name $sdns_name"
	[ "$sdns_ipv6_server" = "1" ] && conf_append "bind" "[::]:$sdns_port" || conf_append "bind" ":$sdns_port"

	if [ "$sdns_tcp_server" = "1" ]; then
		if [ "$sdns_ipv6_server" = "1" ]; then
			conf_append "bind-tcp" "[::]:$sdns_port"
		else
			conf_append "bind-tcp" ":$sdns_port"
		fi
	fi

gensdnssecond
	conf_append "cache-size $sdns_cache"
	[ $sdns_ip_change -eq 1 ] && conf_append "dualstack-ip-selection" "yes"
	
	[ $sdns_www -eq 1 ] && conf_append "prefetch-domain" "yes" || conf_append "prefetch-domain" "no"

#	[ $sdns_exp -eq 1 ] && conf_append "serve-expired" "yes" || conf_append "serve-expired" "no"
	
	conf_append "log-level" "info"
	listnum=`nvram get sdnss_staticnum_x`
	for i in $(seq 1 $listnum)
	do
		j=`expr $i - 1`
		sdnss_enable=`nvram get sdnss_enable_x$j`
		if [ $sdnss_enable -eq 1 ]; then
			sdnss_name=`nvram get sdnss_name_x$j`
			sdnss_ip=`nvram get sdnss_ip_x$j`
			sdnss_port=`nvram get sdnss_port_x$j`
			sdnss_type=`nvram get sdnss_type_x$j`
			sdnss_ipc=`nvram get sdnss_blacklist_ip_x$j`
			local ipc=""
			# if [ $sdnss_ipc = "whitelist" ]; then
				# ipc="-whitelist-ip"
			# elif [ $sdnss_ipc = "blacklist" ]; then
				# ipc="-blacklist-ip"
			# fi
			[ $sdnss_ipc = 1 ] && ipc="-blacklist-ip"
			if [ $sdnss_type = "tcp" ]; then
				if [ $sdnss_port = "default" ]; then
					conf_append "server-tcp $sdnss_ip" "$ipc"
				else
					conf_append	"server-tcp $sdnss_ip:$sdnss_port" "$ipc"
				fi
			elif [ $sdnss_type = "udp" ]; then
				if [ $sdnss_port = "default" ]; then
					conf_append "server" "$sdnss_ip"
				else
					conf_append "server $sdnss_ip:$sdnss_port $ipc"
				fi
			elif [ $sdnss_type = "tls" ]; then
				if [ $sdnss_port = "default" ]; then
					conf_append "server-tls $sdnss_ip $ipc"
				else
					conf_append "server-tls $sdnss_ip:$sdnss_port $ipc"
				fi
			elif [ $sdnss_type = "https" ]; then
				[ $sdnss_port = "default" ] && conf_append "server-https $sdnss_ip $ipc"
			fi	
		fi
	done
	if [ "$ss_white" = "1" ]; then
		rm -f /tmp/whitelist.conf
		logger -t "SmartDNS" "开始处理白名单IP"
		awk '{printf("whitelist-ip %s\n", $1, $1 )}' /etc/storage/chinadns/chnroute.txt >> /tmp/whitelist.conf
		conf_append "conf-file /tmp/whitelist.conf"
	fi
	if [ "$ss_black" = "1" ]; then
		rm -f /tmp/blacklist.conf
		logger -t "SmartDNS" "开始处理黑名单IP"
		awk '{printf("blacklist-ip %s\n", $1, $1 )}' /etc/storage/chinadns/chnroute.txt >> /tmp/blacklist.conf
		conf_append "conf-file /tmp/blacklist.conf"
	fi
}

gensdnssecond(){
	if [ $sdnse_enable -eq 1 ]; then
		ARGS=""
		ADDR=""
		[ "$sdnse_speed" = "1" ] && ARGS="$ARGS -no-speed-check"
		[ ! -z "$sdnse_name" ] && ARGS="$ARGS -group $sdnse_name"
		[ "$sdnse_address" = "1" ] && ARGS="$ARGS -no-rule-addr"
		[ "$sdnse_ns" = "1" ] && ARGS="$ARGS -no-rule-nameserver"
		[ "$sdnse_ipset" = "1" ] && ARGS="$ARGS -no-rule-ipset"
		[ "$sdnse_as" = "1" ] && ARGS="$ARGS -no-rule-soa"
		[ "$sdnse_ipc" = "1" ] && ARGS="$ARGS -no-dualstack-selection"
		[ "$sdnse_cache" = "1" ] && ARGS="$ARGS -no-cache"
		[ "$sdns_ipv6_server" = "1" ] && ADDR="[::]" || ADDR=""
		conf_append "bind" "$ADDR:$sdnse_port $ARGS"
		[ "$sdnse_tcp" = "0" ] && conf_append "bind-tcp" "$ADDR:$sdnse_port$ARGS"
	fi
}

dw_smartdns(){
	curl -k -s -o /opt/bin/smartdns --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/Twinzo1/padavan_smartdns/master/smartdns
	[ ! -f "$smartdns_file" ] && curl -k -s -o $smartdns_file --connect-timeout 10 --retry 3 https://dev.tencent.com/u/dtid_39de1afb676d0d78/p/kp/git/raw/master/smartdns
	if [ ! -f "$smartdns_file" ]; then
		logger -t "SmartDNS" "SmartDNS二进制文件下载失败，可能是地址失效或者网络异常！"
		nvram set sdns_enable=0
		stop_smartdns
		exit 0
	else
		logger -t "SmartDNS" "SmartDNS二进制文件下载成功"
		chmod -R 777 $smartdns_file
	fi
}

start_smartdns(){
	[ ! -f "$smartdns_file" ] && dw_smartdns

	args=""
	logger -t "SmartDNS" "创建配置文件."
	gensmartconf

	grep -v ^! $ADDRESS_CONF >> $SMARTDNS_CONF
	grep -v ^! $BLACKLIST_IP_CONF >> $SMARTDNS_CONF
#	grep -v ^! $WHITELIST_IP_CONF >> $SMARTDNS_CONF
	grep -v ^! $CUSTOM_CONF >> $SMARTDNS_CONF
	#grep -v ^! /tmp/whitelist.txt >> $SMARTDNS_CONF
	#rm -f /tmp/whitelist.txt
	#grep -v ^! /tmp/blacklist.txt >> $SMARTDNS_CONF
	#rm -f /tmp/blacklist.txt
	[ "$sdns_coredump" = "1" ] &&  args="$args -S"
		#get_tz
		#if [ ! -z "$SET_TZ" ]; then
	#		procd_set_param env TZ="$SET_TZ"
		#fi
	$smartdns_file -f -c $SMARTDNS_CONF $args &>/dev/null &
	logger -t "SmartDNS" "SmartDNS启动成功"
	if [ $sdns_redirect = "2" ]; then
		set_iptable $sdns_ipv6_server $sdns_tcp_server
	elif [ $sdns_redirect = "1" ]; then
		set_forward_dnsmasq
	fi

}

stop_smartdns(){
	killall -9 smartdns
	stop_forward_dnsmasq
	clear_iptable $sdns_port $sdns_ipv6_server
	if [ "$sdns_redirect" = "2" ]; then
		clear_iptable $sdns_port $sdns_ipv6_server
	elif [ "$sdns_redirect" = "1" ]; then
		stop_forward_dnsmasq
	fi
	logger -t "SmartDNS" "SmartDNS已关闭"
}

case $1 in
start)
    check_ss
	start_smartdns
	;;
stop)
	stop_smartdns
	;;
*)
	echo "check"
	;;
esac
