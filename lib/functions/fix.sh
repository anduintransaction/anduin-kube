#!/usr/bin/env bash

function fix {
    VBoxManage natnetwork stop --netname minikube && \
        VBoxManage natnetwork start --netname minikube && \
        runCommandOnMinikube "sudo systemctl restart docker" && \
        cleanupDNS && \
        cleanupRoute && \
        modifyDNS && \
        modifyRoute && \
        runCommandOnMinikube "sudo /mnt/sda1/var/init.d/coredns.sh stop" && \
        runCommandOnMinikube "sudo /mnt/sda1/var/init.d/coredns.sh start"
}
