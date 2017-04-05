#!/usr/bin/env bash

function fix {
    runCommandOnMinikube sudo ifconfig eth0 down
    sleep 1
    VBoxManage controlvm minikube nic1 null
    sleep 1
    VBoxManage controlvm minikube nic1 nat
    sleep 1
    runCommandOnMinikube sudo ifconfig eth0 up
    sleep 1
    sudo anduin-kube setup-network
}
