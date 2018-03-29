#!/usr/bin/env bash
PATH=/opt/rh/devtoolset-3/root/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#	Description: Install Aria2c
#	Version: 1.4
#	Author: Jiuling
#=================================================

sh_ver="1.4"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"
file="/etc/aria2"
aria2c_conf="${file}/aria2c.conf"
aria2c_log="/etc/aria2/aria2.log"
aria2c="/usr/local/bin/aria2c"

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
	PIDC=`ps -ef| grep "caddy"| grep -v grep | awk '{print $2}'`
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
	echo "* soft nofile 51200" >> /etc/security/limits.conf
  echo "* hard nofile 51200" >> /etc/security/limits.conf
  echo "ulimit -SHn 51200" >> /etc/profile
	if [[ ${release} == "centos" ]]; then
		Centos_Install_Yum
	fi
		Debian_Install
}
Centos_Install_Yum(){
  yum install wget sed curl head gawk grep -y
	if [[ ${release} = "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 1 ]]; then
			wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo -qO /etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo
			[[ ! -e "/etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo" ]] && echo -e "${Error} CentOS 6 Repo 配置文件下载失败 !" && exit 1
			yum groupinstall "Development Tools" -y
			yum install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils devtoolset-3-gcc-gfortran sed clang -y
			yum remove gcc gcc-c++ -y
			yum install bzip2-devel freetype-devel libjpeg-devel libpng-devel libtiff-devel giflib-devel zlib-devel ghostscript-devel djvulibre-devel libwmf-devel jasper-devel libtool-ltdl-devel libX11-devel libXext-devel libXt-devel lcms-devel libxml2-devel librsvg2-devel OpenEXR-devel -y
			echo -e "${Tip} 请执行 ${Green_font_prefix}scl enable devtoolset-3 bash${Font_color_suffix} 后运行 Centos 安装 Aria2 步骤二" && exit 1
		fi
		wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3-el7/repo/epel-7/rhscl-devtoolset-3-el7-epel-7.repo -qO /etc/yum.repos.d/rhscl-devtoolset-3-el7-epel-7.repo
		[[ ! -e "/etc/yum.repos.d/rhscl-devtoolset-3-el7-epel-7.repo" ]] && echo -e "${Error} CentOS 7 Repo 配置文件下载失败 !" && exit 1
		yum groupinstall "Development Tools" -y
		yum install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils devtoolset-3-gcc-gfortran sed clang -y
		yum remove gcc gcc-c++ -y
		yum install bzip2-devel freetype-devel libjpeg-devel libpng-devel libtiff-devel giflib-devel zlib-devel ghostscript-devel djvulibre-devel libwmf-devel jasper-devel libtool-ltdl-devel libX11-devel libXext-devel libXt-devel lcms-devel libxml2-devel librsvg2-devel OpenEXR-devel -y
		echo -e "${Tip} 请执行 ${Green_font_prefix}scl enable devtoolset-3 bash${Font_color_suffix} 后运行 Centos 安装 Aria2 步骤二" && exit 1
		fi
}
Centos_Install(){
  mkdir /etc/aria2
  cd /etc/aria2
  echo -e "${Info} 检查版本中..."
  Aria2ver=`wget -qO- https://github.com/aria2/aria2/releases | grep css-truncate-target | head -n 1 | awk '{print $2}' | sed 's/class=\"css-truncate-target\">release-//g' | sed 's/<\/span>//g'`
  wget --no-check-certificate https://github.com/aria2/aria2/releases/download/release-${Aria2ver}/aria2-${Aria2ver}.tar.gz
  [[ ! -e "/etc/aria2/aria2-${Aria2ver}.tar.gz" ]] && echo -e "${Error} Aria2源码下载失败 !" && exit 1
  tar xzvf aria2-${Aria2ver}.tar.gz
  cd aria2-${Aria2ver}
  sed -i s"/1\, 16\,/1\, 64\,/" ./src/OptionHandlerFactory.cc
  ./configure
  make && make install
  Download_Config
  Service_Aria2
  BT-Tracker
  [[ ! -e "${aria2c}" ]] && echo -e "${Error} Aria2安装失败 !" && exit 1
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
  BT-Tracker
  [[ ! -e "${aria2c}" ]] && echo -e "${Error} Aria2安装失败 !" && exit 1
  echo -e "${Info} Aria2安装成功！"
}
BT-Tracker(){
  wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/bt-tracker.sh -qO /etc/aria2/bt-tracker.sh
  chmod +x /etc/aria2/bt-tracker.sh
  cronfile="/tmp/crontab.${USER}"
  crontab -l > $cronfile
  echo "*/30 * * * * bash /etc/aria2/bt-tracker.sh" >> $cronfile
  crontab $cronfile
  rm -rf $cronfile
  echo -e "${Info} BT服务器自动更新设置成功！"
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
Service_Caddy(){
	cd /etc/caddy
	wget http://developer.axis.com/download/distribution/apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
	tar zxf apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
	mv apps/sys-utils/start-stop-daemon-IR1_9_18-2/ ./
	rm -rf apps
	cd start-stop-daemon-IR1_9_18-2/
	cc start-stop-daemon.c -o start-stop-daemon
	cp start-stop-daemon /usr/local/bin/start-stop-daemon
	ln -s /usr/local/bin/start-stop-daemon /usr/bin/start-stop-daemon
	[[ ! -s "/usr/local/bin/start-stop-daemon" ]] && echo -e "${Error} Start-Stop-Deamon 安装失败 !"  && exit 1
	echo -e "${Info} Start-Stop-Deamon 安装成功！"
	  if [[ ${release} = "centos" ]]; then
      if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/caddy -qO /etc/init.d/caddy; then
			  echo -e "${Error} Caddy服务 管理脚本下载失败 !" && exit 1
		  fi
		  chmod +x /etc/init.d/caddy
		  chkconfig --add caddy
		  chkconfig caddy on
		  mkdir -p ~/.caddy
      chmod -R a+x ~/.caddy
		else
		  if ! wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/caddy -qO /etc/init.d/caddy; then
			  echo -e "${Error} Caddy服务 管理脚本下载失败 !" && exit 1
		  fi
      chmod +x /etc/init.d/caddy
      update-rc.d -f caddy remove >/dev/null 2>&1
      update-rc.d caddy defaults
      mkdir -p ~/.caddy
      chmod -R a+x ~/.caddy
    fi
}
PHP_Install(){
        if [[ ${release} == "centos" ]]; then
		Centos_Install_Ffmpeg
                Install_PHP70
        else
		Debian_Install_Ffmpeg
                Install_PHP70
	fi
}
Centos_Install_Ffmpeg(){
	yum update
	yum install -y libtool make git
	yum -y groupinstall "Development Tools"
	mkdir /etc/ffmpeg
	cd /etc/ffmpeg
  wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/build-ffmpeg.sh -qO /etc/ffmpeg/build-ffmpeg
  chmod +x build-ffmpeg
  ./build-ffmpeg --build
  [[ ! -s "/usr/bin/ffmpeg" ]] && echo -e "${Error} Ffmpeg 安装失败 !"  && exit 1
  echo -e "${Info} Ffmpeg 安装成功！"
}
Debian_Install_Ffmpeg(){
	apt-get update
	apt-get install -y libtool make git
	apt-get install build-essential curl -y
	mkdir /etc/ffmpeg
	cd /etc/ffmpeg
  wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/ffmpeg.sh -qO /etc/ffmpeg/ffmpeg.sh
  chmod +x ffmpeg.sh
  ./ffmpeg
  [[ ! -s "/usr/bin/ffmpeg" ]] && echo -e "${Error} Ffmpeg 安装失败 !"  && exit 1
  echo -e "${Info} Ffmpeg 安装成功！"
}
Install_PHP70(){
	mkdir /etc/oneinstack
	wget -O /etc/oneinstack/oneinstack-full.tar.gz http://mirrors.linuxeye.com/oneinstack-full.tar.gz
	[[ ! -s "/etc/oneinstack/oneinstack-full.tar.gz" ]] && echo -e "${Error} Oneinstack 下载失败 !" && rm -rf "/etc/oneinstack/oneinstack-full.tar.gz" && exit 1
	cd /etc/oneinstack
	tar xzf oneinstack-full.tar.gz
	cd oneinstack
	wget -qO /etc/oneinstack/oneinstack/install.sh https://raw.githubusercontent.com/Thnineer/Bash/master/oneinstackphp.sh
	./install.sh
	[[ ! -s "/usr/local/php" ]] && echo -e "${Error} PHP7.0 安装失败 !"  && exit 1
	sed -i 's/scandir,//' /usr/local/php/etc/php.ini
	sed -i 's/exec,//' /usr/local/php/etc/php.ini
	sed -i 's/passthru,//' /usr/local/php/etc/php.ini
  service php-fpm restart
  ln /usr/local/imagemagick/bin/convert /usr/local/bin/convert
	echo -e "${Info} PHP 7.0 安装成功！"
}
Ng_SSL_Filemanager_Install_H5ai(){
  if [[ ${release} == "centos" ]]; then
    yum install curl sed wget unzip -y
  else
    apt-get install curl sed wget unzip -y
  fi
  Set_Url
	Set_Mail
	Config_True
	PHP_Install
	curl https://getcaddy.com | bash -s personal http.filemanager
	[[ -e /usr/local/bin/caddy ]] && echo -e "${Info} Caddy安装成功！"
  mkdir /etc/caddy
  wget --no-check-certificate -N "https://raw.githubusercontent.com/Thnineer/Bash/master/init/config-php.conf" -qO /etc/caddy/config.conf
  [[ ! -s "/etc/caddy/config.conf" ]] && echo -e "${Error} Caddy 配置文件下载失败 !" && rm -rf /etc/caddy/config.conf && exit 1
  sed -i 's,https:\/\/example.com,https:\/\/'${Url}',g' /etc/caddy/config.conf
  sed -i 's:mailexample:'${Mail}':g' /etc/caddy/config.conf
  mkdir /etc/filemanager && mkdir  /home/h5ai/ && mkdir /home/h5ai/downloads
  cd /home/
  git clone https://github.com/Thnineer/AriaNg-DailyBuild.git
  mv AriaNg-DailyBuild ariang
  [[ ! -s "/home/ariang/index.html" ]] && echo -e "${Error} AriaNG 下载失败 !" && rm -rf /home/ariang && exit 1
  cd /home/h5ai
  wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/Source/h5ai-0.29.0.zip
  unzip h5ai-0.29.0.zip
  ulimit -n 51200
  echo "* soft nofile 51200" >> /etc/security/limits.conf
  echo "* hard nofile 51200" >> /etc/security/limits.conf
  echo "ulimit -SHn 51200" >> /etc/profile
  sed -i 's;https:\/\/teduis.com\/ariang;https:\/\/'${Url}':7878;' /home/h5ai/_h5ai/public/js/scripts.js
  sed -i 's;https:\/\/teduis.com\/file;https:\/\/'${Url}'\/file;' /home/h5ai/_h5ai/public/js/scripts.js
  Start_caddy
  Service_Caddy
  echo -e "${Info} 安装成功!
${Info} Ariang面板地址:https://${Url}:7878
${Info} Filemanager管理地址：https://${Url}/file
${Info} 默认账号密码：admin admin 请及时更改！" && exit 1
}
# 下载配置文件
Download_Config(){
	cd /etc/aria2
	wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/aria2c.conf -qO /etc/aria2/aria2c.conf
	[[ ! -s "/etc/aria2/aria2c.conf" ]] && echo -e "${Error} Aria2 配置文件下载失败 !" && rm -rf "/etc/aria2/aria2c.conf" && exit 1
	wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/dht.dat -qO  /etc/aria2/dht.dat
	[[ ! -s "/etc/aria2/dht.dat" ]] && echo -e "${Error} Aria2 DHT文件下载失败 !" && rm -rf "/etc/aria2/dht.dat" && exit 1
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
  if [[ ${release} == "centos" ]]; then
    yum install curl sed wget -y
  else
    apt-get install curl sed wget -y
  fi
	Set_Url
	Set_Mail
	Config_True
	curl https://getcaddy.com | bash -s personal http.filemanager
	[[ -e /usr/local/bin/caddy ]] && echo -e "${Info} Caddy安装成功！"
  mkdir /etc/caddy
  wget --no-check-certificate -N "https://raw.githubusercontent.com/Thnineer/Bash/master/init/config.conf" -qO /etc/caddy/config.conf
  [[ ! -s "/etc/caddy/config.conf" ]] && echo -e "${Error} Caddy 配置文件下载失败 !" && rm -rf /etc/caddy/config.conf && exit 1
  sed -i 's,https:\/\/example.com,https:\/\/'${Url}',' /etc/caddy/config.conf
  sed -i 's:mailexample:'${Mail}':' /etc/caddy/config.conf
  mkdir /etc/filemanager && mkdir /home/h5ai/downloads
  cd /home/
  git clone https://github.com/Thnineer/AriaNg-DailyBuild.git
  mv AriaNg-DailyBuild ariang
  [[ ! -s "/home/ariang/index.html" ]] && echo -e "${Error} AriaNG 下载失败 !" && rm -rf /www/wwwroot/ariang && exit 1
  ulimit -n 51200
  echo "* soft nofile 51200" >> /etc/security/limits.conf
  echo "* hard nofile 51200" >> /etc/security/limits.conf
  echo "ulimit -SHn 51200" >> /etc/profile
  Start_caddy
  Service_Caddy
  echo -e "${Info} Filemanager管理地址：https://${Url}/file
${Info} 默认账号密码：admin admin 请及时更改！" && exit 1
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
	service caddy start
	[[ ! -z ${PIDC} ]] && echo -e "${Info} Caddy 启动成功！"
}
Stop_caddy(){
	check_caddy_installed_status
	check_pid_caddy
	[[ -z ${PIDC} ]] && echo -e "${Error} Aria2 没有运行，请检查 !" && exit 1
  service caddy stop
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
	[[ ! -e /var/run/caddy.log ]] && echo -e "${Error} Caddy 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo
	tail -f /var/run/caddy.log
}
Aria2_Buzhou(){
	echo && echo -e " Aria2 安装及管理 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- By Jiuling 您的IP地址：${IP} --

 ${Green_font_prefix}1.${Font_color_suffix} 安装 Aria2
 ${Green_font_prefix}2.${Font_color_suffix} Centos 安装 Aria2 步骤二
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 Aria2
 ${Green_font_prefix}4.${Font_color_suffix} 停止 Aria2
 ${Green_font_prefix}5.${Font_color_suffix} 重启 Aria2
————————————" && echo
if [[  -e ${aria2c} ]]; then
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
stty erase '^H' && read -p " 请输入数字 [1-5]:" numa
case "$numa" in
	1)
	Install_Aria2
	;;
	2)
	Centos_Install
	;;
	3)
	Start_aria2
	;;
	4)
	Stop_aria2
	;;
	5)
	Restart_aria2
	;;
	*)
	echo "请输入正确数字 [1-5]"
	;;
