#!/bin/sh

dir_storage="/opt/etc/privoxy" #如果没有opt目录可修改为/tmp/privoxy
[ ! -d "$dir_storage" ] && mkdir $dir_storage

file_url="https://raw.githubusercontent.com/Twinzo1/padavan/master/privoxy"

config="$dir_storage/config"
default.action="$dir_storage/default.action"
default.filter="$dir_storage/default.filter"
match-all.action="$dir_storage/match-all.action"
regression-tests.action="$dir_storage/regression-tests.action="
user.action="$dir_storage/user.action"
user.filter="$dir_storage/user.filter"
user.trust="$dir_storage/user.trust"
privoxy="$dir_storage/privoxy"

get_file(){
	if [ ! -s "$1" ]; then
		curl -k -s -o $1 --connect-timeout 10 --retry 3 "$file_url/$2"
#		tmp_md5=`md5sum $1 | awk -F " " '{print $1}'`
#		cp -f $1 "$1".bak
#		curl -k -s -o $1 --connect-timeout 10 --retry 3 "$file_url/$2"
#		new_md5=`md5sum $1 | awk -F " " '{print $1}'`
#		if [ "$tmp_md5" = "$new_md5" ]; then
#			rm -f "$1".bak
			logger -t "【Privoxy】" "$2文件下载成功"
#		else
#			logger -t "【Privoxy】" "$2文件两次下载MD5不相同，重新下载"
#			get_file
#		fi
	fi
} 

init_file(){
	get_file "$config" config
	get_file "$default.action" default.action
	get_file "$default.filter" default.filter
	get_file "$match-all.action" match-all.action
	get_file "$regression-tests.action" regression-tests.action
	get_file "$user.action" user.action
	get_file "$user.filter" user.filter
	get_file "$user.trust" user.trust
	get_file "$privoxy" privoxy
	logger -t "【Privoxy】" "配置文件下载成功"
}

func_create_config()
{
	init_file
	ip_address=`ip address show br0 | grep -w inet | sed 's|.* \(.*\)/.*|\1|'`
	cp -af /usr/share/privoxy/privoxy $dir_storage
	chmod 755 $privoxy
	chmod 644 $dir_storage/*
	sed -i "s/^listen-address.*/listen-address  ${ip_address}:8118/" $config
#	/sbin/mtd_storage.sh save
}

func_start()
{
	if [ ! -d "$dir_storage/privoxy" ] ; then
		func_create_config
	fi
	/usr/bin/logger -t "【Privoxy】" "privoxy 启动中"
	$privoxy --pidfile /var/run/privoxy.pid $config
	/usr/bin/logger -t "【Privoxy】" "privoxy 启动成功"
}

func_stop()
{
	/usr/bin/logger -t "【privoxy】" "关闭privoxy"
	killall -q privoxy
}

case "$1" in
start)
	func_start $2
	;;
stop)
	func_stop
	;;
*)
	echo "Usage: $0 {start|stop}"
	exit 1
	;;
esac

exit 0
