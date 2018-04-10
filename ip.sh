IP="$1"

Green_font_prefix="\033[32m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Tip]${Font_color_suffix}"
IPSTART=$(wget -qO- http://www.ctohome.com/linux-vps-pack/ip.php?ip_subnet=${IP} | grep "IPADDR_START" | awk '{print $2}' | sed 's/\/>//')
IPEND=$(wget -qO- http://www.ctohome.com/linux-vps-pack/ip.php?ip_subnet=${IP} | grep "IPADDR_END" | awk '{print $2}' | sed 's/\/>//')
NETMASK=$(wget -qO- http://www.ctohome.com/linux-vps-pack/ip.php?ip_subnet=${IP} | grep "NETMASK" | awk '{print $2}' | sed 's/\/>//')
GATEWAY=$(wget -qO- http://www.ctohome.com/linux-vps-pack/ip.php?ip_subnet=${IP} | tail -n +63 | head -n 1 | awk '{print $2}' | sed 's/class=t2>//' | sed 's/<\/td>//')
CanbeusedIPADDR=$(wget -qO- http://www.ctohome.com/linux-vps-pack/ip.php?ip_subnet=${IP} | tail -n +80 | head -n 1 | sed 's/\t//g' | sed 's/<br \/>/\n/g' | sed 's/<\/td>//' | sed 's/<td class=t2>//' | sed '$d')

echo -e " ${Info} Get information success,this is details:"
echo -e "${IPSTART}"
echo -e "${IPEND}"
echo -e "${NETMASK}"
echo -e "GATEWAY=${GATEWAY}"
echo -e ""
echo -e ""
echo -e " ${Info} This is ip address list:"
echo -e "${CanbeusedIPADDR}"