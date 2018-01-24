#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# By Jiuling.

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Message]${Font_color_suffix}"
Error="${Red_font_prefix}[ERROR]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"
Ver="1.0"
DirectAdminNginxConf_Path="/etc/nginx"
CustomBuild_Path="/usr/local/directadmin/custombuild"
CustomBuild_Build="/usr/local/directadmin/custombuild/build"

echo -e "${Info} Scripts is made by Jiuling. Ver ${Ver}"
echo -e "${Info} More Informatin. Please visit https://teduis.com/bash/Directadmin-Nginx-Lua.html"
echo -e "${Tip} Start installation after 10 seconds. If you want to exit,please press Ctrl+C."
sleep 10
[[ ! -e "${CustomBuild_Build}" ]] && echo -e "${Error} DirectAdmin is not installed !" && exit 1

yum install grep gawk sed curl wget -y

echo -e "${Info} Checking Version..."
LuaJIT_Ver="2.1.0-beta3"
Ngx_Devel_Kit_Ver=`wget -qO- https://github.com/simpl/ngx_devel_kit/releases/latest | grep "css-truncate-target" | awk '{print $2}' | sed 's/class=\"css-truncate-target\">//g' | sed 's/<\/span>//g'`
Lua_Nginx_Module_Ver=`wget -qO- https://github.com/openresty/lua-nginx-module/releases | grep "tag-name" | awk '{print $2}' | head -n 1 | sed 's/class=\"tag-name\">//g' | sed 's/<\/span>//g'`
if [ ! -n "${Ngx_Devel_Kit_Ver}" ]; then
        echo -e "${Error} Unable to get the latest version of Ngx_Devel_Kit!" && exit 1
else
  if [ ! -n "${Lua_Nginx_Module_Ver}" ]; then
        echo -e "${Error} Unable to get the latest version of Lua-Nginx-Module!" && exit 1
  else
  echo -e "The version of Ngx_Devel_Kit is ${Ngx_Devel_Kit_Ver}."
  echo -e "The version of Lua-Nginx-Module is ${Lua_Nginx_Module_Ver}."
  fi
fi

Install_LuaJIT(){
        yum install hwloc-devel libmicrohttpd-devel openssl-devel pcer pcre-devel zlib zlib-devel -y
        yum install -y gcc g++ gcc-c++
        echo -e "${Info} Install LuaJIT"
        wget -q 'http://luajit.org/download/LuaJIT-${LuaJIT_Ver}.tar.gz' -O /root/LuaJIT-${LuaJIT_Ver}.tar.gz
        [[ ! -e "/root/LuaJIT-${LuaJIT_Ver}.tar.gz" ]] && echo -e "${Error} LuaJIT Download Faild !" && exit 1
        cd /root && tar -zxf LuaJIT-${LuaJIT_Ver}.tar.gz
        cd LuaJIT-${LuaJIT_Ver}
        make install PREFIX=/usr/local/luajit
        [[ ! -e "/usr/local/luajit/bin/luajit-${LuaJIT_Ver}" ]] && echo -e "${Error} LuaJIT Install Faild !" && exit 1
        echo -e "${Info} LuaJIT Install Success."
}
Download_modules(){
        wget -q 'https://github.com/simpl/ngx_devel_kit/archive/${Ngx_Devel_Kit_Ver}.tar.gz' -O /root/${Ngx_Devel_Kit_Ver}.tar.gz
        [[ ! -e "/root/${Ngx_Devel_Kit_Ver}.tar.gz" ]] && echo -e "${Error} Ngx_Devel_Kit Download Faild !" && exit 1
        echo -e "${Info} Ngx_Devel_Kit Download Success!"
        cd /root && tar -zxf ${Ngx_Devel_Kit_Ver}.tar.gz
        Ngx_Devel_Kit_Ver_nv=`echo "${Ngx_Devel_Kit_Ver}" | sed 's/v//g'`
        wget -q 'https://github.com/openresty/lua-nginx-module/archive/${Lua_Nginx_Module_Ver}.tar.gz' -O /root/${Lua_Nginx_Module_Ver}.tar.gz
        [[ ! -e "/root/${Lua_Nginx_Module_Ver}.tar.gz" ]] && echo -e "${Error} Lua-Nginx-Module Download Faild !" && exit 1
        echo -e "${Info} Lua-Nginx-Module Download Success!"
        cd /root && tar -zxf ${Lua_Nginx_Module_Ver}.tar.gz
        Lua_Nginx_Module_Ver_nv=`echo "${Lua_Nginx_Module_Ver}" | sed 's/v//g'`
}
Buckup_Nginx_Conf(){
       	cp -r ${DirectAdminNginxConf_Path} /etc/nginxb
}
Make_Nginx(){
       	cd ${CustomBuild_Path}
        mkdir -p custom/nginx
        cp -Rp confiure/nginx/configure.nginx custom/nginx/configure.nginx
       	rm -rf ${DirectAdminNginxConf_Path}
       	export LUAJIT_LIB=/usr/local/luajit/lib
        export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
        sed -i 's/FD_SETSIZE.*/& \\/' ${CustomBuild_Path}/custom/nginx/configure.nginx
        echo "        \"--with-ld-opt='-Wl,-rpath,/usr/local/luajit/lib'\" \\" >> ${CustomBuild_Path}/custom/nginx/configure.nginx
        echo "        \"--add-module=/root/ngx_devel_kit-${Ngx_Devel_Kit_Ver_nv}\" \\" >> ${CustomBuild_Path}/custom/nginx/configure.nginx
        echo "        \"--add-module=/root/lua-nginx-module-${Lua_Nginx_Module_Ver_nv}\"" >> ${CustomBuild_Path}/custom/nginx/configure.nginx
        ./build nginx | tee log.log
        YNSuccess=`cat log.log | grep "Restarting nginx."`
        mv /etc/nginxb ${DirectAdminNginxConf_Path}
        service nginx restart
        if [ -n "${YNSuccess}" ]; then
                echo -e "${Info} Install Success. Restart Nginx Success."
        else
               	echo -e "${Error} Install Faild."
        fi
}
Install_LuaJIT
Download_modules
Buckup_Nginx_Conf
Make_Nginx
