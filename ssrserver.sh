.
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#	Description: Install the ShadowsocksR Server Manyuser
#	Version: 0.9
#	Author: Jiuling Modify since Toyo
#=================================================

sh_ver="0.9 Beta"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"

#获取IP
Get_IP(){
	ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
}

#检查操作系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_pid(){
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
}

Install_SSR(){
	echo -e "${Info} 开始设置 ShadowsocksR账号配置..."
	Set_config_all
	echo -e "${Info} 开始安装/配置 ShadowsocksR依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装 ShadowsocksR文件..."
	Download_SSR
	echo -e "${Info} 开始安装 ShadowsocksR服务 自启..."
	Service_SSR
	echo -e "${Info} 开始写入 ShadowsocksR配置文件..."
	Install_SSR_A
	Write_configuration
	Write_configuration_mysql
	Write_configuration_Type
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动 ShadowsocksR服务端..."
	Start_SSR
}

Set_config_all(){
	Set_Service_ID
	Set_Sql_IP
	Set_Sql_Port
	Set_Sql_Username
	Set_Sql_Pwd
	Set_Sql_Db
	Set_Node_ID
	Set_Iptables_Port
	Set_config_Ipv6
	Set_Install_Directory
}

# 设置 配置信息
Set_Service_ID(){
	echo -e "请输入设置的ShadowsocksR 服务端 特征码（安装第二个后端请改变特征码）"
	stty erase '^H' && read -p "(默认: ssr):" Service_ID
	[[ -z "$Service_ID" ]] && Service_ID="ssr"
	expr ${Service_ID} + 0 &>/dev/null
	echo && echo ${Separator_1} && echo -e "	特征码 : ${Green_font_prefix}${Service_ID}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Sql_IP(){
	echo -e "请设置要安装的ShadowsocksR 服务端 数据库 IP"
	stty erase '^H' && read -p "(默认: 127.0.0.1):" SQL_IP
	[[ -z "$SQL_IP" ]] && ssr_port="127.0.0.1"
	expr ${SQL_IP} + 0 &>/dev/null
	echo && echo ${Separator_1} && echo -e "	数据库IP : ${Green_font_prefix}${SQL_IP}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Sql_Port(){
	echo "请设置要安装的ShadowsocksR 服务端 数据库 端口"
	stty erase '^H' && read -p "(默认: 3306):" SQL_PORT
	[[ -z "${SQL_PORT}" ]] && SQL_PORT="3306"
	echo && echo ${Separator_1} && echo -e "	数据库端口 : ${Green_font_prefix}${SQL_PORT}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Sql_Username(){
	echo "请设置要安装的ShadowsocksR 服务端 数据库 用户名"
	stty erase '^H' && read -p "(默认: root):" SQL_USERNAME
	[[ -z "${SQL_USERNAME}" ]] && SQL_USERNAME="root"
	echo && echo ${Separator_1} && echo -e "	数据库用户名 : ${Green_font_prefix}${SQL_UAERNAME}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Sql_Pwd(){
	echo "请设置要安装的ShadowsocksR 服务端 数据库 密码"
	stty erase '^H' && read -p "(默认: root):" SQL_PWD
	[[ -z "${SQL_PWD}" ]] && SQL_PWD="root"
	echo && echo ${Separator_1} && echo -e "	数据库密码 : ${Green_font_prefix}${SQL_PWD}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Sql_Db(){
	echo "请设置要安装的ShadowsocksR 服务端 数据库 名称"
	stty erase '^H' && read -p "(默认: ss):" SQL_DB
	[[ -z "${SQL_DB}" ]] && SQL_DB="ss"
	echo && echo ${Separator_1} && echo -e "	数据库名称 : ${Green_font_prefix}${SQL_DB}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Node_ID(){
	echo "请设置要安装的ShadowsocksR 服务端 节点ID"
	stty erase '^H' && read -p "(默认: 1):" NODE_ID
	[[ -z "${NODE_ID}" ]] && NODE_ID="1"
	echo && echo ${Separator_1} && echo -e "	节点ID : ${Green_font_prefix}${NODE_ID}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Iptables_Port(){
	echo "请设置要安装的ShadowsocksR 服务端 开放的端口(端口段中间用:号代替)"
	stty erase '^H' && read -p "(默认: 10000:20000):" SSR_Port
	[[ -z "${SSR_Port}" ]] && SSR_Port="10000:20000"
	echo && echo ${Separator_1} && echo -e "	开放端口: ${Green_font_prefix}${SSR_Port}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_config_Ipv6(){
	echo -e "请选择是否为ShadowsocksR 服务端开启IPV6
 ${Green_font_prefix} 1.${Font_color_suffix} 关闭
 ${Green_font_prefix} 2.${Font_color_suffix} 开启" && echo
	stty erase '^H' && read -p "(默认: 1. 关闭):" SQL_IPV6
	[[ -z "${SQL_IPV6}" ]] && SQL_IPV6="false"
	if [[ ${SQL_IPV6} == "1" ]]; then
		SQL_IPV6="false"
	elif [[ ${SQL_IPV6} == "2" ]]; then
		SQL_IPV6="true"
	fi
	echo && echo ${Separator_1} && echo -e "	IPV6状态 : ${Green_font_prefix}${SQL_IPV6}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Install_Directory(){
	echo "请输入安装服务端的目录(末尾必须加/)："
	stty erase '^H' && read -p "(默认: /usr/local/):" Install_Directory
	[[ -z "${Install_Directory}" ]] && Install_Directory="/usr/local/"
	echo && echo ${Separator_1} && echo -e "	安装目录 : ${Green_font_prefix}${Install_Directory}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Modle_Config(){
	echo -e "请设置加速算法(延时大于90ms请选1，小于90ms请选2)：
 ${Green_font_prefix} 1.${Font_color_suffix} hybla
 ${Green_font_prefix} 2.${Font_color_suffix} htcp" && echo
	stty erase '^H' && read -p "(默认: 1. hybla):" Modle_Config
	[[ -z "${Modle_Config}" ]] && Modle_Config="hybla"
	if [[ ${Modle_Config} == "1" ]]; then
		SQL_IPV6="hybla"
	elif [[ ${Modle_Config} == "2" ]]; then
		SQL_IPV6="htcp"
	fi
	echo && echo ${Separator_1} && echo -e "	加速算法 : ${Green_font_prefix}${Modle_Config}${Font_color_suffix}" && echo ${Separator_1} && echo
}


