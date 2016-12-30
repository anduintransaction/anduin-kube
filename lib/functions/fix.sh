#!/usr/bin/env bash

function fix {
    runCommandOnMinikube "sudo ifconfig eth0 down"
    runCommandOnMinikube "sudo ifconfig eth0 up"
    pid=`runCommandOnMinikube "sudo cat /var/run/udhcpc.eth0.pid 2>/dev/null"`
    if [ ! -z "$pid" ]; then
        runCommandOnMinikube "sudo kill $pid 2>/dev/null"
        
    fi
    runCommandOnMinikube "sudo /sbin/udhcpc -b -i eth0 -x hostname minikube -p /var/run/udhcpc.eth0.pid"
}
