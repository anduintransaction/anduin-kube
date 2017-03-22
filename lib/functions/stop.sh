#!/usr/bin/env bash

function stop {
    stt=`minikubeStatus`
    case $stt in
        stopped)
            sudo anduin-kube cleanup
            exit 0
            ;;
        *)
            minikube stop
            sudo anduin-kube cleanup
            ;;
    esac
}
