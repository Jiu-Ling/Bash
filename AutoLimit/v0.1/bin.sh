#!/usr/bin/env bash


CPU=`ps aux | grep "qemu-kvm"| sed '/grep/d' | awk '{print $3}' | grep -wf <(seq 100 400)`
CPUS=`ps aux | grep "qemu-kvm" | sed '/grep/d' | awk '{print $3}' | grep -wf <(seq 100 400) | wc -l`
for (( i=1; i<$[${CPUS}+1]; i++ ));
do
CPU[$i]=`echo "${CPU}" | sed -n ''${i}'p'`;
PID[$i]=`ps aux | grep "qemu-kvm" | grep "${CPU[$i]}" | sed '/grep/d' | awk '{print $2}' | sed -n ''${i}'p'`;
if [[ ! -n "${PID[$i]}" ]] ; then
	echo -e "Now is no over."
else
	if [[ ! -e "${PID[$i]}-qemu-kvm.sh" ]] ; then
	  cp /usr/local/autolimit/limit/default-example.sh /usr/local/autolimit/limit/${PID[$i]}-qemu-kvm.sh
	  sed -i 's/examplea/'${PID[$i]}'/' /usr/local/autolimit/limit/${PID[$i]}-qemu-kvm.sh
	  echo "bash /usr/local/autolimit/limit/${PID[$i]}-qemu-kvm.sh -t 1" /usr/local/autolimit/limit/main.sh
	  chmod +x /usr/local/autolimit/limit/${PID[$i]}-qemu-kvm.sh
	else 
	  echo "Exist!"
	fi
fi
done
