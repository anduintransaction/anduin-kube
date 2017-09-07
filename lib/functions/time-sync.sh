#!/usr/bin/env bash

function timeSync {
    currentDate=`date "+%Y-%m-%d %H:%M:%S"`; minikube ssh -- sudo date -u --set '"'$currentDate'"'
}
