#!/usr/bin/env bash

function stopCoreDNS {
    pidFile=/var/run/coredns.pid
    if [ ! -f $pidFile ]; then
        return
    fi
    pid=`cat $pidFile`
    sudo kill -9 $pidFile > /dev/null 2>&1
    sudo rm -f $pidFile    
}

function stop {
    stt=`minikubeStatus`
    case $stt in
        stopped)
            echo "Already stopped"
            stopCoreDNS
            cleanupDNS
            cleanupRoute
            exit 0
            ;;
        *)
            minikube stop
            stopCoreDNS
            cleanupDNS
            cleanupRoute
            ;;
    esac
}
