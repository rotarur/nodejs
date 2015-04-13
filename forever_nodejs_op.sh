#!/bin/bash
#
# Service script for a Node.js application running under Forever.
#
# global vars used:
# 				NAME 		- name of the application to be started
#				SOURCE_DIR	- source dir where the applications resides
#				PROJECT_DIR	- application's home diretory
#				SOURCE_FILE	- application's binary file
#				USAGE 		- usage message
#				user 		- process owner's username
#				outlog		- Forever's output logs
#				errlog		- Forever's output error log
#				logdir		- logs directory
#				node 		- Node.js's binary file
#				forever 	- Forever's binary file
#				sed 		- sed's binary file
#				awk 		- awk's binary file
# 			forever_dir - base path for all forever related files (pid files, etc.)
#				pidfile 	- application's pid file
#				foreverid 	- Forever id
#
# description: Script for running Node.js apps with Forever
# created by: rotarur
# date: 25/03/2015

# Source function library.
. /etc/init.d/functions

start() {
	echo "Starting $NAME node instance... "

	if [ "$foreverid" == "" ]; then
		# Create the log and pid files
		# make sure that the target user has access to them
		touch $outlog
		#chown $user $logfile # if necessary

		touch $pidfile
		#chown $user $pidfile # if necessary

		# Launch the application
		$forever start --uid $user -p $forever_dir --pidFile $pidfile \
			-o $outlog -e $errlog \
			-a -d $PROJECT_DIR/$SOURCE_FILE
		RETVAL=$?
	else
		echo "Instance already running!"
		RETVAL=0
	fi
}

restart() {
	echo -n "Restarting $NAME node instance : "
	if [ "$foreverid" != "" ]; then
		$forever restart -p $forever_dir $foreverid
	else
		echo "Instance is not running";
	fi
	RETVAL=$?
}

stop() {
	echo -n "Shutting down $NAME node instance : "
	if [ "$foreverid" != "" ]; then
		$forever stop -p $forever_dir $foreverid
	else
		echo "Instance is not running";
	fi
	RETVAL=$?
}

graceful() {
	echo -n "Shutting down gracefuly..."
	if [ "$foreverid" != "" ]; then
		$forever stop --killSignal=SIGTERM -p $forever_dir $foreverid
	else
		echo "Instance is not running";
	fi
	RETVAL=$?
}

NAME=$2
if [ "$NAME" == "" ]; then
	echo $USAGE
	exit 1
fi

SOURCE_DIR="$HOME/workspace"
if [ ! -d "$SOURCE_DIR" ]; then
	echo "> $SOURCE_DIR < does not exist or cannot be accessed."
	echo "Verify if the folder exists and if it has the right permissions."
	exit 1
fi

PROJECT_DIR="$SOURCE_DIR/$NAME"
if [ ! -d "$PROJECT_DIR" ]; then
	echo "Please verify the >$PROJECT_DIR<."
	exit 1
fi

logdir="$PROJECT_DIR/logs"
if [ ! -d $logdir ]; then
	echo "$pid dir does not exist. Creating..."
	mkdir $logdir
fi

SOURCE_FILE="app.js"
USAGE="Usage: forever_nodejs_op.sh {start|restart|stop|graceful|status} <app name>"
user="rr"
outlog="$PROJECT_DIR/logs/$NAME.log"
errlog="$PROJECT_DIR/logs/$NAME.err"
node=`which node`

if [ "$node" == "" ]; then
	echo "Node.js not found."
	exit 1
fi

forever=`which forever`
if [ "$forever" == "" ]; then
	echo "Forever not found."
	exit 1
fi

sed=`which sed`
awk=`which awk`

forever_dir="$PROJECT_DIR/forever"
if [ ! -d $forever_dir ]; then
	echo "$forever_dir does not exit. Creating..."
	mkdir $forever_dir
fi

pidfile="$PROJECT_DIR/logs/$NAME.pid"
if [ -f $pidfile ]; then
	read pid < $pidfile
else
	pid=""
fi

if [ "$pid" != "" ]; then
	# Gnarly sed usage to obtain the foreverid.
	#sed1="/$pid\]/p"
	sed1="/$pid/p"
	sed2="s/.*\[\([0-9]\+\)\].*\s$pid\.*/\1/g"
	foreverid=`$forever list -p $forever_dir | $sed -n $sed1 | $awk '{print $7}'`
else
	foreverid=""
fi

case "$1" in
	start)
    	start
    	;;
    restart)
		restart
		;;
	stop)
    	stop
		;;
	status)
		# warning: only tested for one application running.
		#			test with two at minimum application
		$forever list -p ${foreverid}
		RETVAL=$?
		;;
	graceful)
		graceful
		;;

	*)
		echo $USAGE
		exit 1
		;;
esac
exit $RETVAL
