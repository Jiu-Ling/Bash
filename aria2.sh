#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#	Description: Install Aria2c
#	Version: 1.2
#	Author: Jiuling
#=================================================

sh_ver="1.2"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"
file="/etc/aria2"
aria2c_conf="${file}/aria2c.conf"
aria2c_log="/etc/aria2/aria2.log"
Aria2c_File(){
	if [[ ${release} = "debian" ]]; then
		cat /etc/debian_version |grep 9\..*>/dev/null
		if [[ $? = 1 ]]; then
                aria2c="/usr/bin/aria2c"			
		fi
	else
		aria2c="/usr/local/bin/aria2c"
	fi
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
	PID=`ps -ef| grep "aria2c"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_pid_caddy(){
	PIDC=`ps -ef| grep "caddy"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_installed_status(){
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 没有安装，请检查 !" && exit 1
	[[ ! -e ${aria2c_conf} ]] && echo -e "${Error} Aria2 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}
check_caddy_installed_status(){
	[[ ! -e /usr/local/bin/caddy ]] && echo -e "${Error} Caddy 没有安装，请检查 !" && exit 1
	[[ ! -e /etc/caddy/config.conf ]] && echo -e "${Error} Caddy 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}

# 安装 依赖
Install_Aria2(){
	if [[ ${release} == "centos" ]]; then
		Centos_Install_Yum
	fi
		Debian_Install
}
Centos_Install_Yum(){
	if [[ ${release} = "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 1 ]]; then
			wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo -qO /etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo
			[[ ! -e "/etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo" ]] && echo -e "${Error} CentOS 6 Repo 配置文件下载失败 !" && exit 1
			yum install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils devtoolset-3-gcc-gfortran sed clang -y
			yum groupinstall "Development Tools" -y
			echo -e "${Tip} 请执行 ${Green_font_prefix}scl enable devtoolset-3 bash${Font_color_suffix} 后运行 Centos 安装 Aria2 步骤二" && exit 1
		fi
		wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3-el7/repo/epel-7/rhscl-devtoolset-3-el7-epel-7.repo -qO /etc/yum.repos.d/rhscl-devtoolset-3-el7-epel-7.repo
		[[ ! -e "/etc/yum.repos.d/rhscl-devtoolset-3-el7-epel-7.repo" ]] && echo -e "${Error} CentOS 7 Repo 配置文件下载失败 !" && exit 1
		yum install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils devtoolset-3-gcc-gfortran sed clang -y
		yum groupinstall "Development Tools"
		echo -e "${Tip} 请执行 ${Green_font_prefix}scl enable devtoolset-3 bash${Font_color_suffix} 后运行 Centos 安装 Aria2 步骤二" && exit 1
		fi
}
Centos_Install(){
	mkdir /etc/aria2
	cd /etc/aria2
  wget --no-check-certificate https://github.com/aria2/aria2/releases/download/release-1.33.0/aria2-1.33.0.tar.gz
    [[ ! -e "/etc/aria2/aria2-1.33.0.tar.gz" ]] && echo -e "${Error} Aria2源码下载失败 !" && exit 1
  tar xzvf aria2-1.33.0.tar.gz
  cd aria2-1.33.0
  sed -i s"/1\, 16\,/1\, 64\,/" ./src/OptionHandlerFactory.cc
  ./configure
  make && make install
  Download_Config
  Service_Aria2
  echo -e "${Info} Aria2安装成功！"
}
Debian_Install(){
	apt-get update
	apt-get install -y make gcc g++ sed vim git sed nettle-dev libgmp-dev libssh2-1-dev libc-ares-dev libxml2-dev zlib1g-dev libsqlite3-dev pkg-config libgpg-error-dev libssl-dev libexpat1-dev libxml2-dev libcppunit-dev autoconf automake autotools-dev autopoint libtool libxml2-dev openssl gettext
  mkdir /etc/aria2
  cd /etc/aria2
  git clone https://github.com/aria2/aria2.git
  cd aria2
  sed -i s"/1\, 16\,/1\, 64\,/" ./src/OptionHandlerFactory.cc
  autoreconf -i
  ./configure
  make
  make install
  Download_Config
  Service_Aria2
  echo -e "${Info} Aria2安装成功！"
}

# 设置自启
Service_Aria2(){
		if [[ ${release} = "centos" ]]; then
      if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2 -qO /etc/init.d/aria2; then
			  echo -e "${Error} Aria2服务 管理脚本下载失败 !" && exit 1
		  fi
		  chmod +x /etc/init.d/aria2
		  chkconfig --add aria2
		  chkconfig aria2 on
		  mkdir -p ~/.aria2
      chmod -R a+x ~/.aria2
		else
		  if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2 -qO /etc/init.d/aria2; then
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
	wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2c.conf -qO /etc/aria2/aria2c.conf
	[[ ! -s "/etc/aria2/aria2c.conf" ]] && echo -e "${Error} Aria2 配置文件下载失败 !" && rm -rf "${file}" && exit 1
	wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/dht.dat -qO  /etc/aria2/dht.dat
	[[ ! -s "/etc/aria2/dht.dat" ]] && echo -e "${Error} Aria2 DHT文件下载失败 !" && rm -rf "${file}" && exit 1
	echo '' > /etc/aria2/aria2.session
}
Set_Url(){
	echo "请输入网站网址（不带http(s)）："
	stty erase '^H' && read -p "(默认: localhost):" Url
	[[ -z "${Url}" ]] && Url="localhost"
  echo && echo ${Separator_1} && echo -e "	 网址 : ${Green_font_prefix}${Url}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_Mail(){
	echo "请输入您的邮箱(用于自动申请SSL证书)："
	stty erase '^H' && read -p "(默认: admin@${Url}):" Mail
	[[ -z "${Mail}" ]] && Url="admin@${Url}"
  echo && echo ${Separator_1} && echo -e "	邮箱 : ${Green_font_prefix}${Mail}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Config_True(){
  while [ "$go" != 'y' ] && [ "$go" != 'n' ]
  do
	read -p "您的网站 https://${Url} 确认已经解析好了么(不要加CDN)，确认请y继续(y/n): " go;
   done
   if [ "$go" == 'n' ];then
	exit 1
	fi
}
Ng_SSL_Filemanager_Install(){
check_installed_status
apt-get install curl sed wget -y
	Set_Url
	Set_Mail
	Config_True
	curl https://getcaddy.com | bash -s personal http.filemanager
	[[ -e /usr/local/bin/caddy ]] && echo -e "${Info} Caddy安装成功！"
  mkdir /etc/caddy
  wget --no-check-certificate -N "https://raw.githubusercontent.com/Thnineer/Bash/master/init/config.conf" -O /etc/caddy/config.conf
  [[ ! -s "/etc/caddy/config.conf" ]] && echo -e "${Error} Caddy 配置文件下载失败 !" && rm -rf /etc/caddy/config.conf && exit 1
  sed -i 's,https:\/\/example.com,https:\/\/'${Url}',' /etc/caddy/config.conf
  sed -i 's:mailexample:'${Mail}':' /etc/caddy/config.conf
  mkdir /www && mkdir /www/wwwroot && mkdir /etc/filemanager && mkdir /home/downloads
  cd /www/wwwroot
  git clone https://github.com/Thnineer/AriaNg-DailyBuild.git
  mv AriaNg-DailyBuild ariang
  [[ ! -s "/www/wwwroot/ariang/index.html" ]] && echo -e "${Error} AriaNG 下载失败 !" && rm -rf /www/wwwroot/ariang && exit 1
  ulimit -n 51200
  Start_caddy
  echo -e "${Info} Filemanager管理地址：https://${Url}/file
  默认账号密码：admin admin 请及时更改！" && exit 1
}
Write_Dir(){
	cat >/tmp/a<<-EOF
${Value}
EOF
New_Value=`sed 's:\/:\\/:g' /tmp/a`
rm -rf /tmp/a
}
Start_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Aria2 正在运行，请检查 !" && exit 1
	/etc/init.d/aria2 start
}
Start_caddy(){
	check_caddy_installed_status
	check_pid_caddy
	[[ ! -z ${PIDC} ]] && echo -e "${Error} Caddy 正在运行，请检查 !" && exit 1
	nohup caddy -conf="/etc/caddy/config.conf" >/dev/null 2>&1 &
	[[ ! -z ${PIDC} ]] && echo -e "${Info} Caddy 启动成功！"
}
Stop_caddy(){
	check_caddy_installed_status
	check_pid_caddy
	[[ -z ${PIDC} ]] && echo -e "${Error} Aria2 没有运行，请检查 !" && exit 1
  eval $(ps -ef | grep caddy | grep -v grep | awk '{print "kill "$2}')
  [[ -z ${PIDC} ]] && echo -e "${Error} Caddy停止成功！"
}
Restart_caddy(){
	Stop_caddy
	Start_caddy
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
Aria2c_File
IP=`wget -qO- -t1 -T2 ipinfo.io/ip`      
echo && echo -e " Aria2 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- By Jiuling 您的IP地址：${IP} --
  
 ${Green_font_prefix}1.${Font_color_suffix} 安装 Aria2
 ${Green_font_prefix}2.${Font_color_suffix} Centos 安装 Aria2 步骤二
 ${Green_font_prefix}3.${Font_color_suffix} 安装 AriaNG 和 Filemanager 并启用SSL(Caddy服务端)
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 Aria2
 ${Green_font_prefix}5.${Font_color_suffix} 停止 Aria2
 ${Green_font_prefix}6.${Font_color_suffix} 重启 Aria2
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 启动 Caddy
 ${Green_font_prefix}8.${Font_color_suffix} 停止 Caddy
 ${Green_font_prefix}9.${Font_color_suffix} 重启 Caddy
 ————————————
 ${Green_font_prefix}10.${Font_color_suffix} 查看 日志信息
————————————" && echo
if [[ -e ${aria2c} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: Aria2 ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: Aria2 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: Aria2 ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 请输入数字 [0-10]:" num
case "$num" in
	1)
	Install_Aria2
	;;
	2)
	Centos_Install
	;;
	3)
	Ng_SSL_Filemanager_Install
	;;
	4)
	Start_aria2
	;;
	5)
	Stop_aria2
	;;
	6)
	Restart_aria2
	;;
        7)
	Start_caddy
	;;
	8)
	Stop_caddy
	;;
	9)
	Restart_caddy
	;;
	10)
	View_Log 
	;;
	*)
	echo "请输入正确数字 [1-10]"
	;;
esac