# 安装 依赖
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	Check_python
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
Centos_yum(){
	yum update
	yum install -y vim git python-devel libffi-devel openssl-devel python-setuptools
	easy_install pip
	pip install cymysql
}
Debian_apt(){
	apt-get update
	apt-get install -y vim git python-devel libffi-devel openssl-devel python-setuptools
	easy_install pip
	pip install cymysql
}
Check_python(){
	python_ver=`python -h`
	if [[ -z ${python_ver} ]]; then
		echo -e "${Info} 没有安装Python，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install -y python
		else
			apt-get install -y python
		fi
	fi
}

# 下载 ShadowsocksR 服务端
Download_SSR(){
	cd "${Install_Directory}"
	env GIT_SSL_NO_VERIFY=true git clone -b manyuser https://github.com/Thnineer/shadowsocksr.git
	[[ ! -e ${Install_Directory}shadowsocksr ]] && echo -e "${Error} ShadowsocksR服务端 下载失败 !" && exit 1
	echo -e "${Info} ShadowsocksR服务端 下载完成 !"
}
# 设置自启
Service_SSR(){
	if [[ ${release} = "centos" ]]; then
		Write_Service_Centos
		chmod +x /etc/init.d/${Service_ID}
		chkconfig --add ${Service_ID}
		chkconfig ${Service_ID} on
	else
    Write_Service_Debian
		chmod +x /etc/init.d/${Service_ID}
		update-rc.d -f ${Service_ID} defaults
	fi
	echo -e "${Info} ShadowsocksR服务端 自启设置成功!"
}

Write_Service_Centos(){
		if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/centos-ssr -O /etc/init.d/${Service_ID}; then
			echo -e "${Error} ShadowsocksR服务 管理脚本下载失败 !" && exit 1
		fi
		sed -i 's/NAME="AShadowsocksR"/NAME="'${Service_ID}'-ShadowsocksR"/' /etc/init.d/${Service_ID}
		sed -i 's/^FOLDER=/'${Install_Directory}'shadowsocksr/' /etc/init.d/${Service_ID}
		sed -i 's/^BIN=/'${Install_Directory}'shadowsocksr\/server.py/' /etc/init.d/${Service_ID}
#		sed -i 's/		nohup "${python_ver}" "$BIN" > ssserver.log 2>&1 &/		nohup "${python_ver}" "$BIN" > ${Service_ID}-ssserver.log 2>&1 &/' /etc/init.d/${Service_ID}
		echo "管理脚本设置成功！"
}

