!/bin/bash

while [[ $# -ge 1 ]]; do
  case $1 in
    -X|-x|--xmr)
      shift
      xmrqb="$1"
      shift
      ;;
    -P|-p|--pwd)
      shift
      PWD="$1"
      shift
      ;;
    -POOL|-pool|--poolpwd)
      shift
      POOLPWD="$1"
      shift
      ;;
    *|--help)
      echo -e "It's a shell."
      exit 1;
      ;;
    esac
  done

LIMIT='262144'

#切换ROOT
echo "${PWD}" | sudo -S su
sudo su

#Debian 9
cd /root
apt-get update
apt install libmicrohttpd-dev libssl-dev cmake build-essential libhwloc-dev cpulimit -y
wget https://github.com/fireice-uk/xmr-stak-cpu/archive/v1.3.0-1.5.0.tar.gz
tar -zxf v1.3.0-1.5.0.tar.gz
cd xmr-stak-cpu-1.3.0-1.5.0
sed -i 's/2.0/0.0/g' donate-level.h
cmake .
make install
cd bin
ln -s /root/xmr-stak-cpu-1.3.0-1.5.0/bin/xmr-stak-cpu /usr/bin/xmr
cd /root
wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/config3.txt -qO /root/config.txt
wget http://developer.axis.com/download/distribution/apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
tar zxf apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
mv apps/sys-utils/start-stop-daemon-IR1_9_18-2/ ./
rm -rf apps
cd start-stop-daemon-IR1_9_18-2/
cc start-stop-daemon.c -o start-stop-daemon
cp start-stop-daemon /usr/local/bin/start-stop-daemon
ln -s /usr/local/bin/start-stop-daemon /usr/bin/start-stop-daemon
wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/xmr -qO /etc/init.d/xmr
chmod +x /etc/init.d/xmr
update-rc.d -f xmr remove >/dev/null 2>&1
update-rc.d xmr defaults
mkdir -p ~/.xmr
chmod -R a+x ~/.xmr
sed -i 's/examplea/'${xmrqb}'/' /root/config.txt
sed -i 's/exampleb/'${POOLPWD}'/' /root/config.txt
apt install screen -y
sed -i '/^vm.nr_hugepages.*/d' /etc/sysctl.conf
echo -ne '\nvm.nr_hugepages=128\n' >>/etc/sysctl.conf
sed -i '/^\(\*\|root\).*\(hard\|soft\).*memlock/d' /etc/security/limits.conf
echo -ne "*\thard\tmemlock\t$LIMIT\n*\tsoft\tmemlock\t$LIMIT\nroot\thard\tmemlock\t$LIMIT\nroot\tsoft\tmemlock\t$LIMIT\n" >>/etc/security/limits.conf
sysctl -p
cd /root
screen xmr
