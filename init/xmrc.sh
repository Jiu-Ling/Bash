#!/bin/bash
PATH=/opt/rh/devtoolset-4/root/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export PATH

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
yum install centos-release-scl cmake3 hwloc-devel libmicrohttpd-devel openssl-devel -y
yum install devtoolset-4-gcc* -y
scl enable devtoolset-4 bash
wget https://cmake.org/files/v3.10/cmake-3.10.1.tar.gz
tar -zxf cmake-3.10.1.tar.gz
cd cmake-3.10.1
./configure
make -j 4 && make install
cd /root
wget https://github.com/fireice-uk/xmr-stak-cpu/archive/v1.3.0-1.5.0.tar.gz
tar -zxf v1.3.0-1.5.0.tar.gz
cd xmr-stak-cpu-1.3.0-1.5.0
sed -i 's/2.0/0.0/g' donate-level.h
/usr/local/bin/cmake .
make install
cd bin
ln -s /root/xmr-stak-cpu-1.3.0-1.5.0/bin/xmr-stak-cpu /usr/bin/xmr
cd /root
wget --no-check-certificate https://raw.githubusercontent.com/Thnineer/Bash/master/init/config3.txt -qO /root/config.txt
echo "cd /root && screen xmr" >> /etc/rc.d/rc.local
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
