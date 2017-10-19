#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#	Description: Install Aria2c
#	Version: 1.0
#	Author: Jiuling
#=================================================

sh_ver="1.0"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"
file="/etc/aria2"
aria2c_conf="${file}/aria2c.conf"
aria2c_log="/etc/aria2/aria2.log"
aria2c="/usr/bin/aria2c"

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
	PID=`ps -ef| grep "aria2c"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_installed_status(){
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 没有安装，请检查 !" && exit 1
	[[ ! -e ${aria2_conf} ]] && echo -e "${Error} Aria2 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}

# 安装 依赖
Install_Aria2(){
	if [[ ${release} == "centos" ]]; then
		Centos_Install
		Download_Config
		Service_Aria2
	fi
		Debian_Install
		Download_Config
		Service_Aria2
}
Centos_Install(){
	yum update -y
	yum install wget curl sed -y
  wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo -O /etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo
  [[ ! -e "/etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo" ]] && echo -e "${Error} CentOS Repo 配置文件下载失败 !" && exit 1
  yum install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils devtoolset-3-gcc-gfortran -y
  scl enable devtoolset-3 bash
  wget https://github.com/aria2/aria2/releases/download/release-1.32.0/aria2-1.32.0.tar.gz
  tar xzvf aria2-1.32.0.tar.gz
  cd aria2-1.32.0
  sed -i s"/1\, 16\,/1\, 64\,/" ./src/OptionHandlerFactory.cc
  ./configure
  make && make install
}
Debian_Install(){
	apt-get update
	apt-get install -y vim git sed nettle-dev libgmp-dev libssh2-1-dev libc-ares-dev libxml2-dev zlib1g-dev libsqlite3-dev pkg-config libgpg-error-dev libssl-dev libexpat1-dev libxml2-dev libcppunit-dev autoconf automake autotools-dev autopoint libtool libxml2-dev openssl gettext
  git clone https://github.com/aria2/aria2.git
  cd aria2
  sed -i s"/1\, 16\,/1\, 64\,/" ./src/OptionHandlerFactory.cc
  autoreconf -i
  ./configure
  make
  make install
}

# 设置自启
Service_Aria2(){
		if [[ ${release} = "centos" ]]; then
			mkdir -p /etc/aria2
      if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2 -O /etc/init.d/aria2; then
			  echo -e "${Error} Aria2服务 管理脚本下载失败 !" && exit 1
		  fi
		  chmod +x /etc/init.d/aria2
		  chkconfig --add aria2
		  chkconfig aria2 on
		  mkdir -p ~/.aria2
      chmod -R a+x ~/.aria2
		else
		  mkdir -p /etc/aria2
		  if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2 -O /etc/init.d/aria2; then
			  echo -e "${Error} Aria2服务 管理脚本下载失败 !" && exit 1
		  fi
      chmod +x /etc/init.d/aria2
      update-rc.d -f aria2 remove >/dev/null 2>&1
      update-rc.d aria2 defaults
      mkdir -p ~/.aria2
      chmod -R a+x ~/.aria2
    fi
}
# 下载配置文件
Download_Config(){
	cd /etc/aria2
	wget --no-check-certificate -N "https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2c.conf"
	[[ ! -s "aria2c.conf" ]] && echo -e "${Error} Aria2 配置文件下载失败 !" && rm -rf "${file}" && exit 1
	wget --no-check-certificate -N "https://raw.githubusercontent.com/Thnineer/Bash/master/init/dht.dat"
	[[ ! -s "dht.dat" ]] && echo -e "${Error} Aria2 DHT文件下载失败 !" && rm -rf "${file}" && exit 1
	echo '' > /etc/aria2/aria2.session
}
Start_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Aria2 正在运行，请检查 !" && exit 1
	/etc/init.d/aria2 start
}
Stop_aria2(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Aria2 没有运行，请检查 !" && exit 1
	/etc/init.d/aria2 stop
}
Restart_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/aria2 stop
	/etc/init.d/aria2 start
}
View_Log(){
	[[ ! -e ${aria2_log} ]] && echo -e "${Error} Aria2 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo
	tail -f ${aria2_log}
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
IP=`wget -qO- -t1 -T2 ipinfo.io/ip`      
echo && echo -e " Aria2 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- By Jiuling 您的IP地址：${IP} --
  
 ${Green_font_prefix}1.${Font_color_suffix} 安装 Aria2
————————————
 ${Green_font_prefix}2.${Font_color_suffix} 启动 Aria2
 ${Green_font_prefix}3.${Font_color_suffix} 停止 Aria2
 ${Green_font_prefix}4.${Font_color_suffix} 重启 Aria2
————————————
 ${Green_font_prefix}5.${Font_color_suffix} 查看 日志信息
————————————" && echo
if [[ -e ${aria2c} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 请输入数字 [0-7]:" num
case "$num" in
	1)
	Install_Aria2
	;;
	2)
	Start_aria2
	;;
	3)
	Stop_aria2
	;;
	4)
	Restart_aria2
	;;
	5)
	View_Log
	;;
	*)
	echo "请输入正确数字 [1-5]"
	;;
esac
