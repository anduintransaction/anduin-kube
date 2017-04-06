#!/usr/bin/env bash

function fix {
    if ! runCommandOnMinikube 'sudo iptables -L FORWARD 1 | grep "fix recursive routing" > /dev/null 2>&1'; then
        runCommandOnMinikube 'sudo iptables -I FORWARD 1 -p tcp -d 10.0.0.0/24 -j REJECT --reject-with icmp-port-unreachable -m comment --comment "fix recursive routing"'
    fi
    runCommandOnMinikube sudo ifconfig eth0 down
    echo .
    sleep 1
    VBoxManage controlvm minikube nic1 null
    echo .
    sleep 1
    VBoxManage controlvm minikube nic1 nat
    echo .
    sleep 1
    runCommandOnMinikube sudo ifconfig eth0 up
    echo .
    sleep 1
    sudo anduin-kube setup-network
}