Write_Service_Debian(){
		if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/debian-ssr -O /etc/init.d/${Service_ID}; then
			echo -e "${Error} ShadowsocksR服务 管理脚本下载失败 !" && exit 1
		fi
		sed -i 's/NAME="AShadowsocksR"/NAME="'${Service_ID}'-ShadowsocksR"/' /etc/init.d/${Service_ID}
		sed -i 's/^FOLDER=/'${Install_Directory}'shadowsocksr/' /etc/init.d/${Service_ID}
		sed -i 's/^BIN=/'${Install_Directory}'shadowsocksr\/server.py/' /etc/init.d/${Service_ID}
#		sed -i 's/		nohup "${python_ver}" "$BIN" > ssserver.log 2>&1 &/		nohup "${python_ver}" "$BIN" > ${Service_ID}-ssserver.log 2>&1 &/' /etc/init.d/${Service_ID}
		echo "管理脚本设置成功！"
}

Install_SSR_A(){
	cd "${Install_Directory}shadowsocksr"
	./setup_cymysql.sh
  ./initcfg.sh
}

# 写入配置信息
Write_configuration(){
	cat > ${Install_Directory}shadowsocksr/user-config.json<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "password": "m",
    "method": "chacha20",
    "protocol": "auth_aes128_sha1",
    "protocol_param": "",
    "obfs": "tls1.2_ticket_auth",
    "obfs_param": "",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,

    "additional_ports" : {},
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": ${SQL_IPV6},
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
}
Write_configuration_mysql(){
	cat > ${Install_Directory}shadowsocksr/usermysql.json<<-EOF
{
    "host": "${SQL_IP}",
    "port": ${SQL_PORT},
    "user": "${SQL_USERNAME}",
    "password": "${SQL_PWD}",
    "db": "${SQL_DB}",
    "node_id": ${NODE_ID},
    "transfer_mul": 1.0,
    "ssl_enable": 0,
    "ssl_ca": "",
    "ssl_cert": "",
    "ssl_key": ""
}
EOF
}
Write_configuration_Type(){
	cat > ${Install_Directory}shadowsocksr/userapiconfig.py<<-EOF
# Config
API_INTERFACE = 'legendsockssr' #mudbjson, sspanelv2, sspanelv3, sspanelv3ssr, glzjinmod, legendsockssr, muapiv2(not support)
UPDATE_TIME = 60
SERVER_PUB_ADDR = '127.0.0.1' # mujson_mgr need this to generate ssr link

#mudb
MUDB_FILE = 'mudb.json'

# Mysql
MYSQL_CONFIG = 'usermysql.json'

# API
MUAPI_CONFIG = 'usermuapi.json'
EOF
}

# 设置Iptables
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	elif [[ ${release} == "debian" ]]; then
		iptables-save > /etc/iptables.up.rules
		cat > /etc/network/if-pre-up.d/iptables<<-EOF
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.up.rules
EOF
		chmod +x /etc/network/if-pre-up.d/iptables
	elif [[ ${release} == "ubuntu" ]]; then
		iptables-save > /etc/iptables.up.rules
		echo -e "\npre-up iptables-restore < /etc/iptables.up.rules
