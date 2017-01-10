#!/usr/bin/env bash

function fix {
    VBoxManage natnetwork stop --netname minikube && \
        VBoxManage natnetwork start --netname minikube && \
        runCommandOnMinikube "sudo systemctl restart docker"
}
