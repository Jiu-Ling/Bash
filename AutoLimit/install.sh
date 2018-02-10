#!/usr/bin/env bash

yum install -y sed grep gawk wget curl -y

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Message]${Font_color_suffix}"
Error="${Red_font_prefix}[ERROR]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"
LimitAutoBin="/usr/local/autolimit/bin.sh"
LimitAutoCronExampleSh="/usr/local/autolimit/limit/default-example.sh"
LimitAutoCronBin="/usr/local/autolimit/limit/main.sh"
[[ -e "${LimitAutoBin}" ]] && echo -e "${Error} Autolimit is installed !" && exit 1
mkdir /usr/local/autolimit
mkdir /usr/local/autolimit/limit
wget https://raw.githubusercontent.com/Thnineer/Bash/master/AutoLimit/v0.1/bin.sh -qO ${LimitAutoBin}
wget https://raw.githubusercontent.com/Thnineer/Bash/master/AutoLimit/v0.1/limit/default-example.sh -qO ${LimitAutoCronExampleSh}
wget https://raw.githubusercontent.com/Thnineer/Bash/master/AutoLimit/v0.1/limit/main.sh -qO ${LimitAutoCronBin}
chmod +x ${LimitAutoBin}
chmod +x ${LimitAutoCronBin}
chmod -R 755 ${LimitAutoBin}
chmod -R 755 ${LimitAutoCronBin}
[[ ! -e "${LimitAutoBin}" ]] && echo -e "${Error} AutolimitBin download failed !" && exit 1
[[ ! -e "${LimitAutoCronExampleSh}" ]] && echo -e "${Error} LimitAutoCronExampleSh download failed !" && exit 1
[[ ! -e "${LimitAutoCronBin}" ]] && echo -e "${Error} LimitAutoCronBin download failed !" && exit 1
echo -e "${Info} Install success."
