#!/bin/sh

PIDFILE=/var/run/coredns.pid
COREDNS=/mnt/sda1/var/lib/coredns/coredns
COREDNS_CONFIG=/mnt/sda1/var/lib/coredns/coredns.core

checkPid() {
    if [ ! -f $PIDFILE ]; then
        return 1
    fi
    pid=`cat $PIDFILE`
    if kill -0 $pid > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

start() {
    if checkPid; then
        echo "coredns is running"
        return
    fi
    echo "Starting coredns"
    systemctl stop systemd-resolved
    nohup $COREDNS -conf $COREDNS_CONFIG > /var/log/coredns.log 2>&1 &
    echo $! > $PIDFILE
    echo "Success"
}

stop() {
    if checkPid; then
        echo "Stopping coredns"
        pid=`cat $PIDFILE`
        kill $pid > /dev/null 2>&1
        count=0
        while kill -0 $pid > /dev/null 2>&1; do
            count=`expr $count + 1`
            if [ $count -gt 10 ] ;then
                kill -9 $pid > /dev/null 2>&1
                break
            fi
            sleep 1
        done
        rm $PIDFILE
        echo "Success"
    else
        echo "coredns was stopped"
    fi
}

status() {
    if checkPid; then
        echo "coredns is running"
    else
        echo "coredns was stopped"
    fi
}

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 start|stop|status"
        ;;
esac