post-down iptables-save > /etc/iptables.up.rules" >> /etc/network/interfaces
		chmod +x /etc/network/interfaces
	fi
}

Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${SSR_Port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${SSR_Port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}

Start_SSR(){
	Set_Service_ID
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ShadowsocksR 正在运行 !" && exit 1
	/etc/init.d/${Service_ID} start
}
Stop_SSR(){
	Set_Service_ID
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ShadowsocksR 未运行 !" && exit 1
	/etc/init.d/${Service_ID} stop
}
Restart_SSR(){
	Set_Service_ID
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/ssr stop
	/etc/init.d/${Service_ID} start
}

# Chacha20支持库
Check_Libsodium_ver(){
	echo -e "${Info} 开始获取 libsodium 最新版本..."
	Libsodiumr_ver=`wget -qO- https://github.com/jedisct1/libsodium/releases/latest | grep "<title>" | sed -r 's/.*Release (.+) · jedisct1.*/\1/'`
	[[ -z ${Libsodiumr_ver} ]] && Libsodiumr_ver=${Libsodiumr_ver_backup}
	echo -e "${Info} libsodium 最新版本为 ${Green_font_prefix}${Libsodiumr_ver}${Font_color_suffix} !"
}
Install_Libsodium(){
	[[ -e ${Libsodiumr_file} ]] && echo -e "${Error} libsodium 已安装 !" && exit 1
	echo -e "${Info} libsodium 未安装，开始安装..."
	Check_Libsodium_ver
	if [[ ${release} == "centos" ]]; then
		yum update
		yum -y groupinstall "Development Tools"
		wget  --no-check-certificate -N https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		./configure --disable-maintainer-mode && make -j2 && make install
		echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	else
		apt-get update
		apt-get install -y build-essential
		wget  --no-check-certificate -N https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		./configure --disable-maintainer-mode && make -j2 && make install
	fi
	ldconfig
	cd .. && rm -rf libsodium-${Libsodiumr_ver}.tar.gz && rm -rf libsodium-${Libsodiumr_ver}
	[[ ! -e ${Libsodiumr_file} ]] && echo -e "${Error} libsodium 安装失败 !" && exit 1
	echo && echo -e "${Info} libsodium 安装成功 !" && echo
}

Install_LotServer(){
	[[ -e ${LotServer_file} ]] && echo -e "${Error} LotServer 已安装 !" && exit 1
	#Github: https://github.com/0oVicero0/serverSpeeder_Install
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	[[ ! -e "/tmp/appex.sh" ]] && echo -e "${Error} LotServer 安装脚本下载失败 !" && exit 1
	bash /tmp/appex.sh 'install'
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "appex" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		echo -e "${Info} LotServer 安装完成 !" && exit 1
	else
		echo -e "${Error} LotServer 安装失败 !" && exit 1
	fi
}

System_Config(){
 Set_Modle_Config
echo "* soft nofile 51200" >> /etc/security/limits.conf
echo "* hard nofile 51200" >> /etc/security/limits.conf
echo "ulimit -SHn 51200" >> /etc/profile
echo "fs.file-max = 51200" >> /etc/sysctl.conf
echo "net.core.rmem_max = 67108864" >> /etc/sysctl.conf
echo "net.core.wmem_max = 67108864" >> /etc/sysctl.conf
echo "net.core.rmem_default = 65536" >> /etc/sysctl.conf
echo "net.core.wmem_default = 65536" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 4096" >> /etc/sysctl.conf
echo "net.core.somaxconn = 4096" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 1200" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 10000 65000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 4096" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 67108864" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 67108864" >> /etc/sysctl.conf
echo "net.ipv4.tcp_mtu_probing = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = ${Modle_Config}" >> /etc/sysctl.conf
modprobe tcp_${Modle_Config}
sysctl -p
}

Lotserver_Config(){
	echo "尚未编写"
exit 0
}

Install_Fail2ban(){
 wget  -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh -O /tmp/fail2ban.sh
 bash /tmp/fail2ban.sh
 sleep 2s
 PID=`ps -ef |grep -v grep |grep "fail2ban" |awk '{print $2}'`
  if [[ ! -z ${PID} ]]; then
		echo -e "${Info} Fail2ban 安装完成 !" && exit 1
	else
		echo -e "${Error} Fail2ban 安装失败 !" && exit 1
	fi
}

check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
[[ -z "$ip" ]] && ip="VPS_IP"
echo -e "  ShadowsocksR 服务端 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
          您的IP地址：${ip}
  ---- By Jiuling ----

 ${Green_font_prefix}1.${Font_color_suffix} 安装 ShadowsocksR 服务端
 ${Green_font_prefix}2.${Font_color_suffix} 安装 libsodium(chacha20)
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 ShadowsocksR 服务端
 ${Green_font_prefix}4.${Font_color_suffix} 停止 ShadowsocksR 服务端
 ${Green_font_prefix}5.${Font_color_suffix} 重启 ShadowsocksR 服务端
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 安装锐速(Lotserver)
 ${Green_font_prefix}7.${Font_color_suffix} 系统参数优化
 ${Green_font_prefix}8.${Font_color_suffix} 锐速参数优化
 ${Green_font_prefix}9.${Font_color_suffix} 安装Fail2Ban
 "
echo && stty erase '^H' && read -p "请输入数字 [1-10]：" num
case "$num" in
	1)
	Install_SSR
	;;
	2)
	Install_Libsodium
	;;
	3)
	Start_SSR
	;;
	4)
	Stop_SSR
	;;
	5)
	Restart_SSR
	;;
	6)
	Install_Lotserver
	;;
	7)
	System_Config
	;;
	8)
	Lotserver_Config
	;;
        9)
	Install_Fail2ban
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [1-9]"
	;;
esac
