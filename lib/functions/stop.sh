#!/usr/bin/env bash

function stop {
    stt=`minikubeStatus`
    case $stt in
        stopped)
            sudo -E anduin-kube cleanup
            exit 0
            ;;
        *)
            minikube stop
            sudo -E anduin-kube cleanup
            ;;
    esac
}
