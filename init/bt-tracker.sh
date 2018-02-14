#!/bin/bash
/usr/sbin/service aria2 stop
list=`wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`
if [ -z "`grep "bt-tracker" /etc/aria2/aria2c/.conf`" ]; then
    sed -i '$a bt-tracker='${list} /etc/aria2/aria2c.conf
    echo First use,Preparing......
else
    sed -i "s@bt-tracker.*@bt-tracker=$list@g" /etc/aria2/aria2c.conf
    echo Done!
fi
/usr/sbin/service aria2 start
