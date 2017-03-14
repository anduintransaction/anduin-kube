#!/usr/bin/env bash

function updateIso {
    minikubeConfigFile=~/.minikube/machines/minikube/config.json
    if [ ! -f $minikubeConfigFile ]; then
        echo "Minikube config file not found"
        exit 1
    fi
    currentVersion=`cat $minikubeConfigFile | grep Boot2DockerURL | grep -o 'v\d*\.\d*\.\d*'`
    if [ $currentVersion == $MINIKUBE_ISO_VERSION ]; then
        echo "Same version"
        exit 0
    fi
    echo "Updating minikube iso to $MINIKUBE_ISO_VERSION"
    wget -O ~/.minikube/cache/iso/minikube-$MINIKUBE_ISO_VERSION.iso https://storage.googleapis.com/minikube/iso/minikube-$MINIKUBE_ISO_VERSION.iso &&
        cp ~/.minikube/cache/iso/minikube-$MINIKUBE_ISO_VERSION.iso ~/.minikube/machines/minikube/boot2docker.iso &&
        cat $minikubeConfigFile | sed 's/minikube-'$currentVersion'.iso/minikube-'$MINIKUBE_ISO_VERSION'.iso/' > $minikubeConfigFile.new &&
        mv $minikubeConfigFile.new $minikubeConfigFile
}
