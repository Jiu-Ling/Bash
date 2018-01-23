#!/usr/bin/env bash

while [[ $# -ge 1 ]]; do
    case $1 in
	-t|--time)
	 shift
	 times="$1"
	 ;;
	*)
	 echo "Error!"
	 exit 1;
	 ;;
    esac
done

BinPath="/usr/local/autolimit/limit/"
PID="examplea"
Totaltimes="24"
MaxCPU="100"

if (( "$times" < "$Totaltimes" )) ; then
	CPUNOW=`ps aux | grep "${PID}" | awk '{print $3}'`
	CPUNEW=`ps aux | grep "${PID}" | awk '{print $3}' | grep -wf <(seq 100 400)`
	Date=`date`
	  if [[ ! -n "${CPUNEW}" ]] ; then
	    echo -e "[${Date}]: ${times} time(s). Now this process does not exceed the threshold. PID ${PID},CPU ${CPUNOW}" >> ${BinPath}log.txt
	  else
	    sed -i 's/'${PID}'-qemu-kvm.sh -t '${times}'/'${PID}'-qemu-kvm.sh -t '$[${times}+1]'/' ${BinPath}main.sh
	    echo -e "[${Date}]: ${times} time(s). Now it's still beyond the limit. PID ${PID},CPU ${CPUNOW}" >> ${BinPath}log.txt
	  fi
else
	cpulimit -p ${PID} ${MaxCPU} -z &
	echo -e "[${Date}]: ${times} time(s). Now it's has been restricted. PID ${PID},CPU ${CPUNOW}" >> ${BinPath}log.txt
	sed -i '/'${PID}'-qemu-kvm.sh/d' ${BinPath}main.sh
	rm -rf ${PID}-qemu-kvm.sh
fi
