#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# Notes: OneinStack for CentOS/RadHat 6+ Debian 7+ and Ubuntu 12+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/lj2007331/oneinstack

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#       OneinStack for CentOS/RadHat 6+ Debian 7+ and Ubuntu 12+      #
#       For more information please visit https://oneinstack.com      #
#######################################################################
"

# get pwd
sed -i "s@^oneinstack_dir.*@oneinstack_dir=`pwd`@" ./options.conf

. ./versions.txt
. ./options.conf
. ./include/color.sh
. ./include/check_os.sh
. ./include/check_dir.sh
. ./include/download.sh
. ./include/get_char.sh

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

mkdir -p $wwwroot_dir/default $wwwlogs_dir
[ -d /data ] && chmod 755 /data

# Use default SSH port 22. If you use another SSH port on your server
if [ -e "/etc/ssh/sshd_config" ]; then
  [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
fi
iptables_yn=n
Web_yn=n
DB_yn=n
PHP_version=5
Magick=1
FTP_yn=n
redis_yn=n
memcached_yn=n
HHVM_yn=n

# get the IP information
IPADDR=`./include/get_ipaddr.py`
PUBLIC_IPADDR=`./include/get_public_ipaddr.py`
IPADDR_COUNTRY_ISP=`./include/get_ipaddr_state.py $PUBLIC_IPADDR`
IPADDR_COUNTRY=`echo $IPADDR_COUNTRY_ISP | awk '{print $1}'`
[ "`echo $IPADDR_COUNTRY_ISP | awk '{print $2}'`"x == '1000323'x ] && IPADDR_ISP=aliyun

# del openssl for jcloud
[ -e "/usr/local/bin/openssl" ] && rm -rf /usr/local/bin/openssl
[ -e "/usr/local/include/openssl" ] && rm -rf /usr/local/include/openssl

# Check binary dependencies packages
. ./include/check_sw.sh
case "${OS}" in
  "CentOS")
    installDepsCentOS 2>&1 | tee ${oneinstack_dir}/install.log
    ;;
  "Debian")
    installDepsDebian 2>&1 | tee ${oneinstack_dir}/install.log
    ;;
  "Ubuntu")
    installDepsUbuntu 2>&1 | tee ${oneinstack_dir}/install.log
    ;;
esac

# init
startTime=`date +%s`
. ./include/memory.sh
case "${OS}" in
  "CentOS")
    . include/init_CentOS.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
    [ -n "$(gcc --version | head -n1 | grep '4\.1\.')" ] && export CC="gcc44" CXX="g++44"
    ;;
  "Debian")
    . include/init_Debian.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  "Ubuntu")
    . include/init_Ubuntu.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

# Check download source packages
. ./include/check_download.sh
downloadDepsSrc=1
checkDownload 2>&1 | tee -a ${oneinstack_dir}/install.log

# Install dependencies from source package
installDepsBySrc 2>&1 | tee -a ${oneinstack_dir}/install.log

# Jemalloc
if [[ $Nginx_version =~ ^[1-3]$ ]] || [ "$DB_yn" == 'y' ]; then
  . include/jemalloc.sh
  Install_Jemalloc | tee -a $oneinstack_dir/install.log
fi

# openSSL 
. ./include/openssl.sh
if [[ $Tomcat_version =~ ^[1-3]$ ]] || [[ $Apache_version =~ ^[1-2]$ ]] || [[ $PHP_version =~ ^[1-6]$ ]]; then
  Install_openSSL102 | tee -a $oneinstack_dir/install.log
fi

# PHP
case "${PHP_version}" in
  5)
    . include/php-7.0.sh
    Install_PHP70 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

# ImageMagick or GraphicsMagick
if [ "$Magick" == '1' ]; then
  . include/ImageMagick.sh
  [ ! -d "/usr/local/imagemagick" ] && Install_ImageMagick 2>&1 | tee -a $oneinstack_dir/install.log
  [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/imagick.so" ] && Install_php-imagick 2>&1 | tee -a $oneinstack_dir/install.log
fi

# get web_install_dir and db_install_dir
. include/check_dir.sh


echo "####################Congratulations########################"
echo "Total OneinStack PHP Install Done!"
[ "${PHP_yn}" == 'y' ] && echo -e "\n$(printf "%-32s" "PHP install dir:")${CMSG}${php_install_dir}${CEND}"
echo "###########################################################"
