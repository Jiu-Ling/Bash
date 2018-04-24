#!/usr/bin/env bash

# By Jiuling.

File="$1"
NetworkDevice=$(ifconfig | nl | sed -n ''$(ifconfig | nl |grep $(wget -qO- -t1 -T2 ipinfo.io/ip) | awk '{print $1}')'p' | awk '{print $2}' | sed 's/.$//')
IP_SegmentCount=$(cat $File | wc -l)
PWD=$(pwd)
Green_font_prefix="\033[32m" && Font_color_suffix="\033[0m"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"
Message="${Green_font_prefix}[Message]${Font_color_suffix}"

for (( i=1; i<=${IP_SegmentCount}; i++ ))
	do
		IP=$(cat $File | nl | sed -n ''${i}'p' | awk '{print $2}')
		IP_Info=$(wget -qO- http://www.ctohome.com/linux-vps-pack/ip.php?ip_subnet=${IP})
		IPSTART=$(echo "${IP_Info}" | grep "IPADDR_START" | awk '{print $2}' | sed 's/\/>//')
		IPEND=$(echo "${IP_Info}" | grep "IPADDR_END" | awk '{print $2}' | sed 's/\/>//')
		NETMASK=$(echo "${IP_Info}" | grep "NETMASK" | awk '{print $2}' | sed 's/\/>//')
		GATEWAY=$(echo "${IP_Info}" | tail -n +63 | head -n 1 | awk '{print $2}' | sed 's/class=t2>//' | sed 's/<\/td>//')
		CanbeusedIPADDR=$(echo "${IP_Info}" | tail -n +80 | head -n 1 | sed 's/\t//g' | sed 's/<br \/>/\n/g' | sed 's/<\/td>//' | sed 's/<td class=t2>//' | sed '$d')
		[[ ! -f "${PWD}/tmp.txt" ]] && touch tmp.txt
		IPCOUNT=$[$(cat tmp.txt | wc -l)+1]
		[[ ! -d "${PWD}/ipconfig" ]] && mkdir ipconfig
		Infoadd="DEVICE=${NetworkDevice}\nTYPE=Ethernet\nBOOTPROTO=static\nONBOOT=yes\nCLONENUM_START=${IPCOUNT}\n${IPSTART}\n${IPEND}\n${NETMASK}\nGATEWAY=${GATEWAY}"
		echo "${CanbeusedIPADDR}" >> tmp.txt
		echo -e "${Infoadd}" > ipconfig/ifcfg-${NetworkDevice}-range$[$i-1]
	done

echo -e " ${Tip} Success."
echo -e " ${Tip} Total:\n ${IP_SegmentCount} IP segments.\n $(cat tmp.txt | wc -l) IPs are available."
echo -e " ${Tip} IP Config Files are in ipconfig folder,you can see it now."
cat tmp.txt >> iplist.txt
rm -rf tmp.txt
while [ "$go" != 'y' ] && [ "$go" != 'n' ]
	do
		echo -e " ${Message} Do you want to copy IP config files to /etc/sysconfig/network-scripts now?"
		read -p " (y/n):" go;
	done
if [ "$go" == 'n' ];then
	ls ipconfig
fi
if [ "$go" == 'y' ];then
	cp -p ipconfig/* /etc/sysconfig/network-scripts/
	while [ "$gou" != 'y' ] && [ "$gou" != 'n' ]
		do
			echo -e " ${Message} Do you want to reload network config now?"
			read -p " (y/n):" gou;
		done
		if [ "$gou" == 'n' ];then
			echo -e " ${Tip} Exit."
		fi
		if [ "$gou" == 'y' ];then
			service network restart
			echo -e " ${Tip} Reloading success."
		fi
fi
