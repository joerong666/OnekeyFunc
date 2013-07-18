#!/bin/env bash

pwd_path=`pwd`

FUNC_HOME=`echo $pwd_path |sed 's|/[^/]*$||'`
PYTHON_CMD=$FUNC_HOME/bin/python
FUNCD_CMD=$FUNC_HOME/bin/funcd
CERTMASTER_CMD=$FUNC_HOME/bin/certmaster

#for master
CERTMASTER_CERTMASTER_CONF=$FUNC_HOME/etc/certmaster/certmaster.conf
FUNC_OVERLORD_CONF=$FUNC_HOME/etc/func/overlord.conf

#for slave
CERTMASTER_MINION_CONF=$FUNC_HOME/etc/certmaster/minion.conf
FUNC_MINION_CONF=$FUNC_HOME/etc/func/minion.conf

usage()
{
	echo "Usage: $0 [start|stop|restart|reset|info] [-m master_host] [-p master_port:slave_port] [-n minion_name]"
	exit 1
}

if [ -z "`echo $1 |egrep 'start|stop|restart|reset|info'`" ]; then
	usage
fi

master_host=`echo $* |grep ' -m ' |sed 's/^.* \s*-m\s* \([^ ]*\).*$/\1/'`
minion_name=`echo $* |grep ' -n ' |sed 's/^.* \s*-n\s* \([^ ]*\).*$/\1/'`
ports=`echo $* |grep ' -p ' |sed 's/^.* \s*-p\s* \([^ ]*\).*$/\1/'`
master_port=`echo $ports |awk -F: '{print $1}'`
slave_port=`echo $ports |awk -F: '{print $2}'`

start-certmaster()
{
	echo "Starting certmaster in nohup mode(output to certmaster.out)" 

	if [ ! -z "$master_port" ]; then
		sed -i "s#^\(listen_port \).*#\1= $master_port#" $CERTMASTER_CERTMASTER_CONF
	fi
	if [ ! -z "$slave_port" ]; then
		sed -i "s#^\(listen_port \).*#\1= $slave_port#" $FUNC_OVERLORD_CONF
	fi

	(nohup $PYTHON_CMD $CERTMASTER_CMD >certmaster.out &) >/dev/null 2>&1
}

stop-certmaster()
{
	echo "Stopping certmaster"

	proc="$FUNC_HOME/bin/certmaster"
	pId=`ps -ef|fgrep "$proc" |fgrep -v 'fgrep' |awk '{print $2}'`
	if [ ! -z "$pId" ]; then
		kill $pId
	fi
}

start-funcd()
{
	echo "Starting funcd in nohup mode(output to funcd.out)" 

	if [ ! -z "$master_host" ]; then
		sed -i "s#^\(certmaster \).*#\1= $master_host#" $CERTMASTER_MINION_CONF
	fi
	if [ ! -z "$master_port" ]; then
		sed -i "s#^\(certmaster_port \).*#\1= $master_port#" $CERTMASTER_MINION_CONF
	fi
	if [ ! -z "$slave_port" ]; then
		sed -i "s#^\(listen_port \).*#\1= $slave_port#" $FUNC_MINION_CONF
	fi
	if [ ! -z "$minion_name" ]; then
		sed -i "s#^\(minion_name\).*#\1= $minion_name#" $FUNC_MINION_CONF
	fi

	(nohup $PYTHON_CMD $FUNCD_CMD >funcd.out &) >/dev/null 2>&1
}

stop-funcd()
{	
	echo "Stopping funcd"

	proc="$FUNC_HOME/bin/funcd"
	pId=`ps -ef|fgrep "$proc" |fgrep -v 'fgrep' |awk '{print $2}'`
	if [ ! -z "$pId" ]; then
		kill $pId
	fi
}

op=$1

if [ $op = "start" ]; then
	start-certmaster
	start-funcd
fi

if [ $op = "stop" ]; then
	stop-certmaster
	stop-funcd
fi

if [ $op = "restart" ]; then
	stop-certmaster
	stop-funcd

	start-certmaster
	start-funcd
fi

if [ $op = "reset" ]; then
	stop-certmaster
	stop-funcd

	echo "Cleaning certificates"
	$PYTHON_CMD certmaster-ca --sign `$PYTHON_CMD certmaster-ca --list` >/dev/null 2>&1
	$PYTHON_CMD certmaster-ca --clean `$PYTHON_CMD certmaster-ca --list-signed` >/dev/null 2>&1
	rm -rf $FUNC_HOME/etc/pki/certmaster

	start-certmaster
	start-funcd
fi

if [ $op = "info" ]; then
    echo -e "\n$CERTMASTER_CERTMASTER_CONF:"
    echo "================================"
    egrep -v '^#' $CERTMASTER_CERTMASTER_CONF

    echo -e "\n$FUNC_OVERLORD_CONF:"
    echo "================================"
    egrep -v '^#' $FUNC_OVERLORD_CONF

    echo -e "\n$CERTMASTER_MINION_CONF:"
    echo "================================"
    egrep -v '^#' $CERTMASTER_MINION_CONF

    echo -e "\n$FUNC_MINION_CONF:"
    echo "================================"
    egrep -v '^#' $FUNC_MINION_CONF

    exit 0
fi

echo "----------------------------------------------"	
echo 'Commands:
$ ps x |grep certmaster                              					#check master(certmaster) process
$ ps x |grep funcd                                   					#check slave(funcd) process 

$ cat certmaster.out                                 					#check log of master(certmaster)
$ cat funcd.out                                      					#check log of slave(funcd)

$ ./python certmaster-ca --list                      					#show slaves queuing for certificate
$ ./python certmaster-ca --list-signed               					#show slaves which have been signed
$ ./python certmaster-ca --sign platform2            					#sign platform2 
$ ./python certmaster-ca --sign `./python certmaster-ca --list` 		#sign all slaves
$ ./python certmaster-ca --clean platform2           					#clean certificate for platform2 
$ ./python certmaster-ca --clean `./python certmaster-ca --list-signed`	#clean certificate for all slaves

$ ./python func "*" ping                             					#check connection to minions(or slaves)
'
echo "----------------------------------------------"	
