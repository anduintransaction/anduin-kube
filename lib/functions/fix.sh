#!/usr/bin/env bash

function fix {
    anduin-kube force-stop
    cleanupDNS && \
        cleanupRoute && \
        VBoxManage modifyvm minikube --nic1 none && \
        VBoxManage modifyvm minikube --nic1 nat && \
        anduin-kube start
}