esac
}
Caddy_Buzhou(){
	echo && echo -e " Caddy 安装及管理 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- By Jiuling 您的IP地址：${IP} --

 ${Green_font_prefix}1.${Font_color_suffix} 安装Ariang+Filemanager
 ${Green_font_prefix}2.${Font_color_suffix} 安装Ariang+Filemanager+H5ai(编译安装，可能需要较长时间)
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 Caddy
 ${Green_font_prefix}4.${Font_color_suffix} 停止 Caddy
 ${Green_font_prefix}5.${Font_color_suffix} 重启 Caddy
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 查看 Caddy 日志
————————————" && echo
if [[ -e  /usr/local/bin/caddy ]]; then
	check_pid_caddy
	if [[ ! -z "${PIDC}" ]]; then
		echo -e " 当前状态: Caddy ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: Caddy ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: Caddy ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 请输入数字 [1-6]:" numc
case "$numc" in
	1)
	Ng_SSL_Filemanager_Install
	;;
	2)
	Ng_SSL_Filemanager_Install_H5ai
	;;
        3)
	Start_caddy
	;;
	4)
	Stop_caddy
	;;
	5)
	Restart_caddy
	;;
	6)
	View_Log
	;;
	*)
	echo "请输入正确数字 [1-6]"
	;;
esac
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
IP=`wget -qO- -t1 -T2 ipinfo.io/ip`      
echo && echo -e " Aria2 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- By Jiuling 您的IP地址：${IP} --

 ${Green_font_prefix}1.${Font_color_suffix} Aria2 安装及管理
 ${Green_font_prefix}2.${Font_color_suffix} Web面板 安装及管理
————————————" && echo
echo
stty erase '^H' && read -p " 请输入数字 [1-2]:" num
case "$num" in
	1)
	Aria2_Buzhou
	;;
	2)
	Caddy_Buzhou
	;;
	*)
	echo "请输入正确数字 [1-2]"
	;;
esac
