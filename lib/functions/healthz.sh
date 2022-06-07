#!/usr/bin/env bash

INITIAL_DELAY=120
CHECK_INTERVAL=60
here=`cd $(dirname $BASH_SOURCE); pwd`

function checkAlive {
    echoLog "Skip checking alive"
    return 0
}

function tryFix {
    echoLog "Try fix"
    anduin-kube clear-cache
}

function healthz {
    if [ `whoami` != "root" ]; then
        echoLog "Must be root"
        exit 1
    fi
    echoLog "Healthz started"
    sleep $INITIAL_DELAY
    while true; do
        if ! checkAlive; then
            tryFix
        fi
        sleep $CHECK_INTERVAL
    done
}
